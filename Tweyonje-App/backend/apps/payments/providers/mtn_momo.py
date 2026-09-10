"""MTN MoMo Collections API client (https://momodeveloper.mtn.com)."""

from __future__ import annotations

import logging
import uuid

import requests
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)

TOKEN_CACHE_KEY = "mtn_momo:access_token"
TOKEN_TTL_SECONDS = 60 * 4  # tokens are valid for ~5 minutes


class MTNMoMoError(RuntimeError):
    pass


class MTNMoMoClient:
    """Thin wrapper around the Collections product endpoints."""

    STATUS_MAP = {
        "SUCCESSFUL": "SUCCESSFUL",
        "PENDING": "PENDING",
        "FAILED": "FAILED",
    }

    def __init__(self):
        self.base_url = settings.MTN_MOMO_BASE_URL.rstrip("/")
        self.subscription_key = settings.MTN_MOMO_SUBSCRIPTION_KEY
        self.api_user = settings.MTN_MOMO_API_USER
        self.api_key = settings.MTN_MOMO_API_KEY
        self.target_env = settings.MTN_MOMO_TARGET_ENV
        if not all([self.subscription_key, self.api_user, self.api_key]):
            raise MTNMoMoError("MTN MoMo credentials are not configured.")

    @property
    def _session(self) -> requests.Session:
        session = requests.Session()
        session.headers.update(
            {
                "Ocp-Apim-Subscription-Key": self.subscription_key,
                "X-Target-Environment": self.target_env,
            }
        )
        return session

    def get_access_token(self) -> str:
        cached = cache.get(TOKEN_CACHE_KEY)
        if cached:
            return cached
        response = requests.post(
            f"{self.base_url}/collection/token/",
            auth=(self.api_user, self.api_key),
            headers={"Ocp-Apim-Subscription-Key": self.subscription_key},
            timeout=30,
        )
        if response.status_code != 200:
            logger.error("MTN token error %s: %s", response.status_code, response.text[:500])
            raise MTNMoMoError("Could not authenticate with MTN MoMo.")
        token = response.json()["access_token"]
        expires_in = int(response.json().get("expires_in", TOKEN_TTL_SECONDS))
        cache.set(TOKEN_CACHE_KEY, token, timeout=max(expires_in - 60, 30))
        return token

    def request_to_pay(
        self,
        amount,
        currency: str,
        payer_phone: str,
        external_id: str,
        payee_note: str = "",
        payer_message: str = "",
        callback_url: str | None = None,
    ) -> str:
        """Create a payment request. Returns the provider reference id."""
        headers = self._session.headers.copy()
        headers.update(
            {
                "Authorization": f"Bearer {self.get_access_token()}",
                "X-Reference-Id": str(uuid.uuid4()),
                "Content-Type": "application/json",
            }
        )
        if callback_url:
            headers["X-Callback-Url"] = callback_url
        payload = {
            "amount": str(amount),
            "currency": currency,
            "externalId": external_id,
            "payer": {"partyIdType": "MSISDN", "partyId": payer_phone},
            "payerMessage": payer_message or "Tweyonje waste collection fee",
            "payeeNote": payee_note or "Tweyonje",
        }
        response = requests.post(
            f"{self.base_url}/collection/v1_0/requesttopay/",
            json=payload,
            headers=headers,
            timeout=30,
        )
        # 202 Accepted means the request was queued by MTN.
        if response.status_code not in (200, 201, 202):
            logger.error("MTN requesttopay error %s: %s", response.status_code, response.text[:500])
            raise MTNMoMoError(f"MTN MoMo rejected the payment request ({response.status_code}).")
        return headers["X-Reference-Id"]

    def get_transaction_status(self, provider_reference: str) -> dict:
        headers = self._session.headers.copy()
        headers["Authorization"] = f"Bearer {self.get_access_token()}"
        response = requests.get(
            f"{self.base_url}/collection/v1_0/requesttopay/{provider_reference}",
            headers=headers,
            timeout=30,
        )
        if response.status_code != 200:
            logger.error("MTN status error %s: %s", response.status_code, response.text[:500])
            raise MTNMoMoError("Could not fetch transaction status from MTN MoMo.")
        data = response.json()
        return {
            "raw_status": data.get("status", "PENDING"),
            "status": self.STATUS_MAP.get(data.get("status", "PENDING"), "PENDING"),
            "transaction_id": data.get("financialTransactionId") or "",
            "amount": data.get("amount"),
            "currency": data.get("currency"),
            "reason": data.get("reason") or None,
        }
