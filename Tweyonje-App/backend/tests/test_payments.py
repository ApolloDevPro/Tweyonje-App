import hashlib
import hmac
import json
from unittest import mock

from django.contrib.auth import get_user_model
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from apps.waste_requests.models import WasteCategory, WasteRequest
from core.models import Role
from .base import BaseTestDataMixin, make_waste_request

User = get_user_model()


class PaymentFlowTests(BaseTestDataMixin, APITestCase):
    def _create_request(self):
        return make_waste_request(self.resident)

    def test_dev_provider_marks_payment_successful_and_creates_invoice(self):
        from apps.payments.models import Invoice, Payment
        from apps.payments.services import initiate_momo_payment

        waste_req = self._create_request()
        payment = initiate_momo_payment(
            user=self.resident,
            waste_request=waste_req,
            phone="+256700000001",
        )
        self.assertEqual(payment.status, Payment.Status.SUCCESSFUL)
        self.assertTrue(Invoice.objects.filter(payment=payment).exists())
        waste_req.refresh_from_db()
        self.assertEqual(waste_req.payment_status, WasteRequest.PaymentStatus.PAID)

    @override_settings(PAYMENT_PROVIDER="mtn", MTN_MOMO_SUBSCRIPTION_KEY="k", MTN_MOMO_API_USER="u", MTN_MOMO_API_KEY="s")
    def test_sync_payment_status_finalizes_successful_payment(self):
        from apps.payments.models import Invoice, Payment
        from apps.payments.services import initiate_momo_payment, sync_payment_status

        waste_req = self._create_request()
        with mock.patch("config.celery.app.send_task"):
            with mock.patch(
                "apps.payments.providers.mtn_momo.MTNMoMoClient.request_to_pay",
                return_value="PROVIDER-REF-1",
            ):
                payment = initiate_momo_payment(user=self.resident, waste_request=waste_req, phone="+256700000002")
        self.assertEqual(payment.status, Payment.Status.PENDING)
        self.assertEqual(payment.provider_reference, "PROVIDER-REF-1")

        fake_client = mock.Mock()
        fake_client.get_transaction_status.return_value = {
            "raw_status": "SUCCESSFUL",
            "status": "SUCCESSFUL",
            "transaction_id": "FT2024XYZ",
            "amount": "5000",
            "currency": "UGX",
            "reason": None,
        }
        with mock.patch(
            "apps.payments.providers.mtn_momo.MTNMoMoClient", return_value=fake_client
        ):
            updated = sync_payment_status(payment)

        self.assertEqual(updated.status, Payment.Status.SUCCESSFUL)
        self.assertEqual(updated.transaction_id, "FT2024XYZ")
        self.assertTrue(Invoice.objects.filter(payment=updated).exists())

    @override_settings(PAYMENT_PROVIDER="mtn", MTN_MOMO_SUBSCRIPTION_KEY="k", MTN_MOMO_API_USER="u", MTN_MOMO_API_KEY="s")
    def test_sync_payment_status_marks_failed(self):
        from apps.payments.models import Payment
        from apps.payments.services import initiate_momo_payment, sync_payment_status

        waste_req = self._create_request()
        with mock.patch("config.celery.app.send_task"):
            with mock.patch(
                "apps.payments.providers.mtn_momo.MTNMoMoClient.request_to_pay",
                return_value="PROVIDER-REF-2",
            ):
                payment = initiate_momo_payment(user=self.resident, waste_request=waste_req, phone="+256700000003")

        fake_client = mock.Mock()
        fake_client.get_transaction_status.return_value = {
            "raw_status": "FAILED",
            "status": "FAILED",
            "transaction_id": "",
            "amount": None,
            "currency": None,
            "reason": "Payer rejected",
        }
        with mock.patch("apps.payments.providers.mtn_momo.MTNMoMoClient", return_value=fake_client):
            updated = sync_payment_status(payment)

        self.assertEqual(updated.status, Payment.Status.FAILED)


@override_settings(MTN_MOMO_CALLBACK_TOKEN="test-momo-callback-token")
class MoMoWebhookTests(BaseTestDataMixin, APITestCase):
    def setUp(self):
        super().setUp()
        from apps.payments.models import Payment

        self.payment = Payment.objects.create(
            user=self.resident,
            amount=5000,
            method=Payment.Method.MTN_MOMO,
            phone_number="+256700000009",
            provider_reference="MOMO-TESTREF01",
        )

    def test_webhook_marks_payment_successful(self):
        from apps.payments.models import Invoice, Payment

        url = reverse("payment-webhook") + "?token=test-momo-callback-token"
        response = self.client.post(
            url,
            data=json.dumps({"referenceId": "MOMO-TESTREF01", "status": "SUCCESSFUL", "financialTransactionId": "FT99"}),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["matched"])
        self.payment.refresh_from_db()
        self.assertEqual(self.payment.status, Payment.Status.SUCCESSFUL)
        self.assertTrue(Invoice.objects.filter(payment=self.payment).exists())

    def test_webhook_marks_payment_failed(self):
        from apps.payments.models import Payment

        response = self.client.post(
            reverse("payment-webhook") + "?token=test-momo-callback-token",
            data=json.dumps({"referenceId": "MOMO-TESTREF01", "status": "FAILED"}),
            content_type="application/json",
        )
        self.payment.refresh_from_db()
        self.assertEqual(self.payment.status, Payment.Status.FAILED)

    def test_webhook_unknown_reference_is_accepted_but_unmatched(self):
        response = self.client.post(
            reverse("payment-webhook") + "?token=test-momo-callback-token",
            data=json.dumps({"referenceId": "UNKNOWN-REF", "status": "SUCCESSFUL"}),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data["matched"])

    def test_webhook_requires_reference(self):
        response = self.client.post(
            reverse("payment-webhook") + "?token=test-momo-callback-token",
            data=json.dumps({}),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)


class AirtelWebhookTests(BaseTestDataMixin, APITestCase):
    CALLBACK_KEY = "airtel-test-callback-key"

    @override_settings(AIRTEL_CALLBACK_KEY=CALLBACK_KEY)
    def test_signed_callback_is_verified_and_applied(self):
        from apps.payments.models import Invoice, Payment

        payment = Payment.objects.create(
            user=self.resident,
            amount=3000,
            method=Payment.Method.AIRTEL_MONEY,
            phone_number="+256700000010",
            provider_reference="AIRTEL-TXN-77",
        )
        payload = {"transaction": {"id": "AIRTEL-TXN-77", "status_code": "TS"}, "status": {"code": "200"}}
        raw = json.dumps(payload).encode()
        signature = hmac.new(self.CALLBACK_KEY.encode(), raw, hashlib.sha256).hexdigest()

        response = self.client.post(
            reverse("payment-webhook-airtel"),
            data=raw,
            content_type="application/json",
            HTTP_X_SIGNATURE=signature,
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["matched"])
        payment.refresh_from_db()
        self.assertEqual(payment.status, Payment.Status.SUCCESSFUL)
        self.assertTrue(Invoice.objects.filter(payment=payment).exists())

    @override_settings(AIRTEL_CALLBACK_KEY=CALLBACK_KEY)
    def test_bad_signature_rejected(self):
        payload = {"transaction": {"id": "X", "status_code": "TS"}}
        response = self.client.post(
            reverse("payment-webhook-airtel"),
            data=json.dumps(payload),
            content_type="application/json",
            HTTP_X_SIGNATURE="deadbeef",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
