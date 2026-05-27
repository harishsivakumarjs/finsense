import '../network/dio_client.dart';
import '../models/networth_model.dart';
import '../core/constants/api_endpoints.dart';

class NetworthService {
  final DioClient _dio;
  NetworthService(this._dio);

  Future<Map<String, dynamic>> getNetworth() async {
    final res = await _dio.get(ApiEndpoints.networth);
    return res.data as Map<String, dynamic>;
  }

  Future<List<NetworthHistoryPoint>> getHistory() async {
    final res = await _dio.get(ApiEndpoints.networthHistory);
    return (res.data as List).map((e) => NetworthHistoryPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> takeSnapshot() => _dio.post(ApiEndpoints.networthSnapshot, data: {});

  Future<List<Map<String, dynamic>>> getForecast() async {
    final res = await _dio.get(ApiEndpoints.networthForecast);
    return (res.data as List).cast<Map<String, dynamic>>();
  }
}
