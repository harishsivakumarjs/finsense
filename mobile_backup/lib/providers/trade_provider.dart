import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/trade_service.dart';
import '../models/trade_model.dart';

final tradeServiceProvider = Provider<TradeService>((ref) => TradeService(ref.watch(dioClientProvider)));

final tradeProvider = AsyncNotifierProvider<TradeNotifier, List<TradeModel>>(TradeNotifier.new);

class TradeNotifier extends AsyncNotifier<List<TradeModel>> {
  @override
  Future<List<TradeModel>> build() => ref.read(tradeServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(tradeServiceProvider).getAll());
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(tradeServiceProvider).create(data);
    await refresh();
  }

  Future<void> edit(int id, Map<String, dynamic> data) async {
    await ref.read(tradeServiceProvider).update(id, data);
    await refresh();
  }

  Future<void> remove(int id) async {
    await ref.read(tradeServiceProvider).delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
