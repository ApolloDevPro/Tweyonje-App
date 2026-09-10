import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class WasteClassificationScreen extends ConsumerStatefulWidget {
  const WasteClassificationScreen({super.key});

  @override
  ConsumerState<WasteClassificationScreen> createState() => _WasteClassificationScreenState();
}

class _WasteClassificationScreenState extends ConsumerState<WasteClassificationScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isAnalyzing = false;
  String? _errorMessage;
  Map<String, dynamic>? _predictionResult;

  Future<void> _pickImage(ImageSource source) async {
    try {
      // image_picker launches the native camera / gallery and handles permissions
      // itself, which is far more reliable than a manual CameraPreview controller.
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (picked == null) return; // user cancelled

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
        _predictionResult = null;
        _errorMessage = null;
      });

      await _analyzeWaste();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${source == ImageSource.camera ? 'Camera' : 'Gallery'} error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _analyzeWaste() async {
    if (_imageBytes == null) return;
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          _imageBytes!,
          filename: _imageName ?? 'waste.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      // Call the real backend AI classification endpoint
      final response = await ref.read(apiClientProvider).classifyWasteImage(formData);

      final dynamic prediction = response.data is Map
          ? (response.data as Map)['prediction'] ?? response.data
          : null;

      if (mounted) {
        setState(() {
          _predictionResult = Map<String, dynamic>.from(prediction as Map? ?? {});
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _predictionResult = null;
        _errorMessage = 'Classification failed. Please check your connection and try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Classification failed: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Waste Classification'),
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Snap & Identify Waste',
            style: AppTypography.h3.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Our AI automatically detects waste types, recyclability, and eco-points value.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Image Preview Area
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Image.memory(
                      _imageBytes!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 8),
                        Text('No photo selected', style: AppTypography.caption),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Photo Capture Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Take Photo',
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Gallery',
                  variant: ButtonVariant.outline,
                  icon: const Icon(Icons.photo_library, color: AppColors.primary, size: 20),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Error banner
          if (_errorMessage != null) ...[
            AppCard(
              color: AppColors.dangerSoft,
              border: Border.all(color: AppColors.danger),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.dangerDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Analysis Indicator or Results
          if (_isAnalyzing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Analyzing waste composition with AI...'),
                  ],
                ),
              ),
            )
          else if (_predictionResult != null) ...[
            AppCard(
              color: AppColors.primarySoft,
              border: Border.all(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _predictionResult!['category'] ?? 'Identified Waste',
                        style: AppTypography.h4.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${((_predictionResult!['confidence'] ?? 0.9) * 100).toInt()}% Match',
                          style: AppTypography.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        _predictionResult!['recyclable'] == true ? Icons.recycling : Icons.warning_amber,
                        color: _predictionResult!['recyclable'] == true ? AppColors.primary : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _predictionResult!['recyclable'] == true ? 'Recyclable Material' : 'General Waste',
                        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _predictionResult!['instructions'] ?? '',
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Est. Value / kg', style: AppTypography.caption),
                      Text(
                        'UGX ${_predictionResult!['estimated_value_ugx_kg'] ?? 0}',
                        style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Eco-Points Potential', style: AppTypography.caption),
                      Text(
                        '+${_predictionResult!['eco_points_potential_kg'] ?? 10} pts / kg',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Schedule Pickup for this Item',
              onPressed: () => context.push('/create-request'),
            ),
          ],
        ],
      ),
    );
  }
}
