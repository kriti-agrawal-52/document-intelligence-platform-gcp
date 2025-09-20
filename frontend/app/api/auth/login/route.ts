// Next.js API Route - Server-side proxy for auth login
// This solves the mixed content issue by moving HTTP calls to server-side

import { NextRequest, NextResponse } from 'next/server';

const AUTH_SERVICE_URL = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://localhost:8000';

export async function POST(request: NextRequest) {
  try {
    // Get request body
    const body = await request.json();
    
    // Convert to FormData for backend
    const formData = new FormData();
    formData.append('username', body.username);
    formData.append('password', body.password);
    
    // Make server-side request to auth service
    const response = await fetch(`${AUTH_SERVICE_URL}/auth/token`, {
      method: 'POST',
      body: formData,
    });

    // Handle response data safely
    let data;
    try {
      data = await response.json();
    } catch (jsonError) {
      console.error('JSON parsing error:', jsonError);
      const text = await response.text();
      console.error('Response text:', text);
      return NextResponse.json(
        { error: 'Invalid response from auth service' }, 
        { status: 502 }
      );
    }

    // Return response with same status
    return NextResponse.json(data, { status: response.status });
    
  } catch (error) {
    console.error('Login proxy error:', error);
    return NextResponse.json(
      { error: 'Login failed' }, 
      { status: 500 }
    );
  }
}
