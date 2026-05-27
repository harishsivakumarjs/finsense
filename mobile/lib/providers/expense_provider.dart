import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/expense_service.dart';
import '../models/expense_model.dart';

final expenseServiceProvider = Provider<ExpenseService>((ref) => ExpenseService(ref.watch(dioClientProvider)));

final expenseProvider = AsyncNotifierProvider<ExpenseNotifier, List<ExpenseModel>>(ExpenseNotifier.new);

class ExpenseNotifier extends AsyncNotifier<List<ExpenseModel>> {
  @override
  Future<List<ExpenseModel>> build() => _fetch();

  Future<List<ExpenseModel>> _fetch({int? month, int? year}) =>
      ref.read(expenseServiceProvider).getAll(month: month, year: year);

  Future<void> refresh({int? month, int? year}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(month: month, year: year));
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(expenseServiceProvider).create(data);
    await refresh();
  }

  Future<void> edit(String id, Map<String, dynamic> data) async {
    await ref.read(expenseServiceProvider).update(id, data);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(expenseServiceProvider).delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
