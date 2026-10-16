import os
from datetime import timedelta
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent

load_dotenv(BASE_DIR / ".env")


def env_bool(name, default=False):
    value = os.getenv(name)
    if value is None:
        return default
    return value.lower() in ("1", "true", "yes", "on")


def env_int(name, default=0):
    try:
        return int(os.getenv(name, default))
    except (TypeError, ValueError):
        return default


DEBUG = env_bool("DEBUG", True)

DEV_SECRET_KEY = "django-insecure-tweyonje-dev-key-change-in-production"

if DEBUG:
    SECRET_KEY = os.getenv("SECRET_KEY", DEV_SECRET_KEY)
    if SECRET_KEY == DEV_SECRET_KEY:
        import warnings

        warnings.warn(
            "Using the insecure development SECRET_KEY. "
            "Set SECRET_KEY in your environment for any non-local deployment.",
            stacklevel=2,
        )
else:
    SECRET_KEY = os.getenv("SECRET_KEY")
    if not SECRET_KEY:
        raise RuntimeError("SECRET_KEY must be set when DEBUG is False.")
    if SECRET_KEY == DEV_SECRET_KEY:
        raise RuntimeError("Refusing to start with the development SECRET_KEY when DEBUG is False.")

ALLOWED_HOSTS = [
    h.strip()
    for h in os.getenv(
        "ALLOWED_HOSTS",
        "localhost,127.0.0.1,10.0.2.2" if DEBUG else "tweyonje.ug,staging.tweyonje.ug",
    ).split(",")
    if h.strip()
]

CORS_ALLOW_ALL_ORIGINS = env_bool("CORS_ALLOW_ALL_ORIGINS", False)

# Explicit origins allowed for cross-origin requests (used when CORS_ALLOW_ALL_ORIGINS is False).
CORS_ALLOWED_ORIGINS = [
    o.strip()
    for o in os.getenv(
        "CORS_ALLOWED_ORIGINS",
        "http://localhost,http://127.0.0.1,http://10.0.2.2,http://192.168.1.178,http://localhost:8080",
    ).split(",")
    if o.strip()
]

if DEBUG:
    CSRF_TRUSTED_ORIGINS = [
        o.strip()
        for o in os.getenv(
            "CSRF_TRUSTED_ORIGINS",
            "http://localhost,http://127.0.0.1,http://10.0.2.2,http://192.168.1.178,http://localhost:8080",
        ).split(",")
        if o.strip()
    ]
else:
    CSRF_TRUSTED_ORIGINS = [
        o.strip()
        for o in os.getenv("CSRF_TRUSTED_ORIGINS", "https://tweyonje.ug,https://staging.tweyonje.ug").split(",")
        if o.strip()
    ]

INSTALLED_APPS = [
    "daphne",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "channels",
    "corsheaders",
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "django_filters",
    "drf_spectacular",
    "drf_spectacular_sidecar",
    "whitenoise.runserver_nostatic",
    "core",
    "apps.accounts",
    "apps.profiles",
    "apps.waste_requests",
    "apps.collections",
    "apps.tracking",
    "apps.reports",
    "apps.notifications",
    "apps.payments",
    "apps.recycling",
    "apps.rewards",
    "apps.ratings",
    "apps.platform_admin",
    "apps.analytics",
    "apps.routing",
    "apps.ai",
    "apps.support",
    "apps.security",
    "apps.localization",
    "apps.chat",
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "apps.security.middleware.AuditLogMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

# Channels (WebSocket)
REDIS_URL = os.getenv("REDIS_URL", "")
CHANNEL_LAYERS = {
    "default": (
        {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {"hosts": [REDIS_URL]},
        }
        if REDIS_URL
        else {
            # Single-process development fallback; use REDIS_URL in production.
            "BACKEND": "channels.layers.InMemoryChannelLayer"
        }
    )
}

AUTH_USER_MODEL = "core.User"

AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
]

# Supabase Configuration
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")
SUPABASE_JWT_SECRET = os.getenv("SUPABASE_JWT_SECRET", "")

# Paths that don't require Supabase JWT authentication
SUPABASE_AUTH_EXEMPT_PATHS = [
    "/api/auth/login/",
    "/api/auth/register/",
    "/api/auth/refresh/",
    "/api/auth/password-reset/",
    "/api/auth/otp/",
    "/admin/",
    "/api/schema/",
    "/api/docs/",
    "/health/",
    "/api/waste-requests/categories/",  # Public endpoint
]

# API bearer tokens are Django SimpleJWT tokens, validated by DRF's
# JWTAuthentication below. SupabaseAuthMiddleware must not intercept them.

# Database
# DATABASE_URL takes precedence (set by Railway, Heroku, etc.)
# Otherwise, uses DB_ENGINE to determine database type
DATABASE_URL = os.getenv("DATABASE_URL")
DB_ENGINE = os.getenv("DB_ENGINE", "")

