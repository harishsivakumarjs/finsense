import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../network/dio_client.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioClientProvider));
});

class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;

  const AuthState({this.user, this.isAuthenticated = false, this.isLoading = true});

  AuthState copyWith({UserModel? user, bool? isAuthenticated, bool? isLoading}) => AuthState(
        user: user ?? this.user,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
      );
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final svc = ref.read(authServiceProvider);
    final isAuth = await svc.isAuthenticated();
    if (!isAuth) return const AuthState(isLoading: false);
    try {
      final user = await svc.me();
      return AuthState(user: user, isAuthenticated: true, isLoading: false);
    } catch (_) {
      return const AuthState(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authServiceProvider).login(email, password);
      return AuthState(user: result.user, isAuthenticated: true, isLoading: false);
    });
  }

  Future<void> register({required String name, required String email, required String password, required String mode}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authServiceProvider).register(name: name, email: email, password: password, mode: mode);
      return AuthState(user: result.user, isAuthenticated: true, isLoading: false);
    });
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncData(AuthState(isAuthenticated: false, isLoading: false));
  }

  Future<void> switchMode(String mode) async {
    final user = await ref.read(authServiceProvider).switchMode(mode);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(user: user));
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
