from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    AirtelWebhookView,
    InvoiceViewSet,
    MoMoWebhookView,
    PaymentSummaryView,
    PaymentViewSet,
    PayoutViewSet,
)

router = DefaultRouter()
router.register("invoices", InvoiceViewSet, basename="invoice")
router.register("payouts", PayoutViewSet, basename="payout")
router.register("", PaymentViewSet, basename="payment")

urlpatterns = [
    path("summary/", PaymentSummaryView.as_view(), name="payment-summary"),
    path("webhook/", MoMoWebhookView.as_view(), name="payment-webhook"),
    path("webhook/airtel/", AirtelWebhookView.as_view(), name="payment-webhook-airtel"),
    path("", include(router.urls)),
]
