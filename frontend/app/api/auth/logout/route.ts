// Next.js API Route - Server-side proxy for auth logout

import { NextRequest, NextResponse } from 'next/server';

const AUTH_SERVICE_URL = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://localhost:8000';

export async function POST(request: NextRequest) {
  try {
    // Get authorization header
    const authorization = request.headers.get('authorization');
    
    if (!authorization) {
      return NextResponse.json(
        { error: 'Authorization header required' }, 
        { status: 401 }
      );
    }

    // Make server-side request to auth service
    const response = await fetch(`${AUTH_SERVICE_URL}/auth/logout`, {
      method: 'POST',
      headers: {
        'Authorization': authorization,
        'Content-Type': 'application/json',
      },
    });

    // Handle response safely
    let data = {};
    if (response.headers.get('content-type')?.includes('application/json')) {
      try {
        data = await response.json();
      } catch (jsonError) {
        console.error('Logout JSON parsing error:', jsonError);
      }
    }

    return NextResponse.json(data, { status: response.status });
    
  } catch (error) {
    console.error('Logout proxy error:', error);
    return NextResponse.json(
      { error: 'Logout failed' }, 
      { status: 500 }
    );
  }
}
