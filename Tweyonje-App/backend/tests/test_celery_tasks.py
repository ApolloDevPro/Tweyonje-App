import uuid
from unittest import mock

from django.test import TransactionTestCase

from core import tasks
from .base import BaseTestDataMixin, make_waste_request


class CeleryTaskTests(BaseTestDataMixin, TransactionTestCase):
    def test_process_due_schedules_task_runs(self):
        result = tasks.process_due_schedules()
        self.assertEqual(result, "ok")

    def test_retry_notifications_task_runs(self):
        result = tasks.retry_notifications()
        self.assertEqual(result, "ok")

    def test_poll_payment_status_skips_non_pending(self):
        payment = self._make_successful_payment()
        with mock.patch("apps.payments.services.sync_payment_status") as spy:
            result = tasks.poll_payment_status(str(payment.id))
        spy.assert_not_called()
        self.assertEqual(result, "skipped")

    def test_poll_payment_status_syncs_pending(self):
        payment = self._make_pending_payment()
        with mock.patch("apps.payments.services.sync_payment_status", side_effect=lambda p: p) as spy:
            result = tasks.poll_payment_status(str(payment.id))
        spy.assert_called_once()
        self.assertEqual(result, "PENDING")

    # ------------------------------------------------------------------
    def _make_pending_payment(self):
        from apps.payments.models import Payment

        return Payment.objects.create(
            user=self.resident,
            waste_request=make_waste_request(self.resident),
            amount=5000,
            provider_reference=f"CEL-PEND-{uuid.uuid4().hex[:8]}",
        )

    def _make_successful_payment(self):
        from apps.payments.models import Payment

        return Payment.objects.create(
            user=self.resident,
            waste_request=make_waste_request(self.resident),
            amount=5000,
            status=Payment.Status.SUCCESSFUL,
        )
