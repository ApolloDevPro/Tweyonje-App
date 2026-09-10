import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/biometric_service.dart';
import '../../core/theme/theme.dart';
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
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final err = ref.read(authProvider).errorMessage;
      if (err != null && ref.read(authProvider).status == AuthStatus.unauthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text(err)),
              ],
            ),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });
  }

  Future<void> _checkBiometrics() async {
    final canBio = await BiometricService().isBiometricAvailable();
    if (mounted) setState(() => _biometricsAvailable = canBio);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
      _loginController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      context.go('/');
    } else if (!success && mounted) {
      final err = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(err ?? 'Login failed. Please check your credentials.')),
            ],
          ),
          backgroundColor: AppColors.dangerDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        ),
      );
    }
  }

  void _fillDemo(String email, String password) {
    _loginController.text = email;
    _passwordController.text = password;
  }

  void _showForgotPasswordDialog() {
    final emailPhoneCtrl = TextEditingController(text: _loginController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            const Text('Reset Password'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your registered email address or phone number and we will send you a reset code.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: 'Email or Phone',
              hint: 'e.g. resident@tweyonje.ug',
              controller: emailPhoneCtrl,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset instructions sent to your email/phone.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Send Reset Link'),
          ),
        ],
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: Stack(
        children: [
          // Ambient decorative glowing background circles
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand Logo Emblem
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

                        // App Name & Tagline
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

                        // Login Form Card
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
                                'Sign In',
                                style: AppTypography.h3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Access your pickups, earnings, and eco-points',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Email or Phone Input
                              AppInput(
                                label: 'Email or Phone Number',
                                hint: 'user@example.ug or +256700000000',
                                controller: _loginController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF059669)),
                                validator: (val) => (val == null || val.trim().isEmpty)
                                    ? 'Please enter your email or phone'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Password Input
                              AppInput(
                                label: 'Password',
                                hint: '••••••••',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF059669)),
                                validator: (val) => (val == null || val.length < 4)
                                    ? 'Password must be at least 4 characters'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Remember Me & Forgot Password
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
                                          value: _rememberMe == true,
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Remember me',
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
                                      'Forgot Password?',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Sign In Action Button
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
                                              'Sign In to Tweyonje',
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

                              // Biometric Button (if hardware available)
                              if (_biometricsAvailable) ...[
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
                                    'Biometric Sign In',
                                    style: AppTypography.label.copyWith(color: AppColors.text),
                                  ),
                                  onPressed: () async {
                                    final auth = await BiometricService().authenticate();
                                    if (auth && mounted) {
                                      ref.read(authProvider.notifier).hydrate();
                                    }
                                  },
                                ),
                              ],

                              const SizedBox(height: AppSpacing.lg),
                              // Demo Accounts Autofill Quick Strip
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
                                      _buildDemoChip('🌿 Resident', 'resident@tweyonje.ug'),
                                      _buildDemoChip('🚚 Collector', 'collector@tweyonje.ug'),
                                      _buildDemoChip('🛡️ Authority', 'authority@tweyonje.ug'),
                                      _buildDemoChip('♻️ Recycler', 'recycler@tweyonje.ug'),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => context.push('/register'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  'Create Account',
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

