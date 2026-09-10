import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';
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
  String _selectedRole = 'RESIDENT';
  bool _agreedToTerms = true;

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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms of Service to continue'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      role: _selectedRole,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
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
              Expanded(child: Text(err ?? 'Registration failed. Please check your information.')),
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
          'Join Tweyonje',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Subtitle
                    Text(
                      'Create Your Account',
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

                    // Modern 2x2 Visual Role Selection Grid
                    Text(
                      'I AM REGISTERING AS:',
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

                    // Inputs Card
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
                            label: 'Full Name',
                            hint: 'e.g. Apollo Turyahebwa',
                            controller: _nameController,
                            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF059669)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: 'Email Address',
                            hint: 'apollo@example.ug',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF059669)),
                            validator: (v) =>
                                (v == null || !v.contains('@')) ? 'Please enter a valid email address' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: 'Phone Number (Mobile Money)',
                            hint: '+256 700 000000',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF059669)),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppInput(
                            label: 'Password',
                            hint: '••••••••',
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF059669)),
                            validator: (v) =>
                                (v == null || v.length < 8) ? 'Password must be at least 8 characters' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Terms Agreement
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreedToTerms == true,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (v) => setState(() => _agreedToTerms = v ?? true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'I agree to the Terms of Service & Privacy Policy',
                                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Submit Button
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
                                          'Create My Account',
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

                    // Sign In Footer Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () => context.pop(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Text(
                              'Sign In',
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

