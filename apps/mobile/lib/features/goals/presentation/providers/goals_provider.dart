import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/repositories/goals_repository.dart';
import '../../domain/models/goal_model.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return GoalsRepository(ref.watch(dioClientProvider));
});

final goalsProvider = FutureProvider.autoDispose<List<Goal>>((ref) async {
  return ref.watch(goalsRepositoryProvider).getGoals();
});

final goalDetailProvider = FutureProvider.family.autoDispose<Goal, String>((ref, id) async {
  return ref.watch(goalsRepositoryProvider).getGoal(id);
});

final goalAnalyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.watch(goalsRepositoryProvider).getGoalAnalytics();
});

class GoalNotifier extends StateNotifier<AsyncValue<void>> {
  final GoalsRepository _repository;
  final Ref _ref;

  GoalNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> createGoal(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createGoal(data);
      _ref.invalidate(goalsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateGoal(id, data);
      _ref.invalidate(goalsProvider);
      _ref.invalidate(goalDetailProvider(id));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteGoal(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteGoal(id);
      _ref.invalidate(goalsProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> contribute(String id, double amount, {String? note, String? transactionId}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.contributeToGoal(id, amount, note: note, transactionId: transactionId);
      _ref.invalidate(goalsProvider);
      _ref.invalidate(goalDetailProvider(id));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final goalActionProvider = StateNotifierProvider<GoalNotifier, AsyncValue<void>>((ref) {
  return GoalNotifier(ref.watch(goalsRepositoryProvider), ref);
});
