import 'package:flutter_test/flutter_test.dart';
import 'package:tweyonje/models/models.dart';

void main() {
  group('User Model', () {
    test('should create User from JSON', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'full_name': 'Test User',
        'role': 'RESIDENT',
        'phone_verified': true,
        'email_verified': false,
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.role, UserRole.resident);
      expect(user.phoneVerified, true);
      expect(user.emailVerified, false);
    });

    test('should convert User to JSON', () {
      final user = User(
        id: 1,
        email: 'test@example.com',
        fullName: 'Test User',
        role: UserRole.resident,
        phoneVerified: true,
      );

      final json = user.toJson();

      expect(json['id'], 1);
      expect(json['email'], 'test@example.com');
      expect(json['full_name'], 'Test User');
      expect(json['role'], 'RESIDENT');
    });

    test('should handle missing fields gracefully', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'role': 'RESIDENT',
      };

      final user = User.fromJson(json);

      expect(user.fullName, '');
      expect(user.phoneVerified, false);
      expect(user.emailVerified, false);
    });
  });

  group('WasteRequest Model', () {
    test('should create WasteRequest from JSON', () {
      final json = {
        'id': '123',
        'reference_id': 'TWY-REQ-ABC123',
        'pickup_address': '123 Test Street',
        'estimated_weight_kg': 5.0,
        'status': 'PENDING',
        'payment_status': 'UNPAID',
        'category_details': {
          'id': '1',
          'name': 'Plastic',
          'slug': 'plastic',
          'description': 'Plastic waste',
        },
      };

      final request = WasteRequest.fromJson(json);

      expect(request.id, '123');
      expect(request.referenceId, 'TWY-REQ-ABC123');
      expect(request.pickupAddress, '123 Test Street');
      expect(request.estimatedWeightKg, 5.0);
      expect(request.status, 'PENDING');
      expect(request.categoryDetails, isNotNull);
    });

    test('should handle numeric conversion properly', () {
      final json = {
        'id': '123',
        'reference_id': 'TWY-REQ-ABC123',
        'pickup_address': '123 Test Street',
        'estimated_weight_kg': '5.5', // String instead of number
        'status': 'PENDING',
      };

      final request = WasteRequest.fromJson(json);

      expect(request.estimatedWeightKg, 5.5);
    });
  });

  group('AuthSession Model', () {
    test('should create AuthSession from JSON', () {
      final json = {
        'access': 'access_token',
        'refresh': 'refresh_token',
        'user': {
          'id': 1,
          'email': 'test@example.com',
          'role': 'RESIDENT',
        },
      };

      final session = AuthSession.fromJson(json);

      expect(session.access, 'access_token');
      expect(session.refresh, 'refresh_token');
      expect(session.user.email, 'test@example.com');
    });
  });

  group('UserRole Enum', () {
    test('should parse string to UserRole', () {
      expect(UserRole.fromString('RESIDENT'), UserRole.resident);
      expect(UserRole.fromString('COLLECTOR'), UserRole.collector);
      expect(UserRole.fromString('resident'), UserRole.resident); // Case insensitive
      expect(UserRole.fromString('unknown'), UserRole.resident); // Default fallback
    });

    test('should get value from UserRole', () {
      expect(UserRole.resident.value, 'RESIDENT');
      expect(UserRole.collector.value, 'COLLECTOR');
    });
  });
}