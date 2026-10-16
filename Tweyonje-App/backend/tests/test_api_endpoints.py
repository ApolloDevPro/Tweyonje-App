from django.conf import settings
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Role, Zone
from apps.waste_requests.models import WasteCategory, WasteRequest
from apps.rewards.models import RewardTier, EcoWallet
from apps.recycling.models import RecyclableMaterial
from apps.notifications.models import NotificationDevice

User = get_user_model()


class TweyonjeAPITestCase(APITestCase):
    def setUp(self):
        # Create base test data
        self.zone = Zone.objects.create(name="Kampala Central", code="KLA-C", region="Kampala")
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

        # Create demo resident
        self.resident = User.objects.create_user(
            email="resident_test@tweyonje.ug",
            password="TestPassword123!",
            full_name="Resident Tester",
            role=Role.RESIDENT,
            email_verified=True,
        )
        self.resident_wallet = EcoWallet.objects.create(user=self.resident, current_tier=self.tier)

        # Create demo collector
        self.collector = User.objects.create_user(
            email="collector_test@tweyonje.ug",
            password="TestPassword123!",
            full_name="Collector Tester",
            role=Role.COLLECTOR,
            email_verified=True,
        )

        # Create demo admin
        self.admin = User.objects.create_user(
            email="admin_test@tweyonje.ug",
            password="TestPassword123!",
            full_name="Admin Tester",
            role=Role.ADMINISTRATOR,
            is_staff=True,
            email_verified=True,
        )

    def test_health_check(self):
        url = reverse("health")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json().get("status"), "ok")

    def test_auth_register_and_login(self):
        self.assertNotIn("core.middleware.SupabaseAuthMiddleware", settings.MIDDLEWARE)

        # Register
        register_url = "/api/v1/auth/register/"
        data = {
            "email": "newuser@tweyonje.ug",
            "password": "Password1234!",
            "full_name": "New Resident",
            "role": "RESIDENT",
        }
        resp = self.client.post(register_url, data)
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertIn("user", resp.data)

        # Login
        login_url = "/api/v1/auth/login/"
        login_data = {
            "email": "newuser@tweyonje.ug",
            "password": "Password1234!",
        }
        login_resp = self.client.post(login_url, login_data)
        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
        self.assertIn("access", login_resp.data)
        self.assertIn("refresh", login_resp.data)

        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {login_resp.data['access']}"
        )
        me_resp = self.client.get("/api/v1/auth/me/")
        self.assertEqual(me_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(me_resp.data["email"], "newuser@tweyonje.ug")

        requests_resp = self.client.get("/api/v1/waste-requests/")
        self.assertEqual(requests_resp.status_code, status.HTTP_200_OK)

    def test_profile_endpoints(self):
        self.client.force_authenticate(user=self.resident)
        profile_url = "/api/v1/profiles/me/"
        response = self.client.get(profile_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data.get("user", {}).get("email"), self.resident.email)

    def test_waste_category_and_request_creation(self):
        self.client.force_authenticate(user=self.resident)

        # List categories
        cat_resp = self.client.get("/api/v1/waste-requests/categories/")
        self.assertEqual(cat_resp.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(cat_resp.data), 1)

        # Create waste request
        req_data = {
            "category": str(self.category.id),
            "estimated_weight_kg": 15.5,
            "estimated_price": 1,
            "pickup_address": "Plot 12 Kampala Rd",
            "latitude": 0.3136,
            "longitude": 32.5811,
            "scheduled_date": (timezone.localdate() + timezone.timedelta(days=1)).isoformat(),
            "scheduled_time_slot": "09:00 - 11:00",
            "special_instructions": "Please ring bell",
        }
        create_resp = self.client.post("/api/v1/waste-requests/", req_data)
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(create_resp.data.get("status"), "PENDING")
        self.assertEqual(str(create_resp.data.get("estimated_price")), "7750.00")

    def test_waste_request_rejects_a_pickup_date_in_the_past(self):
        self.client.force_authenticate(user=self.resident)
        response = self.client.post(
            "/api/v1/waste-requests/",
            {
                "category": str(self.category.id),
                "estimated_weight_kg": 2,
                "pickup_address": "Plot 12 Kampala Rd",
                "scheduled_date": (timezone.localdate() - timezone.timedelta(days=1)).isoformat(),
            },
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("scheduled_date", response.data)

    def test_push_device_registration_is_idempotent_and_can_be_disabled(self):
        self.client.force_authenticate(user=self.resident)
        url = "/api/v1/notifications/register_device/"
        payload = {"token": "fcm-test-token", "device_type": "mobile"}

        first_response = self.client.post(url, payload)
        second_response = self.client.post(url, payload)

        self.assertEqual(first_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(second_response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            NotificationDevice.objects.filter(user=self.resident, token="fcm-test-token").count(),
            1,
        )

        disable_response = self.client.post(
            "/api/v1/notifications/unregister_device/",
            {"token": "fcm-test-token"},
        )

        self.assertEqual(disable_response.status_code, status.HTTP_200_OK)
        self.assertFalse(
            NotificationDevice.objects.get(user=self.resident, token="fcm-test-token").is_active
        )

    def test_collector_flow(self):
        # Create request by resident
        waste_req = WasteRequest.objects.create(
            user=self.resident,
            category=self.category,
            estimated_weight_kg=10,
            pickup_address="Jinja Road",
            latitude=0.3200,
            longitude=32.5900,
            zone=self.zone,
            scheduled_date="2026-08-20",
        )

        # Authenticate collector
        self.client.force_authenticate(user=self.collector)

        # View collector tasks / dashboard
        dash_resp = self.client.get("/api/v1/collections/dashboard/")
        self.assertEqual(dash_resp.status_code, status.HTTP_200_OK)

    def test_rewards_and_wallet(self):
        self.client.force_authenticate(user=self.resident)
        wallet_resp = self.client.get("/api/v1/rewards/wallet/")
        self.assertEqual(wallet_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(wallet_resp.data.get("current_points"), 0)

        # Check tiers list
        tiers_resp = self.client.get("/api/v1/rewards/tiers/")
        self.assertEqual(tiers_resp.status_code, status.HTTP_200_OK)

    def test_recycling_materials(self):
        RecyclableMaterial.objects.create(
            name="PET Plastic",
            slug="pet-plastic",
            material_type="PLASTIC",
            price_per_kg=400,
        )
        self.client.force_authenticate(user=self.resident)
        resp = self.client.get("/api/v1/recycling/materials/")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertGreaterEqual(len(resp.data), 1)

    def test_support_ticket_creation(self):
        self.client.force_authenticate(user=self.resident)
        data = {
            "subject": "Delay in pickup",
            "description": "My waste was not collected on time.",
            "category": "COLLECTION_ISSUE",
            "priority": "MEDIUM",
        }
        resp = self.client.post("/api/v1/support/tickets/", data)
        self.assertEqual(resp.status_code, status.HTTP_201_CREATED)
        self.assertEqual(resp.data.get("subject"), "Delay in pickup")

    def test_ai_classification(self):
        self.client.force_authenticate(user=self.resident)
        # Mock file classification request
        from django.core.files.uploadedfile import SimpleUploadedFile
        test_file = SimpleUploadedFile("test_waste.jpg", b"mock_image_bytes", content_type="image/jpeg")
        resp = self.client.post("/api/v1/ai/classify-waste/", {"image": test_file}, format="multipart")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertIn("category", resp.data["prediction"])
        self.assertIn("confidence", resp.data["prediction"])

    def test_localization_strings(self):
        resp = self.client.get("/api/v1/localization/translations/")
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
