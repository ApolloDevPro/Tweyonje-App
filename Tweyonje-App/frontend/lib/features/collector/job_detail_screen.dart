import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/collector_provider.dart';
import '../../widgets/widgets.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;
  final CollectorJob? initialJob;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    this.initialJob,
  });

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  late String _status;
  final _weightController = TextEditingController(text: '12.5');
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialJob?.status ?? 'ASSIGNED';
  }

  Future<void> _advanceStatus() async {
    final notifier = ref.read(collectorDashboardProvider.notifier);
    setState(() => _isUpdating = true);

    String? error;
    String? nextStatus;
    if (_status == 'ASSIGNED') {
      nextStatus = 'EN_ROUTE';
      error = await notifier.startTrip(widget.jobId);
    } else if (_status == 'EN_ROUTE') {
      nextStatus = 'ARRIVED';
      error = await notifier.arrive(widget.jobId);
    } else if (_status == 'ARRIVED') {
      nextStatus = 'COLLECTED';
      final weight = double.tryParse(_weightController.text.trim());
      error = await notifier.complete(
        widget.jobId,
        collectedWeightKg: weight,
      );
    }

    setState(() => _isUpdating = false);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (nextStatus != null) {
      setState(() => _status = nextStatus!);
      if (nextStatus == 'COLLECTED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job completed and marked collected!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.initialJob;
    final lat = job?.latitude ?? 0.3476;
    final lng = job?.longitude ?? 32.5825;

    return Scaffold(
      appBar: AppBar(
        title: Text(job?.reference ?? 'Collection Job'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Reference
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(job?.category ?? 'General Waste', style: AppTypography.h4),
                StatusBadge(status: _status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Navigation Map
            SizedBox(
              height: 220,
              child: AppMap(
                initialLat: lat,
                initialLng: lng,
                initialZoom: 15,
                markers: [
                  AppMapMarker(latitude: lat, longitude: lng, title: 'Pickup Location', color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Location details card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pickup Address', style: AppTypography.caption),
                  const SizedBox(height: 2),
                  Text(
                    job?.address ?? 'Plot 4A, Lumumba Avenue, Kampala',
                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: const Text('Start Navigation'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Collected Weight verification (visible when arrived)
            if (_status == 'ARRIVED' || _status == 'COLLECTED') ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verify Actual Weight (kg)', style: AppTypography.label),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        suffixText: 'kg',
                        hintText: 'Enter scale weight',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Action Button Based on Status
            if (_status != 'COLLECTED')
              AppButton(
                text: _getActionText(),
                isLoading: _isUpdating,
                onPressed: _advanceStatus,
              ),
          ],
        ),
      ),
    );
  }

  String _getActionText() {
    switch (_status) {
      case 'ASSIGNED':
        return 'Start Trip (Mark En Route)';
      case 'EN_ROUTE':
        return 'Arrived at Location';
      case 'ARRIVED':
        return 'Confirm Waste Collected';
      default:
        return 'Done';
    }
  }
}
