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

  // Edge cases — public routes, social routes, onboarding sub-routes

  test('unauthenticated user stays on login without redirect loop', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.login,
        isAuthenticated: false,
        isAuthStateAuthenticated: false,
        emailVerified: false,
        hasProfile: false,
      ),
      isNull,
    );
  });

  test('unauthenticated user stays on register without redirect loop', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.register,
        isAuthenticated: false,
        isAuthStateAuthenticated: false,
        emailVerified: false,
        hasProfile: false,
      ),
      isNull,
    );
  });

  test(
    'authenticated+verified+noProfile redirects from register to onboarding',
    () {
      expect(
        resolveAuthRedirect(
          loc: AppRouter.register,
          isAuthenticated: true,
          isAuthStateAuthenticated: true,
          emailVerified: true,
          hasProfile: false,
        ),
        AppRouter.onboarding,
      );
    },
  );

  test('unauthenticated user is redirected to login from social feed', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.feed,
        isAuthenticated: false,
        isAuthStateAuthenticated: false,
        emailVerified: false,
        hasProfile: false,
      ),
      AppRouter.login,
    );
  });

  test('unauthenticated user is redirected to login from friends', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.friends,
        isAuthenticated: false,
        isAuthStateAuthenticated: false,
        emailVerified: false,
        hasProfile: false,
      ),
      AppRouter.login,
    );
  });

  test('unauthenticated user is redirected from verifyEmail to login', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.verifyEmail,
        isAuthenticated: false,
        isAuthStateAuthenticated: false,
        emailVerified: false,
        hasProfile: false,
      ),
      AppRouter.login,
    );
  });

  test(
    'authenticated+verified+hasProfile stays on social feed (no redirect)',
    () {
      expect(
        resolveAuthRedirect(
          loc: AppRouter.feed,
          isAuthenticated: true,
          isAuthStateAuthenticated: true,
          emailVerified: true,
          hasProfile: true,
        ),
        isNull,
      );
    },
  );

  test(
    'authenticated+unverified stays on verifyEmail without redirect loop',
    () {
      expect(
        resolveAuthRedirect(
          loc: AppRouter.verifyEmail,
          isAuthenticated: true,
          isAuthStateAuthenticated: true,
          emailVerified: false,
          hasProfile: true,
        ),
        isNull,
      );
    },
  );

  test('authenticated+verified leaves verifyEmail for dashboard', () {
    expect(
      resolveAuthRedirect(
        loc: AppRouter.verifyEmail,
        isAuthenticated: true,
        isAuthStateAuthenticated: true,
        emailVerified: true,
        hasProfile: true,
      ),
      AppRouter.dashboard,
    );
  });

  test(
    'authenticated+verified+hasProfile is redirected from onboarding sub-route',
    () {
      expect(
        resolveAuthRedirect(
          loc: '${AppRouter.onboarding}/goal',
          isAuthenticated: true,
          isAuthStateAuthenticated: true,
          emailVerified: true,
          hasProfile: true,
        ),
        AppRouter.dashboard,
      );
    },
  );

  test('authenticated+verified+noProfile stays on onboarding sub-route', () {
    expect(
      resolveAuthRedirect(
        loc: '${AppRouter.onboarding}/goal',
        isAuthenticated: true,
        isAuthStateAuthenticated: true,
        emailVerified: true,
        hasProfile: false,
      ),
      isNull,
    );
  });

  test(
    'authenticated+verified+hasProfile stays on private dashboard sub-route',
    () {
      expect(
        resolveAuthRedirect(
          loc: AppRouter.workoutPlan,
          isAuthenticated: true,
          isAuthStateAuthenticated: true,
          emailVerified: true,
          hasProfile: true,
        ),
        isNull,
      );
    },
  );

  test(
    'authenticated+verified+noProfile is redirected from private route to onboarding',
    () {
      // e.g. Google login from Login screen navigates to /dashboard but the
      // user hasn't completed onboarding yet → must be forced to /onboarding.
      expect(
        resolveAuthRedirect(
          loc: AppRouter.dashboard,
          isAuthenticated: true,
          isAuthStateAuthenticated: true,
          emailVerified: true,
          hasProfile: false,
        ),
        AppRouter.onboarding,
      );
    },
  );
}
