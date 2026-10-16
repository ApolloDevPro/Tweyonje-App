import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class VerificationsScreen extends ConsumerStatefulWidget {
  const VerificationsScreen({super.key});

  @override
  ConsumerState<VerificationsScreen> createState() =>
      _VerificationsScreenState();
}

class _VerificationsScreenState extends ConsumerState<VerificationsScreen> {
  String _selectedFilter = 'all';
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  String? get _apiStatus {
    switch (_selectedFilter) {
      case 'pending':
        return 'PENDING';
      case 'approved':
        return 'APPROVED';
      case 'rejected':
        return 'REJECTED';
      default:
        return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final res =
        await ref.read(apiClientProvider).getVerifications(status: _apiStatus);
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

  void _setFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _future = _fetch();
    });
  }

  Future<void> _act(
    String id, {
    required bool approve,
    String? notes,
  }) async {
    try {
      final res = approve
          ? await ref.read(apiClientProvider).approveVerification(id, notes: notes)
          : await ref.read(apiClientProvider).rejectVerification(id, notes: notes);
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? 'Verification approved successfully'
                  : 'Verification rejected',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        _refresh();
      } else {
        final data = res.data;
        final msg = data is Map && data['error'] is String
            ? data['error'] as String
            : 'Action failed. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collector Verifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildVerificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              isSelected: _selectedFilter == 'all',
              onTap: () => _setFilter('all'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Pending',
              isSelected: _selectedFilter == 'pending',
              onTap: () => _setFilter('pending'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Approved',
              isSelected: _selectedFilter == 'approved',
              onTap: () => _setFilter('approved'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Rejected',
              isSelected: _selectedFilter == 'rejected',
              onTap: () => _setFilter('rejected'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
                'Could not load verifications.',
                style: AppTypography.body,
              ),
            ),
          );
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.verified_user_outlined,
            title: 'No Verifications',
            description: 'Collector verification requests will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final v = items[index];
              final collector = v['collector_details'] is Map
                  ? Map<String, dynamic>.from(v['collector_details'])
                  : const <String, dynamic>{};
              return _VerificationCard(
                verification: {
                  'id': v['id']?.toString() ?? '',
                  'collector_name':
                      collector['full_name']?.toString() ?? 'Collector',
                  'collector_email': collector['email']?.toString() ?? '',
                  'national_id_number':
                      v['national_id_number']?.toString() ?? '—',
                  'status': v['status']?.toString() ?? 'PENDING',
                  'created_at': v['created_at']?.toString() ?? '',
                  'reviewer_notes': v['reviewer_notes']?.toString(),
                },
                onApprove: (notes) => _act(
                  v['id'].toString(),
                  approve: true,
                  notes: notes,
                ),
                onReject: (notes) => _act(
                  v['id'].toString(),
                  approve: false,
                  notes: notes,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withAlpha(24),
      labelStyle: AppTypography.label.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      checkmarkColor: AppColors.primary,
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> verification;
  final void Function(String? notes) onApprove;
  final void Function(String? notes) onReject;

  const _VerificationCard({
    required this.verification,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = verification['status']?.toString() ?? 'PENDING';
    final statusColor = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withAlpha(24),
                  child: Icon(_statusIcon(status), color: statusColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verification['collector_name']?.toString() ?? '—',
                        style: AppTypography.label
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        verification['collector_email']?.toString() ?? '',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _InfoItem(
                  icon: Icons.badge,
                  label: 'National ID',
                  value: verification['national_id_number']?.toString() ?? '—',
                ),
                const SizedBox(width: AppSpacing.lg),
                _InfoItem(
                  icon: Icons.calendar_today,
                  label: 'Submitted',
                  value: _formatDate(verification['created_at']?.toString()),
                ),
              ],
            ),
            if (status == 'PENDING') ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Approve',
                      icon: const Icon(Icons.check, size: 16),
                      onPressed: () => _showNotesDialog(
                        context,
                        title: 'Approve Verification',
                        confirmLabel: 'Approve',
                        onConfirm: onApprove,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      text: 'Reject',
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => _showNotesDialog(
                        context,
                        title: 'Reject Verification',
                        confirmLabel: 'Reject',
                        requireNotes: true,
                        onConfirm: onReject,
                      ),
                      variant: ButtonVariant.outline,
                    ),
                  ),
                ],
              ),
            ] else if (verification['reviewer_notes'] != null &&
                (verification['reviewer_notes']?.toString().isNotEmpty ??
                    false)) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Notes: ${verification['reviewer_notes']}',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNotesDialog(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required void Function(String? notes) onConfirm,
    bool requireNotes = false,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              requireNotes
                  ? 'Please provide a reason for rejection.'
                  : 'Notes (optional)',
              style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: requireNotes
                    ? 'Rejection reason...'
                    : 'Add any notes...',
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
            text: confirmLabel,
            onPressed: () {
              final notes = controller.text.trim();
              if (requireNotes && notes.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              onConfirm(notes.isEmpty ? null : notes);
            },
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return 'Unknown';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'APPROVED' => AppColors.success,
      'REJECTED' => AppColors.danger,
      _ => AppColors.warning,
    };
    final label = status[0] + status.substring(1).toLowerCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            Text(
              value,
              style:
                  AppTypography.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
