import '../network/dio_client.dart';
import '../core/constants/api_endpoints.dart';

class SimulatorService {
  final DioClient _dio;
  SimulatorService(this._dio);

  Future<Map<String, dynamic>> runScenario(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.simulatorScenario, data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> skipEmi(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiEndpoints.simulatorSkipEmi, data: data);
    return res.data as Map<String, dynamic>;
  }
}
