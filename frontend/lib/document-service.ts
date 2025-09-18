// Document service for Document Intelligence Platform
// Handles file uploads, document management, and status polling

import { extractionApi, ApiClientError } from './api-client';
import { ENDPOINTS, TIMEOUT_CONFIG, POLLING_CONFIG } from './api-config';
import type {
  DocumentMetadata,
  DocumentStatusResponse,
  JobAcceptedResponse,
  ImageUploadRequest,
  PDFUploadRequest,
  PaginationParams,
  HealthResponse
} from './types';

export class DocumentService {
  // Active polling intervals to manage cleanup
  private activePolls = new Map<string, NodeJS.Timeout>();

  /**
   * Upload image for text extraction
   */
  async uploadImage(uploadData: ImageUploadRequest, onProgress?: (progress: number) => void): Promise<JobAcceptedResponse> {
    try {
      const formData = new FormData();
      formData.append('image', uploadData.image);
      formData.append('image_name', uploadData.image_name);

      // Note: Progress tracking would need XMLHttpRequest or a custom fetch wrapper
      // For now, we'll use the standard fetch API
      const response = await extractionApi.post<JobAcceptedResponse>(
        ENDPOINTS.EXTRACTION.UPLOAD_IMAGE,
        formData,
        { timeout: TIMEOUT_CONFIG.UPLOAD }
      );

      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        // Handle specific error cases
        if (error.status === 409) {
          throw new Error('A document with this name already exists. Please choose a different name.');
        }
        if (error.status === 413) {
          throw new Error('File is too large. Please select a smaller image.');
        }
        if (error.status === 400) {
          throw new Error(error.message || 'Invalid file format. Please upload a PNG, JPG, or JPEG image.');
        }
        throw new Error(error.message);
      }
      throw new Error('Failed to upload image. Please try again.');
    }
  }

  /**
   * Upload PDF for text extraction
   */
  async uploadPDF(uploadData: PDFUploadRequest, onProgress?: (progress: number) => void): Promise<JobAcceptedResponse> {
    try {
      const formData = new FormData();
      formData.append('pdf_file', uploadData.pdf_file);
      formData.append('document_name', uploadData.document_name);

      const response = await extractionApi.post<JobAcceptedResponse>(
        ENDPOINTS.EXTRACTION.UPLOAD_PDF,
        formData,
        { timeout: TIMEOUT_CONFIG.UPLOAD }
      );

      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        // Handle specific error cases
        if (error.status === 409) {
          throw new Error('A document with this name already exists. Please choose a different name.');
        }
        if (error.status === 413) {
          throw new Error('PDF file is too large. Maximum size is 10MB.');
        }
        if (error.status === 400) {
          if (error.message.includes('too many pages')) {
            throw new Error('PDF has too many pages. Maximum is 20 pages.');
          }
          throw new Error(error.message || 'Invalid PDF file. Please upload a valid PDF document.');
        }
        throw new Error(error.message);
      }
      throw new Error('Failed to upload PDF. Please try again.');
    }
  }

  /**
   * Get list of user documents with pagination
   */
  async getDocuments(params: PaginationParams = {}): Promise<DocumentMetadata[]> {
    try {
      const { limit = 50, skip = 0 } = params;
      const queryParams = new URLSearchParams({
        limit: limit.toString(),
        skip: skip.toString()
      });

      const response = await extractionApi.get<DocumentMetadata[]>(
        `${ENDPOINTS.EXTRACTION.GET_DOCUMENTS}?${queryParams}`
      );

      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        throw new Error(error.message);
      }
      throw new Error('Failed to fetch documents.');
    }
  }

  /**
   * Get specific document details by name
   */
  async getDocument(documentName: string): Promise<DocumentStatusResponse> {
    try {
      const response = await extractionApi.get<DocumentStatusResponse>(
        `${ENDPOINTS.EXTRACTION.GET_DOCUMENT}/${encodeURIComponent(documentName)}`
      );

      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        if (error.status === 404) {
          throw new Error('Document not found.');
        }
        throw new Error(error.message);
      }
      throw new Error('Failed to fetch document details.');
    }
  }

  /**
   * Start polling document status for real-time updates
   */
  startStatusPolling(
    documentName: string,
    onStatusUpdate: (document: DocumentStatusResponse) => void,
    onError?: (error: Error) => void
  ): string {
    // Generate unique poll ID
    const pollId = `${documentName}-${Date.now()}`;
    
    let retryCount = 0;
    let currentInterval = POLLING_CONFIG.INTERVAL;

    const poll = async () => {
      try {
        const document = await this.getDocument(documentName);
        
        // Call update callback
        onStatusUpdate(document);
        
        // Stop polling if document is completed or failed
        if (document.status === 'completed' || document.status === 'failed') {
          this.stopStatusPolling(pollId);
          return;
        }

        // Reset retry count on successful poll
        retryCount = 0;
        currentInterval = POLLING_CONFIG.INTERVAL;

        // Schedule next poll
        const timeoutId = setTimeout(poll, currentInterval);
        this.activePolls.set(pollId, timeoutId);

      } catch (error) {
        retryCount++;
        
        // Stop polling if max retries reached
        if (retryCount >= POLLING_CONFIG.MAX_RETRIES) {
          this.stopStatusPolling(pollId);
          onError?.(new Error('Max polling retries reached'));
          return;
        }

        // Exponential backoff
        currentInterval = Math.min(
          currentInterval * POLLING_CONFIG.BACKOFF_FACTOR,
          30000 // Max 30 seconds
        );

        // Call error callback but continue polling
        onError?.(error instanceof Error ? error : new Error('Polling error'));

        // Schedule next poll with backoff
        const timeoutId = setTimeout(poll, currentInterval);
        this.activePolls.set(pollId, timeoutId);
      }
    };

    // Start initial poll
    const timeoutId = setTimeout(poll, 1000); // Start after 1 second
    this.activePolls.set(pollId, timeoutId);

    return pollId;
  }

  /**
   * Stop status polling
   */
  stopStatusPolling(pollId: string): void {
    const timeoutId = this.activePolls.get(pollId);
    if (timeoutId) {
      clearTimeout(timeoutId);
      this.activePolls.delete(pollId);
    }
  }

  /**
   * Stop all active polling
   */
  stopAllPolling(): void {
    this.activePolls.forEach((timeoutId) => {
      clearTimeout(timeoutId);
    });
    this.activePolls.clear();
  }

  /**
   * Get active polling count (for debugging)
   */
  getActivePollCount(): number {
    return this.activePolls.size;
  }

  /**
   * Check extraction service health
   */
  async checkHealth(): Promise<HealthResponse> {
    try {
      const response = await extractionApi.get<HealthResponse>(
        ENDPOINTS.EXTRACTION.HEALTH,
        { includeAuth: false }
      );
      return response;
    } catch (error) {
      throw new Error('Extraction service is unavailable');
    }
  }

  /**
   * Validate file before upload
   */
  validateImageFile(file: File): { isValid: boolean; error?: string } {
    // Check file type
    if (!file.type.startsWith('image/')) {
      return { isValid: false, error: 'Please select an image file (PNG, JPG, or JPEG).' };
    }

    // Check file size (5MB limit for images)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      return { isValid: false, error: 'Image file is too large. Maximum size is 5MB.' };
    }

    return { isValid: true };
  }

  /**
   * Validate PDF file before upload
   */
  validatePDFFile(file: File): { isValid: boolean; error?: string } {
    // Check file type
    if (file.type !== 'application/pdf') {
      return { isValid: false, error: 'Please select a PDF file.' };
    }

    // Check file size (10MB limit for PDFs)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      return { isValid: false, error: 'PDF file is too large. Maximum size is 10MB.' };
    }

    return { isValid: true };
  }

  /**
   * Generate unique document name if needed
   */
  generateUniqueDocumentName(originalName: string): string {
    const timestamp = Date.now();
    const nameWithoutExtension = originalName.replace(/\.[^/.]+$/, '');
    const extension = originalName.split('.').pop();
    return `${nameWithoutExtension}_${timestamp}${extension ? '.' + extension : ''}`;
  }

  /**
   * Format file size for display
   */
  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * Get file extension from filename
   */
  getFileExtension(filename: string): string {
    return filename.split('.').pop()?.toLowerCase() || '';
  }

  /**
   * Check if filename has valid extension for images
   */
  hasValidImageExtension(filename: string): boolean {
    const extension = this.getFileExtension(filename);
    return ['jpg', 'jpeg', 'png'].includes(extension);
  }

  /**
   * Check if filename has valid extension for PDFs
   */
  hasValidPDFExtension(filename: string): boolean {
    const extension = this.getFileExtension(filename);
    return extension === 'pdf';
  }
}

// Export singleton instance
export const documentService = new DocumentService();
