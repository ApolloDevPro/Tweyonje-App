import 'package:flutter_test/flutter_test.dart';

import 'package:tweyonje/providers/auth_provider.dart';
import 'package:tweyonje/routing/app_router.dart';

void main() {
  group('onboardingRedirect', () {
    test('waits while auth is initial or loading', () {
      for (final status in [AuthStatus.initial, AuthStatus.loading]) {
        expect(
          onboardingRedirect(
            authStatus: status,
            onboardingDone: false,
            location: '/',
          ),
          isNull,
        );
      }
    });

    test('waits while the onboarding flag is unresolved', () {
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.unauthenticated,
          onboardingDone: null,
          location: '/',
        ),
        isNull,
      );
    });

    test('forces onboarding when logged out and onboarding not done', () {
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.unauthenticated,
          onboardingDone: false,
          location: '/',
        ),
        '/onboarding',
      );
    });

    test('allows /onboarding when onboarding is not done (no loop)', () {
      final result = onboardingRedirect(
        authStatus: AuthStatus.unauthenticated,
        onboardingDone: false,
        location: '/onboarding',
      );
      expect(result, isNull);
    });

    test('bounces deep links to login until onboarding is done', () {
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.unauthenticated,
          onboardingDone: false,
          location: '/login',
        ),
        '/onboarding',
      );
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.unauthenticated,
          onboardingDone: false,
          location: '/settings',
        ),
        '/onboarding',
      );
    });

    test('logged out user with onboarding done is sent to /login', () {
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.unauthenticated,
          onboardingDone: true,
          location: '/',
        ),
        '/login',
      );
    });

    test('login and register are allowed once onboarding is done', () {
      for (final location in ['/login', '/register']) {
        expect(
          onboardingRedirect(
            authStatus: AuthStatus.unauthenticated,
            onboardingDone: true,
            location: location,
          ),
          isNull,
        );
      }
    });

    test('authenticated user is never bounced to onboarding or login', () {
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.authenticated,
          onboardingDone: false,
          location: '/',
        ),
        isNull,
      );
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.authenticated,
          onboardingDone: true,
          location: '/',
        ),
        isNull,
      );
    });

    test('authenticated user on login page is sent home', () {
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.authenticated,
          onboardingDone: true,
          location: '/login',
        ),
        '/',
      );
      expect(
        onboardingRedirect(
          authStatus: AuthStatus.authenticated,
          onboardingDone: false,
          location: '/login',
        ),
        '/',
      );
    });
  });
}