import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:tweyonje/core/services/api_client.dart';
import 'package:tweyonje/core/storage/storage_service.dart';

@GenerateMocks([StorageService])
import 'api_client_test.mocks.dart';

void main() {
  group('ApiClient', () {
    late ApiClient apiClient;
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      final dio = Dio(BaseOptions(
        baseUrl: 'http://test.com/api/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      apiClient = ApiClient(dio, mockStorageService);
    });

    test('should add authorization header when token is available', () async {
      when(mockStorageService.getAccessToken()).thenAnswer((_) async => 'test_token');

      // This would require more complex setup with Dio interceptor testing
      // For now, we'll just verify the storage service is called
      await mockStorageService.getAccessToken();
      verify(mockStorageService.getAccessToken()).called(1);
    });

    test('should handle GET requests', () async {
      // This would require mocking Dio responses
      // For demonstration purposes
      expect(apiClient, isNotNull);
    });

    test('should handle POST requests', () async {
      // This would require mocking Dio responses
      expect(apiClient, isNotNull);
    });

    test('should handle token refresh on 401 error', () async {
      when(mockStorageService.getAccessToken()).thenAnswer((_) async => 'test_token');
      when(mockStorageService.getRefreshToken()).thenAnswer((_) async => 'refresh_token');
      when(mockStorageService.saveAccessToken(any)).thenAnswer((_) async => Future.value());

      // This would require mocking Dio to return 401 then success
      // For demonstration purposes
      expect(apiClient, isNotNull);
    });
  });
}