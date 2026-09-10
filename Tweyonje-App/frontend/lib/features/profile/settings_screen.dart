import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/theme.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.tr('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── Appearance ──
          Text(
            context.tr('settings.theme'),
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.dark_mode_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(context.tr('settings.darkMode')),
                  subtitle: Text(
                    switch (settings.themeMode) {
                      ThemeMode.system => context.tr('settings.system'),
                      ThemeMode.dark => context.tr('settings.dark'),
                      ThemeMode.light => context.tr('settings.light'),
                    },
                  ),
                  trailing: Switch(
                    value: settings.themeMode == ThemeMode.dark,
                    onChanged: (v) => controller.setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    ),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(context.tr('settings.light')),
                        icon: const Icon(Icons.light_mode_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(context.tr('settings.system')),
                        icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(context.tr('settings.dark')),
                        icon: const Icon(Icons.dark_mode_outlined, size: 18),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) =>
                        controller.setThemeMode(selection.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Language ──
          Text(
            context.tr('settings.language'),
            style: AppTypography.h5.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: RadioGroup<AppLanguage>(
              groupValue: settings.language,
              onChanged: (v) {
                if (v != null) controller.setLanguage(v);
              },
              child: Column(
                children: AppLanguage.values
                    .map(
                      (lang) => RadioListTile<AppLanguage>(
                        value: lang,
                        title: Text(lang.label),
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Reset onboarding ──
          AppButton(
            text: 'Reset onboarding (show welcome again)',
            variant: ButtonVariant.outline,
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.setOnboardingComplete(false);
              ref.invalidate(appOnboardingProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Onboarding will show on next app start.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}