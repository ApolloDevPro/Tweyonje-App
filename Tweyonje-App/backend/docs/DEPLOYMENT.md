# Deployment Guide

## Overview

Tweyonje backend runs as a Django/ASGI (Daphne) application behind Nginx, with
Django Channels for WebSocket support and Celery for background work.

## Prerequisites

- Python 3.9+
- PostgreSQL 14+ with PostGIS (optional for local dev)
- Redis 6+
- Docker and Docker Compose (for containerized deployments)
- Nginx (reverse proxy)

## Environment

Copy `.env.example` to `.env` and populate every non-empty value. Key variables:

| Variable | Purpose |
|---|---|
| `SECRET_KEY` | Django signing key — **must** differ across environments |
| `DB_ENGINE` | `postgres` / `postgis` / empty (SQLite) |
| `REDIS_URL` | Channels + Celery broker |
| `PAYMENT_PROVIDER` | `dev` / `mtn` / `airtel` |
| `SMS_PROVIDER` | `dev` / `twilio` / `africastalk` |
| `AI_MODEL_PATH` | Path to trained classifier `.joblib` file |

## Local development

```bash
cd Tweyonje-App/backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_data
python manage.py runserver          # Daphne (HTTP + WebSocket)
```

## Containerized stack (recommended)

```bash
cd Tweyonje-App/backend/deployment
cp ../.env.example ../.env          # populate before starting
docker compose up --build -d
```

Compose services:

| Service | Image | Port |
|---|---|---|
| web | Custom Django/Daphne image | 8000 |
| redis | redis:7-alpine | 6379 |
| celery-worker | Custom Celery image | — |
| celery-beat | Custom Celery beat image | — |
| postgres (optional) | postgis/postgis:16-3.4 | 5432 |

When `DB_ENGINE` is empty, the stack falls back to SQLite and the Postgres
service can be omitted.

## CI/CD (GitHub Actions)

Pushing to `develop` triggers the staging pipeline; `main` triggers production.
See `.github/workflows/backend.yml`.

Key steps:

1. Python lint + type-check (flake8, black, isort, mypy)
2. pytest with a PostgreSQL/PostGIS service container
3. Docker image build and push
4. Deploy to target (needs repository secrets configured)

## Migrations

```bash
python manage.py makemigrations    # if new models changed
python manage.py migrate
```

## Static & media files

WhiteNoise serves collected static files in production:

```bash
python manage.py collectstatic --noinput
```

Media uploads live under `MEDIA_ROOT` (default `backend/media/`). Back these up
per `BACKUP_DISASTER_RECOVERY.md`.

## Background tasks

When `CELERY_TASK_ALWAYS_EAGER=true` (the default in `.env.example`) Celery
tasks run synchronously. For production, run a worker and beat scheduler:

```bash
celery -A config worker -l info
celery -A config beat -l info
```

## Management commands

| Command | Purpose |
|---|---|
| `run_payouts` | Batch-payout collectors |
| `run_reconciliation` | Reconcile payment provider statements |
| `process_due_schedules` | Activate recurring collection schedules |
| `check_sla` | Escalate overdue support tickets |
| `retry_notifications` | Redeliver failed notifications |
| `backup_data` | Export database to file |
| `train_waste_classifier` | Train the AI waste classifier |