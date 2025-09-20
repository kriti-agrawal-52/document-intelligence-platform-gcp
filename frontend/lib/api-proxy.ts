// Generalized API Proxy for Internal Backend Services
// This handles all communication with internal HTTP services via Next.js API routes

// Internal service URLs (only available server-side via VPC connector)
const INTERNAL_SERVICES = {
  AUTH: process.env.NEXT_PUBLIC_AUTH_SERVICE_URL || 'http://localhost:8000',
  EXTRACTION: process.env.NEXT_PUBLIC_EXTRACTION_SERVICE_URL || 'http://localhost:8001', 
  SUMMARIZATION: process.env.NEXT_PUBLIC_SUMMARIZATION_SERVICE_URL || 'http://localhost:8002'
} as const;

// Generic proxy function for backend services
export async function proxyToBackend(
  service: keyof typeof INTERNAL_SERVICES,
  endpoint: string,
  options: {
    method: 'GET' | 'POST' | 'PUT' | 'DELETE';
    body?: any;
    headers?: Record<string, string>;
  }
) {
  try {
    const serviceUrl = INTERNAL_SERVICES[service];
    const fullUrl = `${serviceUrl}${endpoint}`;
    
    console.log(`[API Proxy] ${options.method} ${fullUrl}`);

    // Prepare request options
    const fetchOptions: RequestInit = {
      method: options.method,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      }
    };

    // Handle different body types
    if (options.body) {
      if (options.body instanceof FormData) {
        fetchOptions.body = options.body;
        // Remove Content-Type to let browser set boundary for FormData
        delete (fetchOptions.headers as any)['Content-Type'];
      } else {
        fetchOptions.body = JSON.stringify(options.body);
      }
    }

    // Make request to backend service
    const response = await fetch(fullUrl, fetchOptions);
    
    console.log(`[API Proxy] Response: ${response.status} ${response.statusText}`);

    // Handle response safely
    let data;
    const contentType = response.headers.get('content-type');
    
    if (contentType?.includes('application/json')) {
      try {
        data = await response.json();
      } catch (jsonError) {
        console.error(`[API Proxy] JSON parsing error for ${service}:`, jsonError);
        const text = await response.text();
        console.error(`[API Proxy] Raw response:`, text);
        throw new Error(`Invalid JSON response from ${service} service`);
      }
    } else {
      // Handle non-JSON responses
      data = await response.text();
    }

    return {
      data,
      status: response.status,
      statusText: response.statusText,
      headers: Object.fromEntries(response.headers.entries())
    };

  } catch (error) {
    console.error(`[API Proxy] Error calling ${service} service:`, error);
    throw error;
  }
}
