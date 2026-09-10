import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentHistoryProvider.notifier).fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentHistoryProvider);
    final payments = state.payments;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.tr('payments.title')),
          bottom: TabBar(
            tabs: [
              Tab(text: context.tr('payments.paid')),
              Tab(text: 'Invoices'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(paymentHistoryProvider.notifier).fetch(),
          child: TabBarView(
            children: [
              _buildPayments(context, payments, state.isLoading, state.error),
              _buildInvoices(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayments(
    BuildContext context,
    List<Payment> payments,
    bool isLoading,
    String? error,
  ) {
    if (isLoading && payments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (payments.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: context.tr('payments.emptyTitle'),
            description: context.tr('payments.emptyDesc'),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveContent(
        child: ResponsiveWrap(
          minItemWidth: 420,
          runSpacing: 10,
          children: payments.map((p) => _PaymentCard(payment: p)).toList(),
        ),
      ),
    );
  }

  Widget _buildInvoices(BuildContext context, PaymentHistoryState state) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.invoices.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          EmptyState(
            icon: Icons.receipt_outlined,
            title: 'No invoices yet',
            description: 'Downloadable receipts appear here once a pickup is billed.',
          ),
        ],
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveContent(
        child: ResponsiveWrap(
          minItemWidth: 420,
          runSpacing: 10,
          children: state.invoices
              .map((invoice) => _InvoiceCard(invoice: invoice))
              .toList(),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final paid = payment.status.toUpperCase() == 'COMPLETED' ||
        payment.status.toUpperCase() == 'PAID';
    return AppCard(
      onTap: () => _showReceipt(context, payment),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: paid ? AppColors.successSoft : AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  paid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                  color: paid ? AppColors.success : AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.referenceId,
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.createdAt ?? '',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'UGX ${payment.amount.toStringAsFixed(0)}',
                style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                payment.method.replaceAll('_', ' '),
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                paid ? context.tr('payments.paid') : context.tr('payments.pending'),
                style: AppTypography.caption.copyWith(
                  color: paid ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, Payment payment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReceiptSheet(payment: payment),
    );
  }
}

class _ReceiptSheet extends StatelessWidget {
  final Payment payment;

  const _ReceiptSheet({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  context.tr('payments.receipt'),
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReceiptRow(
                label: context.tr('payments.transactionId'),
                value: payment.referenceId,
              ),
              const SizedBox(height: 4),
              _ReceiptRow(
                label: context.tr('payments.method'),
                value: payment.method.replaceAll('_', ' '),
              ),
              const SizedBox(height: 4),
              _ReceiptRow(label: 'Phone', value: payment.phoneNumber),
              const SizedBox(height: 4),
              _ReceiptRow(
                label: context.tr('payments.date'),
                value: payment.createdAt ?? '',
              ),
              if (payment.transactionId != null) ...[
                const SizedBox(height: 4),
                _ReceiptRow(
                  label: 'Provider ID',
                  value: payment.transactionId!,
                ),
              ],
              const Divider(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('payments.total'),
                    style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'UGX ${payment.amount.toStringAsFixed(0)}',
                    style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Done',
                variant: ButtonVariant.outline,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _showInvoice(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: invoice.isPaid
                  ? AppColors.successSoft
                  : AppColors.warningSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.description_outlined,
              color: invoice.isPaid ? AppColors.success : AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.issuedDate ?? '',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'UGX ${invoice.amount.toStringAsFixed(0)}',
                style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                invoice.isPaid
                    ? context.tr('payments.paid')
                    : context.tr('payments.pending'),
                style: AppTypography.caption.copyWith(
                  color: invoice.isPaid ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInvoice(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final items = invoice.items.whereType<Map<String, dynamic>>().toList();
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${context.tr('payments.invoice')} • ${invoice.invoiceNumber}',
                  style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final item in items)
                  _ReceiptRow(
                    label: item['name']?.toString() ?? 'Item',
                    value: 'UGX ${(item['amount'] ?? 0).toString()}',
                  ),
                const Divider(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('payments.total'),
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'UGX ${invoice.amount.toStringAsFixed(0)}',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: 'Done',
                  variant: ButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}