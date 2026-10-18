
TWEYONJE - SMART WASTE MANAGEMENT SYSTEM
Together for a Cleaner Uganda

1. OVERVIEW
Tweyonje is a mobile-based smart waste management platform that
connects Residents, Collectors, Authorities, and Recyclers for
efficient waste collection and recycling in Uganda. Using mobile
technology, real-time tracking, and AI-powered classification, it
creates a seamless link between waste generators, collectors, and
recyclers.

KEY FEATURES

  * Smart Collection Scheduling - Easy pickup requests with
    real-time tracking
  * GPS-Based Routing - Optimized collection routes
  * Mobile Payments - MTN Mobile Money, Airtel Money, and cards
  * Rewards System - Eco-points for recycling and responsible
    disposal
  * AI Classification - Automated waste categorization using
    machine learning
  * Multi-Role Support - Dedicated interfaces for Residents,
    Collectors, Authorities, and Recyclers
  * English Interface - Clean, consistent English-only UI
  * Smart Notifications - Real-time alerts and status updates

2. TECHNOLOGY STACK

Mobile Frontend   Flutter + Dart
                  Cross-platform app (Android & iOS)
Backend           Django + Django REST Framework
                  RESTful API and business logic
Database          PostgreSQL + PostGIS
                  Geospatial data storage and queries
Authentication    JWT + Biometric
                  Secure token-based auth with biometric support
Maps & Location   Google Maps / OpenStreetMap
                  GPS tracking and route optimization
Notifications     Firebase Cloud Messaging
                  Real-time push notifications
Payments          MTN Mobile Money / Airtel Money / Card
                  Local payment integration
AI/ML             Python + scikit-learn / PyTorch
                  Waste classification and analytics
State Management  Flutter Riverpod
                  Reactive state management
Real-time         Django Channels + Daphne
                  Live updates and tracking over WebSocket (/ws/)
Background Jobs   Celery + Redis
                  Scheduled payouts, SLA checks, notification retries
Offline Support   SharedPreferences + Hive
                  Local storage and offline-first architecture
Deployment        Docker + Nginx + GitHub Actions
                  Containerized deployment with CI/CD
                  
4. DEVELOPMENT ROADMAP

The project is organized into 6 sprints covering 125 user stories:

  Sprint 1 - Foundation & Access ........ 20 stories
  Sprint 2 - Core Collection ............ 26 stories
  Sprint 3 - Money & Ecosystem .......... 23 stories
  Sprint 4 - Compliance & Trust ......... 22 stories
  Sprint 5 - Platform & Insight ......... 19 stories
  Sprint 6 - Operations & Support ....... 15 stories


5. GETTING STARTED

PREREQUISITES

  * Backend: Python 3.9+, PostgreSQL 14+ with PostGIS
    (optional for local development)
  * Frontend: Flutter SDK 3.12+, Dart 3.12+
  * Mobile: Android Studio / Xcode for native builds
    (optional for development)


BACKEND SETUP (PowerShell)

  cd Tweyonje-App\backend

  # Create and activate virtual environment
  python -m venv .venv
  .venv\Scripts\activate

  # Install dependencies
  pip install -r requirements.txt

  # Start PostgreSQL with Docker
  docker run -d --name tweyonje-postgres `
    -e POSTGRES_PASSWORD=change-me `
    -e POSTGRES_DB=tweyonje `
    -e POSTGRES_USER=tweyonje `
    -p 5433:5432 `
    -v tweyonje_pgdata:/var/lib/postgresql/data `
    postgis/postgis:16-3.4

  # Configure environment variables
  cp .env.example .env
  # Edit .env with your database credentials.
  # DB_ENGINE: leave empty for local SQLite, "postgres" for
  # PostgreSQL, or "postgis" for PostGIS (requires GDAL on host).

  # Run migrations
  python manage.py migrate

  # Seed initial data
  python manage.py seed_data

  # Create superuser
  python manage.py createsuperuser

  # Start development server (Daphne serves HTTP + WebSocket)
  python manage.py runserver

  # Optional: background tasks require Redis + a Celery worker/beat.
  # Set CELERY_BROKER_URL / REDIS_URL, then:
  celery -A config worker -l info
  celery -A config beat -l info

  # Or run everything containerized (PostGIS, Redis, workers):
  cd backend/deployment
  docker compose up

