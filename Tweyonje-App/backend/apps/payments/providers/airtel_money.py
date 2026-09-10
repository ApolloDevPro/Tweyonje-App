"""Airtel Money API client (https://developers.airtel.africa)."""

from __future__ import annotations

import hashlib
import hmac
import json
import logging

import requests
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)

TOKEN_CACHE_KEY = "airtel:access_token"


class AirtelMoneyError(RuntimeError):
    pass


class AirtelMoneyClient:
    STATUS_MAP = {
        "TS": "SUCCESSFUL",  # Transaction Successful
        "TF": "FAILED",  # Transaction Failed
        "TA": "PENDING",  # Transaction Ambiguous
        "TIP": "PENDING",  # Transaction In Progress
    }

    def __init__(self):
        self.base_url = settings.AIRTEL_BASE_URL.rstrip("/")
        self.client_id = settings.AIRTEL_CLIENT_ID
        self.client_secret = settings.AIRTEL_CLIENT_SECRET
        if not all([self.client_id, self.client_secret]):
            raise AirtelMoneyError("Airtel Money credentials are not configured.")

    def get_access_token(self) -> str:
        cached = cache.get(TOKEN_CACHE_KEY)
        if cached:
            return cached
        response = requests.post(
            f"{self.base_url}/auth/oauth2/token",
            json={"client_id": self.client_id, "client_secret": self.client_secret, "grant_type": "client_credentials"},
            headers={"Content-Type": "application/json", "Accept": "*/*"},
            timeout=30,
        )
        if response.status_code != 200:
            logger.error("Airtel token error %s: %s", response.status_code, response.text[:500])
            raise AirtelMoneyError("Could not authenticate with Airtel Money.")
        data = response.json()
        token = data["access_token"]
        expires_in = int(data.get("expires_in", 3600))
        cache.set(TOKEN_CACHE_KEY, token, timeout=max(expires_in - 60, 60))
        return token

    def initiate_collection(
        self,
        amount,
        currency: str,
        payer_phone: str,
        external_id: str,
        country: str = "UG",
    ) -> dict:
        """Request a collection (push prompt to the payer)."""
        payload = {
            "reference": f"Tweyonje payment {external_id}",
            "subscriber": {
                "country": country,
                "currency": currency,
                "msisdn": payer_phone,
            },
            "transaction": {"amount": str(amount), "country": country, "currency": currency, "id": external_id},
        }
        response = requests.post(
            f"{self.base_url}/merchant/v1/payments/",
            json=payload,
            headers={
                "Authorization": f"Bearer {self.get_access_token()}",
                "Content-Type": "application/json",
                "Accept": "*/*",
                "X-Country": country,
                "X-Currency": currency,
            },
            timeout=30,
        )
        if response.status_code not in (200, 201):
            logger.error("Airtel payments error %s: %s", response.status_code, response.text[:500])
            raise AirtelMoneyError(f"Airtel Money rejected the payment request ({response.status_code}).")
        return self.parse_transaction(response.json())

    def get_transaction_status(self, transaction_id: str) -> dict:
        response = requests.get(
            f"{self.base_url}/standard/v1/payments/{transaction_id}",
            headers={
                "Authorization": f"Bearer {self.get_access_token()}",
                "Accept": "*/*",
                "X-Country": "UG",
            },
            timeout=30,
        )
        if response.status_code != 200:
            logger.error("Airtel status error %s: %s", response.status_code, response.text[:500])
            raise AirtelMoneyError("Could not fetch transaction status from Airtel Money.")
        return self.parse_transaction(response.json())

    @staticmethod
    def parse_transaction(payload: dict) -> dict:
        data = payload.get("data", {})
        txn = data.get("transaction", [])
        # The API nests transaction details inconsistently; normalise both shapes.
        if isinstance(txn, list):
            txn = txn[0] if txn else {}
        status_code = txn.get("status_code") or payload.get("status", {}).get("code") or ""
        message = txn.get("message") or payload.get("status", {}).get("message") or ""
        mapped = AirtelMoneyClient.STATUS_MAP.get(status_code, "PENDING")
        return {
            "raw_status": status_code or message or "PENDING",
            "status": mapped,
            "transaction_id": str(txn.get("id") or txn.get("airtel_money_id") or ""),
            "amount": txn.get("amount"),
            "currency": None,
            "reason": message or None,
        }

    @staticmethod
    def verify_webhook_signature(raw_body: bytes, signature: str) -> bool:
        """Validate the X-Signature header (HMAC-SHA256 of the raw body)."""
        callback_key = getattr(settings, "AIRTEL_CALLBACK_KEY", "")
        if not callback_key or not signature:
            return False
        expected = hmac.new(callback_key.encode(), raw_body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature)
