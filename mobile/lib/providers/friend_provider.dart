import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/friend_service.dart';
import '../models/friend_model.dart';

final friendServiceProvider = Provider<FriendService>((ref) => FriendService(ref.watch(dioClientProvider)));

final friendProvider = AsyncNotifierProvider<FriendNotifier, List<FriendModel>>(FriendNotifier.new);

class FriendNotifier extends AsyncNotifier<List<FriendModel>> {
  @override
  Future<List<FriendModel>> build() => ref.read(friendServiceProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(friendServiceProvider).getAll());
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(friendServiceProvider).create(data);
    await refresh();
  }

  Future<void> edit(String id, Map<String, dynamic> data) async {
    await ref.read(friendServiceProvider).update(id, data);
    await refresh();
  }

  Future<void> settle(String id) async {
    await ref.read(friendServiceProvider).settle(id);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(friendServiceProvider).delete(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
