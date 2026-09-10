import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _poller;
  String? _wasteRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(chatProvider);
      final found = state.conversations
          .where((c) => c.id == widget.conversationId);
      if (found.isNotEmpty) {
        _wasteRequestId = found.first.wasteRequestId;
      }
      _startPolling();
      _scrollToBottom();
    });
  }

  void _startPolling() {
    _poller = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_wasteRequestId != null && mounted) {
        await ref
            .read(chatProvider.notifier)
            .refreshForRequest(_wasteRequestId!);
        _scrollToBottom(onlyIfNearBottom: true);
      }
    });
  }

  void _scrollToBottom({bool onlyIfNearBottom = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      final nearBottom = position.maxScrollExtent - position.pixels < 80;
      if (onlyIfNearBottom && !nearBottom) return;
      _scrollController.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(chatProvider);
    final found = state.conversations
        .where((c) => c.id == widget.conversationId);
    final conversation = found.isEmpty ? null : found.first;
    final messages = state.openMessages ??
        (conversation?.messages ?? <ChatMessage>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation?.otherUserName ?? 'Chat',
              style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
            ),
            if (conversation != null && conversation.referenceId.isNotEmpty)
              Text(
                '${context.tr('chat.reference')}: ${conversation.referenceId}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: messages.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final mine = message.senderId == user?.id;
                          return _ChatBubble(message: message, mine: mine);
                        },
                      ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
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
                            hintText: context.tr('chat.typeMessage'),
                          ),
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
        .read(chatProvider.notifier)
        .send(widget.conversationId, content);
    if (ok) {
      _messageController.clear();
      _scrollToBottom();
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;

  const _ChatBubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * 0.78).clamp(
            120.0,
            560.0,
          ),
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