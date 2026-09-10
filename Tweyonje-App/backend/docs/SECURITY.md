# Security Policy

## Authentication & session management

- **JWT** with short-lived access tokens (default 15 min) and long-lived refresh
  tokens (default 30 days).
- Refresh tokens are rotated on use. Stale tokens are rejected by the
  `run_reconciliation` command.
- **OTP** verification is required for registration and sensitive operations.
  Codes expire after a short window and are single-use.
- **Biometric** login is optional on supported devices; tokens are stored in the
  OS secure enclave via `flutter_secure_storage` / Keychain.

## Rate limiting

Sensitive endpoints are throttled via `django-ratelimit` and DRF's built-in
throttling classes:

| Endpoint | Default |
|---|---|
| Login | 10/min |
| OTP send | 5/min |
| OTP verify | 10/min |
| Password reset | 5/min |
| AI classify | 10/min |

Throttle rates are configurable through environment variables (see `.env.example`).

## Role-based access control

Four roles (`resident`, `collector`, `authority`, `administrator`) each have
dedicated permissions. API endpoints enforce `IsAuthenticated` plus custom
permission classes in every view.

## Data protection

- Passwords are hashed with Django's `make_password` / `PBKDF2`.
- Sensitive tokens never appear in logs.
- PII is isolated per user: each authenticated endpoint filters querysets by
  the requesting user.
- Audit logs record privileged operations in `apps/security`.

## Transport

- `flutter_secure_storage` stores tokens in the Android Keystore and iOS
  Keychain.
- WebSocket connections require a valid JWT passed as `?token=` and are
  verified on connect.
- API traffic is expected behind TLS in production; the frontend
  `SecurityConfig` enforces SSL pinning against allowed domains.

## Payments

- Live payments (MTN MoMo, Airtel Money) use dedicated API clients that
  authenticate via subscription keys / OAuth client credentials.
- Callback webhooks are authenticated with a shared secret
  (`MTN_MOMO_CALLBACK_TOKEN`).
- Stale or failed payments are automatically reconciled by
  `run_reconciliation`.

## AI classifier

- The classifier model is stored server-side; only the classification result
  (not the raw model) is returned to clients.
- Uploaded classification images are written to `MEDIA_ROOT/ai_classifications/`
  and are protected by Django's media file serving configuration.

## Dependencies & updates

- Backend: pinned in `requirements.txt`; dependabot alerts review weekly.
- Frontend: pinned in `pubspec.lock`; audit regularly with `dart pub audit`.
- Docker base images use official, pinned tags (not `latest`).

## Reporting vulnerabilities

Report security issues privately to <security@tweyonje.ug>. Do **not** open
public GitHub issues for vulnerabilities.