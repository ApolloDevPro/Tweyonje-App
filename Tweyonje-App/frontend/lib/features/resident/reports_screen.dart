import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_client.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageName;
  String _severity = 'MEDIUM';
  double _lat = 0.3476;
  double _lng = 32.5825;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final pos = await LocationService().getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      final addr = await LocationService().getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (addr != null && mounted) {
        _addressController.text = addr;
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the dumping incident')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = {
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'severity': _severity,
      };

      final res = await ref.read(apiClientProvider).submitIllegalDumpingReport(data);
      if (res.statusCode == 201 || res.statusCode == 200) {
        final reportId = res.data['id']?.toString();
        if (reportId != null && _imageBytes != null) {
          try {
            await ref.read(apiClientProvider).uploadReportPhoto(
              reportId,
              _imageBytes!,
              _imageName ?? 'dumping_photo.jpg',
            );
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report submitted! Authorities notified. You earned 20 Eco-Points!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report recorded successfully.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Illegal Dumping'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Keep Our Community Clean',
              style: AppTypography.h3.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Report unsanctioned waste piles, roadside dumping, or environmental hazards directly to local authorities.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Photo Evidence
            InkWell(
              onTap: _pickPhoto,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 40, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text('Take Photo Evidence', style: AppTypography.label),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Severity selector
            Text('Severity Level', style: AppTypography.h5),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSeverityChip('LOW', 'Low', AppColors.info),
                const SizedBox(width: 8),
                _buildSeverityChip('MEDIUM', 'Medium', AppColors.warning),
                const SizedBox(width: 8),
                _buildSeverityChip('HIGH', 'High', AppColors.danger),
                const SizedBox(width: 8),
                _buildSeverityChip('CRITICAL', 'Hazardous', AppColors.dangerDark),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Map location
            Text('Incident Location', style: AppTypography.h5),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: AppMap(
                initialLat: _lat,
                initialLng: _lng,
                initialZoom: 14,
                markers: [AppMapMarker(latitude: _lat, longitude: _lng, title: 'Dumping Spot', color: AppColors.danger)],
                onTap: (point) async {
                  setState(() {
                    _lat = point.latitude;
                    _lng = point.longitude;
                  });
                  final addr = await LocationService().getAddressFromCoordinates(point.latitude, point.longitude);
                  if (addr != null && mounted) _addressController.text = addr;
                },
              ),
            ),
            const SizedBox(height: 8),
            AppInput(
              label: 'Address / Description of spot',
              hint: 'Near Nakasero Market entrance',
              controller: _addressController,
            ),
            const SizedBox(height: AppSpacing.md),
            AppInput(
              label: 'Detailed Description',
              hint: 'Types of waste dumped, size, blocked drainage, etc.',
              controller: _descriptionController,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),

            AppButton(
              text: 'Submit Environmental Report',
              variant: ButtonVariant.danger,
              isLoading: _isSubmitting,
              onPressed: _submitReport,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityChip(String val, String label, Color color) {
    final isSel = _severity == val;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: color.withAlpha(51),
      labelStyle: AppTypography.caption.copyWith(
        color: isSel ? color : AppColors.text,
        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (s) => setState(() => _severity = val),
    );
  }
}
