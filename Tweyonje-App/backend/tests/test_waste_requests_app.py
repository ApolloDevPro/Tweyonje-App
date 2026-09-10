from django.urls import reverse
from rest_framework.test import APITestCase

from core.models import User, Role
from apps.waste_requests.models import WasteRequest, WasteCategory


class TestWasteRequestsAPI(APITestCase):
    """Test suite for waste request endpoints"""

    def setUp(self):
        self.user_data = {
            'email': 'test@example.com',
            'password': 'TestPassword123!',
            'full_name': 'Test User',
            'role': Role.RESIDENT,
        }
        self.user = User.objects.create_user(**self.user_data)

        # Create waste category
        self.category = WasteCategory.objects.create(
            name='Plastic',
            slug='plastic',
            description='Plastic waste',
            is_hazardous=False,
            default_price_per_kg=500.0,
            base_eco_points=10,
        )

    def authenticate(self):
        url = reverse('auth-login')
        response = self.client.post(url, {
            'email': self.user_data['email'],
            'password': self.user_data['password'],
        }, format='json')
        access_token = response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

    def test_create_waste_request_success(self):
        """Test successful waste request creation"""
        self.authenticate()

        request_url = reverse('waste-request-list')
        request_data = {
            'pickup_address': '123 Test Street, Kampala',
            'latitude': 0.3476,
            'longitude': 32.5825,
            'estimated_weight_kg': 5.0,
            'category': str(self.category.id),
            'special_instructions': 'Gate code: 1234',
        }

        response = self.client.post(request_url, request_data, format='json')

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['pickup_address'], request_data['pickup_address'])
        self.assertEqual(response.data['status'], 'PENDING')
        self.assertTrue(WasteRequest.objects.filter(user=self.user).exists())

    def test_create_waste_request_unauthorized(self):
        """Test waste request creation without authentication fails"""
        request_url = reverse('waste-request-list')
        request_data = {
            'pickup_address': '123 Test Street, Kampala',
            'latitude': 0.3476,
            'longitude': 32.5825,
            'estimated_weight_kg': 5.0,
        }

        response = self.client.post(request_url, request_data, format='json')

        self.assertEqual(response.status_code, 401)

    def test_get_waste_requests_list(self):
        """Test getting list of user's waste requests"""
        self.authenticate()

        WasteRequest.objects.create(
            user=self.user,
            pickup_address='Address 1',
            estimated_weight_kg=3.0,
            category=self.category,
        )
        WasteRequest.objects.create(
            user=self.user,
            pickup_address='Address 2',
            estimated_weight_kg=7.0,
            category=self.category,
        )

        request_url = reverse('waste-request-list')
        response = self.client.get(request_url, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data['results']), 2)

    def test_get_waste_request_detail(self):
        """Test getting specific waste request details"""
        self.authenticate()

        waste_request = WasteRequest.objects.create(
            user=self.user,
            pickup_address='123 Test Street',
            estimated_weight_kg=5.0,
            category=self.category,
        )

        request_url = reverse('waste-request-detail', kwargs={'pk': waste_request.id})
        response = self.client.get(request_url, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['id'], str(waste_request.id))

    def test_update_waste_request(self):
        """Test updating waste request"""
        self.authenticate()

        waste_request = WasteRequest.objects.create(
            user=self.user,
            pickup_address='123 Test Street',
            estimated_weight_kg=5.0,
            category=self.category,
        )

        request_url = reverse('waste-request-detail', kwargs={'pk': waste_request.id})
        update_data = {
            'special_instructions': 'Updated instructions',
        }
        response = self.client.patch(request_url, update_data, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['special_instructions'], 'Updated instructions')

    def test_delete_waste_request(self):
        """Test deleting waste request"""
        self.authenticate()

        waste_request = WasteRequest.objects.create(
            user=self.user,
            pickup_address='123 Test Street',
            estimated_weight_kg=5.0,
            category=self.category,
        )

        request_url = reverse('waste-request-detail', kwargs={'pk': waste_request.id})
        response = self.client.delete(request_url, format='json')

        self.assertEqual(response.status_code, 204)
        self.assertFalse(WasteRequest.objects.filter(id=waste_request.id).exists())

    def test_waste_category_list(self):
        """Test getting list of waste categories"""
        self.authenticate()

        WasteCategory.objects.create(
            name='Paper',
            slug='paper',
            description='Paper waste',
            is_hazardous=False,
            default_price_per_kg=300.0,
            base_eco_points=5,
        )

        category_url = reverse('waste-category-list')
        response = self.client.get(category_url, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertGreaterEqual(len(response.data['results']), 2)