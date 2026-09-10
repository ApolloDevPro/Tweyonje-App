# CI/CD Setup Guide

This document explains how to set up and use the CI/CD pipelines for the Tweyonje application.

## Overview

The project uses GitHub Actions for CI/CD with the following workflows:

- **Backend CI/CD** (`.github/workflows/backend.yml`)
- **Frontend CI/CD** (`.github/workflows/frontend.yml`)

## Prerequisites

### GitHub Secrets

Configure the following secrets in your GitHub repository settings:

#### Docker Registry
- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_PASSWORD` - Docker Hub password or access token

#### Staging Environment
- `STAGING_HOST` - Staging server hostname/IP
- `STAGING_USER` - SSH username for staging server
- `STAGING_SSH_KEY` - Private SSH key for staging server

#### Production Environment
- `PRODUCTION_HOST` - Production server hostname/IP
- `PRODUCTION_USER` - SSH username for production server
- `PRODUCTION_SSH_KEY` - Private SSH key for production server

#### Expo (for mobile builds)
- `EXPO_TOKEN` - Expo account token for building mobile apps

## Backend CI/CD Pipeline

### Workflow Triggers

The backend pipeline runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Changes only in the `backend/` directory

### Pipeline Stages

#### 1. Test
- Sets up Python 3.11
- Installs dependencies
- Runs linting (flake8, black, isort, mypy)
- Runs Django tests with PostgreSQL/PostGIS
- Uses PostgreSQL service container

#### 2. Build
- Builds Docker image
- Pushes to Docker Hub with tags:
  - `latest`
  - Git commit SHA
- Only runs on `main` or `develop` branches

#### 3. Deploy to Staging
- Deploys to staging environment
- Runs database migrations
- Collects static files
- Only runs on `develop` branch

#### 4. Deploy to Production
- Deploys to production environment
- Runs database migrations
- Collects static files
- Only runs on `main` branch

### Environment Variables

The pipeline uses these environment variables (configured in `.env` on servers):

```bash
DEBUG=False
SECRET_KEY=<your-secret-key>
DB_NAME=tweyonje
DB_USER=tweyonje
DB_PASSWORD=<your-db-password>
DB_HOST=db
DB_PORT=5432
USE_POSTGIS=true
```

## Frontend CI/CD Pipeline

### Workflow Triggers

The frontend pipeline runs on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Changes only in the `frontend/` directory

### Pipeline Stages

#### 1. Lint
- Sets up Node.js 18
- Installs dependencies
- Runs ESLint
- Runs TypeScript type checking

#### 2. Test
- Runs Jest tests with coverage
- Runs in CI mode

#### 3. Build
- Builds the React Native app
- Uploads build artifacts
- Caches build for 7 days

#### 4. Build Docker
- Builds Docker image
- Pushes to Docker Hub
- Only runs on `main` or `develop` branches

#### 5. Deploy to Staging
- Deploys to staging environment
- Only runs on `develop` branch

#### 6. Deploy to Production
- Deploys to production environment
- Only runs on `main` branch

#### 7. Build Android APK
- Builds Android APK using EAS Build
- Only runs on `main` or `develop` branches

#### 8. Build iOS IPA
- Builds iOS IPA using EAS Build
- Only runs on `main` or `develop` branches

## Server Setup

### Staging/Production Server Requirements

1. **Install Docker and Docker Compose**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

2. **Create deployment directory**
   ```bash
   sudo mkdir -p /opt/tweyonje
   sudo chown $USER:$USER /opt/tweyonje
   cd /opt/tweyonje
   ```

3. **Clone the application into the deployment directory**
   ```bash
   git clone <repo-url> /opt/tweyonje
   cd /opt/tweyonje
   ```

4. **Copy environment file**
   ```bash
   scp backend/.env user@server:/opt/tweyonje/backend/.env
   ```

5. **Start services**
   ```bash
   docker compose -f backend/deployment/docker-compose.yml up -d
   ```

> Deploys performed by CI/CD (`deploy-staging` / `deploy-production`) use the same
> compose file and expect images pushed to Docker Hub under `$DOCKER_USERNAME`
> (`tweyonje-backend`, `tweyonje-frontend`). Set `DOCKER_USERNAME` on the deploy
> host to the Docker Hub namespace used by the build jobs.

### SSH Key Setup

1. **Generate SSH key pair**
   ```bash
   ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions
   ```

2. **Add public key to server**
   ```bash
   ssh-copy-id -i ~/.ssh/github_actions.pub user@server
   ```

3. **Add private key to GitHub Secrets**
   - Copy the contents of `~/.ssh/github_actions`
   - Add as `STAGING_SSH_KEY` or `PRODUCTION_SSH_KEY`

## Docker Images

### Backend Image
- **Repository**: `your-docker-username/tweyonje-backend`
- **Tags**: `latest`, `<commit-sha>`
- **Base**: Python 3.11 slim (ASGI via Daphne, HTTP + WebSocket)
- **Port**: 8000

### Frontend Image
- **Repository**: `your-docker-username/tweyonje-frontend`
- **Tags**: `latest`, `<commit-sha>`
- **Base**: Flutter web build served by nginx
- **Port**: 80 (published on host as `8081:80`)

## Manual Deployment

### Backend
```bash
# Build image locally
cd backend
docker build -t tweyonje-backend -f docker/Dockerfile .

