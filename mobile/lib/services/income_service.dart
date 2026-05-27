import '../network/dio_client.dart';
import '../models/income_model.dart';
import '../core/constants/api_endpoints.dart';

class IncomeService {
  final DioClient _dio;
  IncomeService(this._dio);

  Future<List<IncomeModel>> getAll({int? month, int? year}) async {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    final res = await _dio.get(ApiEndpoints.income, params: params);
    return (res.data as List).map((e) => IncomeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<IncomeModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.income, data: data);
    return IncomeModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<IncomeModel> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.income}/$id', data: data);
    return IncomeModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('${ApiEndpoints.income}/$id');

  Future<Map<String, dynamic>> getSummary({int? year}) async {
    final res = await _dio.get(ApiEndpoints.incomeSummary, params: year != null ? {'year': year} : null);
    return res.data as Map<String, dynamic>;
  }
}
