import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() =>
      _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  late Future<(List<Map<String, dynamic>>, Map<String, dynamic>?)> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<(List<Map<String, dynamic>>, Map<String, dynamic>?)> _fetch() async {
    final api = ref.read(apiClientProvider);
    List<Map<String, dynamic>> policies = [];
    Map<String, dynamic>? reconsent;

    try {
      final res = await api.getPrivacyPolicies();
      if (res.statusCode == 200) {
        final List results =
            res.data is List ? res.data : (res.data['results'] ?? []);
        policies = results.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}

    try {
      final res = await api.getNeedsReconsent();
      if (res.statusCode == 200 && res.data is Map) {
        reconsent = Map<String, dynamic>.from(res.data);
      }
    } catch (_) {}

    return (policies, reconsent);
  }

  void _refresh() {
    setState(() => _future = _fetch());
  }

  Future<void> _publish(
    String version,
    String title,
    String content,
  ) async {
    try {
      final res = await ref.read(apiClientProvider).publishPrivacyPolicy({
        'version': version,
        'title': title,
        'content': content,
      });
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Policy published successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _refresh();
      } else {
        final data = res.data;
        String msg = 'Failed to publish policy.';
        if (data is Map) {
          if (data['error'] is String) msg = data['error'] as String;
          if (data['version'] is List) {
            msg = 'Version: ${(data['version'] as List).join(', ')}';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = data is Map && data['error'] is String
          ? data['error'] as String
          : 'Network error. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showPublishDialog() {
    final versionController = TextEditingController();
    final titleController = TextEditingController(text: 'Tweyonje Privacy Policy');
    final contentController = TextEditingController();
    bool publishing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
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
                      style: AppTypography.h4
                          .copyWith(fontWeight: FontWeight.w700),
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
                          style: AppTypography.label
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: versionController,
                          decoration: InputDecoration(
                            hintText: 'e.g., 1.1.0',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Title',
                          style: AppTypography.label
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Policy title',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Content',
                          style: AppTypography.label
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: contentController,
                          maxLines: 10,
                          decoration: InputDecoration(
                            hintText: 'Enter privacy policy content...',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
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
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    AppButton(
                      text: publishing ? 'Publishing...' : 'Publish',
                      isLoading: publishing,
                      onPressed: publishing
                          ? null
                          : () {
                              final version = versionController.text.trim();
                              final title = titleController.text.trim();
                              final content = contentController.text.trim();
                              if (version.isEmpty || content.isEmpty) {
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please fill in all required fields'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                                return;
                              }
                              setDialogState(() => publishing = true);
                              _publish(version, title, content).then((_) {
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              });
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewContent(String version, String title, String content) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$title (v$version)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(content, style: AppTypography.body),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<(List<Map<String, dynamic>>, Map<String, dynamic>?)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          final policies = data?.$1 ?? const <Map<String, dynamic>>[];
          final reconsent = data?.$2;
          final active = policies.cast<Map<String, dynamic>?>().firstWhere(
                (p) => p?['is_active'] == true,
                orElse: () => null,
              );

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (active != null
                                    ? AppColors.success
                                    : AppColors.warning)
                                .withAlpha(24),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            active != null
                                ? Icons.check_circle
                                : Icons.warning_amber,
                            color: active != null
                                ? AppColors.success
                                : AppColors.warning,
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
                                style: AppTypography.h5
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                active != null
                                    ? 'Version ${active['version']}'
                                    : 'No active policy',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (active != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        active['title']?.toString() ?? '',
                        style: AppTypography.label
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        (active['content']?.toString() ?? '').isEmpty
                            ? 'No content'
                            : '${active['content'].toString().length} characters',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        text: 'View Active Policy',
                        icon: const Icon(Icons.visibility, size: 16),
                        onPressed: () => _viewContent(
                          active['version']?.toString() ?? '',
                          active['title']?.toString() ?? 'Privacy Policy',
                          active['content']?.toString() ?? '',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (reconsent != null) ...[
                AppCard(
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
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
                                  style: AppTypography.h5
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${reconsent['total_pending_count'] ?? 0} users need to accept policy v${reconsent['active_policy_version'] ?? '—'}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              SectionHeader(
                title: 'Policy History',
                subtitle: '${policies.length} versions',
              ),
              const SizedBox(height: AppSpacing.md),
              if (policies.isEmpty)
                const EmptyState(
                  icon: Icons.policy_outlined,
                  title: 'No Policies Yet',
                  description: 'Published policies will appear here.',
                )
              else
                ...policies.map((p) {
                  final isActive = p['is_active'] == true;
                  final publishedAt = p['published_at']?.toString();
                  String formatted = '';
                  if (publishedAt != null) {
                    try {
                      formatted = DateFormat('MMM d, yyyy')
                          .format(DateTime.parse(publishedAt));
                    } catch (_) {}
                  }
                  return InkWell(
                    onTap: () => _viewContent(
                      p['version']?.toString() ?? '',
                      p['title']?.toString() ?? 'Privacy Policy',
                      p['content']?.toString() ?? '',
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isActive ? AppColors.primary : AppColors.border,
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Center(
                              child: Text(
                                p['version']?.toString() ?? '—',
                                style: AppTypography.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
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
                                  p['title']?.toString() ?? 'Privacy Policy',
                                  style: AppTypography.label
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatted.isEmpty
                                      ? 'Published'
                                      : 'Published $formatted',
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
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
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
                }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPublishDialog,
        icon: const Icon(Icons.publish),
        label: const Text('Publish New Policy'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
