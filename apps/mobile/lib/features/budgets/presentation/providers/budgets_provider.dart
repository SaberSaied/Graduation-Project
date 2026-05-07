import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/repositories/budgets_repository.dart';
import '../../domain/models/budget_model.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(dioClientProvider));
});

final budgetsProvider = FutureProvider.autoDispose<List<Budget>>((ref) async {
  return ref.watch(budgetsRepositoryProvider).getBudgets();
});

final budgetStatusProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(budgetsRepositoryProvider).getBudgetStatus();
});

final budgetAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(budgetsRepositoryProvider).getBudgetAnalytics();
});

class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final BudgetsRepository _repository;
  final Ref _ref;

  BudgetNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> createBudget(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createBudget(data);
      _ref.invalidate(budgetsProvider);
      _ref.invalidate(budgetStatusProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateBudget(id, data);
      _ref.invalidate(budgetsProvider);
      _ref.invalidate(budgetStatusProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBudget(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteBudget(id);
      _ref.invalidate(budgetsProvider);
      _ref.invalidate(budgetStatusProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final budgetActionProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
  return BudgetNotifier(ref.watch(budgetsRepositoryProvider), ref);
});
