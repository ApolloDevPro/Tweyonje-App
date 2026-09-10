"""
Supabase JWT Authentication Middleware for Django

This middleware verifies Supabase JWT tokens and adds user information
to the request for use in views.
"""

import jwt
from django.conf import settings
from django.http import JsonResponse
from django.contrib.auth.models import AnonymousUser


class SupabaseUser:
    """Represents a user authenticated via Supabase JWT."""
    
    def __init__(self, payload):
        self.id = payload.get('sub')
        self.email = payload.get('email', '')
        self.role = payload.get('role', 'authenticated')
        self.phone = payload.get('phone', '')
        self.full_name = payload.get('user_metadata', {}).get('full_name', '')
        self.first_name = payload.get('user_metadata', {}).get('first_name', '')
        self.last_name = payload.get('user_metadata', {}).get('last_name', '')
        self.user_role = payload.get('user_metadata', {}).get('role', 'RESIDENT')
        self.email_verified = payload.get('email_confirmed_at') is not None
        self.phone_verified = payload.get('phone_confirmed_at') is not None
        self.created_at = payload.get('created_at')
        self.last_sign_in = payload.get('last_sign_in_at')
    
    def __str__(self):
        return f"SupabaseUser(id={self.id}, email={self.email})"
    
    def __repr__(self):
        return self.__str__()


class SupabaseAuthMiddleware:
    """
    Middleware to authenticate requests using Supabase JWT tokens.
    
    Usage:
        Add to MIDDLEWARE in settings.py:
        MIDDLEWARE = [
            ...
            'core.middleware.SupabaseAuthMiddleware',
            ...
        ]
    
    The middleware:
    1. Extracts the Bearer token from the Authorization header
    2. Verifies the JWT using Supabase's JWT secret
    3. Adds the user info to request.supabase_user
    4. Allows the request to proceed (Django auth still works for admin)
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.jwt_secret = getattr(settings, 'SUPABASE_JWT_SECRET', None)
        self.exempt_paths = getattr(settings, 'SUPABASE_AUTH_EXEMPT_PATHS', [
            '/api/auth/login/',
            '/api/auth/register/',
            '/api/auth/refresh/',
            '/api/auth/password-reset/',
            '/api/auth/otp/',
            '/admin/',
            '/api/schema/',
            '/api/docs/',
        ])
    
    def __call__(self, request):
        # Check if path is exempt from Supabase auth
        if any(request.path.startswith(path) for path in self.exempt_paths):
            request.supabase_user = None
            return self.get_response(request)
        
        # Extract Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        
        if not auth_header.startswith('Bearer '):
            # No Supabase token - that's okay, Django auth might handle it
            request.supabase_user = None
            return self.get_response(request)
        
        token = auth_header.split(' ')[1]
        
        if not self.jwt_secret:
            # JWT secret not configured, skip Supabase auth
            request.supabase_user = None
            return self.get_response(request)
        
        try:
            # Verify Supabase JWT
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=['HS256'],
                audience='authenticated',
                options={
                    'verify_exp': True,
                    'verify_aud': True,
                    'verify_iss': True,
                },
            )
            
            # Create Supabase user object
            request.supabase_user = SupabaseUser(payload)
            request.supabase_user_id = payload.get('sub')
            
        except jwt.ExpiredSignatureError:
            return JsonResponse(
                {'error': 'Token has expired', 'code': 'token_expired'},
                status=401
            )
        except jwt.InvalidAudienceError:
            return JsonResponse(
                {'error': 'Invalid token audience', 'code': 'invalid_audience'},
                status=401
            )
        except jwt.InvalidIssuerError:
            return JsonResponse(
                {'error': 'Invalid token issuer', 'code': 'invalid_issuer'},
                status=401
            )
        except jwt.InvalidTokenError as e:
            return JsonResponse(
                {'error': f'Invalid token: {str(e)}', 'code': 'invalid_token'},
                status=401
            )
        except Exception as e:
            return JsonResponse(
                {'error': f'Authentication error: {str(e)}', 'code': 'auth_error'},
                status=401
            )
        
        return self.get_response(request)


class SupabaseRequiredMiddleware:
    """
    Stricter middleware that REQUIRES Supabase JWT for all non-exempt paths.
    Use this for API-only backends.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.jwt_secret = getattr(settings, 'SUPABASE_JWT_SECRET', None)
        self.exempt_paths = getattr(settings, 'SUPABASE_AUTH_EXEMPT_PATHS', [
            '/api/auth/login/',
            '/api/auth/register/',
            '/api/auth/refresh/',
            '/api/auth/password-reset/',
            '/api/auth/otp/',
            '/admin/',
            '/api/schema/',
            '/api/docs/',
            '/health/',
        ])
    
    def __call__(self, request):
        # Check if path is exempt
        if any(request.path.startswith(path) for path in self.exempt_paths):
            request.supabase_user = None
            return self.get_response(request)
        
        # Extract Authorization header
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')
        
        if not auth_header.startswith('Bearer '):
            return JsonResponse(
                {'error': 'Authorization header required', 'code': 'missing_auth_header'},
                status=401
            )
        
        token = auth_header.split(' ')[1]
        
        if not self.jwt_secret:
            return JsonResponse(
                {'error': 'Authentication not configured', 'code': 'auth_not_configured'},
                status=500
            )
        
        try:
            # Verify Supabase JWT
            payload = jwt.decode(
                token,
                self.jwt_secret,
                algorithms=['HS256'],
                audience='authenticated',
                options={
                    'verify_exp': True,
                    'verify_aud': True,
                    'verify_iss': True,
                },
            )
            
            # Create Supabase user object
            request.supabase_user = SupabaseUser(payload)
            request.supabase_user_id = payload.get('sub')
            
        except jwt.ExpiredSignatureError:
            return JsonResponse(
                {'error': 'Token has expired', 'code': 'token_expired'},
                status=401
            )
        except jwt.InvalidAudienceError:
            return JsonResponse(
                {'error': 'Invalid token audience', 'code': 'invalid_audience'},
                status=401
            )
        except jwt.InvalidIssuerError:
            return JsonResponse(
                {'error': 'Invalid token issuer', 'code': 'invalid_issuer'},
                status=401
            )
        except jwt.InvalidTokenError as e:
            return JsonResponse(
                {'error': f'Invalid token: {str(e)}', 'code': 'invalid_token'},
                status=401
            )
        except Exception as e:
            return JsonResponse(
                {'error': f'Authentication error: {str(e)}', 'code': 'auth_error'},
                status=401
            )
        
        return self.get_response(request)
