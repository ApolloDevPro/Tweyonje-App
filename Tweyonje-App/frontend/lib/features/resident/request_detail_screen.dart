import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/waste_request_provider.dart';
import '../../widgets/widgets.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;
  final WasteRequest? initialRequest;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
    this.initialRequest,
  });

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  WasteRequest? _request;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
    if (_request == null) {
      _loadRequest();
    }
  }

  Future<void> _loadRequest() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(apiClientProvider).getRequestDetail(widget.requestId);
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _request = WasteRequest.fromJson(res.data);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final req = _request;
    if (req == null || _isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isUnpaid = req.paymentStatus != 'PAID';

    return Scaffold(
      appBar: AppBar(
        title: Text(req.referenceId.isNotEmpty ? req.referenceId : 'Request #${req.id.substring(0, 6)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req.categoryDetails?.name ?? 'Waste Collection',
                        style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
                      ),
                      StatusBadge(status: req.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildDetailRow('Weight', '${req.estimatedWeightKg} kg'),
                  _buildDetailRow('Estimated Fee', 'UGX ${req.estimatedPrice.toStringAsFixed(0)}'),
                  _buildDetailRow('Payment Status', req.paymentStatus),
                  if (req.scheduledTimeSlot != null)
                    _buildDetailRow('Scheduled Window', req.scheduledTimeSlot!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Live Tracking Map Card
            if (req.latitude != null && req.longitude != null) ...[
              Text('Location & Collector Tracking', style: AppTypography.h5),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: AppMap(
                  initialLat: req.latitude!,
                  initialLng: req.longitude!,
                  initialZoom: 15,
                  markers: [
                    AppMapMarker(
                      latitude: req.latitude!,
                      longitude: req.longitude!,
                      title: 'Pickup Location',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                req.pickupAddress,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Assigned Collector Info
            if (req.assignedCollectorName != null) ...[
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      radius: 24,
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.assignedCollectorName!,
                            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text('Assigned Collector', style: AppTypography.caption),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone, color: AppColors.primary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/tracking/${req.id}'),
                      icon: const Icon(Icons.near_me_outlined, size: 18),
                      label: const Text('Track'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChatWithCollector(req.id),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: const Text('Chat'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/ratings'),
                      icon: const Icon(Icons.star_outline_rounded, size: 18),
                      label: const Text('Rate'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Payment Checkout CTA
            if (isUnpaid) ...[
              AppCard(
                color: AppColors.primarySoft,
                border: Border.all(color: AppColors.primary.withAlpha(77)),
                child: Column(
                  children: [
                    Text(
                      'Payment Due',
                      style: AppTypography.caption.copyWith(color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'UGX ${req.estimatedPrice.toStringAsFixed(0)}',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      text: 'Pay with Mobile Money / Card',
                      onPressed: () => _showPaymentBottomSheet(context, req),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Cancel Button
            if (req.status == 'PENDING')
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Request'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cancel Request?'),
                      content: const Text('Are you sure you want to cancel this pickup request?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(wasteRequestsProvider.notifier).cancelRequest(req.id, 'Resident cancelled');
                    if (mounted && context.mounted) {
                      context.pop();
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChatWithCollector(String requestId) async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.createConversationForRequest(requestId);
      final conversationId = res.data['id'];
      if (mounted && context.mounted) {
        await context.push('/chat/$conversationId');
      }
    } catch (_) {
      if (mounted && context.mounted) {
        context.push('/chat');
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showPaymentBottomSheet(BuildContext context, WasteRequest request) {
    final userPhone = ref.read(authProvider).user?.phone ?? '';
    final phoneController = TextEditingController(text: userPhone);
    String method = 'MTN_MOMO';
    bool isProcessing = false;
    String? errorMessage;

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
              Text('Complete Payment', style: AppTypography.h4),
              const SizedBox(height: 8),
              Text(
                'Select your payment method for UGX ${request.estimatedPrice.toStringAsFixed(0)}',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildPaymentMethodCard(
                title: 'MTN Mobile Money',
                subtitle: 'Instant push prompt (*165#)',
                value: 'MTN_MOMO',
                selected: method == 'MTN_MOMO',
                onTap: () => setModalState(() => method = 'MTN_MOMO'),
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodCard(
                title: 'Airtel Money',
                subtitle: 'Instant push prompt (*185#)',
                value: 'AIRTEL_MONEY',
                selected: method == 'AIRTEL_MONEY',
                onTap: () => setModalState(() => method = 'AIRTEL_MONEY'),
              ),
              const SizedBox(height: 8),
              _buildPaymentMethodCard(
                title: 'Credit or Debit Card',
                subtitle: 'Visa / Mastercard',
                value: 'CARD',
                selected: method == 'CARD',
                onTap: () => setModalState(() => method = 'CARD'),
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                label: 'Payment Phone / Account',
                hint: '+256 770 000000',
                controller: phoneController,
                keyboardType: TextInputType.phone,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: AppTypography.caption.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: isProcessing
                    ? 'Sending Payment Prompt...'
                    : 'Pay UGX ${request.estimatedPrice.toStringAsFixed(0)}',
                isLoading: isProcessing,
                onPressed: isProcessing
                    ? null
                    : () async {
                        final phone = phoneController.text.trim();
                        if (phone.isEmpty && method != 'CARD') {
                          setModalState(() => errorMessage = 'Please enter a valid phone number');
                          return;
                        }
                        setModalState(() {
                          isProcessing = true;
                          errorMessage = null;
                        });

                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final res = await ref.read(apiClientProvider).initiatePayment(
                            wasteRequestId: request.id,
                            phoneNumber: phone.isNotEmpty ? phone : '+256700000000',
                            method: method,
                            amount: request.estimatedPrice,
                          );

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Payment prompt sent to $phone! Ref: ${res.data['reference_id'] ?? ''}',
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          if (mounted) {
                            await _loadRequest();
                            ref.read(wasteRequestsProvider.notifier).fetchRequests();
                          }
                        } catch (e) {
                          setModalState(() {
                            isProcessing = false;
                            errorMessage = 'Payment request failed. Please try again.';
                          });
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required String value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primaryDark : AppColors.text,
                    ),
                  ),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
