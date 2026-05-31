import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../network/dio_client.dart';
import '../models/user_model.dart';
import '../core/constants/api_endpoints.dart';

/// Thrown when a Firebase user exists but their email is not yet verified.
class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException();
}

class AuthService {
  final DioClient _dio;
  final _storage = const FlutterSecureStorage();
  final _firebaseAuth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(
    // Web client ID from google-services.json (client_type: 3)
    serverClientId:
        '604608810400-ti1fvo9akhf3e3u601uku8il3va4cg40.apps.googleusercontent.com',
  );

  AuthService(this._dio);

  String get _jwtKey => dotenv.env['JWT_KEY'] ?? 'finsense_jwt_token';

  // ── Email/Password Registration via Firebase ──────────────────────────────

  /// Creates a Firebase user, sets their display name, and sends a
  /// verification email. Always throws [EmailNotVerifiedException] because the
  /// user must verify before they can access the app.
  Future<void> registerWithFirebase({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(name);
    await cred.user!.sendEmailVerification();
    throw const EmailNotVerifiedException();
  }

  // ── Email/Password Login (Firebase-first, backend fallback) ───────────────

  Future<({String token, UserModel user})> login(
      String email, String password) async {
    User? fbUser;
    bool useBackend = false;

    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      fbUser = cred.user;
    } on FirebaseAuthException catch (e) {
      const legacyCodes = {
        'user-not-found',
        'wrong-password',
        'invalid-credential',
      };
      if (legacyCodes.contains(e.code)) {
        useBackend = true; // No Firebase account → try legacy backend
      } else {
        rethrow; // too-many-requests, user-disabled, etc.
      }
    }

    if (fbUser != null) {
      // Reload to get the freshest emailVerified status
      await fbUser.reload();
      fbUser = _firebaseAuth.currentUser!;
      if (!fbUser.emailVerified) throw const EmailNotVerifiedException();
      // Exchange Firebase ID token for FinSense JWT
      return await _exchangeFirebaseToken(fbUser);
    }

    if (useBackend) {
      return await _legacyLogin(email, password);
    }

    throw Exception('Login failed');
  }

  // ── Verification helpers ──────────────────────────────────────────────────

  Future<void> resendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('Not signed in. Please try again.');
    await user.sendEmailVerification();
  }

  /// Reloads the Firebase user and, if verified, exchanges their token for a
  /// FinSense JWT. Throws if not yet verified.
  Future<({String token, UserModel user})> checkEmailVerified() async {
    var user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('Session expired. Please sign in again.');
    await user.reload();
    user = _firebaseAuth.currentUser!;
    if (!user.emailVerified) throw Exception('Email not yet verified');
    return await _exchangeFirebaseToken(user);
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────

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
    return await _exchangeFirebaseToken(userCredential.user!);
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Future<({String token, UserModel user})> _exchangeFirebaseToken(
      User fbUser) async {
    final idToken = await fbUser.getIdToken(true);
    final res = await _dio.post(ApiEndpoints.googleFirebase, data: {
      'id_token': idToken,
    });
    final token = res.data['access_token'] as String;
    await _storage.write(key: _jwtKey, value: token);
    final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<({String token, UserModel user})> _legacyLogin(
      String email, String password) async {
    final res = await _dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    final token = res.data['access_token'] as String;
    await _storage.write(key: _jwtKey, value: token);
    final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  // ── Other ─────────────────────────────────────────────────────────────────

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
