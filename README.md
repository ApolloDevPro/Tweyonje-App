Tweyonje - Smart Waste Management System

Together for a Cleaner Uganda

A comprehensive mobile-based smart waste management platform connecting Residents, Collectors, Authorities, and Recyclers for efficient waste collection and recycling.

🌟 Overview

Tweyonje is an innovative waste management ecosystem designed to transform how communities handle waste collection and recycling in Uganda. By leveraging mobile technology, real-time tracking, and AI-powered classification, Tweyonje creates a seamless connection between waste generators, collectors, and recyclers.

Key Features

🚀 Smart Collection Scheduling - Easy waste pickup requests with real-time tracking🗺️ GPS-Based Routing - Optimized collection routes for maximum efficiency💰 Mobile Payments - Integrated MTN Mobile Money, Airtel Money, and card payments🎁 Rewards System - Eco-points for recycling and responsible waste disposal🤖 AI Classification - Automated waste categorization using machine learning📱 Multi-Role Support - Dedicated interfaces for Residents, Collectors, Authorities, and Recyclers🌍 English Interface - Clean, consistent English-only UI🔔 Smart Notifications - Real-time alerts and status updates

🛠️ Technology Stack

LayerTechnologyPurposeMobile FrontendFlutter + DartCross-platform mobile application (Android & iOS)BackendDjango + Django REST FrameworkRESTful API and business logicDatabasePostgreSQL + PostGISGeospatial data storage and queriesAuthenticationJWT + BiometricSecure token-based auth with biometric supportMaps & LocationGoogle Maps / OpenStreetMapGPS tracking and route optimizationNotificationsFirebase Cloud MessagingReal-time push notificationsPaymentsMTN Mobile Money / Airtel Money / CardLocal payment integrationAI/MLPython + scikit-learn / PyTorchWaste classification and analyticsState ManagementFlutter RiverpodReactive state managementReal-timeDjango Channels + DaphneLive updates and tracking over WebSocket (/ws/)Background jobsCelery + RedisScheduled payouts, SLA checks, notification retriesOffline SupportSharedPreferences + HiveLocal storage and offline-first architectureDeploymentDocker + Nginx + GitHub ActionsContainerized deployment with CI/CD

📁 Project Structure

tweyonje-app/ ├── backend/ # Django REST API backend │ ├── apps/ # Business modules (bounded contexts) │ │ ├── accounts/ # User registration, authentication, roles │ │ ├── profiles/ # User profiles, vehicles, sites │ │ ├── waste_requests/ # Waste collection requests │ │ ├── collections/ # Job assignment, lifecycle, shifts │ │ ├── tracking/ # GPS tracking, location sharing │ │ ├── reports/ # Illegal dumping reports │ │ ├── notifications/ # Push, SMS, email notifications │ │ ├── payments/ # Payment processing, payouts │ │ ├── recycling/ # Recycling marketplace │ │ ├── rewards/ # Eco-points, tiers, redemption │ │ ├── ratings/ # User ratings, incident reports │ │ ├── platform_admin/ # User management, verification │ │ ├── analytics/ # Dashboards, reports, insights │ │ ├── routing/ # Route optimization │ │ ├── ai/ # Waste classification AI │ │ ├── support/ # Support tickets, disputes │ │ ├── security/ # Audit logs, rate limiting │ │ └── localization/ # Translations, i18n (English) │ ├── core/ # Shared models, permissions, middleware │ ├── config/ # Django settings, URLs, WSGI/ASGI │ ├── api/ # API v1 endpoint registration │ ├── tests/ # Unit and integration tests │ └── docs/ # Backend documentation │ ├── frontend/ # Flutter mobile application │ └── lib/ │ ├── core/ # Core functionality │ │ ├── constants/ # App constants and configurations │ │ ├── network/ # Network configuration and utilities │ │ ├── services/ # Core services (biometric, location) │ │ ├── storage/ # Local storage implementations │ │ └── theme/ # App theme and styling │ ├── features/ # Feature modules │ │ ├── auth/ # Authentication screens and logic │ │ ├── resident/ # Resident-specific screens │ │ ├── collector/ # Collector-specific screens │ │ ├── authority/ # Authority-specific screens │ │ ├── profile/ # User profile management │ │ └── recycling/ # Recycling marketplace │ ├── models/ # Data models and DTOs │ ├── providers/ # Riverpod state providers │ ├── routing/ # Navigation and routing │ ├── widgets/ # Reusable UI widgets │ └── main.dart # App entry point │ └── .github/workflows/ # CI/CD pipelines ├── backend.yml # Backend deployment └── frontend.yml # Frontend deployment 

