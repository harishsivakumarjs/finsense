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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return '/splash';

      final auth = authState.value;
      final isAuth = auth?.isAuthenticated ?? false;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isSplash) return null;
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
    ],
  );
});
