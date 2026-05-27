import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/creator_service.dart';
import '../models/creator_model.dart';

final creatorServiceProvider = Provider<CreatorService>((ref) => CreatorService(ref.watch(dioClientProvider)));

final creatorProvider = AsyncNotifierProvider<CreatorNotifier, List<CreatorModel>>(CreatorNotifier.new);

class CreatorNotifier extends AsyncNotifier<List<CreatorModel>> {
  @override
  Future<List<CreatorModel>> build() => ref.read(creatorServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(creatorServiceProvider).getAll());
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(creatorServiceProvider).create(data);
    await refresh();
  }

  Future<void> edit(String id, Map<String, dynamic> data) async {
    await ref.read(creatorServiceProvider).update(id, data);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(creatorServiceProvider).delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
