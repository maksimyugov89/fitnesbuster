import 'package:fitnesbuster/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('allows splash while auth state is resolving', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.splash,
        isAuthenticated: false,
        isAuthStateAuthenticated: false,
        emailVerified: false,
        hasProfile: false,
      ),
      isNull,
    );
  });

  test('redirects unauthenticated private routes to login', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.dashboard,
        isAuthenticated: false,
        isAuthStateAuthenticated: false,
        emailVerified: false,
        hasProfile: false,
      ),
      AppRouter.login,
    );
  });

  test('keeps authenticated user waiting until AuthBloc is ready', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.dashboard,
        isAuthenticated: true,
        isAuthStateAuthenticated: false,
        emailVerified: false,
        hasProfile: false,
      ),
      isNull,
    );
  });

  test('forces unverified users to verify-email route', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.dashboard,
        isAuthenticated: true,
        isAuthStateAuthenticated: true,
        emailVerified: false,
        hasProfile: true,
      ),
      AppRouter.verifyEmail,
    );
  });

  test(
    'sends verified users without profile to onboarding from public routes',
    () {
      expect(
        resolveAuthRedirect(
          loc: AppRouter.login,
          isAuthenticated: true,
          isAuthStateAuthenticated: true,
          emailVerified: true,
          hasProfile: false,
        ),
        AppRouter.onboarding,
      );
    },
  );

  test(
    'sends verified users with profile away from auth/onboarding routes',
    () {
      expect(
        resolveAuthRedirect(
          loc: AppRouter.onboarding,
          isAuthenticated: true,
          isAuthStateAuthenticated: true,
          emailVerified: true,
          hasProfile: true,
        ),
        AppRouter.dashboard,
      );
    },
  );
}
