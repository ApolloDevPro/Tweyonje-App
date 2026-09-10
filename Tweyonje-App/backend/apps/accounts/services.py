from django.utils import timezone
from django.conf import settings
from django.core.mail import send_mail

from .models import OTPVerification, generate_otp_code, hash_otp_code


def send_otp(identifier, purpose=OTPVerification.Purpose.PHONE_VERIFY, user=None):
    # Invalidate previous unverified OTPs for this identifier/purpose
    OTPVerification.objects.filter(
        identifier=identifier,
        purpose=purpose,
        is_verified=False,
    ).delete()

    # Generate the plaintext once, deliver it, and store only its hash.
    plaintext_code = generate_otp_code()
    otp_record = OTPVerification.objects.create(
        user=user,
        identifier=identifier,
        otp_code=hash_otp_code(plaintext_code),
        purpose=purpose,
    )
    # Transient (never persisted) handle so development tooling can echo the
    # code without re-reading it from the database.
    otp_record.plaintext_code = plaintext_code

    # Dispatch via Email or SMS depending on format
    if "@" in identifier:
        if getattr(settings, "EMAIL_HOST", ""):
            send_mail(
                "Tweyonje Verification Code",
                f"Your Tweyonje verification code is: {plaintext_code}. Valid for 10 minutes.",
                settings.DEFAULT_FROM_EMAIL,
                [identifier],
                fail_silently=True,
            )
    else:
        # SMS dispatch hook (MTN / Airtel / Dev console)
        from apps.notifications.services import send_sms
        send_sms(
            recipient_phone=identifier,
            message=f"Your Tweyonje verification code is: {plaintext_code}. Valid for 10 minutes.",
        )

    return otp_record


def get_otp_plaintext(otp_record) -> str | None:
    """Return the transient plaintext OTP, if still available (dev only)."""
    return getattr(otp_record, "plaintext_code", None)


def verify_otp(identifier, code, purpose=None):
    query = OTPVerification.objects.filter(
        identifier=identifier,
        is_verified=False,
    )
    if purpose:
        query = query.filter(purpose=purpose)

    otp_record = query.order_by("-created_at").first()
    if not otp_record:
        return False, "No OTP request found for this identifier."

    if not otp_record.is_valid():
        return False, "OTP has expired or exceeded max attempts."

    otp_record.attempts += 1
    if not otp_record.check_code(code):
        otp_record.save(update_fields=["attempts"])
        return False, "Invalid OTP code."

    otp_record.is_verified = True
    otp_record.save(update_fields=["is_verified", "attempts"])

    if otp_record.user:
        if "@" in identifier:
            otp_record.user.email_verified = True
            otp_record.user.save(update_fields=["email_verified"])
        else:
            otp_record.user.phone_verified = True
            otp_record.user.save(update_fields=["phone_verified"])

    return True, "OTP verified successfully."
