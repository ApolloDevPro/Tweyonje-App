import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/password_strength_meter.dart';
import '../../widgets/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'RESIDENT';
  bool _agreedToTerms = false;

  // Only Resident and Business allow self-service registration.
  // Collector, Recycler, Authority, and Administrator require admin approval.
  final _roles = [
    {
      'label': 'Resident',
      'value': 'RESIDENT',
      'subtitle': 'Pickups & Rewards',
      'icon': Icons.home_rounded,
      'color': const Color(0xFF059669),
    },
    {
      'label': 'Business',
      'value': 'BUSINESS',
      'subtitle': 'Company & Commercial',
      'icon': Icons.storefront_rounded,
      'color': const Color(0xFFD97706),
    },
  ];

  String? _validateName(String? v) =>
      (v == null || v.trim().isEmpty) ? context.tr('auth.fullNameRequired') : null;

  String? _validateEmail(String? v) {
    final email = v?.trim() ?? '';
    final emailRe = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (email.isEmpty) return context.tr('auth.emailRequired');
    if (!emailRe.hasMatch(email)) return context.tr('auth.emailInvalid');
    return null;
  }

  String? _validatePhone(String? v) {
    final phone = v?.trim() ?? '';
    if (phone.isEmpty) return null; // phone is optional
    if (!PhoneUtils.isValid(phone)) return context.tr('auth.phoneInvalid');
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('auth.acceptTerms')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final rawPhone = _phoneController.text.trim();
    final normalizedPhone = rawPhone.isEmpty ? null : PhoneUtils.normalize(rawPhone);

    final success = await ref.read(authProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          role: _selectedRole,
          phone: normalizedPhone,
          consentPolicyVersion: AppConstants.privacyPolicyVersion,
        );

    if (!mounted) return;
    if (success) {
      if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        context.go(
          '/verify-otp?identifier=$normalizedPhone&purpose=PHONE_VERIFY&postRegister=1',
        );
      } else {
        context.go('/');
      }
    } else {
      final err = ref.read(authProvider).errorMessage;
      final fieldErrors = ref.read(authProvider).fieldErrors;
      // Surface field-level API errors (e.g. duplicate email) inline.
      if (fieldErrors.containsKey('email')) {
        _formKey.currentState?.validate();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(err ?? context.tr('auth.registerFailed'))),
            ],
          ),
          backgroundColor: AppColors.dangerDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

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
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('auth.joinTweyonje'),
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
                      context.tr('auth.createYourAccount'),
                      style: AppTypography.h2.copyWith(
                        color: const Color(0xFF064E3B),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select your account type to get personalized waste & recycling features.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.tr('auth.registeringAs'),
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _roles.length,
                      itemBuilder: (context, index) {
                        final r = _roles[index];
                        final isSelected = _selectedRole == r['value'];
                        final color = r['color'] as Color;

                        return InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          onTap: () => setState(() => _selectedRole = r['value'] as String),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withAlpha(20) : Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: isSelected ? color : const Color(0xFFE5E7EB),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withAlpha(40),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(6),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(r['icon'] as IconData, color: color, size: 26),
                                    const SizedBox(height: 6),
                                    Text(
                                      r['label'] as String,
                                      style: AppTypography.label.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      r['subtitle'] as String,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
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
                            label: context.tr('auth.fullName'),
                            hint: 'e.g. Apollo Turyahebwa',
                            controller: _nameController,
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF059669)),
                            validator: _validateName,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: context.tr('auth.email'),
                            hint: 'apollo@example.ug',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF059669)),
                            validator: _validateEmail,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: context.tr('auth.phone'),
                            hint: context.tr('auth.phoneHint'),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF059669)),
                            validator: _validatePhone,
                            autofillHints: const [AutofillHints.telephoneNumber],
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: context.tr('auth.password'),
                            hint: context.tr('auth.passwordHint'),
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF059669)),
                            validator: _validatePassword,
                            onChanged: (_) => setState(() {}),
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.next,
                          ),
                          if (_passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            PasswordStrengthMeter(password: _passwordController.text),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: context.tr('auth.confirmPassword'),
                            hint: '••••••••',
                            controller: _confirmPasswordController,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF059669)),
                            validator: _validateConfirmPassword,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleRegister(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreedToTerms,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                      children: [
                                        TextSpan(text: context.tr('auth.agreeTermsPrefix')),
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () => context.push('/terms-of-service'),
                                            child: Text(
                                              context.tr('auth.termsOfService'),
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                        TextSpan(text: context.tr('auth.and')),
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () => context.push('/privacy-policy'),
                                            child: Text(
                                              context.tr('auth.privacyPolicy'),
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                              onPressed: isLoading ? null : _handleRegister,
                              child: isLoading
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
                                          context.tr('auth.createMyAccount'),
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
                        Text(
                          "${context.tr('auth.haveAccount')} ",
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => context.pop(),
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