Backend URL:
  http://127.0.0.1:8000

WebSocket endpoint:
  ws://127.0.0.1:8000/ws/?token=<JWT access token>

  Clients subscribe with:
    {"type": "subscribe", "data": {"type":
    "collection|assignment|payment|support|recycling|zone",
    "id": "<uuid>"}}
  and receive scoped events (e.g. collection_update,
  payment_update, location_update).

API documentation:
  Swagger UI ..... http://127.0.0.1:8000/api/docs/
  ReDoc .......... http://127.0.0.1:8000/api/redoc/
  OpenAPI Schema . http://127.0.0.1:8000/api/schema/


FRONTEND SETUP (Flutter & Dart)

  cd Tweyonje-App\frontend

  # Configure build-time values
  # (copy .env.example to .env, then edit API_URL / WS_URL)
  cp .env.example .env

  # Install Flutter dependencies
  flutter pub get

  # Run on Android emulator or connected physical device
  flutter run --dart-define-from-file=.env

  # Run on web browser
  flutter run -d chrome --dart-define-from-file=.env

  # Code analysis and linting
  flutter analyze

  # Format code
  flutter format .

  # Run tests
  flutter test


iOS

The ios/ platform folder is included. To build for iOS
(macOS + Xcode required):

  1. cd ios && pod install
  2. Open Runner.xcworkspace in Xcode, set your bundle
     identifier and signing team.
  3. Run "flutter run" against a simulator or device.

Platform usage descriptions (location, camera, photo library,
Face ID) are already declared in ios/Runner/Info.plist.


FIREBASE PUSH NOTIFICATIONS

Push notifications are enabled in code but fail gracefully
without Firebase config:

  * Android: Create a Firebase project, register the
    ug.tweyonje.tweyonje package, download google-services.json
    and place it at android/app/google-services.json. Enable the
    Google Services Gradle plugin under the "plugins" block of
    android/app/build.gradle.kts.
  * iOS: Download GoogleService-Info.plist and place it at
    ios/Runner/GoogleService-Info.plist.

Templates are provided at:
  android/app/google-services.json.example
  ios/Runner/GoogleService-Info.plist.example


GOOGLE MAPS

Default maps use OpenStreetMap tiles (no key required). To use
Google Maps instead, pass --dart-define=GOOGLE_MAPS_API_KEY=...
(and the MAPS_API_KEY env var for Android builds via
android/maps_api_key_gradle.properties).


APP ICON

Regenerate launcher icons after replacing
assets/app_icon/app_icon.png:

  dart run flutter_launcher_icons


6. CONFIGURATION
BACKEND ENVIRONMENT VARIABLES (.env)

  # Database
  DB_ENGINE=              # empty = SQLite | postgres | postgis
  DB_NAME=tweyonje
  DB_USER=tweyonje
  DB_PASSWORD=change-me
  DB_HOST=localhost
  DB_PORT=5433

  # Security
  SECRET_KEY=your-secret-key-here
  DJANGO_SUPERUSER_PASSWORD=admin-password

  # Real-time + background tasks
  REDIS_URL=redis://localhost:6379/0
  CELERY_BROKER_URL=redis://localhost:6379/0

  # Payment Integration (PAYMENT_PROVIDER: dev | mtn | airtel)
  PAYMENT_PROVIDER=dev
  MTN_MOMO_SUBSCRIPTION_KEY=your-mtn-key
  MTN_MOMO_API_USER=your-mtn-api-user
  MTN_MOMO_API_KEY=your-mtn-secret
  AIRTEL_CLIENT_ID=your-airtel-id
  AIRTEL_CLIENT_SECRET=your-airtel-secret

  # Notifications (SMS_PROVIDER: dev | twilio | africastalk)
  SMS_PROVIDER=dev
  FCM_CREDENTIALS_PATH=path/to/firebase-service-account.json
  TWILIO_ACCOUNT_SID=your-twilio-sid
  TWILIO_AUTH_TOKEN=your-twilio-token


