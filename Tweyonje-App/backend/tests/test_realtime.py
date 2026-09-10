import uuid

from asgiref.sync import async_to_sync, sync_to_async
from channels.testing import WebsocketCommunicator
from django.test import TransactionTestCase
from rest_framework_simplejwt.tokens import RefreshToken

from config.asgi import application
from core import realtime


class WebSocketSubscriberTests(TransactionTestCase):
    """End-to-end tests for ws://.../ws/ subscription flows."""

    def _comm(self, user):
        token = str(RefreshToken.for_user(user).access_token)
        return WebsocketCommunicator(application, f"/ws/?token={token}")

    def test_connect_requires_valid_token(self):
        resident = self._make_resident()
        request = self._make_request(resident)
        comm = self._comm(resident)
        unauth = WebsocketCommunicator(application, "/ws/")

        async def scenario():
            connected, code = await unauth.connect()
            self.assertFalse(connected)
            self.assertEqual(code, 4401)
            await unauth.disconnect()

            connected, _ = await comm.connect()
            self.assertTrue(connected)
            hello = await comm.receive_json_from()
            self.assertEqual(hello["type"], "connected")

            await comm.send_json_to({"type": "subscribe", "data": {"type": "collection", "id": str(request.id)}})
            ack = await comm.receive_json_from()
            self.assertEqual(ack["type"], "subscribed")

            await sync_to_async(realtime.notify_request_update)(request)
            event = await comm.receive_json_from(timeout=5)
            self.assertEqual(event["type"], "collection_update")
            self.assertEqual(event["data"]["request_id"], str(request.id))

            await comm.send_json_to({"type": "unsubscribe", "data": {"type": "collection", "id": str(request.id)}})
            bye = await comm.receive_json_from(timeout=5)
            self.assertEqual(bye["type"], "unsubscribed")

            await comm.disconnect()

        async_to_sync(scenario)()

    def test_subscribe_denied_for_foreign_resources(self):
        owner = self._make_resident(email_prefix="owner")
        intruder = self._make_resident(email_prefix="intruder")
        request = self._make_request(owner)
        comm = self._comm(intruder)

        async def scenario():
            await comm.connect()
            await comm.receive_json_from()  # connected

            await comm.send_json_to({"type": "subscribe", "data": {"type": "collection", "id": str(request.id)}})
            reply = await comm.receive_json_from(timeout=5)
            self.assertEqual(reply["type"], "error")
            self.assertIn("access", reply["data"]["detail"])

            await comm.send_json_to({"type": "subscribe", "data": {"type": "bogus", "id": "1"}})
            reply = await comm.receive_json_from(timeout=5)
            self.assertEqual(reply["type"], "error")

            await comm.disconnect()

        async_to_sync(scenario)()

    def test_payment_stream_broadcasts_updates(self):
        from apps.payments.models import Payment

        payer = self._make_resident(email_prefix="payer")
        payment = Payment.objects.create(
            user=payer,
            amount=1000,
            provider_reference=f"WS-PAY-{uuid.uuid4().hex[:8]}",
        )
        comm = self._comm(payer)

        async def scenario():
            await comm.connect()
            await comm.receive_json_from()  # connected

            await comm.send_json_to({"type": "subscribe", "data": {"type": "payment", "id": str(payment.id)}})
            ack = await comm.receive_json_from()
            self.assertEqual(ack["type"], "subscribed")

            # Drain the create-time broadcast (if any), then trigger another update.
            await sync_to_async(_mark_failed)(payment)

            saw_update = False
            for _ in range(3):
                message = await comm.receive_json_from(timeout=5)
                if message["type"] == "payment_update" and message["data"]["status"] == Payment.Status.FAILED:
                    saw_update = True
                    break
                if message["type"] == "payment_update":
                    continue
            self.assertTrue(saw_update)

            await comm.disconnect()

        async_to_sync(scenario)()

    # ------------------------------------------------------------------
    def _make_resident(self, email_prefix="resident"):
        from django.contrib.auth import get_user_model
        from core.models import Role

        User = get_user_model()
        return User.objects.create_user(
            email=f"{email_prefix}_{uuid.uuid4().hex[:8]}@tweyonje.ug",
            password="TestPassword123!",
            full_name="WS Tester",
            role=Role.RESIDENT,
            email_verified=True,
        )

    def _make_request(self, user):
        from tests.base import make_waste_request

        return make_waste_request(user)


def _mark_failed(payment):
    from apps.payments.models import Payment

    payment.status = Payment.Status.FAILED
    payment.save(update_fields=["status", "updated_at"])
