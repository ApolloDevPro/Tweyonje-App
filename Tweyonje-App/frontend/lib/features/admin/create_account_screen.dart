import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/widgets.dart';
import 'role_meta.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.collector;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref.read(adminControllerProvider.notifier).createUser(
          email: _email.text,
          password: _password.text,
          fullName: _name.text,
          role: _role.value,
          phone: _phone.text,
        );

    if (!mounted) return;
    final state = ref.read(adminControllerProvider);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/admin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message ?? 'Failed to create account.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a team member', style: AppTypography.h4),
              const SizedBox(height: 4),
              Text(
                'Admin-created accounts bypass self-service restrictions and can hold any role.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                'Full name',
                style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              AppInput(
                label: 'Business',
                hint: 'e.g. John Okello',
                controller: _name,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Email address',
                style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              AppInput(
                label: 'Email',
                hint: 'e.g. john@tweyonje.ug',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final pattern = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                  if (!pattern.hasMatch(v.trim())) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Phone number (optional)',
                style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              AppInput(
                label: 'Phone',
                hint: 'e.g. +256 700 000 000',
                controller: _phone,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Temporary password',
                style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              AppInput(
                label: 'Password',
                hint: '8+ characters — share it securely',
                controller: _password,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'At least 8 characters' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                'Role',
                style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                hint: const Text('Select role'),
                style: AppTypography.body,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(roleMeta(r).label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppButton(
                text: 'Create Account',
                icon: const Icon(Icons.check_rounded, size: 18),
                isLoading: state.isCreating,
                onPressed: state.isCreating ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}