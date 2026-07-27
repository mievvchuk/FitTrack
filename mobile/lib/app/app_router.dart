import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_exercises_screen.dart';
import '../features/admin/presentation/screens/admin_payments_screen.dart';
import '../features/admin/presentation/screens/admin_users_screen.dart';
import '../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../features/auth/presentation/providers/auth_controller.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/exercises/presentation/screens/exercise_library_screen.dart';
import '../features/payments/presentation/screens/checkout_screen.dart';
import '../features/payments/presentation/screens/payment_history_screen.dart';
import '../features/payments/presentation/screens/payment_success_screen.dart';
import '../features/payments/presentation/screens/premium_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/progress/presentation/screens/progress_screen.dart';
import '../features/trainer/presentation/screens/trainer_clients_screen.dart';
import '../features/trainer/presentation/screens/trainer_dashboard_screen.dart';
import '../features/trainer/presentation/screens/trainer_programs_screen.dart';
import '../features/workouts/presentation/screens/workouts_screen.dart';
import 'home_dashboard_screen.dart';
import 'splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.matchedLocation;
      final isAuthRoute = AppRoutes.authRoutes.contains(location);
      final isSplash = location == AppRoutes.splash;

      if (authState.status == AuthStatus.unknown) {
        return isSplash ? null : AppRoutes.splash;
      }

      if (authState.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      if (authState.status == AuthStatus.authenticated &&
          (isAuthRoute || isSplash)) {
        return AppRoutes.home;
      }

      if (authState.status == AuthStatus.authenticated) {
        final user = authState.user;

        if (_isAdminRoute(location) && !(user?.isAdmin ?? false)) {
          return AppRoutes.home;
        }

        if (_isTrainerRoute(location) &&
            !(user?.can('programs:create') ?? false) &&
            !(user?.can('clients:read') ?? false)) {
          return AppRoutes.home;
        }
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.exercises,
        builder: (context, state) => const ExerciseLibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.workouts,
        builder: (context, state) => const WorkoutsScreen(),
      ),
      GoRoute(
        path: AppRoutes.progress,
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (context, state) => const AIAssistantScreen(),
      ),
      GoRoute(
        path: AppRoutes.payments,
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.premium,
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        builder: (context, state) {
          return PaymentSuccessScreen(
            paymentId: state.uri.queryParameters['paymentId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.trainerDashboard,
        builder: (context, state) => const TrainerDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.trainerPrograms,
        builder: (context, state) => const TrainerProgramsScreen(),
      ),
      GoRoute(
        path: AppRoutes.trainerClients,
        builder: (context, state) => const TrainerClientsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminExercises,
        builder: (context, state) => const AdminExercisesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPayments,
        builder: (context, state) => const AdminPaymentsScreen(),
      ),
    ],
  );
});

bool _isTrainerRoute(String location) {
  return AppRoutes.trainerRoutes.contains(location) ||
      location.startsWith('${AppRoutes.trainerDashboard}/');
}

bool _isAdminRoute(String location) {
  return AppRoutes.adminRoutes.contains(location) ||
      location.startsWith('${AppRoutes.adminDashboard}/');
}