📋 Development Roadmap

The project is organized into 6 sprints covering 125 user stories:

SprintFocusStories1Foundation & Access202Core Collection263Money & Ecosystem234Compliance & Trust225Platform & Insight196Operations & Support15

🚀 Getting Started

Prerequisites

Backend: Python 3.9+, PostgreSQL 14+ with PostGIS (optional for local dev)Frontend: Flutter SDK 3.12+, Dart 3.12+Mobile: Android Studio / Xcode for native builds (optional for development)

Backend Setup

cd Tweyonje-App\backend # Create and activate virtual environment python -m venv .venv .venv\Scripts\activate # Install dependencies pip install -r requirements.txt # Start PostgreSQL with Docker docker run -d --name tweyonje-postgres ` -e POSTGRES_PASSWORD=change-me ` -e POSTGRES_DB=tweyonje ` -e POSTGRES_USER=tweyonje ` -p 5433:5432 ` -v tweyonje_pgdata:/var/lib/postgresql/data ` postgis/postgis:16-3.4 # Configure environment variables cp .env.example .env # Edit .env with your database credentials. # DB_ENGINE: leave empty for local SQLite, "postgres" for PostgreSQL, # or "postgis" for PostGIS (requires GDAL on the host). # Run migrations python manage.py migrate # Seed initial data python manage.py seed_data # Create superuser python manage.py createsuperuser # Start development server (Daphne serves HTTP + WebSocket) python manage.py runserver # Optional: background tasks require Redis + a Celery worker/beat. # Set CELERY_BROKER_URL / REDIS_URL, then: celery -A config worker -l info celery -A config beat -l info # Or run everything containerized (includes PostGIS, Redis, workers): cd backend/deployment docker compose up

Backend will be available at: http://127.0.0.1:8000

WebSocket endpoint: ws://127.0.0.1:8000/ws/?token=<JWT access token> — clients subscribe with {"type": "subscribe", "data": {"type": "collection|assignment|payment|support|recycling|zone", "id": "<uuid>"}} and receive scoped events (e.g. collection_update, payment_update, location_update).

API Documentation:

Swagger UI: http://127.0.0.1:8000/api/docs/ReDoc: http://127.0.0.1:8000/api/redoc/OpenAPI Schema: http://127.0.0.1:8000/api/schema/

Frontend Setup (Flutter & Dart)

cd Tweyonje-App\frontend # Configure build-time values (copy .env.example -> .env, then edit API_URL / WS_URL) cp .env.example .env # Install Flutter dependencies flutter pub get # Run on Android emulator or connected physical device flutter run --dart-define-from-file=.env # Run on web browser flutter run -d chrome --dart-define-from-file=.env # Code analysis and linting flutter analyze # Format code flutter format . # Run tests flutter test

iOS

The ios/ platform folder is included. To build for iOS (macOS + Xcode required):

cd ios && pod installOpen Runner.xcworkspace in Xcode, set your bundle identifier & signing team.flutter run against a simulator or device.

Platform usage descriptions (location, camera, photo library, Face ID) are already declared in ios/Runner/Info.plist.

Firebase push notifications

Push notifications are enabled in code but fail gracefully without Firebase config:

Android: create a Firebase project, register the ug.tweyonje.tweyonje package, download google-services.json and drop it at android/app/google-services.json. Enable the Google Services Gradle plugin under the plugins block of android/app/build.gradle.kts.iOS: download GoogleService-Info.plist and drop it at ios/Runner/GoogleService-Info.plist.

Placeholder/templates live at android/app/google-services.json.example and ios/Runner/GoogleService-Info.plist.example.

Google Maps

Default maps use OpenStreetMap tiles (no key required). To use Google Maps instead, pass --dart-define=GOOGLE_MAPS_API_KEY=... (and MAPS_API_KEY env var for Android builds via android/maps_api_key_gradle.properties).

App icon

Regenerate launcher icons after replacing assets/app_icon/app_icon.png:

dart run flutter_launcher_icons

🔧 Configuration

Backend Environment Variables

Key environment variables for the backend (.env file):

