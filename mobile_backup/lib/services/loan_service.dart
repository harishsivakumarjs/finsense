import '../network/dio_client.dart';
import '../models/loan_model.dart';
import '../core/constants/api_endpoints.dart';

class LoanService {
  final DioClient _dio;
  LoanService(this._dio);

  Future<List<LoanModel>> getLoans() async {
    final res = await _dio.get(ApiEndpoints.loans);
    return (res.data as List).map((e) => LoanModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LoanModel> createLoan(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.loans, data: data);
    return LoanModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LoanModel> updateLoan(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.loans}/$id', data: data);
    return LoanModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteLoan(int id) => _dio.delete('${ApiEndpoints.loans}/$id');

  Future<Map<String, dynamic>> getScore() async {
    final res = await _dio.get(ApiEndpoints.loansScore);
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getForecast() async {
    final res = await _dio.get(ApiEndpoints.loansForecast);
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getDebtFreeDate() async {
    final res = await _dio.get(ApiEndpoints.loansDebtfree);
    return res.data as Map<String, dynamic>;
  }

  Future<List<CreditCardModel>> getCards() async {
    final res = await _dio.get(ApiEndpoints.cards);
    return (res.data as List).map((e) => CreditCardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CreditCardModel> createCard(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.cards, data: data);
    return CreditCardModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CreditCardModel> updateCard(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.cards}/$id', data: data);
    return CreditCardModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteCard(int id) => _dio.delete('${ApiEndpoints.cards}/$id');
}
