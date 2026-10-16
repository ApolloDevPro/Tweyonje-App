import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

/// Second step of the forgot-password flow: the user submits the reset code
/// emailed by the backend together with a new password.
class PasswordResetScreen extends ConsumerStatefulWidget {
  final String email;
  final String? devToken;

  const PasswordResetScreen({super.key, required this.email, this.devToken});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.email);
  late final _tokenController = TextEditingController(text: widget.devToken ?? '');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final email = v?.trim() ?? '';
    final emailRe = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (email.isEmpty || !emailRe.hasMatch(email)) {
      return context.tr('auth.resetEmailRequired');
    }
    return null;
  }

  String? _validateToken(String? v) {
    if (v == null || v.trim().isEmpty) return context.tr('auth.resetCodeRequired');
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.length < 8) return context.tr('auth.newPasswordRequired');
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return context.tr('auth.confirmPassword');
    if (v != _passwordController.text) return context.tr('auth.passwordsNoMatch');
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authProvider.notifier).confirmPasswordReset(
            token: _tokenController.text.trim(),
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('auth.resetSuccess')),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      String msg = context.tr('common.tryAgain');
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) {
          msg = detail;
        } else {
          for (final value in data.values) {
            if (value is List && value.isNotEmpty) {
              msg = value.first.toString();
              break;
            }
            if (value is String && value.isNotEmpty) {
              msg = value;
              break;
            }
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.dangerDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF374151)),
          ),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
        title: Text(
          context.tr('auth.resetPassword'),
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('auth.resetPassword'),
                      style: AppTypography.h2.copyWith(
                        color: const Color(0xFF064E3B),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('auth.resetPasswordSubtitle'),
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xxl),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AppInput(
                            label: context.tr('auth.resetEmailLabel'),
                            hint: 'e.g. resident@tweyonje.ug',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF059669)),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: context.tr('auth.resetCodeLabel'),
                            hint: '••••••',
                            controller: _tokenController,
                            prefixIcon: const Icon(Icons.pin_outlined, color: Color(0xFF059669)),
                            validator: _validateToken,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: context.tr('auth.newPassword'),
                            hint: context.tr('auth.passwordHint'),
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF059669)),
                            validator: _validatePassword,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: context.tr('auth.confirmNewPassword'),
                            hint: '••••••••',
                            controller: _confirmPasswordController,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF059669)),
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF059669), Color(0xFF047857)],
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withAlpha(80),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              onPressed: _submitting ? null : _submit,
                              child: _submitting
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          context.tr('auth.updatePassword'),
                                          style: AppTypography.labelLarge.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => context.go('/login'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              context.tr('auth.signIn'),
                              style: AppTypography.body.copyWith(
                                color: const Color(0xFF059669),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
