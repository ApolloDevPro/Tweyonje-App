import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String identifier;
  final String purpose;

  /// When true the user just registered — success navigates to the app root
  /// instead of popping back to a screen that no longer exists.
  final bool postRegister;

  const OtpVerificationScreen({
    super.key,
    required this.identifier,
    this.purpose = 'PHONE_VERIFY',
    this.postRegister = false,
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
  String? _devCode;
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

  void _exit() {
    if (widget.postRegister || !context.canPop()) {
      context.go('/');
    } else {
      context.pop();
    }
  }

  Future<void> _sendOtp({bool resend = true}) async {
    setState(() {
      _sending = true;
      _message = null;
      _isError = false;
    });
    try {
      final data = await ref.read(authProvider.notifier).sendOtp(
            widget.identifier,
            purpose: widget.purpose,
          );
      setState(() {
        _sending = false;
        _message = data?['message'] as String? ??
            'Verification code sent. Check your phone / email.';
        _isError = false;
        _devCode = data?['dev_code'] as String?;
        _resendIn = 30;
      });
      _tickResend();
    } catch (e) {
      setState(() {
        _sending = false;
        _message = e is DioException
            ? (e.response?.data is Map
                ? (e.response?.data['detail'] ??
                    e.response?.data['error'] as String? ??
                    'Failed to send code.')
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
    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() {
        _message = context.tr('auth.enterOtp');
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
      final ok = await ref.read(authProvider.notifier).verifyOtp(
            widget.identifier,
            code,
            purpose: widget.purpose,
          );
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _message = ok
            ? context.tr('auth.verified')
            : 'Invalid or expired code.';
        _isError = !ok;
      });
      if (ok) {
        _codeController.clear();
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) _exit();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _message = e is DioException && e.response?.data is Map
            ? (e.response?.data['detail'] ??
                e.response?.data['error'] as String? ??
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
        title: Text(context.tr('auth.verifyAccount')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: _exit,
        ),
        actions: [
          TextButton(
            onPressed: _exit,
            child: Text(
              context.tr('auth.skip'),
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
              '${context.tr('auth.otpSentTo')} ${widget.identifier}',
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
            if (_devCode != null && _devCode!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Text(
                  '${context.tr('auth.devCodeLabel')}: $_devCode',
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
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
              text: context.tr('auth.verifyCode'),
              icon: const Icon(Icons.check_rounded, size: 18),
              isLoading: _verifying,
              onPressed: _verify,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: _sending || _resendIn > 0 ? null : _sendOtp,
              child: Text(
                _resendIn > 0
                    ? '${context.tr('auth.resendIn')} $_resendIn ${context.tr('auth.seconds')}…'
                    : context.tr('auth.resendCode'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