# Database DB_ENGINE= # empty = SQLite | postgres | postgis DB_NAME=tweyonje DB_USER=tweyonje DB_PASSWORD=change-me DB_HOST=localhost DB_PORT=5433 # Security SECRET_KEY=your-secret-key-here DJANGO_SUPERUSER_PASSWORD=admin-password # Real-time + background tasks REDIS_URL=redis://localhost:6379/0 CELERY_BROKER_URL=redis://localhost:6379/0 # Payment Integration (PAYMENT_PROVIDER: dev | mtn | airtel) PAYMENT_PROVIDER=dev MTN_MOMO_SUBSCRIPTION_KEY=your-mtn-key MTN_MOMO_API_USER=your-mtn-api-user MTN_MOMO_API_KEY=your-mtn-secret AIRTEL_CLIENT_ID=your-airtel-id AIRTEL_CLIENT_SECRET=your-airtel-secret # Notifications (SMS_PROVIDER: dev | twilio | africastalk) SMS_PROVIDER=dev FCM_CREDENTIALS_PATH=path/to/firebase-service-account.json TWILIO_ACCOUNT_SID=your-twilio-sid TWILIO_AUTH_TOKEN=your-twilio-token

Frontend Environment Variables

The Flutter app has no runtime .env loader; values are injected at build/run time via --dart-define (see frontend/.env.example):

# frontend/.env (pass with --dart-define-from-file=.env) API_URL=http://127.0.0.1:8000 WS_URL=ws://127.0.0.1:8000/ws/ # GOOGLE_MAPS_API_KEY= (only needed for Google Maps)

🔄 CI/CD Pipeline

The project uses GitHub Actions for automated testing and deployment:

Backend Pipeline (.github/workflows/backend.yml)

✅ Runs comprehensive test suite with PostgreSQL/PostGIS🔍 Code quality checks (flake8, black, isort, mypy)🐳 Builds and pushes Docker images🚀 Deploys to staging (develop branch) and production (main branch)

Frontend Pipeline (.github/workflows/frontend.yml)

✅ Flutter analysis and code quality checks🧪 Flutter tests with coverage reporting📱 Builds Flutter application for multiple platforms🐳 Builds and pushes Docker images🚀 Deploys to staging and production📲 Generates Android APK and iOS/IPA builds

See backend/docs/CI_CD_SETUP.md for detailed CI/CD configuration.

🛠️ Management Commands

Backend Operations

python manage.py run_payouts # Batch payouts for a period python manage.py run_reconciliation # Reconcile provider statements python manage.py process_due_schedules # Process recurring schedules python manage.py check_sla # Escalate past-due support tickets python manage.py retry_notifications # Redeliver failed notifications python manage.py backup_data --output backups # Database backup python manage.py train_waste_classifier --data-dir path/to/images # Train AI model

🌟 Backend Highlights

Architecture Features

Role-Based Access Control: Residents, collectors, authorities, and admins see only their relevant dataGeospatial Queries: PostGIS-powered location-based queries and routingCollection Slots: Time window enforcement per zone/weekdayDynamic Route Optimization: Automatic route recalculation on job assignmentIdempotent Rewards: Eco-points awarded safely per sourcePrivacy Policy Versioning: Track consent versions and re-consent requirementsDispute Resolution: Evidence validation with automatic refund workflowsSmart Notifications: SMS fallback to email with retry logicRate Limiting: Configurable throttling for sensitive endpoints

📱 Frontend Features

Component Library

Core UI: Screen, Card, Button, Input, Icon, Avatar, Badge, StatCardAdvanced: Map with GPS tracking, Rating/Review system, File Upload, Chat/MessagingUtilities: Date/Time pickers, Loading skeletons, Error boundaries

Screen Implementations

Resident: Home, Request creation, Live tracking, Schedule management, RewardsCollector: Dashboard, Job details, Route optimization, Earnings, HistoryAuthority: Analytics dashboard, Zone management, Collector oversightAdmin: User management, Verification workflow, System configurationShared: Onboarding, Notification preferences, Support tickets

Services & Providers

Location: GPS tracking, distance calculation, geocodingBiometric: Biometric authentication supportAuthentication: Session management, token refreshStorage: Secure local storage for sensitive dataNavigation: Type-safe routing with authentication guards

Cross-Platform

Single Flutter codebase for Android, iOS, Web, and DesktopPlatform-specific optimizations for biometrics and accessibilityHot reload for rapid development testingResponsive design for different screen sizes

🤝 Contributing

We welcome contributions to Tweyonje! Please follow these guidelines:

Fork the repository and create a feature branchFollow the coding standards (Black for Python, Flutter/Dart conventions)Write tests for new features and bug fixesUpdate documentation as neededSubmit a pull request with a clear description

📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

📞 Support

For questions, issues, or suggestions:

📧 Email: support@tweyonje.ug🐛 Issues: GitHub Issues📖 Documentation: Full Docs

Built with ❤️ for a Cleaner Uganda

© 2024 Tweyonje. All rights reserved.


