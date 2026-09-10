import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Settings'),
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
          _SettingsSection(
            title: 'Collection Settings',
            icon: Icons.delete_outline,
            children: [
              _SettingItem(
                label: 'Minimum Weight for Pickup',
                value: '0.5 kg',
                onTap: () => _editSetting('collection.min_weight_kg', '0.5'),
              ),
              _SettingItem(
                label: 'Max Emergency Distance',
                value: '50 km',
                onTap: () => _editSetting('collection.max_emergency_distance_km', '50'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsSection(
            title: 'Rewards Settings',
            icon: Icons.card_giftcard,
            children: [
              _SettingItem(
                label: 'Points for Report',
                value: '25 points',
                onTap: () => _editSetting('rewards.report_points', '25'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsSection(
            title: 'Platform Settings',
            icon: Icons.settings,
            children: [
              _SettingItem(
                label: 'Platform Version',
                value: '1.0.0',
                onTap: () => _editSetting('platform.version', '1.0.0'),
              ),
              _SettingItem(
                label: 'Support Email',
                value: 'support@tweyonje.ug',
                onTap: () => _editSetting('platform.support_email', 'support@tweyonje.ug'),
              ),
              _SettingItem(
                label: 'Support Phone',
                value: '+256 700 000 000',
                onTap: () => _editSetting('platform.support_phone', '+256 700 000 000'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsSection(
            title: 'Security Settings',
            icon: Icons.security,
            children: [
              _SettingItem(
                label: 'OTP Debug Echo',
                value: 'Disabled',
                onTap: () => _toggleSetting('OTP_DEBUG_ECHO'),
                isToggle: true,
                isEnabled: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsSection(
            title: 'Rate Limiting',
            icon: Icons.speed,
            children: [
              _SettingItem(
                label: 'Auth Login',
                value: '10/min',
                onTap: () => _editSetting('THROTTLE_AUTH_LOGIN', '10/min'),
              ),
              _SettingItem(
                label: 'OTP Send',
                value: '5/min',
                onTap: () => _editSetting('THROTTLE_OTP_SEND', '5/min'),
              ),
              _SettingItem(
                label: 'OTP Verify',
                value: '10/min',
                onTap: () => _editSetting('THROTTLE_OTP_VERIFY', '10/min'),
              ),
              _SettingItem(
                label: 'AI Classify',
                value: '10/min',
                onTap: () => _editSetting('THROTTLE_AI_CLASSIFY', '10/min'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _refresh() {
    // Refresh settings
  }

  void _editSetting(String key, String currentValue) {
    showDialog(
      context: context,
      builder: (context) => _EditSettingDialog(
        settingKey: key,
        currentValue: currentValue,
        onSave: (newValue) {
          Navigator.pop(context);
          _showSuccessSnackBar('Setting updated successfully');
        },
      ),
    );
  }

  void _toggleSetting(String key) {
    // Toggle boolean setting
    _showSuccessSnackBar('Setting toggled');
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

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

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
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                title,
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isToggle;
  final bool isEnabled;

  const _SettingItem({
    required this.label,
    required this.value,
    required this.onTap,
    this.isToggle = false,
    this.isEnabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isToggle)
              Switch(
                value: isEnabled,
                onChanged: (_) => onTap(),
                activeThumbColor: AppColors.primary,
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

class _EditSettingDialog extends StatefulWidget {
  final String settingKey;
  final String currentValue;
  final Function(String) onSave;

  const _EditSettingDialog({
    required this.settingKey,
    required this.currentValue,
    required this.onSave,
  });

  @override
  State<_EditSettingDialog> createState() => _EditSettingDialogState();
}

class _EditSettingDialogState extends State<_EditSettingDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.settingKey}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.settingKey,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Enter new value',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: 'Save',
          onPressed: () {
            if (_controller.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Value cannot be empty'),
                  backgroundColor: AppColors.danger,
                ),
              );
              return;
            }
            widget.onSave(_controller.text.trim());
          },
        ),
      ],
    );
  }
}
