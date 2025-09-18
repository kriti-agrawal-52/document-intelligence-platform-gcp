// API Configuration for Document Intelligence Platform
// This file contains all API endpoints and configuration

// Environment-based API base URLs
export const API_CONFIG = {
  AUTH_SERVICE: process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://localhost:8000',
  EXTRACTION_SERVICE: process.env.NEXT_PUBLIC_EXTRACTION_SERVICE_URL || 'http://localhost:8001',
  SUMMARIZATION_SERVICE: process.env.NEXT_PUBLIC_SUMMARIZATION_SERVICE_URL || 'http://localhost:8002'
} as const;

// API endpoints mapping
export const ENDPOINTS = {
  // Authentication Service
  AUTH: {
    REGISTER: '/auth/register',
    LOGIN: '/auth/token',
    LOGOUT: '/auth/logout',
    PROFILE: '/auth/users/me',
    UPDATE_PROFILE: '/auth/users/me',
    CHANGE_PASSWORD: '/auth/users/me/change-password',
    DELETE_ACCOUNT: '/auth/users/me',
    HEALTH: '/auth/health'
  },
  // Text Extraction Service
  EXTRACTION: {
    UPLOAD_IMAGE: '/extract/image_text',
    UPLOAD_PDF: '/extract/pdf_text',
    GET_DOCUMENTS: '/extract/documents',
    GET_DOCUMENT: '/extract/document',
    HEALTH: '/extract/health'
  },
  // Text Summarization Service (mainly background processing)
  SUMMARIZATION: {
    HEALTH: '/health'
  }
} as const;

// Request timeout configuration
export const TIMEOUT_CONFIG = {
  DEFAULT: 10000, // 10 seconds
  UPLOAD: 60000,  // 60 seconds for file uploads
  LONG_POLLING: 30000 // 30 seconds for status polling
} as const;

// File upload constraints (matching backend)
export const UPLOAD_CONSTRAINTS = {
  IMAGE: {
    MAX_SIZE: 5 * 1024 * 1024, // 5MB
    ALLOWED_TYPES: ['image/png', 'image/jpeg', 'image/jpg'],
    ALLOWED_EXTENSIONS: ['.png', '.jpg', '.jpeg']
  },
  PDF: {
    MAX_SIZE: 10 * 1024 * 1024, // 10MB
    MAX_PAGES: 20,
    ALLOWED_TYPES: ['application/pdf'],
    ALLOWED_EXTENSIONS: ['.pdf']
  }
} as const;

// Polling configuration for document status updates
export const POLLING_CONFIG = {
  INTERVAL: 3000, // 3 seconds
  MAX_RETRIES: 100, // Maximum number of polling attempts
  BACKOFF_FACTOR: 1.2 // Exponential backoff multiplier
} as const;
