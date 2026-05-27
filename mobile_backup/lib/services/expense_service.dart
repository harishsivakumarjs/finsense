import '../network/dio_client.dart';
import '../models/expense_model.dart';
import '../core/constants/api_endpoints.dart';

class ExpenseService {
  final DioClient _dio;
  ExpenseService(this._dio);

  Future<List<ExpenseModel>> getAll({int? month, int? year}) async {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    final res = await _dio.get(ApiEndpoints.expenses, params: params);
    return (res.data as List).map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ExpenseModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.expenses, data: data);
    return ExpenseModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ExpenseModel> update(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.expenses}/$id', data: data);
    return ExpenseModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _dio.delete('${ApiEndpoints.expenses}/$id');

  Future<Map<String, dynamic>> getSummary() async {
    final res = await _dio.get(ApiEndpoints.expensesSummary);
    return res.data as Map<String, dynamic>;
  }

  Future<List<ExpenseModel>> getSubscriptions() async {
    final res = await _dio.get(ApiEndpoints.expensesSubscriptions);
    return (res.data as List).map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
