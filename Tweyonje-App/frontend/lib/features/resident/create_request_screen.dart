import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';
import '../../core/services/location_service.dart';
import '../../models/models.dart';
import '../../providers/waste_request_provider.dart';
import '../../widgets/widgets.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();

  WasteCategory? _selectedCategory;
  double _weightKg = 5.0;
  double _latitude = 0.3476;
  double _longitude = 32.5825;
  final bool _isEmergency = false;
  bool _isSubmitting = false;
  String _selectedSlot = 'MORNING_8_12';
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    final pos = await LocationService().getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      final addr = await LocationService().getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (addr != null && mounted) {
        _addressController.text = addr;
      }
    }
  }

  double get _calculatedPrice {
    final rate = _selectedCategory?.defaultPricePerKg ?? 1000.0;
    final base = _weightKg * (rate > 0 ? rate : 1000.0);
    return _isEmergency ? base * 1.5 : base;
  }

  Future<void> _handleSubmit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a waste category')),
      );
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter or select a pickup address')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'category': _selectedCategory?.id,
      'estimated_weight_kg': _weightKg,
      'pickup_address': _addressController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'scheduled_date': _scheduledDate.toIso8601String().split('T').first,
      'scheduled_time_slot': _selectedSlot,
      'is_emergency': _isEmergency,
      'special_instructions': _instructionsController.text.trim(),
    };

    var success = false;
    Object? submitError;
    try {
      success = await ref.read(wasteRequestsProvider.notifier).createRequest(payload);
    } catch (error) {
      submitError = error;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waste collection requested successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else if (mounted) {
      final message = _requestErrorMessage(submitError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  String _requestErrorMessage(Object? error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        for (final value in data.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String && value.isNotEmpty) return value;
        }
      }
    }
    return error == null
        ? 'The server could not create the request. Please try again.'
        : 'Could not create the pickup request: $error';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(wasteCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Waste Pickup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Selection
            Text(
              'Waste Category',
              style: AppTypography.h5.copyWith(color: AppColors.text),
            ),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Text('Loading categories...');
                }
                _selectedCategory ??= categories.first;

                return SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      final isSel = _selectedCategory?.id == cat.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primarySoft : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSel ? AppColors.primary : AppColors.border,
                              width: isSel ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: isSel ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? AppColors.primaryDark : AppColors.text,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => const Text('Error loading waste categories'),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Weight Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estimated Weight', style: AppTypography.h5),
                Text(
                  '${_weightKg.toStringAsFixed(1)} kg',
                  style: AppTypography.h4.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Slider(
              value: _weightKg,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _weightKg = val),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Location Map and Address
            Text('Pickup Location', style: AppTypography.h5),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: AppMap(
                initialLat: _latitude,
                initialLng: _longitude,
                initialZoom: 14,
                markers: [
                  AppMapMarker(latitude: _latitude, longitude: _longitude, title: 'Pickup point'),
                ],
                onTap: (point) async {
                  setState(() {
                    _latitude = point.latitude;
                    _longitude = point.longitude;
                  });
                  final addr = await LocationService().getAddressFromCoordinates(point.latitude, point.longitude);
                  if (addr != null && mounted) {
                    _addressController.text = addr;
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    label: 'Address / Landmark',
                    hint: 'Plot 12, Kampala Road',
                    controller: _addressController,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: IconButton.filledTonal(
                    onPressed: _fetchCurrentLocation,
                    icon: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Scheduled pickup date
            Text('Pickup Date', style: AppTypography.h5),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _scheduledDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null && mounted) {
                  setState(() => _scheduledDate = date);
                }
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                MaterialLocalizations.of(context).formatMediumDate(_scheduledDate),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Time Slot Selection
            Text('Preferred Time Slot', style: AppTypography.h5),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Morning (8 AM - 12 PM)'),
                  selected: _selectedSlot == 'MORNING_8_12',
                  onSelected: (s) => setState(() => _selectedSlot = 'MORNING_8_12'),
                ),
                ChoiceChip(
                  label: const Text('Afternoon (1 PM - 5 PM)'),
                  selected: _selectedSlot == 'AFTERNOON_1_5',
                  onSelected: (s) => setState(() => _selectedSlot = 'AFTERNOON_1_5'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Special instructions
            AppInput(
              label: 'Special Instructions (Optional)',
              hint: 'e.g. Call upon arrival, gate is black',
              controller: _instructionsController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Price Estimation Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withAlpha(77)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated Fee', style: AppTypography.caption),
                      Text(
                        'UGX ${_calculatedPrice.toStringAsFixed(0)}',
                        style: AppTypography.h3.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.eco, color: AppColors.primary, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '+${(_weightKg * 5).toInt()} Eco-Points',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            AppButton(
              text: 'Confirm & Request Pickup',
              isLoading: _isSubmitting,
              onPressed: _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
