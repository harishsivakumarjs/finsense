import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../network/dio_client.dart';
import '../models/user_model.dart';
import '../core/constants/api_endpoints.dart';

class AuthService {
  final DioClient _dio;
  final _storage = const FlutterSecureStorage();
  final _googleSignIn = GoogleSignIn(
    // Web client ID from google-services.json (client_type: 3) — needed for Firebase server-side token
    serverClientId:
        '604608810400-ti1fvo9akhf3e3u601uku8il3va4cg40.apps.googleusercontent.com',
  );

  AuthService(this._dio);

  String get _jwtKey => dotenv.env['JWT_KEY'] ?? 'finsense_jwt_token';

  Future<({String token, UserModel user})> login(
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

  Future<({String token, UserModel user})> register({
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
    final token = res.data['access_token'] as String;
    await _storage.write(key: _jwtKey, value: token);
    final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

  Future<({String token, UserModel user})> signInWithGoogle() async {
    // 1. Trigger Google account picker
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google Sign-In cancelled');

    // 2. Obtain Google auth tokens
    final googleAuth = await googleUser.authentication;

    // 3. Create a Firebase credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Sign in to Firebase with the Google credential
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    // 5. Get the Firebase ID token to exchange with our backend
    final firebaseIdToken = await userCredential.user!.getIdToken();

    // 6. Exchange Firebase ID token for a FinSense JWT
    final res = await _dio.post(ApiEndpoints.googleFirebase, data: {
      'id_token': firebaseIdToken,
    });

    final token = res.data['access_token'] as String;
    await _storage.write(key: _jwtKey, value: token);
    final user = UserModel.fromJson(res.data['user'] as Map<String, dynamic>);
    return (token: token, user: user);
  }

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
    // Sign out from both Firebase and Google Sign-In
    await Future.wait([
      FirebaseAuth.instance.signOut(),
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
