from django.urls import path

from .views import (
    CurrentUserView,
    LoginView,
    LogoutView,
    PasswordResetConfirmView,
    PasswordResetRequestView,
    RefreshView,
    RegisterView,
    SendOTPView,
    VerifyOTPView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="auth-register"),
    path("login/", LoginView.as_view(), name="auth-login"),
    path("refresh/", RefreshView.as_view(), name="auth-refresh"),
    path("logout/", LogoutView.as_view(), name="auth-logout"),
    path("me/", CurrentUserView.as_view(), name="auth-me"),
    path("otp/send/", SendOTPView.as_view(), name="auth-otp-send"),
    path("otp/verify/", VerifyOTPView.as_view(), name="auth-otp-verify"),
    path("password-reset/", PasswordResetRequestView.as_view(), name="auth-password-reset-request"),
    path("password-reset/confirm/", PasswordResetConfirmView.as_view(), name="auth-password-reset-confirm"),
]

# Add GDPR data export endpoints
from .views_export import DataExportView, DataExportRequestView, DataExportStatusView

urlpatterns += [
    path("me/export/", DataExportView.as_view(), name="data-export"),
    path("me/export/request/", DataExportRequestView.as_view(), name="data-export-request"),
    path("me/export/status/<str:task_id>/", DataExportStatusView.as_view(), name="data-export-status"),
]
