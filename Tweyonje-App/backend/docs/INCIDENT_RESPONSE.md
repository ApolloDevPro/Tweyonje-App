# Incident Response Plan

## Scope

Covers unplanned outages, data breaches, payment failures, and any event
affecting the availability or integrity of the Tweyonje platform.

## Response team

| Role | Contact |
|---|---|
| On-call engineer | +256-700-000-000 |
| Database administrator | dbadmin@tweyonje.ug |
| System administrator | sysadmin@tweyonje.ug |
| Management | management@tweyonje.ug |

## Severity levels

| Level | Description | Target initial response |
|---|---|---|
| **P1** | Full outage or confirmed data breach | 15 minutes |
| **P2** | Partial outage or degraded payments | 1 hour |
| **P3** | Non-critical failure (notifications, analytics) | 4 hours |
| **P4** | Cosmetic or low-impact issue | 24 hours |

## Response procedure

### 1. Detect and triage

- Monitoring (Sentry, Celery beat logs, health checks) triggers an alert.
- On-call engineer confirms the incident, assigns severity, and notifies the
  response team.

### 2. Contain

- **Outage**: restart affected containers via `docker compose restart <service>`.
  If recurring, scale the service and inspect logs.
- **Data breach**: immediately revoke compromised credentials, rotate
  `SECRET_KEY`, `MTN_MOMO_API_KEY`, and any exposed tokens. Disable public
  access if necessary.
- **Payment failure**: switch `PAYMENT_PROVIDER` to `dev` if the live provider
  is degraded; process pending payouts once the provider recovers.

### 3. Eradicate

- Identify root cause from logs (`backend/runserver.log`,
  `docker compose logs --tail=500`).
- Apply fix (code patch, config change, dependency update).

### 4. Recover

- Run `python manage.py migrate` if schema changes were involved.
- Execute `python manage.py retry_notifications` for any failed deliveries.
- Reconcile pending payments with `python manage.py run_reconciliation`.
- Monitor dashboards and Sentry for recurrence.

### 5. Communicate

- Internal stakeholders receive a status update within the target response
  window.
- Affected users are notified via in-app notification and email if PII or
  payments were impacted.

### 6. Post-mortem

- Document timeline, root cause, resolution, and preventive actions.
- Update `BACKUP_DISASTER_RECOVERY.md` if recovery steps changed.
- Schedule a follow-up within 7 days for P1/P2 incidents.

## Backup restoration (data loss scenario)

1. Pull the most recent backup from S3 or local `database/backups/`.
2. Restore to a staging instance, verify row counts and key records.
3. Promote to production via `pg_restore` / file copy.
4. Run `python manage.py migrate` if backup is older than the current schema.

## Payment reconciliation after failure

```bash
python manage.py run_payouts
python manage.py run_reconciliation
```

Review any entries flagged as `FAILED` in the Django admin and resolve manually
if provider-side investigation is needed.