# Run container
docker run -p 8000:8000 \
  -e DB_HOST=host.docker.internal \
  -e DB_PASSWORD=your-password \
  tweyonje-backend
```

### Frontend
```bash
# Build image locally
cd frontend
docker build -t tweyonje-frontend .

# Run container
docker run -p 8081:80 tweyonje-frontend
```

## Monitoring

### Check Pipeline Status
- Go to GitHub repository
- Click on "Actions" tab
- View workflow runs and logs

### Check Deployment
```bash
# On server
cd /opt/tweyonje
docker compose -f backend/deployment/docker-compose.yml ps
docker compose -f backend/deployment/docker-compose.yml logs -f backend
docker compose -f backend/deployment/docker-compose.yml logs -f frontend
```

## Rollback

### Backend Rollback
```bash
cd /opt/tweyonje
docker compose -f backend/deployment/docker-compose.yml pull backend:previous-tag
docker compose -f backend/deployment/docker-compose.yml up -d backend
```

### Frontend Rollback
```bash
cd /opt/tweyonje
docker compose -f backend/deployment/docker-compose.yml pull frontend:previous-tag
docker compose -f backend/deployment/docker-compose.yml up -d frontend
```

## Troubleshooting

### Pipeline Fails on Tests
- Check test logs in GitHub Actions
- Ensure PostgreSQL service is healthy
- Verify environment variables are correct

### Deployment Fails
- Check SSH key permissions
- Verify server connectivity
- Ensure Docker is running on server
- Check `backend/deployment/docker-compose.yml` syntax

### Docker Build Fails
- Verify Docker Hub credentials
- Check Dockerfile syntax
- Ensure base images are available

## Security Best Practices

1. **Never commit `.env` files** - Use GitHub Secrets
2. **Rotate SSH keys regularly** - Update GitHub Secrets when changed
3. **Use separate environments** - Staging for testing, production for live
4. **Enable branch protection** - Require PR reviews before merging to main
5. **Monitor pipeline runs** - Review logs for suspicious activity
6. **Keep dependencies updated** - Regular security updates

## Cost Optimization

- **Use GitHub Actions cache** - Reduces build times
- **Docker layer caching** - Speeds up image builds
- **Conditional deployments** - Only deploy on specific branches
- **Artifact retention** - Clean up old artifacts regularly

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Django Deployment](https://docs.djangoproject.com/en/stable/howto/deployment/)
