import '../network/dio_client.dart';
import '../models/friend_model.dart';
import '../core/constants/api_endpoints.dart';

class FriendService {
  final DioClient _dio;
  FriendService(this._dio);

  Future<List<FriendModel>> getAll() async {
    final res = await _dio.get(ApiEndpoints.friends);
    return (res.data as List).map((e) => FriendModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FriendModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.friends, data: data);
    return FriendModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FriendModel> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.friends}/$id', data: data);
    return FriendModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('${ApiEndpoints.friends}/$id');

  Future<FriendModel> settle(String id) async {
    final res = await _dio.put('${ApiEndpoints.friends}/$id/settle', data: {});
    return FriendModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getSummary() async {
    final res = await _dio.get(ApiEndpoints.friendsSummary);
    return res.data as Map<String, dynamic>;
  }
}
