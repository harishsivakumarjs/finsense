import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/networth_service.dart';
import '../models/networth_model.dart';

final networthServiceProvider = Provider<NetworthService>((ref) => NetworthService(ref.watch(dioClientProvider)));

final networthProvider = AsyncNotifierProvider<NetworthNotifier, Map<String, dynamic>>(NetworthNotifier.new);

class NetworthNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() => _fetch();

  Future<Map<String, dynamic>> _fetch() => ref.read(networthServiceProvider).getNetworth();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> takeSnapshot() async {
    await ref.read(networthServiceProvider).takeSnapshot();
    await refresh();
  }
}

final networthHistoryProvider = FutureProvider<List<NetworthHistoryPoint>>((ref) async {
  return ref.watch(networthServiceProvider).getHistory();
});
