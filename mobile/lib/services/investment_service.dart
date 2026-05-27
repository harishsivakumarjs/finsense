import '../network/dio_client.dart';
import '../models/investment_model.dart';
import '../core/constants/api_endpoints.dart';

class InvestmentService {
  final DioClient _dio;
  InvestmentService(this._dio);

  Future<List<InvestmentModel>> getAll() async {
    final res = await _dio.get(ApiEndpoints.investments);
    return (res.data as List).map((e) => InvestmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<InvestmentModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.investments, data: data);
    return InvestmentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<InvestmentModel> update(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.investments}/$id', data: data);
    return InvestmentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('${ApiEndpoints.investments}/$id');

  Future<InvestmentModel> updateValue(String id, double value) async {
    final res = await _dio.put('${ApiEndpoints.investments}/$id/value', data: {'current_value': value});
    return InvestmentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getAllocation() async {
    final res = await _dio.get(ApiEndpoints.investmentsAllocation);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getXirr() async {
    final res = await _dio.get(ApiEndpoints.investmentsXirr);
    return res.data as Map<String, dynamic>;
  }
}
