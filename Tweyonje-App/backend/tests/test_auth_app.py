from django.urls import reverse
from rest_framework.test import APITestCase

from core.models import User, Role
from apps.accounts.models import OTPVerification, hash_otp_code


class TestAuthenticationAPI(APITestCase):
    """Test suite for authentication endpoints"""

    def setUp(self):
        self.user_data = {
            'email': 'test@example.com',
            'password': 'TestPassword123!',
            'full_name': 'Test User',
            'phone': '+256700000000',
            'role': Role.RESIDENT,
        }

    def test_user_registration_success(self):
        """Test successful user registration"""
        url = reverse('auth-register')
        response = self.client.post(url, self.user_data, format='json')

        self.assertEqual(response.status_code, 201)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertIn('user', response.data)
        self.assertEqual(response.data['user']['email'], self.user_data['email'])

        # Verify user was created in database
        user = User.objects.get(email=self.user_data['email'])
        self.assertEqual(user.role, Role.RESIDENT)
        self.assertFalse(user.phone_verified)

    def test_user_registration_duplicate_email(self):
        """Test registration with duplicate email fails"""
        # Create first user
        User.objects.create_user(
            email=self.user_data['email'],
            password=self.user_data['password'],
            full_name=self.user_data['full_name'],
        )

        # Try to register duplicate
        url = reverse('auth-register')
        response = self.client.post(url, self.user_data, format='json')

        self.assertEqual(response.status_code, 400)
        self.assertIn('email', response.data)

    def test_user_registration_invalid_password(self):
        """Test registration with invalid password fails"""
        invalid_data = self.user_data.copy()
        invalid_data['password'] = 'weak'

        url = reverse('auth-register')
        response = self.client.post(url, invalid_data, format='json')

        self.assertEqual(response.status_code, 400)

    def test_user_login_success(self):
        """Test successful user login"""
        # Create user first
        User.objects.create_user(
            email=self.user_data['email'],
            password=self.user_data['password'],
            full_name=self.user_data['full_name'],
        )

        # Login
        url = reverse('auth-login')
        login_data = {
            'email': self.user_data['email'],
            'password': self.user_data['password'],
        }
        response = self.client.post(url, login_data, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)

    def test_user_login_invalid_credentials(self):
        """Test login with invalid credentials fails"""
        url = reverse('auth-login')
        login_data = {
            'email': 'nonexistent@example.com',
            'password': 'wrongpassword',
        }
        response = self.client.post(url, login_data, format='json')

        self.assertEqual(response.status_code, 401)

    def test_token_refresh_success(self):
        """Test successful token refresh"""
        # Create and login user
        User.objects.create_user(
            email=self.user_data['email'],
            password=self.user_data['password'],
            full_name=self.user_data['full_name'],
        )

        url = reverse('auth-login')
        response = self.client.post(url, {
            'email': self.user_data['email'],
            'password': self.user_data['password'],
        }, format='json')

        refresh_token = response.data['refresh']

        # Refresh token
        refresh_url = reverse('auth-refresh')
        response = self.client.post(refresh_url, {'refresh': refresh_token}, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)

    def test_user_logout_success(self):
        """Test successful user logout"""
        # Create and login user
        User.objects.create_user(
            email=self.user_data['email'],
            password=self.user_data['password'],
            full_name=self.user_data['full_name'],
        )

        url = reverse('auth-login')
        response = self.client.post(url, {
            'email': self.user_data['email'],
            'password': self.user_data['password'],
        }, format='json')

        access_token = response.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

        # Logout
        logout_url = reverse('auth-logout')
        response = self.client.post(logout_url, {'refresh': response.data['refresh']}, format='json')

        self.assertEqual(response.status_code, 204)

    def test_otp_verification_request(self):
        """Test OTP verification request"""
        url = reverse('auth-otp-send')
        response = self.client.post(url, {
            'identifier': '+256700000000',
            'purpose': OTPVerification.Purpose.PHONE_VERIFY,
        }, format='json')

        self.assertEqual(response.status_code, 200)
        self.assertTrue(OTPVerification.objects.filter(identifier='+256700000000').exists())

    def test_otp_verification_success(self):
        """Test successful OTP verification"""
        # Create OTP (stored code is a hash; verify with the plaintext).
        otp = OTPVerification.objects.create(
            identifier='+256700000000',
            purpose=OTPVerification.Purpose.PHONE_VERIFY,
            otp_code=hash_otp_code('123456'),
        )

        url = reverse('auth-otp-verify')
        response = self.client.post(url, {
            'identifier': '+256700000000',
            'otp_code': '123456',
            'purpose': OTPVerification.Purpose.PHONE_VERIFY,
        }, format='json')

        self.assertEqual(response.status_code, 200)

        # Verify OTP was marked as verified
        otp.refresh_from_db()
        self.assertTrue(otp.is_verified)

    def test_otp_verification_invalid_code(self):
        """Test OTP verification with invalid code fails"""
        url = reverse('auth-otp-verify')
        response = self.client.post(url, {
            'identifier': '+256700000000',
            'otp_code': '000000',
            'purpose': OTPVerification.Purpose.PHONE_VERIFY,
        }, format='json')

        self.assertEqual(response.status_code, 400)