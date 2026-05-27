import '../network/dio_client.dart';
import '../models/creator_model.dart';
import '../core/constants/api_endpoints.dart';

class CreatorService {
  final DioClient _dio;
  CreatorService(this._dio);

  Future<List<CreatorModel>> getAll() async {
    final res = await _dio.get(ApiEndpoints.creator);
    return (res.data as List).map((e) => CreatorModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CreatorModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.creator, data: data);
    return CreatorModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CreatorModel> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.creator}/$id', data: data);
    return CreatorModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('${ApiEndpoints.creator}/$id');

  Future<Map<String, dynamic>> getSummary() async {
    final res = await _dio.get(ApiEndpoints.creatorSummary);
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getRpmTrend() async {
    final res = await _dio.get(ApiEndpoints.creatorRpm);
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}
