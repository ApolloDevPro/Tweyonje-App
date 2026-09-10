import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String identifier;
  final String purpose;

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    this.purpose = 'PHONE_VERIFY',
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  String? _message;
  bool _isError = false;
  int _resendIn = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp(resend: false));
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp({bool resend = true}) async {
    setState(() {
      _sending = true;
      _message = null;
      _isError = false;
    });
    try {
      final res = await ref.read(apiClientProvider).post(
            ApiEndpoints.resendOtp,
            data: {
              'identifier': widget.identifier,
              'purpose': widget.purpose,
            },
          );
      setState(() {
        _sending = false;
        _message = res.data['detail'] ??
            'Verification code sent. Check your phone / email.';
        _isError = false;
        _resendIn = 30;
      });
      _tickResend();
    } catch (e) {
      setState(() {
        _sending = false;
        _message = e is DioException
            ? (e.response?.data is Map
                ? (e.response?.data['detail'] ?? e.response?.data['error'])
                : 'Failed to send code.')
            : 'Failed to send code.';
        _isError = true;
      });
    }
  }

  void _tickResend() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      final next = _resendIn - 1;
      setState(() => _resendIn = next < 0 ? 0 : next);
      return _resendIn > 0;
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _message = 'Enter the code you received.';
        _isError = true;
      });
      return;
    }
    setState(() {
      _verifying = true;
      _message = null;
      _isError = false;
    });
    try {
      final res = await ref.read(apiClientProvider).verifyOtp(
            widget.identifier,
            code,
            purpose: widget.purpose,
          );
      setState(() {
        _verifying = false;
        _message = res.data['detail'] ??
            (res.data['message'] ?? 'Your account is now verified.');
        _isError = false;
      });
      if (res.statusCode == 200 || res.statusCode == 201) {
        _codeController.clear();
      }
    } catch (e) {
      setState(() {
        _verifying = false;
        _message = e is DioException && e.response?.data is Map
            ? (e.response?.data['detail'] ??
                e.response?.data['error'] ??
                'Invalid or expired code.')
            : 'Invalid or expired code.';
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify your account'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 96,
              height: 96,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl * 2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primary,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                size: 48,
                color: AppColors.textInverse,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'We sent a verification code to ${widget.identifier}',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: AppTypography.h2.copyWith(
                letterSpacing: 12,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '• • • • • •',
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: _isError ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Verify Code',
              icon: const Icon(Icons.check_rounded, size: 18),
              isLoading: _verifying,
              onPressed: _verify,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _sending || _resendIn > 0 ? null : _sendOtp,
              child: Text(
                _resendIn > 0
                    ? 'Resend code in $_resendIn s'
                    : 'Resend code',
              ),
            ),
          ],
        ),
      ),
    );
  }
}