"""Mobile-money provider clients.

Each client talks to the live provider REST API. Credentials come from
Django settings (environment variables); see ``.env.example``. When a
provider is not configured, callers fall back to dev simulation.
"""

from .airtel_money import AirtelMoneyClient
from .mtn_momo import MTNMoMoClient

__all__ = ["MTNMoMoClient", "AirtelMoneyClient"]