FRONTEND ENVIRONMENT VARIABLES

The Flutter app has no runtime .env loader. Values are injected
at build/run time via --dart-define (see frontend/.env.example):

  # frontend/.env  (pass with --dart-define-from-file=.env)
  API_URL=http://127.0.0.1:8000
  WS_URL=ws://127.0.0.1:8000/ws/
  # GOOGLE_MAPS_API_KEY=   (only needed for Google Maps)

7. CI/CD PIPELINE

GitHub Actions handles automated testing and deployment.

BACKEND PIPELINE (.github/workflows/backend.yml)

  * Runs the full test suite with PostgreSQL/PostGIS
  * Code quality checks (flake8, black, isort, mypy)
  * Builds and pushes Docker images
  * Deploys to staging (develop branch) and production
    (main branch)

FRONTEND PIPELINE (.github/workflows/frontend.yml)

  * Flutter analysis and code quality checks
  * Flutter tests with coverage reporting
  * Builds the Flutter app for multiple platforms
  * Builds and pushes Docker images
  * Deploys to staging and production
  * Generates Android APK and iOS/IPA builds

See backend/docs/CI_CD_SETUP.md for detailed CI/CD configuration.

8. MANAGEMENT COMMANDS

  python manage.py run_payouts                 Batch payouts for a period
  python manage.py run_reconciliation          Reconcile provider statements
  python manage.py process_due_schedules       Process recurring schedules
  python manage.py check_sla                   Escalate past-due tickets
  python manage.py retry_notifications         Redeliver failed notifications
  python manage.py backup_data --output backups
                                               Database backup
  python manage.py train_waste_classifier --data-dir path/to/images
                                               Train AI model

9. BACKEND HIGHLIGHTS

  * Role-Based Access Control - Residents, collectors,
    authorities, and admins see only their relevant data
  * Geospatial Queries - PostGIS-powered location-based queries
    and routing
  * Collection Slots - Time window enforcement per zone/weekday
  * Dynamic Route Optimization - Automatic route recalculation
    on job assignment
  * Idempotent Rewards - Eco-points awarded safely per source
  * Privacy Policy Versioning - Track consent versions and
    re-consent requirements
  * Dispute Resolution - Evidence validation with automatic
    refund workflows
  * Smart Notifications - SMS fallback to email with retry logic
  * Rate Limiting - Configurable throttling for sensitive
    endpoints

10. FRONTEND FEATURES
COMPONENT LIBRARY

  * Core UI: Screen, Card, Button, Input, Icon, Avatar, Badge,
    StatCard
  * Advanced: Map with GPS tracking, Rating/Review system,
    File Upload, Chat/Messaging
  * Utilities: Date/Time pickers, Loading skeletons, Error
    boundaries

SCREEN IMPLEMENTATIONS

  * Resident: Home, Request creation, Live tracking, Schedule
    management, Rewards
  * Collector: Dashboard, Job details, Route optimization,
    Earnings, History
  * Authority: Analytics dashboard, Zone management, Collector
    oversight
  * Admin: User management, Verification workflow, System
    configuration
  * Shared: Onboarding, Notification preferences, Support tickets

SERVICES & PROVIDERS

  * Location: GPS tracking, distance calculation, geocoding
  * Biometric: Biometric authentication support
  * Authentication: Session management, token refresh
  * Storage: Secure local storage for sensitive data
  * Navigation: Type-safe routing with authentication guards

CROSS-PLATFORM

  * Single Flutter codebase for Android, iOS, Web, and Desktop
  * Platform-specific optimizations for biometrics and
    accessibility
  * Hot reload for rapid development testing
  * Responsive design for different screen sizes



