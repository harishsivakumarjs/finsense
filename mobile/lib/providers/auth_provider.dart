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
  final bool isPendingVerification;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = true,
    this.isPendingVerification = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    bool? isPendingVerification,
  }) =>
      AuthState(
        user: user ?? this.user,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
        isPendingVerification:
            isPendingVerification ?? this.isPendingVerification,
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

  // ── Email/Password (Firebase-first) ──────────────────────────────────────

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final result =
            await ref.read(authServiceProvider).login(email, password);
        return AuthState(
            user: result.user, isAuthenticated: true, isLoading: false);
      } on EmailNotVerifiedException {
        return const AuthState(
            isLoading: false, isPendingVerification: true);
      }
    });
  }

  /// Creates a Firebase user, sends a verification email, and sets
  /// [isPendingVerification] = true. No DB record is created until the user
  /// verifies and calls [checkEmailVerified].
  Future<void> registerWithFirebase({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(authServiceProvider).registerWithFirebase(
              name: name,
              email: email,
              password: password,
            );
      } on EmailNotVerifiedException {
        return const AuthState(
            isLoading: false, isPendingVerification: true);
      }
      return const AuthState(isLoading: false);
    });
  }

  /// Reloads Firebase user and, if verified, exchanges token for FinSense JWT.
  Future<void> checkEmailVerified() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(authServiceProvider).checkEmailVerified();
      return AuthState(
          user: result.user, isAuthenticated: true, isLoading: false);
    });
  }

  // ── Google ────────────────────────────────────────────────────────────────

  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(authServiceProvider).signInWithGoogle();
      return AuthState(
          user: result.user, isAuthenticated: true, isLoading: false);
    });
  }

  // ── Session ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state =
        const AsyncData(AuthState(isAuthenticated: false, isLoading: false));
  }

  Future<void> switchMode(String mode) async {
    final user = await ref.read(authServiceProvider).switchMode(mode);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(user: user));
    }
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
