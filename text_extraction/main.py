# text_extraction_service/main.py

import asyncio
import base64
import json
import os
from contextlib import asynccontextmanager
from datetime import datetime, timezone
from io import BytesIO

import openai
from bson import ObjectId 
from fastapi import (Depends, FastAPI, File, Form, HTTPException, UploadFile,
                     status)
from motor.motor_asyncio import AsyncIOMotorCollection
from pydantic import BaseModel, Field
from pymongo.errors import DuplicateKeyError
from google.cloud import storage, pubsub_v1
from google.api_core import exceptions as gcp_exceptions
# --- Import local modules ---
from text_extraction_service.database import (close_mongo_connection,
                                              connect_to_mongo,
                                              get_extracted_texts_collection)
from text_extraction_service.redis_cache import (cache_extraction,
                                                 close_redis_connection,
                                                 connect_to_redis,
                                                 get_cached_extraction)
from text_extraction_service.pdf_processor import create_pdf_processor

from shared.auth_utils import get_current_user_id
from shared.config import get_config, get_env_vars
from shared.jwt_blacklist import (close_jwt_blacklist_redis,
                                  init_jwt_blacklist_redis)

# --- Global Configuration and Clients ---
config_data = get_config()
env_vars = get_env_vars()
openai_client = None
pubsub_publisher = None 
gcs_client = None
pdf_processor = None
# Environment variables
PUBSUB_TOPIC_NAME = env_vars.PUBSUB_TOPIC_NAME
GCP_PROJECT_ID = env_vars.GCP_PROJECT_ID
GCS_BUCKET = env_vars.GCS_USER_IMAGES_BUCKET

# --- FastAPI App Initialization ---
app = FastAPI(
    title="Text Extraction Service",
    description="Extracts text and queues summarization jobs.",
    version="0.3.0",
    lifespan=lifespan,  # The lifespan manager is defined below
)


# --- Lifespan Manager for Connections ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    global openai_client, sqs_client, s3_client, pdf_processor

    # Initialize OpenAI client
    if not env_vars.openai_api_key:
        raise ValueError("OPENAI_API_KEY environment variable is not set.")
    openai_client = openai.AsyncOpenAI(api_key=env_vars.openai_api_key)
    print("OpenAI client initialized.")

    # Initialize SQS client if the URL is configured
    if SQS_QUEUE_URL:
        sqs_client = boto3.client("sqs", region_name=AWS_REGION)
        print(f"SQS client initialized for queue: {SQS_QUEUE_URL}")

    # Initialize S3 client if bucket is configured
    if S3_BUCKET:
        s3_client = boto3.client("s3", region_name=AWS_REGION)
        print(f"S3 client initialized for bucket: {S3_BUCKET}")

    # Initialize PDF processor
    if openai_client:
        pdf_processor = create_pdf_processor(openai_client)
        print("PDF processor initialized.")

    # Use asyncio.gather to initialize database connections concurrently
    await asyncio.gather(
        connect_to_mongo(), connect_to_redis(), init_jwt_blacklist_redis()
    )
    
    print("Startup complete.")
    yield  # The application is now running

    # --- Cleanup on Shutdown ---
    print("Shutting down...")
    if openai_client:
        # The openai client uses httpx which is best closed explicitly
        await openai_client.close()
        print("OpenAI client closed.")
    
    await asyncio.gather(
        close_mongo_connection(), close_redis_connection(), close_jwt_blacklist_redis()
    )
    print("Shutdown complete.")


# --- Helper Functions ---
async def upload_image_to_s3(image_bytes: bytes, s3_key: str, content_type: str) -> str:
    """Upload image to S3 and return the S3 URL."""
    try:
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=image_bytes,
            ContentType=content_type,
            Metadata={
                "uploaded_at": datetime.now(timezone.utc).isoformat(),
                "service": "text-extraction",
            },
        )
        s3_url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{s3_key}"
        print(f"Successfully uploaded image to S3: {s3_url}")
        return s3_url
    except Exception as e:
        print(f"Failed to upload image to S3: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to upload image to S3: {str(e)}"
        )


