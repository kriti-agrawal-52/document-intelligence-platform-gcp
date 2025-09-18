// Type definitions for Document Intelligence Platform API
// These types match the backend API response models

// Authentication Types
export interface UserCreate {
  username: string;
  email: string;
  password: string;
}

export interface UserOut {
  id: number;
  username: string;
  email: string | null;
  is_active: boolean;
}

export interface UserProfileResponse {
  id: number;
  username: string;
  email: string | null;
  is_active: boolean;
  created_at: string | null;
  last_updated: string | null;
}

export interface UserProfileUpdate {
  username?: string;
  email?: string;
}

export interface PasswordChangeRequest {
  current_password: string;
  new_password: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
  user_id: number;
}

// Document Types
export type DocumentStatus = 
  | 'uploading' 
  | 'processing_extraction' 
  | 'processing_summary' 
  | 'completed' 
  | 'failed';

export type FileType = 'image' | 'pdf';

export interface DocumentMetadata {
  document_id: string;
  image_name: string;
  file_type: FileType;
  status: DocumentStatus;
  created_at: string;
  updated_at: string | null;
  s3_url: string | null;
  has_summary: boolean;
  // PDF-specific fields
  num_pages?: number;
  file_size_mb?: number;
}

export interface DocumentStatusResponse {
  document_id: string;
  image_name: string;
  status: DocumentStatus;
  extracted_text: string;
  summary: string | null;
  s3_url: string | null;
  created_at: string;
  updated_at: string | null;
}

export interface JobAcceptedResponse {
  message: string;
  document_id: string;
  image_name: string;
  extracted_text: string;
  s3_url: string;
}

// Upload Types
export interface ImageUploadRequest {
  image: File;
  image_name: string;
}

export interface PDFUploadRequest {
  pdf_file: File;
  document_name: string;
}

// Frontend-specific types
export interface UploadProgress {
  id: string;
  filename: string;
  progress: number;
  status: 'uploading' | 'processing' | 'completed' | 'failed';
  error?: string;
}

export interface PaginationParams {
  limit?: number;
  skip?: number;
}

export interface DocumentsListResponse {
  documents: DocumentMetadata[];
  total: number;
  skip: number;
  limit: number;
  has_more: boolean;
}

// UI State Types
export interface AuthState {
  isAuthenticated: boolean;
  user: UserProfileResponse | null;
  token: string | null;
  loading: boolean;
  error: string | null;
}

export interface DocumentsState {
  list: DocumentMetadata[];
  current: DocumentStatusResponse | null;
  loading: boolean;
  error: string | null;
  pagination: {
    skip: number;
    limit: number;
    total: number;
    has_more: boolean;
  };
}

export interface UploadsState {
  inProgress: Map<string, UploadProgress>;
  completed: string[];
  failed: string[];
}

export interface UIState {
  sidebarOpen: boolean;
  notifications: Notification[];
  activePolls: Map<string, NodeJS.Timeout>;
}

// Notification types
export interface Notification {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message?: string;
  timestamp: number;
  duration?: number;
}

// Form validation types
export interface FormErrors {
  [key: string]: string | undefined;
}

// API Error types
export interface ApiErrorResponse {
  detail: string;
  status_code?: number;
}

// Health check response
export interface HealthResponse {
  status: string;
}

// File validation types
export interface FileValidationResult {
  isValid: boolean;
  error?: string;
  warnings?: string[];
}

export interface FileInfo {
  name: string;
  size: number;
  type: string;
  lastModified: number;
}

// Status badge types for UI components
export type StatusBadgeVariant = 'processing' | 'completed' | 'failed' | 'uploading';
export type FileTypeBadgeVariant = 'image' | 'pdf';

// Component prop types
export interface StatusBadgeProps {
  status: DocumentStatus;
  size?: 'sm' | 'md' | 'lg';
  animated?: boolean;
}

export interface FileTypeBadgeProps {
  type: FileType;
  size?: 'sm' | 'md' | 'lg';
}
