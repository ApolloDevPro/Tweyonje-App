import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:tweyonje/core/services/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('should handle network timeout errors', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ErrorHandler.handleDioError(dioError);

      expect(exception, isA<NetworkException>());
      expect(exception.message, contains('timeout'));
    });

    test('should handle 401 authentication errors', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'detail': 'Authentication failed'},
        ),
      );

      final exception = ErrorHandler.handleDioError(dioError);

      expect(exception, isA<AuthenticationException>());
      expect(exception.statusCode, 401);
    });

    test('should handle 404 not found errors', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
          data: {'detail': 'Not found'},
        ),
      );

      final exception = ErrorHandler.handleDioError(dioError);

      expect(exception, isA<NotFoundException>());
      expect(exception.statusCode, 404);
    });

    test('should handle 400 bad request errors', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'message': 'Invalid input'},
        ),
      );

      final exception = ErrorHandler.handleDioError(dioError);

      expect(exception, isA<BadRequestException>());
      expect(exception.statusCode, 400);
    });

    test('should handle 429 rate limit errors', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 429,
          data: {'message': 'Too many requests'},
        ),
      );

      final exception = ErrorHandler.handleDioError(dioError);

      expect(exception, isA<RateLimitException>());
      expect(exception.statusCode, 429);
    });

    test('should handle 500 server errors', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
          data: {'message': 'Internal server error'},
        ),
      );

      final exception = ErrorHandler.handleDioError(dioError);

      expect(exception, isA<ServerException>());
      expect(exception.statusCode, 500);
    });

    test('should handle validation errors with error details', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {
            'message': 'Validation failed',
            'errors': {
              'email': ['This field is required.'],
              'password': ['Password is too short.'],
            },
          },
        ),
      );

      final exception = ErrorHandler.handleDioError(dioError);

      expect(exception, isA<ValidationException>());
      final validationException = exception as ValidationException;
      expect(validationException.validationErrors, isNotNull);
      expect(validationException.validationErrors!.containsKey('email'), true);
    });

    test('should handle connection errors', () {
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final exception = ErrorHandler.handleDioError(dioError);

      expect(exception, isA<NetworkException>());
    });

    test('should provide user-friendly error messages', () {
      final exception = NetworkException();
      final message = ErrorHandler.getUserFriendlyMessage(exception);

      expect(message, isNotEmpty);
      expect(message.toLowerCase(), contains('network'));
    });
  });
}
