import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/biometric_service.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final biometric = ref.read(biometricServiceProvider);
    final storage = LocalStorage();
    final enabled = await biometric.isBiometricEnabled();
    final notifications = await storage.isNotificationsEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _notificationsEnabled = notifications;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final biometric = ref.read(biometricServiceProvider);
    if (value) {
      final available = await biometric.isBiometricAvailable();
      if (!available) {
        _showSnackBar(
          'Biometric authentication is not available on this device',
        );
        return;
      }
      final authenticated = await biometric.authenticate(
        reason: 'Enable biometric sign-in',
      );
      if (!authenticated) {
        _showSnackBar('Biometric authentication failed, please try again');
        return;
      }
      await biometric.enableBiometric();
      setState(() => _biometricEnabled = true);
      _showSnackBar('Biometric authentication enabled');
    } else {
      await biometric.disableBiometric();
      setState(() => _biometricEnabled = false);
      _showSnackBar('Biometric authentication disabled');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final storage = LocalStorage();
    await storage.setNotificationsEnabled(value);
    setState(() => _notificationsEnabled = value);
    _showSnackBar(
      value ? 'Push notifications enabled' : 'Push notifications disabled',
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Profile Header Card
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U',
                    style: AppTypography.h2.copyWith(color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Tweyonje User',
                        style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: AppTypography.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          user?.role.value ?? 'RESIDENT',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditProfileModal(context, ref, user),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Preferences', style: AppTypography.h5),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_outlined, color: AppColors.primary),
                  title: const Text('Language & Appearance'),
                  subtitle: const Text('Dark mode, English / Luganda / Swahili'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.fingerprint, color: AppColors.primary),
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Touch ID / Face ID quick sign-in'),
                  trailing: Switch(
                    value: _biometricEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: _toggleBiometric,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Pickup arrivals, SLA alerts, payments'),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: _toggleNotifications,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('Legal & Support', style: AppTypography.h5),
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.textSecondary),
                  title: const Text('Help & Support Desk'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/support'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.textSecondary),
                  title: const Text('Privacy Policy & Terms'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/privacy-policy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          AppButton(
            text: 'Sign Out',
            variant: ButtonVariant.outline,
            icon: const Icon(Icons.logout, color: AppColors.primary, size: 20),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileModal(BuildContext context, WidgetRef ref, user) {
    final fullNameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit Profile', style: AppTypography.h4),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'Full Name',
                hint: 'Enter your full name',
                controller: fullNameController,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInput(
                label: 'Phone Number',
                hint: '+256 7XX XXX XXX',
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: isSaving ? 'Saving...' : 'Save Changes',
                isLoading: isSaving,
                onPressed: isSaving
                    ? null
                    : () async {
                        if (fullNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter your full name')),
                          );
                          return;
                        }
                        setModalState(() => isSaving = true);
                        try {
                          final success = await ref.read(authServiceProvider).updateProfile(
                            fullName: fullNameController.text.trim(),
                            phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                          );
                          if (success && ctx.mounted) {
                            Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } else if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update profile'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        } finally {
                          if (ctx.mounted) {
                            setModalState(() => isSaving = false);
                          }
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
