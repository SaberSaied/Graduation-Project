import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../domain/models/category_model.dart';

class CategoriesRepository {
  final DioClient _dioClient;

  CategoriesRepository(this._dioClient);

  Future<Map<String, List<Category>>> getCategories({
    CategoryType? type,
    String? search,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.categories,
      queryParameters: {
        if (type != null) 'type': type == CategoryType.INCOME ? 'INCOME' : 'EXPENSE',
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final data = response.data['data'];
    
    final List<Category> incomeCategories = (data['incomeCategories'] as List)
        .map((json) => Category.fromJson(json))
        .toList();
        
    final List<Category> expenseCategories = (data['expenseCategories'] as List)
        .map((json) => Category.fromJson(json))
        .toList();

    return {
      'income': incomeCategories,
      'expense': expenseCategories,
    };
  }

  Future<Category> createCategory(String name, String icon, String color, CategoryType type) async {
    final response = await _dioClient.post(
      ApiConstants.categories,
      data: {
        'name': name,
        'icon': icon,
        'color': color,
        'type': type == CategoryType.INCOME ? 'INCOME' : 'EXPENSE',
      },
    );
    return Category.fromJson(response.data['data']);
  }

  Future<Category> updateCategory(String id, {String? name, String? icon, String? color}) async {
    final response = await _dioClient.patch(
      '${ApiConstants.categories}/$id',
      data: {
        if (name != null) 'name': name,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
      },
    );
    return Category.fromJson(response.data['data']);
  }

  Future<void> deleteCategory(String id) async {
    await _dioClient.delete('${ApiConstants.categories}/$id');
  }
}
