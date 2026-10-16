import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/services/biometric_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/phone_utils.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _biometricsAvailable = false;
  bool _biometricsEnabled = false;
  bool _rememberMe = true;
  bool _requestingReset = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final err = ref.read(authProvider).errorMessage;
      if (err != null && ref.read(authProvider).status == AuthStatus.unauthenticated) {
        _showError(err);
        ref.read(authProvider.notifier).clearError();
      }
    });
  }

  Future<void> _bootstrap() async {
    final service = BiometricService();
    final canBio = await service.isBiometricAvailable();
    final enabled = canBio ? await service.isBiometricEnabled() : false;
    final storage = LocalStorage();
    final remembered = await storage.getPreferenceString(AppConstants.rememberedLoginKey);
    if (mounted) {
      setState(() {
        _biometricsAvailable = canBio;
        _biometricsEnabled = enabled;
        if (remembered != null && remembered.isNotEmpty) {
          _loginController.text = remembered;
        }
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.dangerDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
  }

  String? _validateIdentifier(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return context.tr('auth.emailOrPhoneRequired');
    if (PhoneUtils.looksLikeEmail(v)) {
      final emailRe = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
      if (!emailRe.hasMatch(v)) return context.tr('auth.emailOrPhoneInvalid');
    } else if (!PhoneUtils.isValid(v)) {
      return context.tr('auth.emailOrPhoneInvalid');
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return context.tr('auth.passwordRequired');
    return null;
  }

  String _resolveIdentifier(String raw) {
    final v = raw.trim();
    if (PhoneUtils.looksLikeEmail(v)) return v;
    return PhoneUtils.normalize(v) ?? v;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _resolveIdentifier(_loginController.text);
    final success = await ref.read(authProvider.notifier).login(
          identifier,
          _passwordController.text,
        );

    if (!mounted) return;
    if (success) {
      final storage = LocalStorage();
      if (_rememberMe) {
        await storage.setPreferenceString(
          AppConstants.rememberedLoginKey,
          _loginController.text.trim(),
        );
      } else {
        await storage.removePreference(AppConstants.rememberedLoginKey);
      }
      if (!mounted) return;
      context.go('/');
    } else {
      final err = ref.read(authProvider).errorMessage;
      _showError(err ?? context.tr('auth.loginFailed'));
    }
  }

  Future<void> _handleBiometricSignIn() async {
    final auth = await BiometricService().authenticate();
    if (!mounted) return;
    if (!auth) return;
    await ref.read(authProvider.notifier).hydrate();
    if (!mounted) return;
    if (ref.read(authProvider).status == AuthStatus.authenticated) {
      context.go('/');
    } else {
      _showError(
        'No saved session found on this device. Please sign in with your '
        'email and password first, then enable biometrics in Settings.',
      );
    }
  }

  void _fillDemo(String email, String password) {
    _loginController.text = email;
    _passwordController.text = password;
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _loginController.text.trim());
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.lock_reset, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(context.tr('auth.resetPassword')),
            ],
          ),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('auth.resetPasswordSubtitle'),
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppInput(
                  label: context.tr('auth.resetEmailLabel'),
                  hint: 'e.g. resident@tweyonje.ug',
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF059669)),
                  validator: (v) {
                    final email = v?.trim() ?? '';
                    final emailRe = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                    if (email.isEmpty || !emailRe.hasMatch(email)) {
                      return context.tr('auth.resetEmailRequired');
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.tr('common.cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              onPressed: _requestingReset
                  ? null
                  : () async {
                      if (!dialogFormKey.currentState!.validate()) return;
                      setDialogState(() => _requestingReset = true);
                      setState(() => _requestingReset = true);
                      try {
                        final devToken = await ref
                            .read(authProvider.notifier)
                            .requestPasswordReset(emailCtrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx, true);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.tr('auth.resetSent')),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          final uri = Uri(
                            path: '/reset-password',
                            queryParameters: {
                              'email': emailCtrl.text.trim(),
                              if (devToken != null && devToken.isNotEmpty) 'devToken': devToken,
                            },
                          );
                          context.go(uri.toString());
                        }
                      } catch (e) {
                        if (ctx.mounted) Navigator.pop(ctx, false);
                        if (mounted) {
                          _showError(context.tr('common.tryAgain'));
                        }
                      } finally {
                        if (mounted) setState(() => _requestingReset = false);
                      }
                    },
              child: _requestingReset
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(context.tr('auth.sendResetCode')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final showBiometrics = _biometricsAvailable && _biometricsEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withAlpha(45),
                    AppColors.primary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withAlpha(35),
                    AppColors.accent.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF34D399), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF059669).withAlpha(75),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.recycling_rounded,
                                  size: 46,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Tweyonje',
                          textAlign: TextAlign.center,
                          style: AppTypography.displaySmall.copyWith(
                            color: const Color(0xFF064E3B),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.primary.withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.eco, size: 14, color: AppColors.primaryDark),
                                const SizedBox(width: 6),
                                Text(
                                  'Smart Waste Management • Uganda',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(12),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                context.tr('auth.signIn'),
                                style: AppTypography.h3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('auth.signInSubtitle'),
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppInput(
                                label: context.tr('auth.emailOrPhone'),
                                hint: context.tr('auth.emailOrPhoneHint'),
                                controller: _loginController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF059669)),
                                validator: _validateIdentifier,
                                autofillHints: const [
                                  AutofillHints.username,
                                  AutofillHints.email,
                                  AutofillHints.telephoneNumber,
                                ],
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppInput(
                                label: context.tr('auth.password'),
                                hint: '••••••••',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF059669)),
                                validator: _validatePassword,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.tr('auth.rememberMe'),
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      context.tr('auth.forgotPassword'),
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
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
                                  onPressed: isLoading ? null : _handleLogin,
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
                                              context.tr('auth.signInButton'),
                                              style: AppTypography.labelLarge.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                              if (showBiometrics) ...[
                                const SizedBox(height: AppSpacing.md),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                  ),
                                  icon: const Icon(Icons.fingerprint, color: Color(0xFF059669), size: 22),
                                  label: Text(
                                    context.tr('auth.biometricSignIn'),
                                    style: AppTypography.label.copyWith(color: AppColors.text),
                                  ),
                                  onPressed: isLoading ? null : _handleBiometricSignIn,
                                ),
                              ],
                              if (kDebugMode) ...[
                                const SizedBox(height: AppSpacing.lg),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(child: Divider()),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            'QUICK TEST ACCOUNTS',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                        const Expanded(child: Divider()),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _buildDemoChip('Resident', 'resident@tweyonje.ug'),
                                        _buildDemoChip('Collector', 'collector@tweyonje.ug'),
                                        _buildDemoChip('Authority', 'authority@tweyonje.ug'),
                                        _buildDemoChip('Recycler', 'recycler@tweyonje.ug'),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${context.tr('auth.noAccount')} ",
                              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => context.push('/register'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  context.tr('auth.createAccount'),
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
        ],
      ),
    );
  }

  Widget _buildDemoChip(String label, String email) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: () => _fillDemo(email, 'Pass@1234'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
