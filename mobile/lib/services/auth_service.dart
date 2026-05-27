import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/dio_client.dart';
import '../models/user_model.dart';
import '../core/constants/api_endpoints.dart';

class AuthService {
  final DioClient _dio;
  final _storage = const FlutterSecureStorage();

  AuthService(this._dio);

  String get _jwtKey => dotenv.env['JWT_KEY'] ?? 'finsense_jwt_token';

  Future<({String token, UserModel user})> login(String email, String password) async {
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

  Future<UserModel> me() async {
    final res = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> switchMode(String mode) async {
    final res = await _dio.put(ApiEndpoints.mode, data: {'mode': mode});
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try { await _dio.post(ApiEndpoints.logout); } catch (_) {}
    await _storage.delete(key: _jwtKey);
  }

  Future<String?> getToken() => _storage.read(key: _jwtKey);

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
