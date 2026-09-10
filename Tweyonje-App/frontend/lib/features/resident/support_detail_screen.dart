import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class SupportDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportDetailScreen> createState() =>
      _SupportDetailScreenState();
}

class _SupportDetailScreenState extends ConsumerState<SupportDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  SupportTicket? _local;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiClientProvider).getTicketDetail(widget.ticketId).then((res) {
        if (res.statusCode == 200 && res.data is Map) {
          final fresh =
              SupportTicket.fromJson(Map<String, dynamic>.from(res.data));
          setState(() => _local = fresh);
          _syncAndScroll(fresh);
        }
      });
    });
  }

  void _syncAndScroll(SupportTicket ticket) {
    final messages = ticket.messages;
    final found = ref
        .read(supportProvider)
        .tickets
        .where((t) => t.id == ticket.id);
    final existing = found.isEmpty ? null : found.first;
    if (existing != null) {
      final known = existing.messages.length;
      final newOnes = messages.length - known;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (newOnes > 0 && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(supportProvider);
    final found = ref
        .read(supportProvider)
        .tickets
        .where((t) => t.id == widget.ticketId);
    final ticket = _local ?? (found.isEmpty ? null : found.first);

    // Combine the locally-fetched messages with any newer provider messages.
    final messages = <TicketMessage>[];
    for (final t in [ticket, if (found.isNotEmpty) found.first]) {
      if (t == null) continue;
      for (final m in t.messages) {
        if (!messages.any((x) => x.id == m.id)) messages.add(m);
      }
    }
    messages.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('${context.tr('support.ticketNo')} #${widget.ticketId}')),
      body: ticket == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          style: AppTypography.h5.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            StatusBadge(status: ticket.status),
                            const SizedBox(width: 8),
                            Text(
                              ticket.priority,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              ticket.createdAt ?? '',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final mine = message.senderId == user?.id;
                          return _MessageBubble(message: message, mine: mine);
                        },
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: context.tr('support.typeMessage'),
                            ),
                            textInputAction: TextInputAction.newline,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppButton(
                          text: '',
                          width: 48,
                          height: 48,
                          isLoading: state.isSending,
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 20,
                            color: AppColors.textInverse,
                          ),
                          onPressed: _send,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _send() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    final ok = await ref
        .read(supportProvider.notifier)
        .sendMessage(widget.ticketId, content);
    if (ok) _messageController.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final TicketMessage message;
  final bool mine;

  const _MessageBubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(mine ? AppRadius.lg : 4),
            bottomRight: Radius.circular(mine ? 4 : AppRadius.lg),
          ),
          border: mine ? null : Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!mine) ...[
              Text(
                message.senderName,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              message.content,
              style: AppTypography.bodySmall.copyWith(
                color: mine ? AppColors.textInverse : AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message.createdAt ?? '',
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: mine
                    ? AppColors.textInverse.withValues(alpha: 0.7)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}