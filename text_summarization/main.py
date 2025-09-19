# text_summarisation_service/main.py

import asyncio
import json
import os
from contextlib import asynccontextmanager
from concurrent.futures import ThreadPoolExecutor

import openai
from bson import ObjectId
from fastapi import FastAPI, HTTPException
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from google.cloud import pubsub_v1
from google.auth import default

from shared.config import get_config

# --- Configuration ---
config_data = get_config()
summarization_service_config = config_data.services.text_summarization_service

MONGO_CONN_STR = os.getenv("MONGO_CONNECTION_STRING")
MONGO_DB_NAME = os.getenv("MONGO_DATABASE_NAME", "doc-intel-db")
MONGO_COLLECTION_NAME = os.getenv("MONGO_COLLECTION_NAME", "extracted_texts")
GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID", "doc-intelligence-1758210325")
PUBSUB_SUBSCRIPTION = os.getenv("PUBSUB_SUBSCRIPTION", "summarization-jobs-subscription")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

# --- Global Clients ---
mongo_client: AsyncIOMotorClient = None
db_collection = None
openai_client: openai.AsyncOpenAI = None
subscriber_client = None
executor = None


# --- Lifespan Manager for Connections ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    global mongo_client, db_collection, openai_client, subscriber_client, executor
    print("Starting up summarization service...")

    print(f"Connecting to MongoDB...")
    mongo_client = AsyncIOMotorClient(MONGO_CONN_STR)
    db_collection = mongo_client[MONGO_DB_NAME][MONGO_COLLECTION_NAME]
    print("MongoDB connection successful.")

    if not OPENAI_API_KEY:
        raise ValueError("OPENAI_API_KEY is not set.")
    openai_client = openai.AsyncOpenAI(api_key=OPENAI_API_KEY)
    print("OpenAI client initialized.")

    # Initialize Google Cloud Pub/Sub subscriber
    try:
        # Try to get default credentials (works in GCP environments)
        credentials, project = default()
        subscriber_client = pubsub_v1.SubscriberClient(credentials=credentials)
        print(f"Pub/Sub subscriber client initialized for project: {GCP_PROJECT_ID}")
    except Exception as e:
        print(f"Warning: Could not initialize Pub/Sub client with default credentials: {e}")
        # Fallback to environment-based authentication
        subscriber_client = pubsub_v1.SubscriberClient()
        print("Pub/Sub subscriber client initialized with environment credentials")

    # Create thread pool executor for blocking Pub/Sub operations
    executor = ThreadPoolExecutor(max_workers=4)

    print("Starting Pub/Sub message consumption...")
    asyncio.create_task(consume_pubsub_messages())

    yield

    print("Shutting down...")
    if executor:
        executor.shutdown(wait=True)
    if mongo_client:
        mongo_client.close()


# --- FastAPI App ---
app = FastAPI(title="Text Summarization Service", version="1.0.0", lifespan=lifespan)


@app.get(summarization_service_config.base_path + "/health", tags=["Health"])
async def health_check():
    return {"status": "Summarization Service is healthy"}


# --- Pub/Sub Worker Logic ---
class PubSubMessageBody(BaseModel):
    document_id: str
    user_id: int
    text_to_summarize: str


async def process_pubsub_message(message):
    try:
        # Decode the message data
        message_data = message.data.decode('utf-8')
        body_data = json.loads(message_data)

        validated_body = PubSubMessageBody(**body_data)
        doc_id = validated_body.document_id
        text = validated_body.text_to_summarize

        print(f"Processing document ID: {doc_id}")

        prompt = f"Please provide a concise summary of the following text:\n\n{text}"
        response = await openai_client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=150,
        )
        summary = response.choices[0].message.content.strip()

        await db_collection.update_one(
            {"_id": ObjectId(doc_id)},
            {"$set": {"summary": summary, "status": "complete"}},
        )
        print(f"Successfully summarized and updated document ID: {doc_id}")

        # Acknowledge the message to remove it from the subscription
        message.ack()
        print(f"Acknowledged message for document ID: {doc_id}")

    except Exception as e:
        print(f"Error processing message: {e}. Message will be retried.")
        # Don't acknowledge the message so it will be retried
        message.nack()


def message_callback(message):
    """Callback function for Pub/Sub messages (runs in thread pool)"""
    try:
        # Create new event loop for this thread
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        # Run the async message processing
        loop.run_until_complete(process_pubsub_message(message))
    except Exception as e:
        print(f"Error in message callback: {e}")
        message.nack()
    finally:
        loop.close()

async def consume_pubsub_messages():
    """Start consuming messages from Pub/Sub subscription"""
    subscription_path = subscriber_client.subscription_path(GCP_PROJECT_ID, PUBSUB_SUBSCRIPTION)
    
    print(f"Starting to listen for messages on {subscription_path}")
    
    # Configure flow control settings
    flow_control = pubsub_v1.types.FlowControl(max_messages=5)  # Limit concurrent messages
    
    try:
        # Start pulling messages
        streaming_pull_future = subscriber_client.subscribe(
            subscription_path, 
            callback=message_callback,
            flow_control=flow_control
        )
        
        print(f"Listening for messages on {subscription_path}...")
        
        # Keep the main thread running
        while True:
            await asyncio.sleep(1)
            
    except KeyboardInterrupt:
        streaming_pull_future.cancel()
        print("Pub/Sub message consumption stopped.")
    except Exception as e:
        print(f"Error in Pub/Sub consumption: {e}")
        await asyncio.sleep(10)  # Wait before retrying


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8002)
