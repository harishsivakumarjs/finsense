import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/insurance_service.dart';
import '../models/insurance_model.dart';

final insuranceServiceProvider = Provider<InsuranceService>((ref) => InsuranceService(ref.watch(dioClientProvider)));

final insuranceProvider = AsyncNotifierProvider<InsuranceNotifier, List<InsuranceModel>>(InsuranceNotifier.new);

class InsuranceNotifier extends AsyncNotifier<List<InsuranceModel>> {
  @override
  Future<List<InsuranceModel>> build() => ref.read(insuranceServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(insuranceServiceProvider).getAll());
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(insuranceServiceProvider).create(data);
    await refresh();
  }

  Future<void> edit(String id, Map<String, dynamic> data) async {
    await ref.read(insuranceServiceProvider).update(id, data);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(insuranceServiceProvider).delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
