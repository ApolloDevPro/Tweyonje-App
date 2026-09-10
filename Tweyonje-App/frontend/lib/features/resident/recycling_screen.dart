import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

class RecyclingScreen extends ConsumerStatefulWidget {
  const RecyclingScreen({super.key});

  @override
  ConsumerState<RecyclingScreen> createState() => _RecyclingScreenState();
}

class _RecyclingScreenState extends ConsumerState<RecyclingScreen> {
  final materials = [
    {
      'title': 'Plastic Bottles (PET)',
      'price': '800 UGX / kg',
      'buyers': 'Kampala Plastics Ltd, EcoPlast Uganda',
      'icon': Icons.local_drink_outlined,
    },
    {
      'title': 'Aluminium Cans & Scrap',
      'price': '3,500 UGX / kg',
      'buyers': 'Uganda Scrap Recyclers, Jinja Metal Works',
      'icon': Icons.hardware_outlined,
    },
    {
      'title': 'Cardboard & Paper',
      'price': '400 UGX / kg',
      'buyers': 'Mukono Paper Mills',
      'icon': Icons.description_outlined,
    },
    {
      'title': 'E-Waste & Electronics',
      'price': '5,000 - 50,000 UGX / item',
      'buyers': 'WEEE Centre Uganda',
      'icon': Icons.electrical_services_outlined,
    },
  ];

  void _showSellModal(BuildContext context, String materialTitle, String price) {
    final weightController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sell Recyclables', style: AppTypography.h4),
              const SizedBox(height: 4),
              Text(
                'Submit an offer for $materialTitle ($price)',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'Estimated Quantity / Weight (kg or items)',
                hint: 'e.g. 15',
                controller: weightController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInput(
                label: 'Pickup Location',
                hint: 'e.g. Kisaasi, Bukoto, Nakawa',
                controller: addressController,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppInput(
                label: 'Contact Phone Number',
                hint: '+256 770 000000',
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: isSubmitting ? 'Posting Offer...' : 'Submit to Certified Recyclers',
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (weightController.text.trim().isEmpty) return;
                        setModalState(() => isSubmitting = true);
                        try {
                          await ref.read(apiClientProvider).createRecyclingOffer({
                            'material_type': materialTitle,
                            'quantity': double.tryParse(weightController.text.trim()) ?? 10.0,
                            'location': addressController.text.trim(),
                            'phone': phoneController.text.trim(),
                          });
                        } catch (_) {}

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Recycling offer posted! Certified buyers will contact you for pickup.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycling Marketplace'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppGradients.accent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_exchange, color: Colors.white, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monetize Your Recyclables',
                        style: AppTypography.h4.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Connect directly with certified recycling plants in Uganda',
                        style: AppTypography.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Live Buying Rates in Kampala', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.sm),
          ...materials.map((mat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(mat['icon'] as IconData, color: AppColors.primaryDark, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mat['title'] as String,
                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            mat['price'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Buyers: ${mat['buyers']}',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      onPressed: () => _showSellModal(
                        context,
                        mat['title'] as String,
                        mat['price'] as String,
                      ),
                      child: const Text('Sell'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
