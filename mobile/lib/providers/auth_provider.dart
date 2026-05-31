import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../network/dio_client.dart';
import '../services/auth_service.dart';

export '../services/auth_service.dart' show EmailVerificationPendingException;

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioClientProvider));
});

class AuthState {
  final UserModel? user;
  final bool isAuthenticated;
  final bool isLoading;
  /// Set when the backend asks the user to verify their email.
  final bool isPendingVerification;
  /// The email address waiting for verification (for UI display + resend).
  final String? pendingEmail;
  final String? pendingMessage;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = true,
    this.isPendingVerification = false,
    this.pendingEmail,
    this.pendingMessage,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isAuthenticated,
    bool? isLoading,
    bool? isPendingVerification,
    String? pendingEmail,
    String? pendingMessage,
  }) =>
      AuthState(
        user: user ?? this.user,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
        isPendingVerification:
            isPendingVerification ?? this.isPendingVerification,
        pendingEmail: pendingEmail ?? this.pendingEmail,
        pendingMessage: pendingMessage ?? this.pendingMessage,
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

  // ── Email / Password ──────────────────────────────────────────────────────

  /// Registers via backend. On success sets isPendingVerification = true.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String mode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await ref.read(authServiceProvider).register(
              name: name,
              email: email,
              password: password,
              mode: mode,
            );
      } on EmailVerificationPendingException catch (e) {
        return AuthState(
          isLoading: false,
          isPendingVerification: true,
          pendingEmail: e.email,
          pendingMessage: e.message,
        );
      }
      return const AuthState(isLoading: false);
    });
  }

  /// Logs in via backend. Propagates EmailVerificationPendingException as
  /// isPendingVerification state instead of an error.
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        final result =
            await ref.read(authServiceProvider).login(email, password);
        return AuthState(
            user: result.user, isAuthenticated: true, isLoading: false);
      } on EmailVerificationPendingException catch (e) {
        return AuthState(
          isLoading: false,
          isPendingVerification: true,
          pendingEmail: e.email,
          pendingMessage: e.message,
        );
      }
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
    if (current != null) state = AsyncData(current.copyWith(user: user));
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
