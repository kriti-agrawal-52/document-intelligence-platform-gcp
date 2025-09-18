// API Client for Document Intelligence Platform
// Centralized HTTP client with authentication, error handling, and interceptors

import { API_CONFIG, TIMEOUT_CONFIG } from './api-config';

// Types for API responses and errors
export interface ApiError {
  message: string;
  status: number;
  detail?: string;
}

export interface ApiResponse<T = any> {
  data: T;
  status: number;
  statusText: string;
}

// Custom error class for API errors
export class ApiClientError extends Error {
  public status: number;
  public detail?: string;

  constructor(message: string, status: number, detail?: string) {
    super(message);
    this.name = 'ApiClientError';
    this.status = status;
    this.detail = detail;
  }
}

// Token management utilities
export const TokenManager = {
  getToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem('auth_token');
  },

  setToken(token: string): void {
    if (typeof window === 'undefined') return;
    localStorage.setItem('auth_token', token);
  },

  removeToken(): void {
    if (typeof window === 'undefined') return;
    localStorage.removeItem('auth_token');
  },

  isTokenExpired(token: string): boolean {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]));
      return payload.exp * 1000 < Date.now();
    } catch {
      return true;
    }
  }
};

// Base API client class
class ApiClient {
  private baseURL: string;
  private defaultTimeout: number;

  constructor(baseURL: string, timeout = TIMEOUT_CONFIG.DEFAULT) {
    this.baseURL = baseURL;
    this.defaultTimeout = timeout;
  }

  // Create request headers with authentication
  private createHeaders(includeAuth = true, contentType = 'application/json'): HeadersInit {
    const headers: HeadersInit = {};

    if (contentType) {
      headers['Content-Type'] = contentType;
    }

    if (includeAuth) {
      const token = TokenManager.getToken();
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
    }

    return headers;
  }

  // Handle API response and errors
  private async handleResponse<T>(response: Response): Promise<T> {
    if (!response.ok) {
      let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
      let errorDetail: string | undefined;

      try {
        const errorData = await response.json();
        errorMessage = errorData.detail || errorData.message || errorMessage;
        errorDetail = errorData.detail;
      } catch {
        // If response is not JSON, use default error message
      }

      // Handle specific status codes
      if (response.status === 401) {
        // Unauthorized - clear token and redirect to login
        TokenManager.removeToken();
        if (typeof window !== 'undefined') {
          window.location.href = '/login';
        }
      }

      throw new ApiClientError(errorMessage, response.status, errorDetail);
    }

    // Handle empty responses (e.g., 204 No Content)
    if (response.status === 204 || response.headers.get('content-length') === '0') {
      return {} as T;
    }

    try {
      return await response.json();
    } catch {
      // If response is not JSON, return empty object
      return {} as T;
    }
  }

  // Generic request method
  async request<T>(
    endpoint: string,
    options: RequestInit & { timeout?: number; includeAuth?: boolean } = {}
  ): Promise<T> {
    const {
      timeout = this.defaultTimeout,
      includeAuth = true,
      headers = {},
      ...restOptions
    } = options;

    const url = `${this.baseURL}${endpoint}`;
    const requestHeaders = {
      ...this.createHeaders(includeAuth),
      ...headers
    };

    // Create abort controller for timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(url, {
        ...restOptions,
        headers: requestHeaders,
        signal: controller.signal
      });

      clearTimeout(timeoutId);
      return await this.handleResponse<T>(response);
    } catch (error) {
      clearTimeout(timeoutId);
      
      if (error instanceof ApiClientError) {
        throw error;
      }

      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          throw new ApiClientError('Request timeout', 408);
        }
        throw new ApiClientError(error.message, 0);
      }

      throw new ApiClientError('Unknown error occurred', 0);
    }
  }

  // HTTP method shortcuts
  async get<T>(endpoint: string, options?: RequestInit & { timeout?: number; includeAuth?: boolean }): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'GET' });
  }

  async post<T>(
    endpoint: string, 
    data?: any, 
    options?: RequestInit & { timeout?: number; includeAuth?: boolean }
  ): Promise<T> {
    const body = data instanceof FormData ? data : JSON.stringify(data);
    const contentType = data instanceof FormData ? undefined : 'application/json';
    
    return this.request<T>(endpoint, {
      ...options,
      method: 'POST',
      body,
      headers: {
        ...options?.headers,
        ...(contentType && { 'Content-Type': contentType })
      }
    });
  }

  async put<T>(
    endpoint: string, 
    data?: any, 
    options?: RequestInit & { timeout?: number; includeAuth?: boolean }
  ): Promise<T> {
    return this.request<T>(endpoint, {
      ...options,
      method: 'PUT',
      body: JSON.stringify(data)
    });
  }

  async delete<T>(endpoint: string, options?: RequestInit & { timeout?: number; includeAuth?: boolean }): Promise<T> {
    return this.request<T>(endpoint, { ...options, method: 'DELETE' });
  }
}

// Create API client instances for each service
export const authApi = new ApiClient(API_CONFIG.AUTH_SERVICE);
export const extractionApi = new ApiClient(API_CONFIG.EXTRACTION_SERVICE);
export const summarizationApi = new ApiClient(API_CONFIG.SUMMARIZATION_SERVICE);

// Export default client (auth service)
export default authApi;
