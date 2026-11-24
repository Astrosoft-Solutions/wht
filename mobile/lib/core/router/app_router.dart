import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_controller.dart';
import '../../features/auth/providers/onboarding_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/sign_up_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/customers/screens/before_after_screen.dart';
import '../../features/customers/screens/customer_form_screen.dart';
import '../../features/customers/screens/customer_list_screen.dart';
import '../../features/customers/screens/service_record_screen.dart';
import '../../features/content/screens/announcements_screen.dart';
import '../../features/content/screens/gallery_screen.dart';
import '../../features/habits/screens/daily_habits_screen.dart';
import '../../features/home/screens/dashboard_screen.dart';
import '../../features/home/screens/home_shell.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/subscription/screens/my_plan_screen.dart';
import '../../features/subscription/screens/plans_screen.dart';

class Routes {
  Routes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const habits = '/habits';
  static const reports = '/reports';
  static const profile = '/profile';
  static const myPlan = '/subscription';
  static const plans = '/subscription/plans';
  static const settings = '/settings';
  static const about = '/about';
  static const changePassword = '/change-password';
  static const gallery = '/gallery';
  static const announcements = '/announcements';
  static const customers = '/customers';
  static const customerNew = '/customers/new';
  static String customerEdit(int id) => '/customers/$id/edit';
  static String customerRecord(int id) => '/customers/$id/record';
  static String customerBeforeAfter(int id) => '/customers/$id/before-after';
}

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.listen(onboardingSeenProvider, (_, _) => refresh.value++);
  ref.listen(splashDelayProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  const publicRoutes = {Routes.onboarding, Routes.signIn, Routes.signUp, Routes.forgotPassword};

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final splashDone = !ref.read(splashDelayProvider).isLoading;
      final location = state.matchedLocation;

      if (!splashDone || auth.isLoading && !auth.hasValue) {
        if (location == Routes.splash) return null;
        return Uri(path: Routes.splash, queryParameters: {'from': state.uri.toString()}).toString();
      }

      final signedIn = auth.value != null;
      if (!signedIn) {
        final onboardingSeen = ref.read(onboardingSeenProvider);
        if (location == Routes.onboarding && onboardingSeen) return Routes.signIn;
        if (publicRoutes.contains(location)) return null;
        return onboardingSeen ? Routes.signIn : Routes.onboarding;
      }

      if (location == Routes.splash) {
        final from = state.uri.queryParameters['from'];
        final returnsToApp = from != null && from.startsWith('/') && !from.startsWith(Routes.splash) && !publicRoutes.contains(from);
        return returnsToApp ? from : Routes.home;
      }
      if (publicRoutes.contains(location)) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.habits, builder: (_, _) => const DailyHabitsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.reports, builder: (_, _) => const ReportsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(
        path: Routes.myPlan,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const MyPlanScreen(),
        routes: [GoRoute(path: 'plans', builder: (_, _) => const PlansScreen())],
      ),
      GoRoute(path: Routes.gallery, parentNavigatorKey: _rootKey, builder: (_, _) => const GalleryScreen()),
      GoRoute(path: Routes.settings, parentNavigatorKey: _rootKey, builder: (_, _) => const SettingsScreen()),
      GoRoute(path: Routes.about, parentNavigatorKey: _rootKey, builder: (_, _) => const AboutScreen()),
      GoRoute(path: Routes.changePassword, parentNavigatorKey: _rootKey, builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: Routes.announcements, parentNavigatorKey: _rootKey, builder: (_, _) => const AnnouncementsScreen()),
      GoRoute(
        path: Routes.customers,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CustomerListScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const CustomerFormScreen()),
          GoRoute(
            path: ':id/edit',
            builder: (_, state) => CustomerFormScreen(customerId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: ':id/record',
            builder: (_, state) => ServiceRecordScreen(customerId: int.parse(state.pathParameters['id']!)),
          ),
          GoRoute(
            path: ':id/before-after',
            builder: (_, state) => BeforeAfterScreen(customerId: int.parse(state.pathParameters['id']!)),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
