import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final res = await ref.read(apiClientProvider).getSystemSettings();
    if (res.statusCode == 200) {
      final List results =
          res.data is List ? res.data : (res.data['results'] ?? []);
      return results.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  void _refresh() {
    setState(() => _future = _fetch());
  }

  Future<void> _saveSetting(Map<String, dynamic> setting, String newValue) async {
    final id = setting['id']?.toString();
    if (id == null) return;
    try {
      final res = await ref
          .read(apiClientProvider)
          .updateSystemSetting(id, {'value': newValue});
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setting updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _refresh();
      } else {
        final data = res.data;
        final msg = data is Map && data['detail'] is String
            ? data['detail'] as String
            : 'Failed to update setting.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = data is Map && data['detail'] is String
          ? data['detail'] as String
          : 'Network error. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  IconData _iconForKey(String key) {
    final k = key.toLowerCase();
    if (k.contains('reward') || k.contains('point')) {
      return Icons.card_giftcard;
    }
    if (k.contains('otp') || k.contains('throttle') || k.contains('rate')) {
      return Icons.security;
    }
    if (k.contains('support') || k.contains('platform')) {
      return Icons.settings;
    }
    if (k.contains('collection') || k.contains('weight') || k.contains('pickup')) {
      return Icons.delete_outline;
    }
    return Icons.tune;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Could not load settings.',
                  style: AppTypography.body,
                ),
              ),
            );
          }
          final settings = snapshot.data ?? const [];
          if (settings.isEmpty) {
            return const EmptyState(
              icon: Icons.settings_outlined,
              title: 'No Settings Found',
              description:
                  'System settings configured by administrators will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: settings.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final s = settings[index];
                final key = s['key']?.toString() ?? '—';
                final value = s['value']?.toString() ?? '';
                final description = s['description']?.toString();
                return AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(24),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        _iconForKey(key),
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      key,
                      style: AppTypography.label
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value.isEmpty ? '(empty)' : value,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (description != null && description.isNotEmpty)
                          Text(
                            description,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.edit_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => _editSetting(s),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _editSetting(Map<String, dynamic> setting) {
    final key = setting['key']?.toString() ?? 'Setting';
    final currentValue = setting['value']?.toString() ?? '';
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Setting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              key,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              maxLines: 3,
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Save',
            onPressed: () {
              final newValue = controller.text.trim();
              if (newValue.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Value cannot be empty'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              _saveSetting(setting, newValue);
            },
          ),
        ],
      ),
    );
  }
}
