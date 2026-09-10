import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/l10n/app_strings.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/sync_service.dart';
import 'core/theme/theme.dart';
import 'providers/settings_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/service_controllers.dart';
import 'routing/app_router.dart';
import 'core/storage/offline_storage.dart';
import 'core/security/security_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://knskyxabdwxutyriravt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtuc2t5eGFiZHd4dXR5cmlyYXZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwNDE2MDAsImV4cCI6MjEwNDYxNzYwMH0.Tx5fuOnpC2z0PRu5jzEznko34nnbRyH-sk7Txq7f8jk',
  );

  // Initialize security configuration
  SecurityConfig.instance.initialize(
    isProduction: const bool.fromEnvironment(
      'dart.vm.product',
      defaultValue: false,
    ),
    sslPinningEnabled: true,
    allowedDomains: ['tweyonje.ug', 'staging.tweyonje.ug', '127.0.0.1'],
  );

  // Initialize offline storage (best-effort: storage failures must never
  // prevent the app from rendering).
  final offlineStorage = OfflineStorage();
  try {
    await offlineStorage.init();
  } catch (e) {
    debugPrint('Offline storage init failed: $e');
  }

  // Provide the initialized instance to the app so providers (e.g.
  // SyncService) reuse the same boxes instead of creating an uninitialized copy.
  final container = ProviderContainer(
    overrides: [offlineStorageProvider.overrideWithValue(offlineStorage)],
  );

  // Initialize push notifications (Firebase configuration required).
  // Best-effort: if Firebase config is absent this is a no-op.
  try {
    final pushNotificationService = container.read(
      pushNotificationServiceProvider,
    );
    await pushNotificationService.initialize();
  } catch (e) {
    debugPrint('Push notification init skipped: $e');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(UncontrolledProviderScope(container: container, child: TweyonjeApp()));
}

class TweyonjeApp extends ConsumerWidget {
  const TweyonjeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(appSettingsProvider);

    // Keep the sync (offline queue) service alive for the app's lifetime.
    ref.watch(syncServiceProvider);

    // App-wide refresh triggered by FCM pushes / background events so screens
    // always reflect the latest server state.
    final bus = ref.watch(appEventBusProvider);
    if (bus.last != null) {
      final event = bus.last!;
      switch (event.type) {
        case AppEventType.paymentCompleted:
          ref.invalidate(paymentHistoryProvider);
        case AppEventType.assignmentUpdated:
        case AppEventType.collectionCompleted:
          ref.invalidate(paymentHistoryProvider);
        case AppEventType.conversationUpdated:
          ref.invalidate(chatProvider);
        case AppEventType.requestUpdated:
        case AppEventType.shiftChanged:
          break;
        case AppEventType.notificationAdded:
          ref.invalidate(notificationProvider);
          break;
      }
      bus.consume();
    }

    return TranslationsScope(
      language: settings.language,
      child: MaterialApp.router(
        title: 'Tweyonje - Smart Waste Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.themeMode,
        routerConfig: router,
      ),
    );
  }
}
