class AuditLogMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        
        # Log state-modifying requests for authenticated users or auth endpoints
        if request.path.startswith("/api/v1/") and request.method in ("POST", "PUT", "PATCH", "DELETE"):
            try:
                from apps.security.models import AuditLog
                
                user = request.user if request.user and request.user.is_authenticated else None
                ip = request.META.get("HTTP_X_FORWARDED_FOR", request.META.get("REMOTE_ADDR", ""))
                if ip and "," in ip:
                    ip = ip.split(",")[0].strip()
                
                AuditLog.objects.create(
                    user=user,
                    action=f"{request.method} {request.path}",
                    ip_address=ip[:45] if ip else None,
                    user_agent=request.META.get("HTTP_USER_AGENT", "")[:512],
                    path=request.path[:512],
                    method=request.method,
                    status_code=response.status_code,
                )
            except Exception:
                # Middleware must never crash the response cycle
                pass
                
        return response
