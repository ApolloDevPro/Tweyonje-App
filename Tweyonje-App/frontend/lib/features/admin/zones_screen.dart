import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class ZonesScreen extends ConsumerStatefulWidget {
  const ZonesScreen({super.key});

  @override
  ConsumerState<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends ConsumerState<ZonesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Zone Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsRow(),
          Expanded(
            child: _buildZonesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddZoneDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Zone'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.map,
              label: 'Total Zones',
              value: '8',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle,
              label: 'Active',
              value: '7',
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _StatCard(
              icon: Icons.block,
              label: 'Inactive',
              value: '1',
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 8,
      itemBuilder: (context, index) {
        return _ZoneCard(
          zone: _mockZone(index),
          onEdit: () => _editZone(_mockZone(index)),
          onToggle: () => _toggleZone(_mockZone(index)),
        );
      },
    );
  }

  void _refresh() {
    // Refresh zones list
  }

  void _showAddZoneDialog() {
    showDialog(
      context: context,
      builder: (context) => _ZoneDialog(
        onSave: () {
          Navigator.pop(context);
          _showSuccessSnackBar('Zone added successfully');
        },
      ),
    );
  }

  void _editZone(Zone zone) {
    showDialog(
      context: context,
      builder: (context) => _ZoneDialog(
        zone: zone,
        onSave: () {
          Navigator.pop(context);
          _showSuccessSnackBar('Zone updated successfully');
        },
      ),
    );
  }

  void _toggleZone(Zone zone) {
    _showSuccessSnackBar('Zone ${zone.isActive ? 'deactivated' : 'activated'}');
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

  Zone _mockZone(int index) {
    final zones = [
      ('KLA-C', 'Kampala Central', 'Kampala', true),
      ('KLA-K', 'Kawempe', 'Kampala', true),
      ('KLA-M', 'Makindye', 'Kampala', true),
      ('KLA-N', 'Nakawa', 'Kampala', true),
      ('KLA-R', 'Rubaga', 'Kampala', true),
      ('ENT-1', 'Entebbe', 'Wakiso', true),
      ('MUK-1', 'Mukono Central', 'Mukono', true),
      ('GUL-1', 'Gulu City', 'Gulu', false),
    ];
    final zone = zones[index];
    return Zone(
      id: index,
      code: zone.$1,
      name: zone.$2,
      region: zone.$3,
      isActive: zone.$4,
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final Zone zone;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _ZoneCard({
    required this.zone,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: zone.isActive
                  ? AppColors.success.withAlpha(24)
                  : AppColors.danger.withAlpha(24),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text(
                zone.code,
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: zone.isActive ? AppColors.success : AppColors.danger,
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
                  zone.name,
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  zone.region,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(isActive: zone.isActive),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: onEdit,
            color: AppColors.textSecondary,
          ),
          Switch(
            value: zone.isActive,
            onChanged: (_) => onToggle(),
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withAlpha(24)
            : AppColors.danger.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: AppTypography.labelSmall.copyWith(
          color: isActive ? AppColors.success : AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ZoneDialog extends StatefulWidget {
  final Zone? zone;
  final VoidCallback onSave;

  const _ZoneDialog({
    this.zone,
    required this.onSave,
  });

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _regionController;
  late final TextEditingController _descriptionController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.zone?.code ?? '');
    _nameController = TextEditingController(text: widget.zone?.name ?? '');
    _regionController = TextEditingController(text: widget.zone?.region ?? '');
    _descriptionController = TextEditingController(text: widget.zone?.description ?? '');
    _isActive = widget.zone?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _regionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.zone != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.add_location,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  isEditing ? 'Edit Zone' : 'Add New Zone',
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone Code',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'e.g., KLA-C',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Zone Name',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Kampala Central',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Region',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _regionController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Kampala',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Description (Optional)',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Zone description...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Switch(
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        activeThumbColor: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Active',
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
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
                  text: isEditing ? 'Update' : 'Create',
                  onPressed: () {
                    if (_codeController.text.trim().isEmpty ||
                        _nameController.text.trim().isEmpty ||
                        _regionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                      return;
                    }
                    widget.onSave();
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

// Mock model for Zone
class Zone {
  final int id;
  final String code;
  final String name;
  final String region;
  final bool isActive;
  final String? description;

  Zone({
    required this.id,
    required this.code,
    required this.name,
    required this.region,
    required this.isActive,
    this.description,
  });
}
