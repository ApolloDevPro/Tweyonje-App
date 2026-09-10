import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/theme/theme.dart';
import 'app_button.dart';

enum ErrorType {
  network,
  authentication,
  server,
  validation,
  permission,
  unknown,
}

class AppError {
  final String title;
  final String message;
  final ErrorType type;
  final String? technicalDetails;
  final VoidCallback? onRetry;

  AppError({
    required this.title,
    required this.message,
    required this.type,
    this.technicalDetails,
    this.onRetry,
  });

  factory AppError.fromDioException(DioException exception, {VoidCallback? onRetry}) {
    String title = 'Something went wrong';
    String message = 'An unexpected error occurred. Please try again.';
    ErrorType type = ErrorType.unknown;
    String? technicalDetails;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        title = 'Connection Timeout';
        message = 'The request took too long to complete. Please check your internet connection and try again.';
        type = ErrorType.network;
        technicalDetails = exception.message;
        break;

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        technicalDetails = 'Status: $statusCode';

        switch (statusCode) {
          case 400:
            title = 'Invalid Request';
            message = 'The request was invalid. Please check your input and try again.';
            type = ErrorType.validation;
            break;
          case 401:
            title = 'Authentication Required';
            message = 'Please log in to access this feature.';
            type = ErrorType.authentication;
            break;
          case 403:
            title = 'Access Denied';
            message = 'You don\'t have permission to perform this action.';
            type = ErrorType.permission;
            break;
          case 404:
            title = 'Not Found';
            message = 'The requested resource was not found.';
            type = ErrorType.server;
            break;
          case 429:
            title = 'Too Many Requests';
            message = 'You\'ve made too many requests. Please wait a moment and try again.';
            type = ErrorType.network;
            break;
          case 500:
          case 502:
          case 503:
          case 504:
            title = 'Server Error';
            message = 'Our servers are experiencing issues. Please try again later.';
            type = ErrorType.server;
            break;
          default:
            title = 'Error';
            message = 'An error occurred. Please try again.';
            type = ErrorType.unknown;
        }
        break;

      case DioExceptionType.cancel:
        title = 'Request Cancelled';
        message = 'The request was cancelled.';
        type = ErrorType.network;
        break;

      case DioExceptionType.connectionError:
        title = 'No Internet Connection';
        message = 'Please check your internet connection and try again.';
        type = ErrorType.network;
        technicalDetails = exception.message;
        break;

      case DioExceptionType.badCertificate:
        title = 'SSL Certificate Error';
        message = 'Unable to verify the server\'s security certificate. Please try again later.';
        type = ErrorType.network;
        technicalDetails = exception.message;
        break;

      case DioExceptionType.unknown:
        title = 'Unexpected Error';
        message = 'An unexpected error occurred. Please try again.';
        type = ErrorType.unknown;
        technicalDetails = exception.message;
        break;
    }

    return AppError(
      title: title,
      message: message,
      type: type,
      technicalDetails: technicalDetails,
      onRetry: onRetry,
    );
  }

  factory AppError.fromException(dynamic exception, {VoidCallback? onRetry}) {
    if (exception is DioException) {
      return AppError.fromDioException(exception, onRetry: onRetry);
    }

    return AppError(
      title: 'Error',
      message: exception.toString(),
      type: ErrorType.unknown,
      onRetry: onRetry,
    );
  }

  IconData get icon {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.permission:
        return Icons.block;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  Color get color {
    switch (type) {
      case ErrorType.network:
        return AppColors.warning;
      case ErrorType.authentication:
        return AppColors.info;
      case ErrorType.server:
        return AppColors.danger;
      case ErrorType.validation:
        return AppColors.warning;
      case ErrorType.permission:
        return AppColors.danger;
      case ErrorType.unknown:
        return AppColors.danger;
    }
  }
}

class ErrorDisplay extends StatelessWidget {
  final AppError error;
  final bool showTechnicalDetails;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.showTechnicalDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: error.color.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Icon(
              error.icon,
              size: 40,
              color: error.color,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            error.title,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error.message,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (showTechnicalDetails && error.technicalDetails != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                error.technicalDetails!,
                style: AppTypography.caption.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          if (error.onRetry != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Try Again',
              icon: const Icon(Icons.refresh, size: 16),
              onPressed: error.onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorSnackBar {
  static void show(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(error.icon, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: error.color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: error.onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: error.onRetry!,
              )
            : null,
      ),
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final AppError error;

  const ErrorDialog({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(error.icon, color: error.color, size: 48),
      title: Text(error.title),
      content: Text(error.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        if (error.onRetry != null)
          AppButton(
            text: 'Retry',
            onPressed: () {
              Navigator.pop(context);
              error.onRetry!();
            },
          ),
      ],
    );
  }

  static void show(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(error: error),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: actionLabel!,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onContinue;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 48,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        if (onContinue != null)
          AppButton(
            text: 'Continue',
            onPressed: () {
              Navigator.pop(context);
              onContinue!();
            },
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onContinue,
  }) {
    showDialog(
      context: context,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        onContinue: onContinue,
      ),
    );
  }
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        AppButton(
          text: confirmText,
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          variant: isDestructive
              ? ButtonVariant.danger
              : ButtonVariant.primary,
        ),
      ],
    );
  }

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: () => Navigator.pop(context, true),
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }
}
