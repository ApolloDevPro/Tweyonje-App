import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/admin_provider.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class AdminZonesScreen extends ConsumerStatefulWidget {
  const AdminZonesScreen({super.key});

  @override
  ConsumerState<AdminZonesScreen> createState() => _AdminZonesScreenState();
}

class _AdminZonesScreenState extends ConsumerState<AdminZonesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(zoneAssignmentProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zoneAssignmentProvider);
    final collectors = ref
        .watch(adminUsersProvider)
        .value
        ?.where((u) => u.role == UserRole.collector)
        .toList() ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('zones.title'))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(zoneAssignmentProvider.notifier).fetch(),
        child: state.isLoading && state.zones.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  if (collectors.isEmpty) ...[
                    const EmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'No collectors found',
                      description: 'Create a collector account first, then assign a zone.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (state.zones.isEmpty) ...[
                    const EmptyState(
                      icon: Icons.place_outlined,
                      title: 'No zones created yet',
                      description: 'Zones are managed from the admin dashboard.',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  for (final zone in state.zones) ...[
                    _ZoneCard(zone: zone, collectors: collectors),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ZoneCard extends ConsumerStatefulWidget {
  final Zone zone;
  final List<User> collectors;

  const _ZoneCard({required this.zone, required this.collectors});

  @override
  ConsumerState<_ZoneCard> createState() => _ZoneCardState();
}

class _ZoneCardState extends ConsumerState<_ZoneCard> {
  int? _selectedCollector;
  bool _showPicker = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zoneAssignmentProvider);

    return AppCard(
      onTap: () => setState(() => _showPicker = !_showPicker),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.place_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.zone.name,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.zone.code}${widget.zone.region != null ? ' • ${widget.zone.region}' : ''}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.zone.isActive) ...[
                Text(
                  context.tr('common.inactive'),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                _showPicker ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          if (_showPicker) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('zones.selectCollector'),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int?>(
              initialValue: _selectedCollector,
              hint: Text(context.tr('zones.selectCollector')),
              items: widget.collectors
                  .map((c) => DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text('${c.fullName} (${c.email})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCollector = v),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.message != null) ...[
              Text(
                state.message!,
                style: AppTypography.bodySmall.copyWith(
                  color: state.isError ? AppColors.danger : AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppButton(
              text: context.tr('zones.assign'),
              isLoading: state.isAssigning,
              width: double.infinity,
              onPressed: _selectedCollector == null
                  ? null
                  : () => ref
                      .read(zoneAssignmentProvider.notifier)
                      .assignCollector(widget.zone.id, _selectedCollector!),
            ),
          ],
        ],
      ),
    );
  }
}