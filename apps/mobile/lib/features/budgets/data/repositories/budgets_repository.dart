import '../../../../core/network/dio_client.dart';
import '../../domain/models/budget_model.dart';

class BudgetsRepository {
  final DioClient _client;

  BudgetsRepository(this._client);

  Future<List<Budget>> getBudgets() async {
    final response = await _client.get('/budgets');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => Budget.fromJson(json)).toList();
  }

  Future<List<dynamic>> getBudgetStatus() async {
    final response = await _client.get('/budgets/status');
    return response.data['data'];
  }

  Future<Budget> createBudget(Map<String, dynamic> data) async {
    final response = await _client.post('/budgets', data: data);
    return Budget.fromJson(response.data['data']);
  }

  Future<Budget> updateBudget(String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/budgets/$id', data: data);
    return Budget.fromJson(response.data['data']);
  }

  Future<void> deleteBudget(String id) async {
    await _client.delete('/budgets/$id');
  }

  Future<Map<String, dynamic>> getBudgetAnalytics() async {
    final response = await _client.get('/budgets/analytics');
    return response.data['data'];
  }
}
