import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/income_service.dart';
import '../models/income_model.dart';

final incomeServiceProvider = Provider<IncomeService>((ref) => IncomeService(ref.watch(dioClientProvider)));

final incomeProvider = AsyncNotifierProvider<IncomeNotifier, List<IncomeModel>>(IncomeNotifier.new);

class IncomeNotifier extends AsyncNotifier<List<IncomeModel>> {
  @override
  Future<List<IncomeModel>> build() => _fetch();

  Future<List<IncomeModel>> _fetch({int? month, int? year}) =>
      ref.read(incomeServiceProvider).getAll(month: month, year: year);

  Future<void> refresh({int? month, int? year}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(month: month, year: year));
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(incomeServiceProvider).create(data);
    await refresh();
  }

  Future<void> edit(int id, Map<String, dynamic> data) async {
    await ref.read(incomeServiceProvider).update(id, data);
    await refresh();
  }

  Future<void> remove(int id) async {
    await ref.read(incomeServiceProvider).delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
