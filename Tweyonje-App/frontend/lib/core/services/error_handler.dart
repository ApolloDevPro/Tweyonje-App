import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({String? message})
      : super(
          message: message ?? 'Network connection failed. Please check your internet connection.',
          statusCode: null,
        );
}

class ServerException extends AppException {
  ServerException({
    required super.message,
    super.statusCode,
    super.errorCode,
  });
}

class AuthenticationException extends AppException {
  AuthenticationException({String? message})
      : super(
          message: message ?? 'Authentication failed. Please login again.',
          statusCode: 401,
        );
}

class BadRequestException extends AppException {
  BadRequestException({String? message})
      : super(
          message: message ?? 'Invalid request. Please check your input.',
          statusCode: 400,
        );
}

class NotFoundException extends AppException {
  NotFoundException({String? message})
      : super(
          message: message ?? 'Resource not found.',
          statusCode: 404,
        );
}

class ValidationException extends AppException {
  final Map<String, dynamic>? validationErrors;

  ValidationException({
    String? message,
    this.validationErrors,
  }) : super(
          message: message ?? 'Validation failed. Please check your input.',
          statusCode: 400,
        );
}

class RateLimitException extends AppException {
  RateLimitException({String? message})
      : super(
          message: message ?? 'Too many requests. Please try again later.',
          statusCode: 429,
        );
}

class StorageException extends AppException {
  StorageException({String? message})
      : super(
          message: message ?? 'Storage operation failed.',
          statusCode: null,
        );
}

class PermissionException extends AppException {
  PermissionException({String? message})
      : super(
          message: message ?? 'Permission denied. Please grant the required permissions.',
          statusCode: null,
        );
}

class ErrorHandler {
  static AppException handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkException(message: 'Connection timeout. Please try again.');

      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response!.statusCode!, error.response!.data);

      case DioExceptionType.cancel:
        return AppException(message: 'Request was cancelled.');

      case DioExceptionType.connectionError:
        return NetworkException();

      case DioExceptionType.badCertificate:
        return AppException(message: 'SSL certificate error.');

      case DioExceptionType.unknown:
        return AppException(message: 'An unknown error occurred: ${error.message}');
    }
  }

  static AppException _handleStatusCode(int statusCode, dynamic responseData) {
    String message = 'An error occurred';
    Map<String, dynamic>? validationErrors;

    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] ?? responseData['detail'] ?? message;
      validationErrors = responseData['errors'];
    }

    switch (statusCode) {
      case 400:
        if (validationErrors != null) {
          return ValidationException(message: message, validationErrors: validationErrors);
        }
        return BadRequestException(message: message);
      case 401:
        return AuthenticationException(message: message);
      case 403:
        return AppException(message: message, statusCode: statusCode);
      case 404:
        return NotFoundException(message: message);
      case 429:
        return RateLimitException(message: message);
      case 500:
        return ServerException(message: message, statusCode: statusCode);
      default:
        return ServerException(message: message, statusCode: statusCode);
    }
  }

  static String getUserFriendlyMessage(AppException exception) {
    return exception.message;
  }
}