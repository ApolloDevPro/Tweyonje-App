# Backend Dockerfile for Tweyonje.
# Serves the ASGI app (HTTP + WebSocket) via Daphne and can also run Celery
# workers/beat. Dependencies pin Python 3.11 to match CI.

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DEBIAN_FRONTEND=noninteractive

# libgomp1 is required by the PyTorch CPU wheels pulled in via requirements.txt.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies first to leverage Docker layer caching.
COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip install -r requirements.txt

# Copy the application code.
COPY . .

# Collect static files into staticfiles/ so Whitenoise/nginx can serve them.
RUN python manage.py collectstatic --noinput --no-post-process

# Run as an unprivileged user.
RUN groupadd -r django && useradd -r -g django django \
    && chown -R django:django /app
USER django

ENV PORT=8000
EXPOSE $PORT

# Daphne serves both HTTP and WebSockets from the single ASGI app.
CMD daphne -b 0.0.0.0 -p $PORT config.asgi:application