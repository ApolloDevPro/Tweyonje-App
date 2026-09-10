from django.http import JsonResponse
from django.utils import timezone

from django.db import connections


def health(request):
    db_ok = True
    try:
        connections["default"].cursor().execute("SELECT 1")
    except Exception:
        db_ok = False
    return JsonResponse(
        {
            "status": "ok" if db_ok else "degraded",
            "service": "tweyonje-backend",
            "version": "1.0.0",
            "time": timezone.now().isoformat(),
            "database": "up" if db_ok else "down",
        }
    )
