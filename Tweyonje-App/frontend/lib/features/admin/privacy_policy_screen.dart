import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _ActivePolicyCard(),
          const SizedBox(height: AppSpacing.xl),
          _PolicyHistorySection(),
          const SizedBox(height: AppSpacing.xl),
          _ReconsentSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPublishDialog(),
        icon: const Icon(Icons.publish),
        label: const Text('Publish New Policy'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _refresh() {
    // Refresh policies
  }

  void _showPublishDialog() {
    showDialog(
      context: context,
      builder: (context) => _PublishPolicyDialog(
        onPublish: () {
          Navigator.pop(context);
          _showSuccessSnackBar('Policy published successfully');
        },
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ActivePolicyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Policy',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'ACTIVE',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _StatItem(
                icon: Icons.people,
                label: 'Total Users',
                value: '1,234',
              ),
              const SizedBox(width: AppSpacing.xl),
              _StatItem(
                icon: Icons.check,
                label: 'Consented',
                value: '1,180',
              ),
              const SizedBox(width: AppSpacing.xl),
              _StatItem(
                icon: Icons.pending,
                label: 'Pending',
                value: '54',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'View Active Policy',
            icon: const Icon(Icons.visibility, size: 16),
            onPressed: () => _viewPolicy('1.0.0'),
            variant: ButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  void _viewPolicy(String version) {
    // View policy details
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyHistorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Policy History',
          subtitle: 'Previous versions',
        ),
        const SizedBox(height: AppSpacing.md),
        _PolicyHistoryItem(
          version: '1.0.0',
          title: 'Tweyonje Privacy Policy',
          publishedAt: 'Jan 15, 2024',
          isActive: true,
          onTap: () {},
        ),
        _PolicyHistoryItem(
          version: '0.9.0',
          title: 'Tweyonje Privacy Policy',
          publishedAt: 'Dec 1, 2023',
          isActive: false,
          onTap: () {},
        ),
        _PolicyHistoryItem(
          version: '0.8.0',
          title: 'Tweyonje Privacy Policy',
          publishedAt: 'Nov 15, 2023',
          isActive: false,
          onTap: () {},
        ),
      ],
    );
  }
}

class _PolicyHistoryItem extends StatelessWidget {
  final String version;
  final String title;
  final String publishedAt;
  final bool isActive;
  final VoidCallback onTap;

  const _PolicyHistoryItem({
    required this.version,
    required this.title,
    required this.publishedAt,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withAlpha(24)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(
                  version,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Published $publishedAt',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Active',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}

class _ReconsentSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      border: Border.all(color: AppColors.warning, width: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.warning,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Re-consent',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '54 users need to accept the latest policy',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'View Pending Users',
                  icon: const Icon(Icons.people, size: 16),
                  onPressed: () {},
                  variant: ButtonVariant.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  text: 'Send Reminder',
                  icon: const Icon(Icons.notifications_active, size: 16),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PublishPolicyDialog extends StatefulWidget {
  final VoidCallback onPublish;

  const _PublishPolicyDialog({required this.onPublish});

  @override
  State<_PublishPolicyDialog> createState() => _PublishPolicyDialogState();
}

class _PublishPolicyDialogState extends State<_PublishPolicyDialog> {
  final _versionController = TextEditingController();
  final _titleController = TextEditingController(text: 'Tweyonje Privacy Policy');
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _versionController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.publish, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Publish New Privacy Policy',
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _versionController,
                      decoration: InputDecoration(
                        hintText: 'e.g., 1.1.0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Title',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Policy title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Content',
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _contentController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText: 'Enter privacy policy content...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                AppButton(
                  text: 'Publish',
                  onPressed: () {
                    if (_versionController.text.trim().isEmpty ||
                        _contentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }
                    widget.onPublish();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
