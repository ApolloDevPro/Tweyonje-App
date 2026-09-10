import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supportProvider.notifier).fetchTickets(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('support.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/support/create'),
        icon: const Icon(Icons.add_comment_rounded),
        label: Text(context.tr('support.newTicket')),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: RefreshIndicator(
        onRefresh: () => ref.read(supportProvider.notifier).fetchTickets(),
        child: state.isLoading && state.tickets.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.tickets.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.support_agent_rounded,
                        title: context.tr('support.emptyTitle'),
                        description: context.tr('support.emptyDesc'),
                        actionText: context.tr('support.newTicket'),
                        onAction: () => context.push('/support/create'),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ticket = state.tickets[index];
                      return _TicketCard(ticket: ticket);
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ticket.status.toUpperCase()) {
      'OPEN' => AppColors.info,
      'IN_PROGRESS' || 'RESOLVED' => AppColors.warning,
      'CLOSED' => AppColors.textMuted,
      _ => AppColors.info,
    };

    return AppCard(
      onTap: () => context.push('/support/${ticket.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  ticket.status.replaceAll('_', ' '),
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${context.tr('support.ticketNo')} ${ticket.ticketNumber}',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.dataset_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                ticket.category.replaceAll('_', ' '),
                style: AppTypography.bodySmall,
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.priority_high_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                ticket.priority,
                style: AppTypography.bodySmall,
              ),
              const Spacer(),
              Text(
                ticket.updatedAt ?? ticket.createdAt ?? '',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}