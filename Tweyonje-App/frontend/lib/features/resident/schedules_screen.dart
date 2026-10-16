import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/service_controllers.dart';
import '../../providers/waste_request_provider.dart';
import '../../widgets/widgets.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleProvider.notifier).fetch(silent: true);
    });
  }

  Future<void> _openCreateBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreateScheduleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('schedules.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateBottomSheet,
        icon: const Icon(Icons.event_available_outlined),
        label: Text(context.tr('schedules.add')),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(scheduleProvider.notifier).fetch(silent: false),
        child: scheduleState.isLoading && scheduleState.schedules.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : scheduleState.schedules.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.event_repeat_rounded,
                        title: context.tr('schedules.emptyTitle'),
                        description: context.tr('schedules.emptyDesc'),
                        actionText: context.tr('schedules.add'),
                        onAction: _openCreateBottomSheet,
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ResponsiveContent(
                      child: ResponsiveWrap(
                        minItemWidth: 380,
                        runSpacing: 10,
                        children: scheduleState.schedules.map((schedule) {
                          return _ScheduleCard(
                            schedule: schedule,
                            onToggle: () async {
                              final error = await ref
                                  .read(scheduleProvider.notifier)
                                  .toggle(schedule.id);
                              if (error != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final RecurringSchedule schedule;
  final VoidCallback onToggle;

  const _ScheduleCard({required this.schedule, required this.onToggle});

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final weekday = schedule.preferredWeekday != null &&
            schedule.preferredWeekday! >= 1 &&
            schedule.preferredWeekday! <= 7
        ? _weekdays[schedule.preferredWeekday! - 1]
        : 'Weekly';

    return AppCard(
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
                child: const Icon(
                  Icons.event_repeat_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.categoryName ?? schedule.category,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_frequencyLabel(schedule.frequency)} • $weekday'
                      '${schedule.preferredTime != null ? ' • ${schedule.preferredTime}' : ''}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: schedule.isActive,
                onChanged: (_) => onToggle(),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  schedule.address,
                  style: AppTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (schedule.nextRun != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.notifications_active_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Next: ${schedule.nextRun}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _frequencyLabel(String frequency) {
    switch (frequency.toUpperCase()) {
      case 'DAILY':
        return 'Daily';
      case 'BIWEEKLY':
        return 'Every 2 weeks';
      case 'MONTHLY':
        return 'Monthly';
      default:
        return 'Weekly';
    }
  }
}

class _CreateScheduleSheet extends ConsumerStatefulWidget {
  const _CreateScheduleSheet();

  @override
  ConsumerState<_CreateScheduleSheet> createState() =>
      _CreateScheduleSheetState();
}

class _CreateScheduleSheetState extends ConsumerState<_CreateScheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String _category = 'MIXED';
  String _frequency = 'WEEKLY';
  int _weekday = 1;
  String _time = '08:00';

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(wasteCategoriesProvider).value ??
        <WasteCategory>[
          WasteCategory(
            id: 'MIXED',
            name: 'Mixed Waste',
            slug: 'mixed',
            description: 'Mixed household waste',
          ),
        ];
    final scheduleState = ref.watch(scheduleProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('schedules.add'),
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'MIXED'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _frequency,
                decoration:
                    InputDecoration(labelText: context.tr('schedules.frequency')),
                items: [
                  const DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                  const DropdownMenuItem(
                    value: 'BIWEEKLY',
                    child: Text('Every 2 weeks'),
                  ),
                  const DropdownMenuItem(
                    value: 'MONTHLY',
                    child: Text('Monthly'),
                  ),
                ],
                onChanged: (v) => setState(() => _frequency = v ?? 'WEEKLY'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _weekday,
                      decoration:
                          InputDecoration(labelText: context.tr('schedules.weekday')),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Monday')),
                        DropdownMenuItem(value: 2, child: Text('Tuesday')),
                        DropdownMenuItem(value: 3, child: Text('Wednesday')),
                        DropdownMenuItem(value: 4, child: Text('Thursday')),
                        DropdownMenuItem(value: 5, child: Text('Friday')),
                        DropdownMenuItem(value: 6, child: Text('Saturday')),
                        DropdownMenuItem(value: 7, child: Text('Sunday')),
                      ],
                      onChanged: (v) => setState(() => _weekday = v ?? 1),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _time,
                      decoration:
                          InputDecoration(labelText: context.tr('schedules.time')),
                      items: [
                        for (var h = 6; h <= 19; h++)
                          DropdownMenuItem(
                            value: '${h.toString().padLeft(2, '0')}:00',
                            child: Text('${h.toString().padLeft(2, '0')}:00'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _time = v ?? '08:00'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _addressController,
                decoration:
                    InputDecoration(labelText: context.tr('schedules.address')),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Address is required' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (scheduleState.message != null) ...[
                Text(
                  scheduleState.message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: scheduleState.isError
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppButton(
                text: context.tr('common.save'),
                isLoading: scheduleState.isCreating,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(scheduleProvider.notifier).create({
      'category': _category,
      'frequency': _frequency,
      'preferred_weekday': _weekday,
      'preferred_time': _time,
      'address': _addressController.text.trim(),
    });
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}