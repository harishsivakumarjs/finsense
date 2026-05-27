import '../network/dio_client.dart';
import '../models/insurance_model.dart';
import '../core/constants/api_endpoints.dart';

class InsuranceService {
  final DioClient _dio;
  InsuranceService(this._dio);

  Future<List<InsuranceModel>> getAll() async {
    final res = await _dio.get(ApiEndpoints.insurance);
    return (res.data as List).map((e) => InsuranceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<InsuranceModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.insurance, data: data);
    return InsuranceModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<InsuranceModel> update(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.insurance}/$id', data: data);
    return InsuranceModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _dio.delete('${ApiEndpoints.insurance}/$id');

  Future<Map<String, dynamic>> getSummary() async {
    final res = await _dio.get(ApiEndpoints.insuranceSummary);
    return res.data as Map<String, dynamic>;
  }
}
