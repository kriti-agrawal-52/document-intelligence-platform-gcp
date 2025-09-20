// Generalized API Proxy Route - Handles all backend service requests
// This single route proxies requests to auth, extraction, and summarization services

import { NextRequest, NextResponse } from 'next/server';
import { proxyToBackend } from '@/lib/api-proxy';

// Service mapping based on URL path
const getServiceFromPath = (path: string[]): 'AUTH' | 'EXTRACTION' | 'SUMMARIZATION' | null => {
  if (!path.length) return null;
  
  const firstSegment = path[0];
  
  switch (firstSegment) {
    case 'auth':
      return 'AUTH';
    case 'extract':
      return 'EXTRACTION';
    case 'summarize':
      return 'SUMMARIZATION';
    default:
      return null;
  }
};

// Generic handler for all HTTP methods
async function handleRequest(
  request: NextRequest, 
  method: 'GET' | 'POST' | 'PUT' | 'DELETE',
  params: { path: string[] }
) {
  try {
    // Get path segments from params (Next.js App Router style)
    const servicePath = params.path || [];
    
    console.log('[Proxy Route] Service path:', servicePath);
    
    if (!servicePath.length) {
      return NextResponse.json({ error: 'Invalid API path' }, { status: 400 });
    }

    // Determine which service to proxy to
    const service = getServiceFromPath(servicePath);
    if (!service) {
      return NextResponse.json({ error: 'Unknown service' }, { status: 404 });
    }

    // Reconstruct the backend endpoint path
    const backendPath = '/' + servicePath.join('/');
    
    // Get request body if present
    let body;
    if (['POST', 'PUT'].includes(method)) {
      const contentType = request.headers.get('content-type');
      if (contentType?.includes('application/json')) {
        body = await request.json();
      } else if (contentType?.includes('multipart/form-data')) {
        body = await request.formData();
      }
    }

    // Get authorization header
    const authorization = request.headers.get('authorization');
    const headers: Record<string, string> = {};
    if (authorization) {
      headers['Authorization'] = authorization;
    }

    // Proxy to backend service
    const result = await proxyToBackend(service, backendPath, {
      method,
      body,
      headers
    });

    // Return the backend response directly without double-wrapping
    return new Response(JSON.stringify(result.data), {
      status: result.status,
      headers: {
        'Content-Type': 'application/json',
        'X-Proxied-From': service,
        'X-Backend-Status': result.statusText
      }
    });

  } catch (error) {
    console.error('[Proxy Route] Error:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Proxy request failed' },
      { status: 500 }
    );
  }
}

// Export HTTP method handlers
export async function GET(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return handleRequest(request, 'GET', params);
}

export async function POST(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return handleRequest(request, 'POST', params);
}

export async function PUT(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return handleRequest(request, 'PUT', params);
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: { path: string[] } }
) {
  return handleRequest(request, 'DELETE', params);
}
