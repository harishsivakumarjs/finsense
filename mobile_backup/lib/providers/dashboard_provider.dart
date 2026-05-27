import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/dashboard_model.dart';

final dashboardProvider = AsyncNotifierProvider<DashboardNotifier, DashboardModel?>(DashboardNotifier.new);

class DashboardNotifier extends AsyncNotifier<DashboardModel?> {
  @override
  Future<DashboardModel?> build() => _fetch();

  Future<DashboardModel?> _fetch() async {
    final res = await ref.read(dioClientProvider).get(ApiEndpoints.dashboard);
    return DashboardModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