if DATABASE_URL:
    # Use DATABASE_URL (e.g., postgres://user:pass@host:port/dbname)
    import dj_database_url
    DATABASES = {
        "default": dj_database_url.config(
            default="sqlite:///db.sqlite3",
            conn_max_age=env_int("DB_CONN_MAX_AGE", 60),
        )
    }
elif DB_ENGINE in ("", "sqlite") or (DB_ENGINE not in ("postgres", "postgis") and not os.getenv("DB_HOST")):
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }
elif DB_ENGINE == "postgis":
    DATABASES = {
        "default": {
            "ENGINE": "django.contrib.gis.db.backends.postgis",
            "NAME": os.getenv("DB_NAME", "tweyonje"),
            "USER": os.getenv("DB_USER", "tweyonje"),
            "PASSWORD": os.getenv("DB_PASSWORD", "change-me"),
            "HOST": os.getenv("DB_HOST", "localhost"),
            "PORT": os.getenv("DB_PORT", "5432"),
            "CONN_MAX_AGE": env_int("DB_CONN_MAX_AGE", 60),
            "OPTIONS": {
                "sslmode": os.getenv("DB_SSLMODE", "require") if os.getenv("DB_HOST", "").endswith("supabase.co") else "prefer",
            },
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": os.getenv("DB_NAME", "tweyonje"),
            "USER": os.getenv("DB_USER", "tweyonje"),
            "PASSWORD": os.getenv("DB_PASSWORD", "change-me"),
            "HOST": os.getenv("DB_HOST", "localhost"),
            "PORT": os.getenv("DB_PORT", "5432"),
            "CONN_MAX_AGE": env_int("DB_CONN_MAX_AGE", 60),
            "OPTIONS": {
                "sslmode": os.getenv("DB_SSLMODE", "require") if os.getenv("DB_HOST", "").endswith("supabase.co") else "prefer",
            },
        }
    }

USE_POSTGIS = DB_ENGINE == "postgis"
if USE_POSTGIS and "django.contrib.gis" not in INSTALLED_APPS:
    INSTALLED_APPS.append("django.contrib.gis")

PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",
    "django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher",
]

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator", "OPTIONS": {"min_length": 8}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
]

LANGUAGE_CODE = "en-us"
TIME_ZONE = "Africa/Kampala"
USE_I18N = True
USE_TZ = True

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

# File upload limits
DATA_UPLOAD_MAX_MEMORY_SIZE = env_int("DATA_UPLOAD_MAX_MEMORY_SIZE", 10485760)  # 10MB
FILE_UPLOAD_MAX_MEMORY_SIZE = env_int("FILE_UPLOAD_MAX_MEMORY_SIZE", 10485760)  # 10MB
MAX_PHOTO_SIZE_MB = env_int("MAX_PHOTO_SIZE_MB", 5)  # 5MB per photo

# Serialized waste classifier (joblib). Override via AI_MODEL_PATH env var.
# When the file is absent the AI endpoints fall back to the keyword heuristic.
AI_MODEL_PATH = os.getenv("AI_MODEL_PATH", str(BASE_DIR / "media" / "ai" / "waste_classifier.joblib"))

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

# REST Framework
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ),
    "DEFAULT_PAGINATION_CLASS": "core.pagination.DefaultPagination",
    "DEFAULT_SCHEMA_CLASS": "drf_spectacular.openapi.AutoSchema",
    "EXCEPTION_HANDLER": "rest_framework.views.exception_handler",
    "DEFAULT_THROTTLE_RATES": {
        "auth_login": os.getenv("THROTTLE_AUTH_LOGIN", "10/min"),
        "otp_send": os.getenv("THROTTLE_OTP_SEND", "5/min"),
        "otp_verify": os.getenv("THROTTLE_OTP_VERIFY", "10/min"),
        "password_reset": os.getenv("THROTTLE_PASSWORD_RESET", "5/min"),
        "ai_classify": os.getenv("THROTTLE_AI_CLASSIFY", "10/min"),
        "anon": os.getenv("THROTTLE_ANON", "60/min"),
        "file_upload": os.getenv("THROTTLE_FILE_UPLOAD", "20/hour"),
        "photo_upload": os.getenv("THROTTLE_PHOTO_UPLOAD", "30/hour"),
        "bulk_operation": os.getenv("THROTTLE_BULK_OPERATION", "5/min"),
    },
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(minutes=env_int("JWT_ACCESS_TOKEN_MINUTES", 15)),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=env_int("JWT_REFRESH_TOKEN_DAYS", 30)),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
}

SPECTACULAR_SETTINGS = {
    "TITLE": "Tweyonje API",
    "DESCRIPTION": "Together for a Cleaner Uganda - Smart Waste Management API",
    "VERSION": "1.0.0",
    "SERVE_INCLUDE_SCHEMA": False,
    # Serve Swagger UI / ReDoc assets locally instead of from a CDN.
    "SWAGGER_UI_DIST": "SIDECAR",
    "REDOC_DIST": "SIDECAR",
}

