import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/theme/theme.dart';
import '../../widgets/widgets.dart';

enum PaymentMethod { mtnMomo, airtelMoney, card }

enum PaymentStatus { pending, completed, failed }

class PaymentScreen extends ConsumerStatefulWidget {
  final double amount;
  final String requestId;
  final String? description;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.requestId,
    this.description,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod? _selectedMethod;
  String _phoneNumber = '';
  bool _isProcessing = false;
  String? _transactionId;
  PaymentStatus _status = PaymentStatus.pending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Display
            AppCard(
              child: Column(
                children: [
                  Text('Amount to Pay', style: AppTypography.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    'UGX ${widget.amount.toStringAsFixed(0)}',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.description!,
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Payment Method Selection
            Text('Select Payment Method', style: AppTypography.h6),
            const SizedBox(height: AppSpacing.md),

            // MTN Mobile Money
            _buildPaymentMethodCard(
              method: PaymentMethod.mtnMomo,
              title: 'MTN Mobile Money',
              icon: Icons.phone_android,
              color: Colors.yellow[700],
            ),
            const SizedBox(height: AppSpacing.md),

            // Airtel Money
            _buildPaymentMethodCard(
              method: PaymentMethod.airtelMoney,
              title: 'Airtel Money',
              icon: Icons.phone_iphone,
              color: Colors.red[700],
            ),
            const SizedBox(height: AppSpacing.md),

            // Card Payment
            _buildPaymentMethodCard(
              method: PaymentMethod.card,
              title: 'Card Payment',
              icon: Icons.credit_card,
              color: Colors.blue[700],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Phone Number Input (for mobile money)
            if (_selectedMethod == PaymentMethod.mtnMomo ||
                _selectedMethod == PaymentMethod.airtelMoney) ...[
              Text('Phone Number', style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                decoration: InputDecoration(
                  hintText: '+256 7XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) => _phoneNumber = value,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Processing Indicator
            if (_isProcessing) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing payment...'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Success/Error Message
            if (_transactionId != null) ...[
              AppCard(
                color: _status == PaymentStatus.completed
                    ? AppColors.successSoft
                    : AppColors.errorSoft,
                border: Border.all(
                  color: _status == PaymentStatus.completed
                      ? AppColors.success
                      : AppColors.error,
                ),
                child: Column(
                  children: [
                    Icon(
                      _status == PaymentStatus.completed
                          ? Icons.check_circle
                          : Icons.error,
                      color: _status == PaymentStatus.completed
                          ? AppColors.success
                          : AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _status == PaymentStatus.completed
                          ? 'Payment Successful!'
                          : 'Payment Failed',
                      style: AppTypography.h6,
                    ),
                    if (_transactionId != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Transaction ID: $_transactionId',
                        style: AppTypography.caption,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Pay Button
            AppButton(
              text: _isProcessing ? 'Processing...' : 'Pay Now',
              onPressed: _selectedMethod != null && !_isProcessing
                  ? _processPayment
                  : null,
              disabled: _selectedMethod == null || _isProcessing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required PaymentMethod method,
    required String title,
    required IconData icon,
    required Color? color,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          color: isSelected ? AppColors.primarySoft : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTypography.body.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) return;

    setState(() {
      _isProcessing = true;
      _transactionId = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      final paymentData = {
        'waste_request_id': widget.requestId,
        'amount': widget.amount,
        'method': _selectedMethod == PaymentMethod.mtnMomo
            ? 'MTN_MOMO'
            : _selectedMethod == PaymentMethod.airtelMoney
            ? 'AIRTEL_MONEY'
            : 'CARD',
        'phone_number': _phoneNumber,
      };

      final response = await apiClient.post(
        ApiEndpoints.initiatePayment,
        data: paymentData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final status = (response.data['status'] ?? '').toString().toUpperCase();
        setState(() {
          _transactionId = response.data['reference_id'];
          _status = status == 'SUCCESSFUL' || status == 'PAID'
              ? PaymentStatus.completed
              : status == 'FAILED'
              ? PaymentStatus.failed
              : PaymentStatus.pending;
        });

        if (_status == PaymentStatus.completed) {
          // Show success message and navigate back
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment successful!')),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        setState(() {
          _status = PaymentStatus.failed;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _status = PaymentStatus.failed;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment error: $e')));
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
