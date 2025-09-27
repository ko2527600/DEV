import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/supabase_auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/courses_screen.dart';
import '../../features/dashboard/presentation/screens/progress_screen.dart';
import '../../features/dashboard/presentation/screens/study_groups_screen.dart';
import '../../features/dashboard/presentation/screens/resources_screen.dart';
import '../../features/dashboard/presentation/screens/notifications_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isGoingToSplash = state.matchedLocation == '/';

      // Allow splash screen to show
      if (isGoingToSplash) {
        return null;
      }

      // If user is not logged in and not going to auth screens, redirect to login
      if (!isLoggedIn && !isGoingToAuth) {
        return '/login';
      }

      // If user is logged in and going to auth screens, redirect to dashboard
      if (isLoggedIn && isGoingToAuth) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CoursesScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/study-groups',
        builder: (context, state) => const StudyGroupsScreen(),
      ),
      GoRoute(
        path: '/resources',
        builder: (context, state) => const ResourcesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
