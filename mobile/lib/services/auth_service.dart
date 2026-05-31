import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../network/dio_client.dart';
import '../models/user_model.dart';
import '../core/constants/api_endpoints.dart';

/// Thrown after registration when the user must verify their email before
/// they can log in. Contains the email address so the UI can display it.
class EmailVerificationPendingException implements Exception {
  final String email;
  final String message;
  const EmailVerificationPendingException({required this.email, required this.message});
}

class AuthService {
  final DioClient _dio;
  final _storage = const FlutterSecureStorage();
  final _firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(
    serverClientId:
        '604608810400-ti1fvo9akhf3e3u601uku8il3va4cg40.apps.googleusercontent.com',
  );

  AuthService(this._dio);

  String get _jwtKey => dotenv.env['JWT_KEY'] ?? 'finsense_jwt_token';

  // ── Email / Password (backend-only) ───────────────────────────────────────

  /// Registers a new user via the backend.
  /// On success, the backend sends a verification email and returns a message
  /// (NOT a JWT). This method throws [EmailVerificationPendingException] so the
  /// caller can show the "verify your email" screen.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String mode,
  }) async {
    final res = await _dio.post(ApiEndpoints.register, data: {
      'name': name,
      'email': email,
      'password': password,
      'mode': mode,
    });
    final message = res.data['message'] as String? ??
        'Account created. Please verify your email before signing in.';
    throw EmailVerificationPendingException(email: email, message: message);
  }

  /// Logs in via backend. Returns the JWT + user on success.
  /// Throws [EmailVerificationPendingException] when the backend returns 403
  /// (account exists but email not verified).
  Future<({String token, UserModel user})> login(
      String email, String password) async {
    try {
      final res = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: _jwtKey, value: token);
      final user =
          UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
      return (token: token, user: user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final detail = e.response?.data?['detail'] as String? ??
            'Please verify your email before signing in.';
        throw EmailVerificationPendingException(
            email: email, message: detail);
      }
      rethrow;
    }
  }

  /// Requests a fresh verification email from the backend.
  Future<void> resendVerificationEmail(String email) async {
    await _dio.post(ApiEndpoints.resendVerification, data: {'email': email});
  }

  // ── Google Sign-In (Firebase) ─────────────────────────────────────────────

  Future<({String token, UserModel user})> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final firebaseIdToken =
        await userCredential.user!.getIdToken();

    final res = await _dio.post(ApiEndpoints.googleFirebase, data: {
      'id_token': firebaseIdToken,
    });
    final token = res.data['access_token'] as String;
    await _storage.write(key: _jwtKey, value: token);
    final user =
        UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  // ── Session ───────────────────────────────────────────────────────────────

  Future<UserModel> me() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> switchMode(String mode) async {
    final res = await _dio.put(ApiEndpoints.mode, data: {'mode': mode});
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (_) {}
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]).catchError((_) {});
    await _storage.delete(key: _jwtKey);
  }

  Future<String?> getToken() => _storage.read(key: _jwtKey);

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
