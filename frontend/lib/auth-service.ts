// Authentication service for Document Intelligence Platform
// Handles login, registration, profile management, and token management

import { authApi, TokenManager, ApiClientError } from './api-client';
import { ENDPOINTS } from './api-config';
import type {
  LoginRequest,
  LoginResponse,
  UserCreate,
  UserOut,
  UserProfileResponse,
  UserProfileUpdate,
  PasswordChangeRequest,
  HealthResponse
} from './types';

export class AuthService {
  /**
   * User registration
   */
  async register(userData: UserCreate): Promise<UserOut> {
    try {
      const response = await authApi.post<UserOut>(
        ENDPOINTS.AUTH.REGISTER,
        userData,
        { includeAuth: false }
      );
      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        throw new Error(error.message);
      }
      throw new Error('Registration failed. Please try again.');
    }
  }

  /**
   * User login
   */
  async login(credentials: LoginRequest): Promise<LoginResponse> {
    try {
      // Backend expects form data for login - send FormData to proxy
      const formData = new FormData();
      formData.append('username', credentials.username);
      formData.append('password', credentials.password);

      const response = await authApi.post<LoginResponse>(
        ENDPOINTS.AUTH.LOGIN,
        formData,
        { includeAuth: false }
      );

      // Store token in localStorage
      if (response.access_token) {
        TokenManager.setToken(response.access_token);
      }

      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        throw new Error(error.message);
      }
      throw new Error('Login failed. Please check your credentials.');
    }
  }

  /**
   * User logout
   */
  async logout(): Promise<void> {
    try {
      const token = TokenManager.getToken();
      if (token) {
        // Call backend logout endpoint to blacklist token
        await authApi.post(ENDPOINTS.AUTH.LOGOUT, null, {
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });
      }
    } catch (error) {
      // Even if backend logout fails, we should clear local token
      console.warn('Backend logout failed, but continuing with local logout');
    } finally {
      // Always clear local token
      TokenManager.removeToken();
      
      // Redirect to login page
      if (typeof window !== 'undefined') {
        window.location.href = '/login';
      }
    }
  }

  /**
   * Get current user profile
   */
  async getCurrentUser(): Promise<UserProfileResponse> {
    try {
      const response = await authApi.get<UserProfileResponse>(ENDPOINTS.AUTH.PROFILE);
      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        if (error.status === 401) {
          throw new Error('Session expired. Please login again.');
        }
        throw new Error(error.message);
      }
      throw new Error('Failed to fetch user profile.');
    }
  }

  /**
   * Update user profile
   */
  async updateProfile(profileData: UserProfileUpdate): Promise<UserProfileResponse> {
    try {
      const response = await authApi.put<UserProfileResponse>(
        ENDPOINTS.AUTH.UPDATE_PROFILE,
        profileData
      );
      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        throw new Error(error.message);
      }
      throw new Error('Failed to update profile.');
    }
  }

  /**
   * Change user password
   */
  async changePassword(passwordData: PasswordChangeRequest): Promise<{ message: string }> {
    try {
      const response = await authApi.post<{ message: string }>(
        ENDPOINTS.AUTH.CHANGE_PASSWORD,
        passwordData
      );
      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        throw new Error(error.message);
      }
      throw new Error('Failed to change password.');
    }
  }

  /**
   * Delete user account
   */
  async deleteAccount(): Promise<{ message: string }> {
    try {
      const response = await authApi.delete<{ message: string }>(
        ENDPOINTS.AUTH.DELETE_ACCOUNT
      );
      
      // Clear token after successful account deletion
      TokenManager.removeToken();
      
      return response;
    } catch (error) {
      if (error instanceof ApiClientError) {
        throw new Error(error.message);
      }
      throw new Error('Failed to delete account.');
    }
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    const token = TokenManager.getToken();
    if (!token) return false;
    
    // Check if token is expired
    return !TokenManager.isTokenExpired(token);
  }

  /**
   * Get current auth token
   */
  getToken(): string | null {
    return TokenManager.getToken();
  }

  /**
   * Check auth service health
   */
  async checkHealth(): Promise<HealthResponse> {
    try {
      const response = await authApi.get<HealthResponse>(
        ENDPOINTS.AUTH.HEALTH,
        { includeAuth: false }
      );
      return response;
    } catch (error) {
      throw new Error('Auth service is unavailable');
    }
  }

  /**
   * Initialize auth state from stored token
   */
  async initializeAuth(): Promise<UserProfileResponse | null> {
    if (!this.isAuthenticated()) {
      return null;
    }

    try {
      const user = await this.getCurrentUser();
      return user;
    } catch (error) {
      // If token is invalid, clear it
      TokenManager.removeToken();
      return null;
    }
  }
}

// Export singleton instance
export const authService = new AuthService();
