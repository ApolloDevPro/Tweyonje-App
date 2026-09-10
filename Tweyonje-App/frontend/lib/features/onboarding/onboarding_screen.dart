import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/theme.dart';
import '../../core/storage/storage_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: Icons.local_shipping_rounded,
      key1: 'onboarding.s1Title',
      key2: 'onboarding.s1Desc',
    ),
    (
      icon: Icons.eco_rounded,
      key1: 'onboarding.s2Title',
      key2: 'onboarding.s2Desc',
    ),
    (
      icon: Icons.volunteer_activism_rounded,
      key1: 'onboarding.s3Title',
      key2: 'onboarding.s3Desc',
    ),
  ];

  Future<void> _finish() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingComplete(true);
    ref.invalidate(appOnboardingProvider);
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _Slide(
                icon: slide.icon,
                titleKey: slide.key1,
                descKey: slide.key2,
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + AppSpacing.lg,
            right: AppSpacing.lg,
            child: TextButton(
              onPressed: _finish,
              child: Text(context.tr('onboarding.skip')),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  text: _page == _slides.length - 1
                      ? context.tr('onboarding.getStarted')
                      : context.tr('onboarding.next'),
                  icon: _page == _slides.length - 1
                      ? null
                      : const Icon(Icons.arrow_forward_rounded, size: 18),
                  onPressed: _page == _slides.length - 1
                      ? _finish
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String descKey;

  const _Slide({
    required this.icon,
    required this.titleKey,
    required this.descKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(60),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(icon, size: 64, color: AppColors.textInverse),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            context.tr(titleKey),
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr(descKey),
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}