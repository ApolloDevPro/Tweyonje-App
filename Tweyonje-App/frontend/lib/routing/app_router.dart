import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_verification_screen.dart';
import '../features/auth/password_reset_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/terms_of_service_screen.dart';
import '../features/admin/admin_analytics_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_home_screen.dart';
import '../features/admin/admin_zones_screen.dart';
import '../features/admin/create_account_screen.dart';
import '../features/admin/data_export_screen.dart';
import '../features/admin/privacy_policy_screen.dart';
import '../features/admin/settings_screen.dart';
import '../features/admin/verifications_screen.dart';
import '../features/authority/authority_dashboard_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/collector/collector_home_screen.dart';
import '../features/collector/collector_history_screen.dart';
import '../features/collector/job_detail_screen.dart';
import '../features/collector/route_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/profile/privacy_policy_view.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/recycler/recycler_dashboard_screen.dart';
import '../features/recycler/recycler_resources_screen.dart';
import '../features/resident/create_request_screen.dart';
import '../features/resident/live_tracking_screen.dart';
import '../features/resident/my_requests_screen.dart';
import '../features/resident/notifications_screen.dart';
import '../features/resident/payment_history_screen.dart';
import '../features/resident/payment_screen.dart';
import '../features/resident/ratings_screen.dart';
import '../features/resident/recycling_screen.dart';
import '../features/resident/reports_screen.dart';
import '../features/resident/request_detail_screen.dart';
import '../features/resident/resident_home_screen.dart';
import '../features/resident/rewards_screen.dart';
import '../features/resident/schedules_screen.dart';
import '../features/resident/support_create_screen.dart';
import '../features/resident/support_detail_screen.dart';
import '../features/resident/support_screen.dart';
import '../features/resident/waste_classification_screen.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

/// Routes that unauthenticated users may visit without being bounced to login.
const Set<String> _publicAuthRoutes = {
  '/login',
  '/register',
  '/reset-password',
  '/verify-otp',
  '/privacy-policy',
  '/terms-of-service',
};

/// Pure decision helper for the router redirect. Exported for unit tests.
///
/// `onboardingDone` is `null` while the stored flag is still being resolved,
/// in which case navigation is left untouched to avoid premature redirects.
String? onboardingRedirect({
  required AuthStatus authStatus,
  required bool? onboardingDone,
  required String location,
}) {
  if (authStatus == AuthStatus.initial || authStatus == AuthStatus.loading) {
    return null;
  }
  if (onboardingDone == null) return null;

  // The splash screen drives its own navigation after its animation.
  if (location == '/splash') return null;

  final isAuth = authStatus == AuthStatus.authenticated;
  final isLoggingIn = location == '/login' || location == '/register';

  if (!isAuth && !onboardingDone) {
    return location == '/onboarding' ? null : '/onboarding';
  }

  if (!isAuth) {
    if (_publicAuthRoutes.contains(location)) return null;
    return '/login';
  }

  if (isLoggingIn) return '/';
  return null;
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) => notifyListeners());
    _ref.listen<AsyncValue<bool>>(appOnboardingProvider, (previous, next) {
      notifyListeners();
    });
  }

  String? redirect(BuildContext context, GoRouterState state) {
    return onboardingRedirect(
      authStatus: _ref.read(authProvider).status,
      onboardingDone: _ref.read(appOnboardingProvider).value,
      location: state.matchedLocation,
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          final role = ref.read(authProvider).user?.role ?? UserRole.resident;
          switch (role) {
            case UserRole.collector:
              return const CollectorHomeScreen();
            case UserRole.administrator:
              return const AdminHomeScreen();
            case UserRole.authority:
              return const AuthorityDashboardScreen();
            case UserRole.recycler:
              return const RecyclerDashboardScreen();
            default:
              return const ResidentHomeScreen();
          }
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return OtpVerificationScreen(
            identifier: query['identifier'] ?? '',
            purpose: query['purpose'] ?? 'PHONE_VERIFY',
            postRegister: query['postRegister'] == '1',
          );
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return PasswordResetScreen(
            email: query['email'] ?? '',
            devToken: query['devToken'],
          );
        },
      ),
      GoRoute(
        path: '/terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/schedules',
        builder: (context, state) => const SchedulesScreen(),
      ),
      GoRoute(
        path: '/payment-history',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/ratings',
        builder: (context, state) => const RatingsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/support/create',
        builder: (context, state) => const SupportCreateScreen(),
      ),
      GoRoute(
        path: '/support/:id',
        builder: (context, state) => SupportDetailScreen(
          ticketId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/tracking/:id',
        builder: (context, state) =>
            LiveTrackingScreen(requestId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/create-request',
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: '/my-requests',
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return PaymentScreen(
            amount: double.tryParse(query['amount'] ?? '') ?? 0,
            requestId: query['requestId'] ?? '',
            description: query['description'],
          );
        },
      ),
      GoRoute(
        path: '/request-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extraReq = state.extra as WasteRequest?;
          return RequestDetailScreen(requestId: id, initialRequest: extraReq);
        },
      ),
      GoRoute(
        path: '/waste-classify',
        builder: (context, state) => const WasteClassificationScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: '/recycling',
        builder: (context, state) => const RecyclingScreen(),
      ),
      GoRoute(
        path: '/collector-job/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extraJob = state.extra as CollectorJob?;
          return JobDetailScreen(jobId: id, initialJob: extraJob);
        },
      ),
      GoRoute(
        path: '/collector-route',
        builder: (context, state) => const RouteScreen(),
      ),
      GoRoute(
        path: '/collector-history',
        builder: (context, state) => const CollectorHistoryScreen(),
      ),
      GoRoute(
        path: '/recycler/resources',
        builder: (context, state) => const RecyclerResourcesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyView(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/verifications',
        builder: (context, state) => const VerificationsScreen(),
      ),
      GoRoute(
        path: '/admin/zones',
        builder: (context, state) => const AdminZonesScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/admin/data-export',
        builder: (context, state) => const DataExportScreen(),
      ),
      GoRoute(
        path: '/admin/create-account',
        builder: (context, state) => const CreateAccountScreen(),
      ),
    ],
  );
});
