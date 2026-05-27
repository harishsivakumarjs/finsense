import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/loan_service.dart';
import '../models/loan_model.dart';

final loanServiceProvider = Provider<LoanService>((ref) => LoanService(ref.watch(dioClientProvider)));

final loanProvider = AsyncNotifierProvider<LoanNotifier, List<LoanModel>>(LoanNotifier.new);

class LoanNotifier extends AsyncNotifier<List<LoanModel>> {
  @override
  Future<List<LoanModel>> build() => ref.read(loanServiceProvider).getLoans();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(loanServiceProvider).getLoans());
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(loanServiceProvider).createLoan(data);
    await refresh();
  }

  Future<void> edit(String id, Map<String, dynamic> data) async {
    await ref.read(loanServiceProvider).updateLoan(id, data);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(loanServiceProvider).deleteLoan(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}

final cardProvider = AsyncNotifierProvider<CardNotifier, List<CreditCardModel>>(CardNotifier.new);

class CardNotifier extends AsyncNotifier<List<CreditCardModel>> {
  @override
  Future<List<CreditCardModel>> build() => ref.read(loanServiceProvider).getCards();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(loanServiceProvider).getCards());
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(loanServiceProvider).createCard(data);
    await refresh();
  }

  Future<void> edit(String id, Map<String, dynamic> data) async {
    await ref.read(loanServiceProvider).updateCard(id, data);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(loanServiceProvider).deleteCard(id);
    state = AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}
