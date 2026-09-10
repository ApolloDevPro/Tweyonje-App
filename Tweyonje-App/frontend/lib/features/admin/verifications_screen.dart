import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class VerificationsScreen extends ConsumerStatefulWidget {
  const VerificationsScreen({super.key});

  @override
  ConsumerState<VerificationsScreen> createState() => _VerificationsScreenState();
}

class _VerificationsScreenState extends ConsumerState<VerificationsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Collector Verifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
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
              onTap: () => setState(() => _selectedFilter = 'all'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Pending',
              isSelected: _selectedFilter == 'pending',
              onTap: () => setState(() => _selectedFilter = 'pending'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Approved',
              isSelected: _selectedFilter == 'approved',
              onTap: () => setState(() => _selectedFilter = 'approved'),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: 'Rejected',
              isSelected: _selectedFilter == 'rejected',
              onTap: () => setState(() => _selectedFilter = 'rejected'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationsList() {
    // This would fetch from API - for now showing placeholder
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _VerificationCard(
          verification: _mockVerification(index),
          onApprove: () => _approveVerification(_mockVerification(index).id),
          onReject: () => _rejectVerification(_mockVerification(index).id),
          onView: () => _viewVerification(_mockVerification(index)),
        );
      },
    );
  }

  void _refresh() {
    // Refresh verifications list
  }

  void _approveVerification(String id) {
    showDialog(
      context: context,
      builder: (context) => _ApprovalDialog(
        verificationId: id,
        onConfirm: () {
          Navigator.pop(context);
          _showSuccessSnackBar('Verification approved successfully');
        },
      ),
    );
  }

  void _rejectVerification(String id) {
    showDialog(
      context: context,
      builder: (context) => _RejectionDialog(
        verificationId: id,
        onConfirm: () {
          Navigator.pop(context);
          _showSuccessSnackBar('Verification rejected');
        },
      ),
    );
  }

  void _viewVerification(CollectorVerification verification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerificationDetailScreen(verification: verification),
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

  CollectorVerification _mockVerification(int index) {
    final statuses = ['PENDING', 'APPROVED', 'REJECTED'];
    return CollectorVerification(
      id: 'ver_$index',
      collectorId: index,
      collectorEmail: 'collector$index@tweyonje.ug',
      collectorName: 'Collector $index',
      nationalIdNumber: 'CM123456789',
      status: statuses[index % 3],
      createdAt: DateTime.now().subtract(Duration(days: index)).toIso8601String(),
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
  final CollectorVerification verification;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onView;

  const _VerificationCard({
    required this.verification,
    required this.onApprove,
    required this.onReject,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(verification.status);
    final statusIcon = _getStatusIcon(verification.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withAlpha(24),
                child: Icon(statusIcon, color: statusColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verification.collectorName,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      verification.collectorEmail,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              _StatusChip(status: verification.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _InfoItem(
                icon: Icons.badge,
                label: 'ID',
                value: verification.nationalIdNumber,
              ),
              const SizedBox(width: AppSpacing.lg),
              _InfoItem(
                icon: Icons.calendar_today,
                label: 'Submitted',
                value: _formatDate(verification.createdAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              if (verification.status == 'PENDING') ...[
                Expanded(
                  child: AppButton(
                    text: 'Approve',
                    icon: const Icon(Icons.check, size: 16),
                    onPressed: onApprove,
                     variant: ButtonVariant.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    text: 'Reject',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onReject,
                     variant: ButtonVariant.outline,
                  ),
                ),
              ],
              Expanded(
                child: AppButton(
                  text: 'View Details',
                  icon: const Icon(Icons.visibility, size: 16),
                  onPressed: onView,
                  variant: ButtonVariant.ghost,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
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
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ApprovalDialog extends StatefulWidget {
  final String verificationId;
  final VoidCallback onConfirm;

  const _ApprovalDialog({
    required this.verificationId,
    required this.onConfirm,
  });

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approve Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to approve this collector verification?',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Notes (optional)',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any notes about this approval...',
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
          text: 'Approve',
          onPressed: () {
            // Call API to approve
            widget.onConfirm();
          },
        ),
      ],
    );
  }
}

class _RejectionDialog extends StatefulWidget {
  final String verificationId;
  final VoidCallback onConfirm;

  const _RejectionDialog({
    required this.verificationId,
    required this.onConfirm,
  });

  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to reject this collector verification?',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Rejection Reason',
            style: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Please provide a reason for rejection...',
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
          text: 'Reject',
          onPressed: () {
            if (_reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please provide a rejection reason'),
                  backgroundColor: AppColors.danger,
                ),
              );
              return;
            }
            // Call API to reject
            widget.onConfirm();
          },
          variant: ButtonVariant.outline,
        ),
      ],
    );
  }
}

class VerificationDetailScreen extends StatelessWidget {
  final CollectorVerification verification;

  const VerificationDetailScreen({super.key, required this.verification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verification Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(
              title: 'Collector Information',
              children: [
                _DetailRow(
                  label: 'Name',
                  value: verification.collectorName,
                ),
                _DetailRow(
                  label: 'Email',
                  value: verification.collectorEmail,
                ),
                _DetailRow(
                  label: 'National ID',
                  value: verification.nationalIdNumber,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _Section(
              title: 'Documents',
              children: [
                _DocumentItem(
                  label: 'National ID Photo',
                  icon: Icons.badge,
                  onTap: () {},
                ),
                _DocumentItem(
                  label: 'Driving License',
                  icon: Icons.drive_eta,
                  onTap: () {},
                ),
                _DocumentItem(
                  label: 'Vehicle Logbook',
                  icon: Icons.directions_car,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _Section(
              title: 'Verification Status',
              children: [
                _DetailRow(
                  label: 'Status',
                  value: verification.status,
                  valueColor: _getStatusColor(verification.status),
                ),
                _DetailRow(
                  label: 'Submitted On',
                  value: _formatDate(verification.createdAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DocumentItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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

// Mock model for verification
class CollectorVerification {
  final String id;
  final int collectorId;
  final String collectorEmail;
  final String collectorName;
  final String nationalIdNumber;
  final String status;
  final String createdAt;

  CollectorVerification({
    required this.id,
    required this.collectorId,
    required this.collectorEmail,
    required this.collectorName,
    required this.nationalIdNumber,
    required this.status,
    required this.createdAt,
  });
}
