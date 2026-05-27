import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/investment_service.dart';
import '../models/investment_model.dart';

final investmentServiceProvider = Provider<InvestmentService>((ref) => InvestmentService(ref.watch(dioClientProvider)));

final investmentProvider = AsyncNotifierProvider<InvestmentNotifier, List<InvestmentModel>>(InvestmentNotifier.new);

class InvestmentNotifier extends AsyncNotifier<List<InvestmentModel>> {
  @override
  Future<List<InvestmentModel>> build() => ref.read(investmentServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(investmentServiceProvider).getAll());
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(investmentServiceProvider).create(data);
    await refresh();
  }

  Future<void> edit(String id, Map<String, dynamic> data) async {
    await ref.read(investmentServiceProvider).update(id, data);
    await refresh();
  }

  Future<void> updateValue(String id, double value) async {
    await ref.read(investmentServiceProvider).updateValue(id, value);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(investmentServiceProvider).delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