# App settings
CURRENCY = os.getenv("CURRENCY", "UGX")

# Number of hours after which a PENDING payment that was submitted to a live
# provider (has a provider_reference) may be reconciled as failed.
RECONCILIATION_STALE_HOURS = env_int("RECONCILIATION_STALE_HOURS", 8)

# Echo the plaintext OTP code in the API response. Off by default; enable only
# in local/dev environments for testing convenience.
OTP_DEBUG_ECHO = env_bool("OTP_DEBUG_ECHO", False)

EMAIL_HOST = os.getenv("EMAIL_HOST", "")
EMAIL_PORT = env_int("EMAIL_PORT", 587)
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER", "")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD", "")
EMAIL_USE_TLS = env_bool("EMAIL_USE_TLS", True)
DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL", "noreply@tweyonje.ug")

PAYMENT_PROVIDER = os.getenv("PAYMENT_PROVIDER", "dev")
MTN_MOMO_CALLBACK_URL = os.getenv("MTN_MOMO_CALLBACK_URL", "")
# Shared secret required by MoMoWebhookView to authenticate MTN MoMo callbacks.
# When unset, the MTN MoMo webhook is disabled (returns 403 for all callbacks).
MTN_MOMO_CALLBACK_TOKEN = os.getenv("MTN_MOMO_CALLBACK_TOKEN", "")
AIRTEL_CALLBACK_URL = os.getenv("AIRTEL_CALLBACK_URL", "")

MTN_MOMO_BASE_URL = os.getenv("MTN_MOMO_BASE_URL", "https://sandbox.momodeveloper.mtn.com")
MTN_MOMO_SUBSCRIPTION_KEY = os.getenv("MTN_MOMO_SUBSCRIPTION_KEY", "")
MTN_MOMO_API_USER = os.getenv("MTN_MOMO_API_USER", "")
MTN_MOMO_API_KEY = os.getenv("MTN_MOMO_API_KEY", "")
MTN_MOMO_TARGET_ENV = os.getenv("MTN_MOMO_TARGET_ENV", "sandbox")

AIRTEL_BASE_URL = os.getenv("AIRTEL_BASE_URL", "https://openapiuat.airtel.africa")
AIRTEL_CLIENT_ID = os.getenv("AIRTEL_CLIENT_ID", "")
AIRTEL_CLIENT_SECRET = os.getenv("AIRTEL_CLIENT_SECRET", "")
AIRTEL_CALLBACK_KEY = os.getenv("AIRTEL_CALLBACK_KEY", "")

FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "")
FCM_CREDENTIALS_PATH = os.getenv("FCM_CREDENTIALS_PATH", "")

# SMS providers: dev | twilio | africastalk
SMS_PROVIDER = os.getenv("SMS_PROVIDER", "dev")
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID", "")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN", "")
TWILIO_FROM_NUMBER = os.getenv("TWILIO_FROM_NUMBER", "")
AFRICASTALK_USERNAME = os.getenv("AFRICASTALK_USERNAME", "")
AFRICASTALK_API_KEY = os.getenv("AFRICASTALK_API_KEY", "")

# WhatsApp / USSD placeholders (extend via environment as needed)
USSD_CODE = os.getenv("USSD_CODE", "*268#")

#  Celery
CELERY_BROKER_URL = os.getenv("CELERY_BROKER_URL") or REDIS_URL
CELERY_RESULT_BACKEND = os.getenv("CELERY_RESULT_BACKEND") or REDIS_URL
CELERY_TASK_ALWAYS_EAGER = env_bool("CELERY_TASK_ALWAYS_EAGER", False)
CELERY_TASK_EAGER_PROPAGATES = True

CELERY_BEAT_SCHEDULE = {}
for _task_name, _env_key, _default in (
    ("process_due_schedules", "CELERY_PROCESS_DUE_SCHEDULES_SECONDS", 300),  # Every 5 minutes
    ("check_sla", "CELERY_CHECK_SLA_SECONDS", 900),  # Every 15 minutes
    ("retry_notifications", "CELERY_RETRY_NOTIFICATIONS_SECONDS", 600),  # Every 10 minutes
    ("run_payouts", "CELERY_RUN_PAYOUTS_SECONDS", 86400),  # Daily at midnight (use crontab for exact time)
    ("run_reconciliation", "CELERY_RUN_RECONCILIATION_SECONDS", 3600),  # Every hour
):
    _seconds = env_int(_env_key, _default)
    if _seconds > 0:
        CELERY_BEAT_SCHEDULE[_task_name] = {"task": f"core.tasks.{_task_name}", "schedule": _seconds}

#  Sentry (optional)
SENTRY_DSN = os.getenv("SENTRY_DSN", "")
if SENTRY_DSN and not DEBUG:
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[DjangoIntegration()],
        traces_sample_rate=float(os.getenv("SENTRY_TRACES_SAMPLE_RATE", "0.1")),
        send_default_pii=False,
    )