async def encode_image_to_base64_url(image_bytes: bytes):
    """Encodes image bytes to a base64 data URL."""
    try:
        encoded_image = base64.b64encode(image_bytes).decode("utf-8")
        return {
            "type": "image_url",
            "image_url": {"url": f"data:image/jpeg;base64,{encoded_image}"},
        }
    except Exception as e:
        print(f"Failed to encode image to base64: {e}")
        return None


async def create_openai_image_message(image_message: dict, prompt: str):
    """Creates a single OpenAI message for image processing."""
    return {
        "role": "user",
        "content": [{"type": "text", "text": prompt}, image_message],
    }


async def cache_user_recent_extractions(
    user_id: int, document_id: str, image_name: str, s3_url: str
):
    """Cache user's recent extractions in Redis for fast retrieval."""
    try:
        cache_key = config_data.cache.redis_key_patterns.user_recent_extractions.format(
            user_id=user_id
        )
        extraction_data = {
            "document_id": document_id,
            "image_name": image_name,
            "s3_url": s3_url,
            "cached_at": datetime.now(timezone.utc).isoformat(),
        }

        # Use Redis cache function from redis_cache.py
        await cache_extraction(
            cache_key,
            json.dumps(extraction_data),
            ttl=config_data.cache.ttl.user_recent_extractions,
        )
        print(f"Cached recent extraction for user {user_id}: {document_id}")
    except Exception as e:
        print(f"Failed to cache user recent extractions: {e}")
        # Don't fail the request if caching fails


# --- Pydantic Models for API Responses ---
class DocumentStatusResponse(BaseModel):
    document_id: str
    image_name: str
    status: str
    extracted_text: str
    summary: str | None = None
    s3_url: str | None = None
    created_at: str
    updated_at: str | None = None


class JobAcceptedResponse(BaseModel):
    message: str
    document_id: str
    image_name: str
    extracted_text: str
    s3_url: str


class DocumentMetadata(BaseModel):
    document_id: str
    image_name: str
    file_type: str = "image"  # "image" or "pdf"
    status: str
    created_at: str
    updated_at: str | None = None
    s3_url: str | None = None
    has_summary: bool
    # PDF-specific fields
    num_pages: int | None = None
    file_size_mb: float | None = None


# --- API Endpoints ---
@app.get(
    config_data.services.text_extraction_service.base_path + "/health", tags=["Health"]
)
async def health_check():
    return {"status": "Text Extraction Service is healthy!"}


