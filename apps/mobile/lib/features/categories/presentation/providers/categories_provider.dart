import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/storage/local_cache.dart';
import '../../data/categories_repository.dart';
import '../../domain/models/category_model.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CategoriesRepository(dioClient);
});

class CategoriesState {
  final List<Category> incomeCategories;
  final List<Category> expenseCategories;
  final bool isLoading;
  final String? error;

  CategoriesState({
    this.incomeCategories = const [],
    this.expenseCategories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriesState copyWith({
    List<Category>? incomeCategories,
    List<Category>? expenseCategories,
    bool? isLoading,
    String? error,
  }) {
    return CategoriesState(
      incomeCategories: incomeCategories ?? this.incomeCategories,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoriesRepository _repository;

  CategoriesNotifier(this._repository) : super(CategoriesState()) {
    loadCategories();
  }

  Future<void> loadCategories({String? search}) async {
    // Try to load from cache first
    final cached = LocalCache.getCachedCategories();
    if (cached != null && search == null) {
      final List<Category> all = cached.map((e) => Category.fromJson(e)).toList();
      state = state.copyWith(
        incomeCategories: all.where((c) => c.type == CategoryType.income).toList(),
        expenseCategories: all.where((c) => c.type == CategoryType.expense).toList(),
      );
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.getCategories(search: search);
      
      state = state.copyWith(
        incomeCategories: result['income']!,
        expenseCategories: result['expense']!,
        isLoading: false,
      );

      // Cache all if not searching
      if (search == null) {
        final allJson = [...result['income']!, ...result['expense']!]
            .map((c) => c.toJson())
            .toList();
        await LocalCache.cacheCategories(allJson);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addCategory(String name, String icon, String color, CategoryType type) async {
    try {
      final newCat = await _repository.createCategory(name, icon, color, type);
      if (type == CategoryType.income) {
        state = state.copyWith(incomeCategories: [...state.incomeCategories, newCat]..sort((a, b) => a.name.compareTo(b.name)));
      } else {
        state = state.copyWith(expenseCategories: [...state.expenseCategories, newCat]..sort((a, b) => a.name.compareTo(b.name)));
      }
      
      // Update cache
      final allJson = [...state.incomeCategories, ...state.expenseCategories]
          .map((Category c) => c.toJson())
          .toList();
      await LocalCache.cacheCategories(allJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      state = state.copyWith(
        incomeCategories: state.incomeCategories.where((c) => c.id != id).toList(),
        expenseCategories: state.expenseCategories.where((c) => c.id != id).toList(),
      );
      
      // Update cache
      final allJson = [...state.incomeCategories, ...state.expenseCategories]
          .map((Category c) => c.toJson())
          .toList();
      await LocalCache.cacheCategories(allJson);
    } catch (e) {
      rethrow;
    }
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  final repository = ref.watch(categoriesRepositoryProvider);
  return CategoriesNotifier(repository);
});
