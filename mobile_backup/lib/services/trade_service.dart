import '../network/dio_client.dart';
import '../models/trade_model.dart';
import '../core/constants/api_endpoints.dart';

class TradeService {
  final DioClient _dio;
  TradeService(this._dio);

  Future<List<TradeModel>> getAll() async {
    final res = await _dio.get(ApiEndpoints.trades);
    return (res.data as List).map((e) => TradeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TradeModel> create(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.trades, data: data);
    return TradeModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TradeModel> update(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiEndpoints.trades}/$id', data: data);
    return TradeModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _dio.delete('${ApiEndpoints.trades}/$id');

  Future<Map<String, dynamic>> getPnl() async {
    final res = await _dio.get(ApiEndpoints.tradesPnl);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final res = await _dio.get(ApiEndpoints.tradesAnalytics);
    return res.data as Map<String, dynamic>;
  }
}
