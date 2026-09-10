import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/services/api_client.dart';
import '../../core/theme/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_controllers.dart';
import '../../widgets/widgets.dart';

class RatingsScreen extends ConsumerStatefulWidget {
  const RatingsScreen({super.key});

  @override
  ConsumerState<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends ConsumerState<RatingsScreen> {
  List<RatingReview> _reviews = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    try {
      final res = await ref
          .read(apiClientProvider)
          .getUserRatingSummary(user.id.toString());
      if (res.statusCode == 200 && res.data is Map) {
        final summary = RatingSummary.fromJson(
          Map<String, dynamic>.from(res.data),
        );
        setState(() => _reviews = summary.recentReviews);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('ratings.title'))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _reviews.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.star_outline_rounded,
                    title: context.tr('ratings.emptyTitle'),
                    description: context.tr('ratings.emptyDesc'),
                    actionText: user == null
                        ? null
                        : context.tr('ratings.rateCollector'),
                    onAction: () => _showRateDialog(context, user!),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _reviews.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return user == null
                        ? const SizedBox.shrink()
                        : AppButton(
                            text: context.tr('ratings.rateCollector'),
                            icon: const Icon(Icons.star_rounded, size: 18),
                            onPressed: () => _showRateDialog(context, user),
                          );
                  }
                  final review = _reviews[index - 1];
                  return _ReviewCard(review: review);
                },
              ),
      ),
    );
  }

  Future<void> _showRateDialog(BuildContext context, User currentUser) async {
    final ratingState = ref.read(ratingControllerProvider);
    await showDialog<void>(
      context: context,
      builder: (context) => RateCollectorDialog(
        currentUserId: currentUser.id,
      ),
    );
    if (context.mounted && ratingState.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ratingState.message!)),
      );
      ref.read(ratingControllerProvider.notifier).clearMessage();
    }
    _load();
  }
}

class RateCollectorDialog extends ConsumerStatefulWidget {
  final int currentUserId;

  const RateCollectorDialog({super.key, required this.currentUserId});

  @override
  ConsumerState<RateCollectorDialog> createState() =>
      _RateCollectorDialogState();
}

class _RateCollectorDialogState extends ConsumerState<RateCollectorDialog> {
  final _controller = TextEditingController();
  String _email = '';
  int _score = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<int?> _resolveCollectorId() async {
    final email = _email.trim().toLowerCase();
    if (email.isEmpty) return null;
    try {
      final res = await ref
          .read(apiClientProvider)
          .lookupCollector(email: email);
      if (res.statusCode == 200) {
        final results = res.data['results'] as List? ?? [];
        if (results.isNotEmpty) {
          return int.tryParse(
                (results.first as Map<String, dynamic>)['id'].toString(),
              ) ?? 0;
        }
      }
    } catch (_) {}
    // Fallback: if a collector email is unknown, still allow rating if we can
    // resolve via registered collectors.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ratingControllerProvider);

    return AlertDialog(
      title: Text(context.tr('ratings.rateCollector')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Collector email',
                hintText: 'collector@tweyonje.ug',
              ),
              onChanged: (v) => setState(() => _email = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(context.tr('ratings.yourReview')),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 32,
                  icon: Icon(
                    i < _score
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: i < _score ? AppColors.accent : AppColors.textMuted,
                  ),
                  onPressed: () => setState(() => _score = i + 1),
                );
              }),
            ),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.tr('ratings.yourReview'),
              ),
            ),
            if (state.message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                state.message!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: state.isError ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('common.cancel')),
        ),
        AppButton(
          text: context.tr('ratings.submit'),
          isLoading: state.isSubmitting,
          width: 160,
          height: 44,
          onPressed: _submit,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final id = await _resolveCollectorId();
    if (id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Collector not found. Ask them for the exact email used to sign in.',
            ),
          ),
        );
      }
      return;
    }
    final ok = await ref.read(ratingControllerProvider.notifier).submit(
          toUserId: id,
          score: _score,
          review: _controller.text.trim().isEmpty
              ? null
              : _controller.text.trim(),
        );
    if (ok && mounted) Navigator.of(context).pop();
  }
}

class _ReviewCard extends StatelessWidget {
  final RatingReview review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  review.fromUserName.isEmpty
                      ? '?'
                      : review.fromUserName.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.fromUserName,
                  style: AppTypography.h5.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StarRow(score: review.score),
            ],
          ),
          const SizedBox(height: 8),
          if (review.review != null && review.review!.isNotEmpty) ...[
            Text(review.review!, style: AppTypography.body),
            const SizedBox(height: 6),
          ],
          Text(
            review.createdAt ?? '',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int score;

  const _StarRow({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < score ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: i < score ? AppColors.accent : AppColors.textMuted,
        );
      }),
    );
  }
}