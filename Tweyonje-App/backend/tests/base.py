"""Shared test fixtures for the Tweyonje backend test suite."""

import uuid

from django.contrib.auth import get_user_model

from apps.recycling.models import RecyclableMaterial
from apps.rewards.models import EcoWallet, RewardTier
from apps.waste_requests.models import WasteCategory
from core.models import Role, Zone

User = get_user_model()


class BaseTestDataMixin:
    """Creates zones, categories, tiers and the standard demo users."""

    def setUp(self):
        self.zone = Zone.objects.create(name="Kampala Central", code=f"KLA-C-{self._suffix()}", region="Kampala")
        self.category = WasteCategory.objects.create(
            name="Household Waste",
            slug="household",
            default_price_per_kg=500,
            base_eco_points=10,
        )
        self.tier = RewardTier.objects.create(
            name="Bronze",
            threshold_points=0,
            multiplier=1.0,
        )
        self.material = RecyclableMaterial.objects.create(
            name="PET Bottles",
            slug="pet-bottles",
        )

        self.resident = User.objects.create_user(
            email=f"resident_{self._suffix()}@tweyonje.ug",
            password="TestPassword123!",
            full_name="Resident Tester",
            role=Role.RESIDENT,
            email_verified=True,
        )
        self.resident_wallet = EcoWallet.objects.create(user=self.resident, current_tier=self.tier)

        self.collector = User.objects.create_user(
            email=f"collector_{self._suffix()}@tweyonje.ug",
            password="TestPassword123!",
            full_name="Collector Tester",
            role=Role.COLLECTOR,
            email_verified=True,
        )
        self.admin = User.objects.create_user(
            email=f"admin_{self._suffix()}@tweyonje.ug",
            password="TestPassword123!",
            full_name="Admin Tester",
            role=Role.ADMINISTRATOR,
            is_staff=True,
            email_verified=True,
        )
        self.other_resident = User.objects.create_user(
            email=f"other_{self._suffix()}@tweyonje.ug",
            password="TestPassword123!",
            full_name="Other Resident",
            role=Role.RESIDENT,
            email_verified=True,
        )

    @staticmethod
    def _suffix() -> str:
        return uuid.uuid4().hex[:8]


def make_waste_request(user, zone=None, category=None):
    from apps.waste_requests.models import WasteRequest

    if zone is None:
        zone = Zone.objects.create(
            name=f"Zone-{uuid.uuid4().hex[:6]}",
            code=f"Z-{uuid.uuid4().hex[:6]}",
            region="Kampala",
        )
    if category is None:
        category = WasteCategory.objects.create(
            name=f"Cat-{uuid.uuid4().hex[:6]}",
            slug=f"cat-{uuid.uuid4().hex[:6]}",
            default_price_per_kg=500,
            base_eco_points=10,
        )
    return WasteRequest.objects.create(
        user=user,
        category=category,
        zone=zone,
        estimated_weight_kg=10,
        pickup_address="Plot 1, Kampala Road",
        latitude=0.3476,
        longitude=32.5825,
        scheduled_date="2030-01-01",
        estimated_price=5000,
    )
