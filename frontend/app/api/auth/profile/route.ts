// Next.js API Route - Server-side proxy for auth profile

import { NextRequest, NextResponse } from 'next/server';

const AUTH_SERVICE_URL = process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://localhost:8000';

export async function GET(request: NextRequest) {
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
    const response = await fetch(`${AUTH_SERVICE_URL}/auth/users/me`, {
      method: 'GET',
      headers: {
        'Authorization': authorization,
        'Content-Type': 'application/json',
      },
    });

    // Handle response safely
    let data;
    try {
      data = await response.json();
    } catch (jsonError) {
      console.error('Profile JSON parsing error:', jsonError);
      const text = await response.text();
      console.error('Profile response text:', text);
      return NextResponse.json(
        { error: 'Invalid response from auth service' }, 
        { status: 502 }
      );
    }

    return NextResponse.json(data, { status: response.status });
    
  } catch (error) {
    console.error('Profile proxy error:', error);
    return NextResponse.json(
      { error: 'Profile fetch failed' }, 
      { status: 500 }
    );
  }
}

export async function PUT(request: NextRequest) {
  try {
    // Get authorization header and request body
    const authorization = request.headers.get('authorization');
    const body = await request.json();
    
    if (!authorization) {
      return NextResponse.json(
        { error: 'Authorization header required' }, 
        { status: 401 }
      );
    }

    // Make server-side request to auth service
    const response = await fetch(`${AUTH_SERVICE_URL}/auth/users/me`, {
      method: 'PUT',
      headers: {
        'Authorization': authorization,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    // Handle response safely
    let data;
    try {
      data = await response.json();
    } catch (jsonError) {
      console.error('Profile update JSON parsing error:', jsonError);
      const text = await response.text();
      console.error('Profile update response text:', text);
      return NextResponse.json(
        { error: 'Invalid response from auth service' }, 
        { status: 502 }
      );
    }

    return NextResponse.json(data, { status: response.status });
    
  } catch (error) {
    console.error('Profile update proxy error:', error);
    return NextResponse.json(
      { error: 'Profile update failed' }, 
      { status: 500 }
    );
  }
}

export async function DELETE(request: NextRequest) {
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
    const response = await fetch(`${AUTH_SERVICE_URL}/auth/users/me`, {
      method: 'DELETE',
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
        console.error('Delete account JSON parsing error:', jsonError);
      }
    }

    return NextResponse.json(data, { status: response.status });
    
  } catch (error) {
    console.error('Delete account proxy error:', error);
    return NextResponse.json(
      { error: 'Account deletion failed' }, 
      { status: 500 }
    );
  }
}
