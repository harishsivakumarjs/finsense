import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/tax_service.dart';
import '../models/tax_model.dart';

final taxServiceProvider = Provider<TaxService>((ref) => TaxService(ref.watch(dioClientProvider)));

final taxSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(dioClientProvider).get('/tax/summary');
  return res.data as Map<String, dynamic>;
});

final taxDeductionsProvider = AsyncNotifierProvider<TaxDeductionsNotifier, List<TaxDeductionEntry>>(TaxDeductionsNotifier.new);

class TaxDeductionsNotifier extends AsyncNotifier<List<TaxDeductionEntry>> {
  @override
  Future<List<TaxDeductionEntry>> build() => ref.read(taxServiceProvider).getDeductions();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(taxServiceProvider).getDeductions());
  }

  Future<void> add(Map<String, dynamic> data) async {
    await ref.read(taxServiceProvider).addDeduction(data);
    await refresh();
  }
}

final advanceTaxProvider = AsyncNotifierProvider<AdvanceTaxNotifier, List<AdvanceTaxPayment>>(AdvanceTaxNotifier.new);

class AdvanceTaxNotifier extends AsyncNotifier<List<AdvanceTaxPayment>> {
  @override
  Future<List<AdvanceTaxPayment>> build() => ref.read(taxServiceProvider).getAdvanceTax();

  Future<void> markPaid(int id) async {
    await ref.read(taxServiceProvider).markAdvanceTaxPaid(id);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(taxServiceProvider).getAdvanceTax());
  }
}
