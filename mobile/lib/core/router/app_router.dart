import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/income/income_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/debt/debt_screen.dart';
import '../../screens/trading/trading_screen.dart';
import '../../screens/investments/investments_screen.dart';
import '../../screens/insurance/insurance_screen.dart';
import '../../screens/creator/creator_screen.dart';
import '../../screens/tax/tax_screen.dart';
import '../../screens/networth/networth_screen.dart';
import '../../screens/friends/friends_screen.dart';
import '../../screens/simulator/simulator_screen.dart';
import '../../screens/profile/profile_screen.dart';

// Bridges Riverpod auth state into a ChangeNotifier so GoRouter's
// refreshListenable can trigger redirect re-evaluation without recreating
// the entire GoRouter on every auth state change.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: listenable,
    redirect: (context, state) {
      final authAsync = ref.read(authProvider);
      if (authAsync.isLoading) return null;

      final isAuth = authAsync.value?.isAuthenticated ?? false;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (loc == '/splash') return null;
      if (!isAuth && !isAuthRoute) return '/login';
      if (isAuth && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/income', builder: (_, __) => const IncomeScreen()),
      GoRoute(path: '/expenses', builder: (_, __) => const ExpensesScreen()),
      GoRoute(path: '/debt', builder: (_, __) => const DebtScreen()),
      GoRoute(path: '/trading', builder: (_, __) => const TradingScreen()),
      GoRoute(path: '/investments', builder: (_, __) => const InvestmentsScreen()),
      GoRoute(path: '/insurance', builder: (_, __) => const InsuranceScreen()),
      GoRoute(path: '/creator', builder: (_, __) => const CreatorScreen()),
      GoRoute(path: '/tax', builder: (_, __) => const TaxScreen()),
      GoRoute(path: '/networth', builder: (_, __) => const NetworthScreen()),
      GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
      GoRoute(path: '/simulator', builder: (_, __) => const SimulatorScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
  );

  ref.onDispose(listenable.dispose);
  return router;
});
