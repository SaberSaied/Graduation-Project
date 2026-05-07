import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/repositories/obligations_repository.dart';
import '../../domain/models/financial_obligation.dart';

final obligationsRepositoryProvider = Provider<ObligationsRepository>((ref) {
  return ObligationsRepository(ref.watch(dioClientProvider));
});

final obligationsProvider = FutureProvider.autoDispose.family<List<FinancialObligation>, String?>((ref, type) async {
  return ref.watch(obligationsRepositoryProvider).getObligations(type: type);
});

final obligationsSummaryProvider = FutureProvider.autoDispose<ObligationsSummary>((ref) async {
  return ref.watch(obligationsRepositoryProvider).getSummary();
});

class ObligationNotifier extends StateNotifier<AsyncValue<void>> {
  final ObligationsRepository _repository;
  final Ref _ref;

  ObligationNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> createObligation(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createObligation(data);
      _ref.invalidate(obligationsProvider);
      _ref.invalidate(obligationsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsPaid(String id, double amount) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markAsPaid(id, amount);
      _ref.invalidate(obligationsProvider);
      _ref.invalidate(obligationsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteObligation(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteObligation(id);
      _ref.invalidate(obligationsProvider);
      _ref.invalidate(obligationsSummaryProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final obligationActionProvider = StateNotifierProvider<ObligationNotifier, AsyncValue<void>>((ref) {
  return ObligationNotifier(ref.watch(obligationsRepositoryProvider), ref);
});
