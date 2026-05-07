import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../domain/models/history_filter_model.dart';
import '../../data/repositories/history_repository.dart';

final historyRepositoryProvider = Provider((ref) {
  final client = ref.watch(dioClientProvider);
  return HistoryRepository(client);
});

final historyFilterProvider = StateProvider<HistoryFilter>((ref) => HistoryFilter());

final historyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final filter = ref.watch(historyFilterProvider);
  final repo = ref.watch(historyRepositoryProvider);
  return repo.getStats(filter);
});

class HistoryState {
  final List<Map<String, dynamic>> transactions;
  final bool isLoading;
  final bool isLoadMore;
  final int page;
  final bool hasNext;
  final String? error;

  HistoryState({
    required this.transactions,
    this.isLoading = false,
    this.isLoadMore = false,
    this.page = 1,
    this.hasNext = true,
    this.error,
  });

  HistoryState copyWith({
    List<Map<String, dynamic>>? transactions,
    bool? isLoading,
    bool? isLoadMore,
    int? page,
    bool? hasNext,
    String? error,
  }) {
    return HistoryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      error: error,
    );
  }
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryRepository _repository;
  final HistoryFilter _filter;

  HistoryNotifier(this._repository, this._filter) : super(HistoryState(transactions: [])) {
    fetchTransactions();
  }

  Future<void> fetchTransactions({bool refresh = false}) async {
    if (state.isLoading || (state.isLoadMore && !refresh)) return;

    if (refresh) {
      state = state.copyWith(isLoading: true, page: 1, transactions: []);
    } else {
      state = state.copyWith(isLoadMore: true);
    }

    try {
      final result = await _repository.getTransactions(
        filter: _filter,
        page: state.page,
      );

      final newItems = List<Map<String, dynamic>>.from(result['data'] ?? []);
      final pagination = result['pagination'];
      
      state = state.copyWith(
        transactions: refresh ? newItems : [...state.transactions, ...newItems],
        isLoading: false,
        isLoadMore: false,
        page: state.page + 1,
        hasNext: pagination?['hasNext'] ?? false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        error: e.toString(),
      );
    }
  }

  void removeTransaction(String id) {
    state = state.copyWith(
      transactions: state.transactions.where((t) => t['id'] != id).toList(),
    );
  }
}

final historyTransactionsProvider = StateNotifierProvider.autoDispose<HistoryNotifier, HistoryState>((ref) {
  final repo = ref.watch(historyRepositoryProvider);
  final filter = ref.watch(historyFilterProvider);
  return HistoryNotifier(repo, filter);
});
