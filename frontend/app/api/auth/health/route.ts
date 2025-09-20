// Next.js API Route - Server-side proxy for auth health check

import { NextRequest, NextResponse } from 'next/server';

const AUTH_SERVICE_URL = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://localhost:8000';

export async function GET(request: NextRequest) {
  try {
    // Make server-side request to auth service
    const response = await fetch(`${AUTH_SERVICE_URL}/auth/health`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Handle response data safely
    let data;
    try {
      data = await response.json();
    } catch (jsonError) {
      console.error('Health check JSON parsing error:', jsonError);
      const text = await response.text();
      console.error('Health check response text:', text);
      return NextResponse.json(
        { error: 'Invalid response from auth service' }, 
        { status: 502 }
      );
    }

    return NextResponse.json(data, { status: response.status });
    
  } catch (error) {
    console.error('Health check proxy error:', error);
    return NextResponse.json(
      { error: 'Health check failed' }, 
      { status: 500 }
    );
  }
}
