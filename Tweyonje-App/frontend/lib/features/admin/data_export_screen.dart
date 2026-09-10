import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

enum ExportFormat {
  csv,
  json,
  pdf,
}

enum ExportDataType {
  users,
  wasteRequests,
  collections,
  reports,
  payments,
  verifications,
}

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Data Export'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _exportInfoCard(),
          const SizedBox(height: AppSpacing.xl),
          _DataTypeSelection(),
          const SizedBox(height: AppSpacing.xl),
          _FormatSelection(),
          const SizedBox(height: AppSpacing.xl),
          _DateRangeSelection(),
          const SizedBox(height: AppSpacing.xl),
          _ExportButton(),
        ],
      ),
    );
  }

  Widget _exportInfoCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(24),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.info,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Platform Data',
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the data type and format to export. Exported files can be used for analysis, reporting, or backup purposes.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataTypeSelection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Data Type',
          subtitle: 'Choose what data to export',
        ),
        const SizedBox(height: AppSpacing.md),
        _DataTypeOption(
          icon: Icons.people,
          label: 'Users',
          description: 'All registered users and their details',
          value: ExportDataType.users,
        ),
        _DataTypeOption(
          icon: Icons.delete_outline,
          label: 'Waste Requests',
          description: 'All waste collection requests',
          value: ExportDataType.wasteRequests,
        ),
        _DataTypeOption(
          icon: Icons.local_shipping,
          label: 'Collections',
          description: 'Collection assignments and completions',
          value: ExportDataType.collections,
        ),
        _DataTypeOption(
          icon: Icons.report,
          label: 'Reports',
          description: 'Illegal dumping reports',
          value: ExportDataType.reports,
        ),
        _DataTypeOption(
          icon: Icons.payments,
          label: 'Payments',
          description: 'Transaction records and payouts',
          value: ExportDataType.payments,
        ),
        _DataTypeOption(
          icon: Icons.verified_user,
          label: 'Verifications',
          description: 'Collector verification records',
          value: ExportDataType.verifications,
        ),
      ],
    );
  }
}

class _DataTypeOption extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String description;
  final ExportDataType value;

  const _DataTypeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_exportScreenProvider);
    final isSelected = state.selectedDataType == value;

    return InkWell(
      onTap: () {
        ref.read(_exportScreenProvider.notifier).setDataType(value);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: isSelected ? AppColors.primary.withAlpha(12) : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary 
                    : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                       color: isSelected ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              )
            else
              const Icon(
                Icons.radio_button_unchecked,
                color: AppColors.textTertiary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _FormatSelection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_exportScreenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Export Format',
          subtitle: 'Choose the file format',
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: ExportFormat.values.map((format) {
            final isSelected = state.selectedFormat == format;
            return Expanded(
              child: InkWell(
                onTap: () {
                  ref.read(_exportScreenProvider.notifier).setFormat(format);
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: format != ExportFormat.values.last 
                        ? AppSpacing.md 
                        : 0,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: isSelected 
                        ? AppColors.primary.withAlpha(12) 
                        : Colors.white,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getFormatIcon(format),
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        format.name.toUpperCase(),
                        style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getFormatDescription(format),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.json:
        return Icons.code;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'Spreadsheet compatible';
      case ExportFormat.json:
        return 'Developer friendly';
      case ExportFormat.pdf:
        return 'Print ready';
    }
  }
}

class _DateRangeSelection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_exportScreenProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Date Range',
          subtitle: 'Filter by date (optional)',
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.dateRange != null
                              ? '${DateFormat('MMM d, yyyy').format(state.dateRange!.start)} - ${DateFormat('MMM d, yyyy').format(state.dateRange!.end)}'
                              : 'All time',
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          state.dateRange != null
                              ? '${state.dateRange!.duration.inDays} days selected'
                              : 'No date filter applied',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.dateRange != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(_exportScreenProvider.notifier).clearDateRange();
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                text: state.dateRange != null ? 'Change Range' : 'Select Range',
                icon: const Icon(Icons.date_range, size: 16),
                onPressed: () => _selectDateRange(context, ref),
                variant: ButtonVariant.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: ref.read(_exportScreenProvider).dateRange ??
          DateTimeRange(start: lastMonth, end: now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(_exportScreenProvider.notifier).setDateRange(picked);
    }
  }
}

class _ExportButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_exportScreenProvider);

    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: 'Export Data',
        icon: const Icon(Icons.download, size: 18),
        onPressed: state.selectedDataType != null && !state.isExporting
            ? () {
                // Trigger export
                ref.read(_exportScreenProvider.notifier).export();
              }
            : null,
        isLoading: state.isExporting,
      ),
    );
  }
}

// State management for export screen
class _ExportScreenState {
  final ExportDataType? selectedDataType;
  final ExportFormat selectedFormat;
  final DateTimeRange? dateRange;
  final bool isExporting;

  _ExportScreenState({
    this.selectedDataType,
    this.selectedFormat = ExportFormat.csv,
    this.dateRange,
    this.isExporting = false,
  });

  _ExportScreenState copyWith({
    ExportDataType? selectedDataType,
    ExportFormat? selectedFormat,
    DateTimeRange? dateRange,
    bool? isExporting,
  }) {
    return _ExportScreenState(
      selectedDataType: selectedDataType ?? this.selectedDataType,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      dateRange: dateRange ?? this.dateRange,
      isExporting: isExporting ?? this.isExporting,
    );
  }
}

class _ExportScreenNotifier extends StateNotifier<_ExportScreenState> {
  _ExportScreenNotifier() : super(_ExportScreenState());

  void setDataType(ExportDataType type) {
    state = state.copyWith(selectedDataType: type);
  }

  void setFormat(ExportFormat format) {
    state = state.copyWith(selectedFormat: format);
  }

  void setDateRange(DateTimeRange range) {
    state = state.copyWith(dateRange: range);
  }

  void clearDateRange() {
    state = state.copyWith(dateRange: null);
  }

  void export() {
    state = state.copyWith(isExporting: true);
    // Simulate export
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(isExporting: false);
    });
  }
}

final _exportScreenProvider =
    StateNotifierProvider<_ExportScreenNotifier, _ExportScreenState>((ref) {
  return _ExportScreenNotifier();
});
