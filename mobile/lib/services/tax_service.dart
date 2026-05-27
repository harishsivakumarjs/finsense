import '../network/dio_client.dart';
import '../models/tax_model.dart';
import '../core/constants/api_endpoints.dart';

class TaxService {
  final DioClient _dio;
  TaxService(this._dio);

  Future<Map<String, dynamic>> getSummary({int? year}) async {
    final res = await _dio.get(ApiEndpoints.taxSummary, params: year != null ? {'year': year} : null);
    return res.data as Map<String, dynamic>;
  }

  Future<List<TaxDeductionEntry>> getDeductions() async {
    final res = await _dio.get(ApiEndpoints.taxDeductions);
    return (res.data as List).map((e) => TaxDeductionEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TaxDeductionEntry> addDeduction(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.taxDeductions, data: data);
    return TaxDeductionEntry.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<AdvanceTaxPayment>> getAdvanceTax() async {
    final res = await _dio.get(ApiEndpoints.taxAdvance);
    return (res.data as List).map((e) => AdvanceTaxPayment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAdvanceTaxPaid(String id) =>
      _dio.put('${ApiEndpoints.taxAdvance}/$id/pay', data: {});

  Future<List<TaxSuggestion>> getSuggestions() async {
    final res = await _dio.get(ApiEndpoints.taxSuggestions);
    return (res.data as List).map((e) => TaxSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }
}
