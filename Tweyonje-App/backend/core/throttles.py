"""Custom throttle classes for API rate limiting."""
from rest_framework.throttling import UserRateThrottle


class FileUploadThrottle(UserRateThrottle):
    """
    Rate limit for file upload endpoints.
    Prevents abuse of photo/document upload features.
    """
    scope = 'file_upload'
    
    def allow_request(self, request, view):
        # Only apply to requests with files
        if not request.FILES:
            return True
        return super().allow_request(request, view)


class PhotoUploadThrottle(UserRateThrottle):
    """Specific throttle for photo uploads (more restrictive)."""
    scope = 'photo_upload'


class BulkOperationThrottle(UserRateThrottle):
    """Throttle for bulk operations that are resource-intensive."""
    scope = 'bulk_operation'
