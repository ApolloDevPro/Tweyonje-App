import logging
import requests
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags

from .models import Notification

logger = logging.getLogger(__name__)


def _send_sms_twilio(recipient_phone, message):
    """Twilio Programmable Messaging REST API."""
    response = requests.post(
        f"https://api.twilio.com/2010-04-01/Accounts/{settings.TWILIO_ACCOUNT_SID}/Messages.json",
        data={
            "To": recipient_phone,
            "From": settings.TWILIO_FROM_NUMBER,
            "Body": message,
        },
        auth=(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN),
        timeout=30,
    )
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Twilio SMS failed ({response.status_code}): {response.text[:300]}")
    return True


def _send_sms_africastalking(recipient_phone, message):
    """Africa's Talking SMS API (popular East Africa gateway)."""
    response = requests.post(
        "https://api.africastalking.com/version1/messaging",
        headers={
            "apiKey": settings.AFRICASTALK_API_KEY,
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json",
        },
        data={
            "username": settings.AFRICASTALK_USERNAME,
            "to": recipient_phone,
            "message": message,
        },
        timeout=30,
    )
    if response.status_code not in (200, 201):
        raise RuntimeError(f"Africa's Talking SMS failed ({response.status_code}): {response.text[:300]}")
    return True


def send_sms(recipient_phone, message):
    """
    Sends SMS via the configured provider.

    Providers:
      - "twilio": Twilio REST API
      - "africastalk": Africa's Talking REST API
      - anything else ("dev"): log only (development / unconfigured)
    """
    provider = getattr(settings, "SMS_PROVIDER", "dev")
    logger.info(f"[SMS Provider: {provider}] Sending to {recipient_phone}: {message}")

    if provider == "twilio":
        if not all([settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN, settings.TWILIO_FROM_NUMBER]):
            logger.warning("Twilio selected but credentials incomplete; SMS skipped.")
            return False
        return _send_sms_twilio(recipient_phone, message)

    if provider == "africastalk":
        if not all([settings.AFRICASTALK_USERNAME, settings.AFRICASTALK_API_KEY]):
            logger.warning("Africa's Talking selected but credentials incomplete; SMS skipped.")
            return False
        return _send_sms_africastalking(recipient_phone, message)

    # In development/test or if live credentials are not set, it succeeds as mock
    return True


def send_push_notification(user, title, message, data=None):
    """
    Dispatches a push notification via Firebase Cloud Messaging.

    Uses the firebase-admin SDK when a service account JSON is available
    (set GOOGLE_APPLICATION_CREDENTIALS or FCM_CREDENTIALS_PATH); otherwise
    logs in development.
    """
    import os

    creds_path = getattr(settings, "FCM_CREDENTIALS_PATH", "") or os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
    device_token = (data or {}).get("device_token") or getattr(user, "fcm_token", None)
    if creds_path and device_token:
        try:
            import firebase_admin
            from firebase_admin import credentials, messaging

            if not firebase_admin._apps:
                firebase_admin.initialize_app(credentials.Certificate(creds_path))
            messaging.send(
                messaging.Message(
                    token=device_token,
                    notification=messaging.Notification(title=title, body=message),
                    data={k: str(v) for k, v in (data or {}).items() if k != "device_token"},
                )
            )
            return True
        except Exception as exc:
            logger.error(f"FCM dispatch failed for user {user.email}: {exc}")
            return False

    logger.info(f"[Push FCM] Dispatched to user {user.email}: {title} - {message}")
    return True


def send_notification(recipient, title, message, channel=Notification.Channel.IN_APP, metadata=None):
    """
    Creates and dispatches a notification record, respecting user preferences.
    """
    notif = Notification.objects.create(
        recipient=recipient,
        title=title,
        message=message,
        channel=channel,
        status=Notification.Status.PENDING,
        metadata=metadata or {},
    )

    try:
        if channel == Notification.Channel.SMS:
            if recipient.phone:
                send_sms(recipient.phone, f"{title}: {message}")
                notif.status = Notification.Status.SENT
            else:
                # Fallback to email if phone is missing
                if recipient.email and getattr(settings, "EMAIL_HOST", ""):
                    _send_html_email(
                        recipient=recipient,
                        subject=title,
                        template_name="emails/notification_generic.html",
                        context={"title": title, "message": message}
                    )
                notif.status = Notification.Status.SENT
        elif channel == Notification.Channel.EMAIL:
            if recipient.email and getattr(settings, "EMAIL_HOST", ""):
                _send_html_email(
                    recipient=recipient,
                    subject=title,
                    template_name="emails/notification_generic.html",
                    context={"title": title, "message": message}
                )
            notif.status = Notification.Status.SENT
        elif channel == Notification.Channel.PUSH:
            send_push_notification(recipient, title, message, data=metadata)
            notif.status = Notification.Status.SENT
        else:
            # In-app notification
            notif.status = Notification.Status.SENT

    except Exception as exc:
        logger.error(f"Error dispatching notification {notif.id}: {exc}")
        notif.status = Notification.Status.FAILED
        notif.failure_reason = str(exc)

    notif.save(update_fields=["status", "failure_reason"])
    return notif


def _send_html_email(recipient, subject, template_name, context):
    """Send HTML email using Django templates."""
    context.update({
        'recipient_email': recipient.email,
        'user_name': recipient.full_name or recipient.email,
        'app_url': getattr(settings, 'FRONTEND_URL', 'https://tweyonje.ug'),
        'unsubscribe_url': f"{getattr(settings, 'FRONTEND_URL', 'https://tweyonje.ug')}/unsubscribe?email={recipient.email}",
    })
    
    html_message = render_to_string(template_name, context)
    plain_message = strip_tags(html_message)
    
    send_mail(
        subject,
        plain_message,
        settings.DEFAULT_FROM_EMAIL,
        [recipient.email],
        html_message=html_message,
        fail_silently=False,
    )


def retry_failed_notifications(max_retries=3):
    failed_notifs = Notification.objects.filter(
        status=Notification.Status.FAILED,
        retry_count__lt=max_retries,
    )
    retried_count = 0
    for notif in failed_notifs:
        notif.retry_count += 1
        try:
            if notif.channel == Notification.Channel.SMS and notif.recipient.phone:
                send_sms(notif.recipient.phone, f"{notif.title}: {notif.message}")
            elif notif.channel == Notification.Channel.EMAIL and notif.recipient.email:
                send_mail(
                    notif.title,
                    notif.message,
                    settings.DEFAULT_FROM_EMAIL,
                    [notif.recipient.email],
                    fail_silently=True,
                )
            notif.status = Notification.Status.SENT
            notif.failure_reason = ""
            retried_count += 1
        except Exception as exc:
            notif.failure_reason = str(exc)
        notif.save(update_fields=["status", "retry_count", "failure_reason"])

    return retried_count
