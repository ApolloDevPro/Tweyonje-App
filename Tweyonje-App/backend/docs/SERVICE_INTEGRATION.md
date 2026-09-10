# Service Integration Guide

This document explains how to integrate the frontend services with the backend API endpoints.

## API Client Configuration

The API client is located at `frontend/src/api/client.ts`. Ensure it's configured with the correct base URL:

```typescript
const api = axios.create({
  baseURL: 'http://localhost:8000/api/v1', // or your production URL
  timeout: 10000,
});
```

## Service Integration Checklist

### 1. Location Service (`services/location.ts`)

**Required API Endpoints:**
- `POST /api/v1/location/update` - Update user location
- `GET /api/v1/location/nearby` - Get nearby collectors/zones
- `POST /api/v1/location/geocode` - Convert address to coordinates

**Integration Steps:**
```typescript
// In services/location.ts
import { api } from '../api/client';

export async function updateUserLocation(latitude: number, longitude: number) {
  return await api.post('/location/update', { latitude, longitude });
}

export async function getNearbyCollectors(latitude: number, longitude: number, radius: number) {
  return await api.get('/location/nearby', { params: { latitude, longitude, radius } });
}
```

### 2. Notification Service (`services/notifications.ts`)

**Required API Endpoints:**
- `POST /api/v1/notifications/register` - Register device token
- `POST /api/v1/notifications/preferences` - Update notification preferences
- `GET /api/v1/notifications/` - Get user notifications

**Integration Steps:**
```typescript
// In services/notifications.ts
import { api } from '../api/client';

export async function registerDeviceToken(token: string) {
  return await api.post('/notifications/register', { token });
}

export async function updateNotificationPreferences(preferences: any) {
  return await api.post('/notifications/preferences', preferences);
}
```

### 3. WebSocket Service (`services/websocket.ts`)

**Required Configuration:**
- WebSocket URL: `ws://localhost:8000/ws/` (or production URL)
- Authentication: JWT token in query string or headers

**Integration Steps:**
```typescript
// In services/websocket.ts
const WS_URL = 'ws://localhost:8000/ws/';

export function connectWebSocket(token: string) {
  const ws = new WebSocket(`${WS_URL}?token=${token}`);
  // Handle connection, messages, errors
}
```

### 4. Biometric Service (`services/biometric.ts`)

**Required API Endpoints:**
- `POST /api/v1/auth/biometric/register` - Register biometric
- `POST /api/v1/auth/biometric/verify` - Verify biometric

**Integration Steps:**
```typescript
// In services/biometric.ts
import { api } from '../api/client';

export async function registerBiometric(biometricData: any) {
  return await api.post('/auth/biometric/register', biometricData);
}

export async function verifyBiometric(biometricData: any) {
  return await api.post('/auth/biometric/verify', biometricData);
}
```

### 5. Deep Linking Service (`services/deepLinking.ts`)

**Required Configuration:**
- Deep link scheme: `tweyonje://`
- Host: `app`

**Integration Steps:**
```typescript
// In services/deepLinking.ts
// The service is already configured for deep linking
// Ensure backend API supports deep link parameters
```

### 6. Offline Queue (`services/offlineQueue.ts`)

**Required Configuration:**
- The service is already integrated with the API client
- Ensure `api.request` is properly configured

**Integration Steps:**
```typescript
// The offline queue is already integrated
// Just ensure the API client is configured correctly
```

## Screen Integration Examples

### Authentication Screens

**Login Screen:**
```typescript
// In screens/auth/LoginScreen.tsx
import { api } from '../../api/client';

const handleLogin = async () => {
  try {
    const response = await api.post('/auth/login', {
      email,
      password,
    });
    // Store tokens and navigate
  } catch (error) {
    // Handle error
  }
};
```

**OTP Verification:**
```typescript
// In screens/auth/OTPVerificationScreen.tsx
import { api } from '../../api/client';

const handleVerify = async (code: string) => {
  try {
    const response = await api.post('/auth/verify-otp', { code });
    // Handle success
  } catch (error) {
    // Handle error
  }
};
```

### Resident Screens

**Create Request:**
```typescript
// In screens/resident/CreateRequestScreen.tsx
import { api } from '../../api/client';

const handleSubmit = async () => {
  try {
    const response = await api.post('/waste-requests/', requestData);
    // Handle success
  } catch (error) {
    // Handle error
  }
};
```

**Payments:**
```typescript
// In screens/resident/PaymentsScreen.tsx
import { api } from '../../api/client';

const handlePayment = async (paymentData: any) => {
  try {
    const response = await api.post('/payments/', paymentData);
    // Handle success
  } catch (error) {
    // Handle error
  }
};
```

### Collector Screens

**Job Details:**
```typescript
// In screens/collector/JobDetailScreen.tsx
import { api } from '../../api/client';

const updateJobStatus = async (status: string) => {
  try {
    const response = await api.patch(`/collections/${jobId}/`, { status });
    // Handle success
  } catch (error) {
    // Handle error
  }
};
```

### Authority Screens

**Requests:**
```typescript
// In screens/authority/AuthorityRequestsScreen.tsx
import { api } from '../../api/client';

const fetchRequests = async () => {
  try {
    const response = await api.get('/waste-requests/', {
      params: { zone: authorityZone },
    });
    // Handle success
  } catch (error) {
    // Handle error
  }
};
```

### Admin Screens

**Users:**
```typescript
// In screens/admin/AdminUsersScreen.tsx
import { api } from '../../api/client';

const fetchUsers = async () => {
  try {
    const response = await api.get('/users/');
    // Handle success
  } catch (error) {
    // Handle error
  }
};
```

## Error Handling

All API calls should include proper error handling:

```typescript
try {
  const response = await api.post('/endpoint', data);
  return response.data;
} catch (error) {
  if (axios.isAxiosError(error)) {
    if (error.response?.status === 401) {
      // Unauthorized - redirect to login
    } else if (error.response?.status === 403) {
      // Forbidden - show permission error
    } else if (error.response?.status === 404) {
      // Not found - show error message
    } else {
      // Other errors
    }
  }
  throw error;
}
```

## Authentication

All authenticated requests should include the JWT token:

```typescript
// In api/client.ts
api.interceptors.request.use((config) => {
  const token = getToken(); // Get token from storage
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

## Testing

Test each integration:

1. **Unit Tests**: Test service functions in isolation
2. **Integration Tests**: Test API endpoints with mock data
3. **E2E Tests**: Test full user flows

## Deployment

For production:

1. Update `baseURL` to production API URL
2. Enable HTTPS/WSS for secure connections
3. Configure CORS settings on backend
4. Test all integrations in staging environment first

## Notes

- The backend API follows RESTful conventions
- All dates should be in ISO 8601 format
- File uploads use multipart/form-data
- Pagination uses page and page_size parameters
- Filtering uses query parameters
- Rate limiting is enforced on sensitive endpoints