@app.post(
    config_data.services.text_extraction_service.base_path + "/image_text",
    summary="Extract text from an uploaded image and start summarization job.",
    response_model=JobAcceptedResponse,
    status_code=status.HTTP_202_ACCEPTED,
    tags=["Extraction"],
)
async def extract_text_from_image(
    user_id: int = Depends(get_current_user_id),
    image: UploadFile = File(...),
    image_name: str = Form(...),
    collection: AsyncIOMotorCollection = Depends(get_extracted_texts_collection),
):
    # Validate file type
    if not image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Only images are allowed.",
        )

    # Check for duplicate document name for this user
    existing_doc = await collection.find_one(
        {"image_name": image_name, "user_id": user_id}
    )
    if existing_doc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A document with the name '{image_name}' already exists.",
        )

    try:
        # Step 1: Read image bytes
        image_bytes = await image.read()

        # Step 2: Create document in DB first to get document_id
        current_time = datetime.now(timezone.utc)
        db_document = {
            "image_name": image_name,
            "user_id": user_id,
            "file_type": "image",
            "extracted_text": "",
            "summary": None,
            "status": "uploading",
            "s3_url": None,
            "created_at": current_time,
            "updated_at": current_time,
        }
        insert_result = await collection.insert_one(db_document)
        document_id = str(insert_result.inserted_id)

        # Step 3: Upload to S3 with format {user_id}_{document_id}_{image_name}
        file_extension = (
            image.filename.split(".")[-1] if "." in image.filename else "jpg"
        )
        s3_key = f"{user_id}_{document_id}_{image_name}.{file_extension}"
        s3_url = await upload_image_to_s3(image_bytes, s3_key, image.content_type)

        # Step 4: Update document with S3 URL
        await collection.update_one(
            {"_id": insert_result.inserted_id},
            {
                "$set": {
                    "s3_url": s3_url,
                    "status": "processing_extraction",
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )

        # Step 5: Extract text using OpenAI
        image_message_content = await encode_image_to_base64_url(image_bytes)
        if not image_message_content:
            await collection.update_one(
                {"_id": insert_result.inserted_id},
                {
                    "$set": {
                        "status": "failed",
                        "updated_at": datetime.now(timezone.utc),
                    }
                },
            )
            raise HTTPException(
                status_code=500, detail="Failed to encode image for processing."
            )

        prompt_text = config_data.openai.prompt_for_text_extraction
        openai_message = await create_openai_image_message(
            image_message_content, prompt_text
        )

        response = await openai_client.chat.completions.create(
            model=config_data.openai.model,
            messages=[openai_message],
            max_tokens=config_data.openai.max_tokens,
            temperature=config_data.openai.temperature,
        )

        extracted_text_result = response.choices[0].message.content
        if not extracted_text_result:
            await collection.update_one(
                {"_id": insert_result.inserted_id},
                {
                    "$set": {
                        "status": "failed",
                        "updated_at": datetime.now(timezone.utc),
                    }
                },
            )
            raise HTTPException(status_code=500, detail="OpenAI returned no text.")

        # Step 6: Update document with extracted text
        await collection.update_one(
            {"_id": insert_result.inserted_id},
            {
                "$set": {
            "extracted_text": extracted_text_result,
            "status": "processing_summary",
                    "updated_at": datetime.now(timezone.utc),
        }
            },
        )
        
        # Step 7: Send message to SQS for summarization
        if sqs_client and SQS_QUEUE_URL:
            message_body = {
                "document_id": document_id,
                "user_id": user_id,
                "text_to_summarize": extracted_text_result,
            }
            sqs_client.send_message(
                QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(message_body)
            )
            print(f"Sent document ID {document_id} to SQS for summarization.")
        else:
            print("WARNING: SQS client not configured. Summarization job not queued.")
            # Mark as complete if no summarization is configured
            await collection.update_one(
                {"_id": insert_result.inserted_id},
                {
                    "$set": {
                        "status": "completed",
                        "updated_at": datetime.now(timezone.utc),
                    }
                },
            )

        # Step 8: Cache user's recent extractions in Redis
        await cache_user_recent_extractions(user_id, document_id, image_name, s3_url)

        return JobAcceptedResponse(
            message="Text extracted successfully. Summarization is in progress.",
            document_id=document_id,
            image_name=image_name,
            extracted_text=extracted_text_result,
            s3_url=s3_url,
        )

    except openai.APIStatusError as e:
        # Update document status to failed
        if "document_id" in locals():
            await collection.update_one(
                {"_id": ObjectId(document_id)},
                {
                    "$set": {
                        "status": "failed",
                        "updated_at": datetime.now(timezone.utc),
                    }
                },
            )
        raise HTTPException(
            status_code=e.status_code or 500,
            detail=f"OpenAI API error: {e.response.text}",
        )
    except Exception as e:
        # Update document status to failed
        if "document_id" in locals():
            await collection.update_one(
                {"_id": ObjectId(document_id)},
                {
                    "$set": {
                        "status": "failed",
                        "updated_at": datetime.now(timezone.utc),
                    }
                },
            )
        raise HTTPException(
            status_code=500, detail=f"An unexpected error occurred: {str(e)}"
        )


@app.post(
    config_data.services.text_extraction_service.base_path + "/pdf_text",
    summary="Extract text from an uploaded PDF and start summarization job.",
    response_model=JobAcceptedResponse,
    status_code=status.HTTP_202_ACCEPTED,
    tags=["Extraction"],
)
async def extract_text_from_pdf(
    user_id: int = Depends(get_current_user_id),
    pdf_file: UploadFile = File(...),
    document_name: str = Form(...),
    collection: AsyncIOMotorCollection = Depends(get_extracted_texts_collection),
):
    """
    Extract text from an uploaded PDF document.
    
    This endpoint:
    1. Validates the PDF file
    2. Stores the raw PDF in S3
    3. Converts PDF pages to images
    4. Extracts text from each page using OpenAI Vision API
    5. Concatenates text from all pages
    6. Stores the result in DocumentDB
    7. Queues the text for summarization via SQS
    8. Caches the extraction for quick user access
    """
    # Validate file type
    if not pdf_file.content_type == "application/pdf":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid file type. Only PDF files are allowed.",
        )
    
    # Check if document name already exists for this user
    existing_doc = await collection.find_one(
        {"user_id": user_id, "image_name": document_name}
    )
    if existing_doc:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Document with name '{document_name}' already exists for this user.",
        )

    try:
        # Read PDF content
        pdf_content = await pdf_file.read()
        
        # Validate PDF
        if not pdf_processor.validate_pdf(pdf_content):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or corrupted PDF file.",
            )
        
        # Get PDF size information
        pdf_info = pdf_processor.get_pdf_size_info(pdf_content)
        
        # Check file size limits (conservative for practice environment)
        max_size_mb = 10  # Reduced for cost-effective processing
        if pdf_info.get("size_mb", 0) > max_size_mb:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"PDF file too large. Maximum size is {max_size_mb}MB.",
            )
        
        # Check page limits (conservative for practice environment)
        max_pages = 20  # Reduced to prevent resource exhaustion
        if pdf_info.get("num_pages", 0) > max_pages:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"PDF has too many pages. Maximum is {max_pages} pages.",
            )

        print(f"Processing PDF: {document_name}, Size: {pdf_info.get('size_mb')}MB, Pages: {pdf_info.get('num_pages')}")

        # Step 1: Create initial document in DocumentDB to get document_id
        document_data = {
            "user_id": user_id,
            "image_name": document_name,
            "file_type": "pdf",
            "file_size_mb": pdf_info.get("size_mb"),
            "num_pages": pdf_info.get("num_pages"),
            "status": "processing_extraction",
            "created_at": datetime.now(timezone.utc),
        }
        
        result = await collection.insert_one(document_data)
        document_id = str(result.inserted_id)
        print(f"Created document record with ID: {document_id}")

        # Step 2: Upload raw PDF to S3
        s3_key = f"{user_id}_{document_id}_{document_name}.pdf"
        s3_url = await upload_pdf_to_s3(pdf_content, s3_key)
        print(f"Uploaded PDF to S3: {s3_url}")

        # Step 3: Update document with S3 URL
        await collection.update_one(
            {"_id": ObjectId(document_id)},
            {
                "$set": {
                    "s3_url": s3_url,
                    "s3_key": s3_key,
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )

        # Step 4: Process PDF (convert to images and extract text)
        extracted_text, pdf_metadata, actual_pages = await pdf_processor.process_pdf(
            pdf_content, document_name
        )
        
        print(f"Extracted text from PDF: {len(extracted_text)} characters from {actual_pages} pages")

        # Step 5: Update document with extracted text and processing status
        await collection.update_one(
            {"_id": ObjectId(document_id)},
            {
                "$set": {
                    "extracted_text": extracted_text,
                    "pdf_metadata": pdf_metadata,
                    "actual_pages": actual_pages,
                    "status": "processing_summary",
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )

        # Step 6: Send message to SQS for summarization
        if sqs_client and SQS_QUEUE_URL:
            sqs_message = {
                "document_id": document_id,
                "user_id": user_id,
                "text_to_summarize": extracted_text,
            }
            sqs_client.send_message(
                QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps(sqs_message)
            )
            print(f"Sent SQS message for document {document_id}")

        # Step 7: Cache user's recent extractions
        await cache_user_recent_extractions(user_id, document_id, document_name, s3_url)

        return JobAcceptedResponse(
            message="Text extracted from PDF successfully. Summarization is in progress.",
            document_id=document_id,
            image_name=document_name,
            extracted_text=extracted_text[:500] + "..." if len(extracted_text) > 500 else extracted_text,  # Truncate for response
            s3_url=s3_url,
        )

    except HTTPException:
        # Re-raise HTTP exceptions (validation errors)
        raise
    except openai.APIStatusError as e:
        # Update document status to failed
        if "document_id" in locals():
            await collection.update_one(
                {"_id": ObjectId(document_id)},
                {
                    "$set": {
                        "status": "failed",
                        "error": f"OpenAI API error: {str(e)}",
                        "updated_at": datetime.now(timezone.utc),
                    }
                },
            )
        raise HTTPException(
            status_code=503, detail=f"OpenAI API error: {str(e)}"
        )
    except Exception as e:
        # Update document status to failed
        if "document_id" in locals():
            await collection.update_one(
                {"_id": ObjectId(document_id)},
                {
                    "$set": {
                        "status": "failed",
                        "error": str(e),
                        "updated_at": datetime.now(timezone.utc),
                    }
                },
            )
        raise HTTPException(
            status_code=500, detail=f"An unexpected error occurred: {str(e)}"
        )


async def upload_pdf_to_s3(pdf_content: bytes, s3_key: str) -> str:
    """Upload PDF content to S3 and return the URL."""
    try:
        s3_client.put_object(
            Bucket=S3_BUCKET,
            Key=s3_key,
            Body=pdf_content,
            ContentType="application/pdf",
        )
        s3_url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{s3_key}"
        return s3_url
    except Exception as e:
        print(f"Failed to upload PDF to S3: {e}")
        raise HTTPException(
            status_code=500, detail=f"Failed to upload PDF to S3: {str(e)}"
        )


@app.get(
    config_data.services.text_extraction_service.base_path + "/documents",
    response_model=list[DocumentMetadata],
    summary="Get list of user's documents with metadata",
    tags=["Extraction"],
)
async def get_user_documents(
    user_id: int = Depends(get_current_user_id),
    collection: AsyncIOMotorCollection = Depends(get_extracted_texts_collection),
    limit: int = 50,
    skip: int = 0,
):
    """Get list of user's documents sorted by creation date (newest first)."""
    cursor = (
        collection.find({"user_id": user_id})
        .sort("created_at", -1)
        .skip(skip)
        .limit(limit)
    )

    documents = []
    async for doc in cursor:
        doc_metadata = DocumentMetadata(
            document_id=str(doc["_id"]),
            image_name=doc["image_name"],
            file_type=doc.get("file_type", "image"),
            status=doc["status"],
            created_at=doc["created_at"].isoformat(),
            updated_at=doc.get("updated_at", doc["created_at"]).isoformat(),
            s3_url=doc.get("s3_url"),
            has_summary=bool(doc.get("summary")),
            num_pages=doc.get("num_pages"),
            file_size_mb=doc.get("file_size_mb"),
        )
        documents.append(doc_metadata)

    return documents


@app.get(
    config_data.services.text_extraction_service.base_path + "/document/{image_name}",
    response_model=DocumentStatusResponse,
    summary="Get the full details of a specific document",
    tags=["Extraction"],
)
async def get_document_status(
    image_name: str,
    user_id: int = Depends(get_current_user_id),
    collection: AsyncIOMotorCollection = Depends(get_extracted_texts_collection),
):
    document = await collection.find_one({"image_name": image_name, "user_id": user_id})
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Document not found."
        )

    return DocumentStatusResponse(
        document_id=str(document["_id"]),
        image_name=document["image_name"],
        status=document["status"],
        extracted_text=document.get("extracted_text", ""),
        summary=document.get("summary"),
        s3_url=document.get("s3_url"),
        created_at=document["created_at"].isoformat(),
        updated_at=document.get("updated_at", document["created_at"]).isoformat(),
    )


# Run the application for local development
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "text_extraction_service.main:app",
        host=config_data.services.text_extraction_service.host,
        port=config_data.services.text_extraction_service.port,
        reload=True,
    )
