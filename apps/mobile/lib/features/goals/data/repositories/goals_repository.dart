import '../../../../core/network/dio_client.dart';
import '../../domain/models/goal_model.dart';

class GoalsRepository {
  final DioClient _client;

  GoalsRepository(this._client);

  Future<List<Goal>> getGoals() async {
    final response = await _client.get('/goals');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => Goal.fromJson(json)).toList();
  }

  Future<Goal> getGoal(String id) async {
    final response = await _client.get('/goals/$id');
    return Goal.fromJson(response.data['data']);
  }

  Future<Goal> createGoal(Map<String, dynamic> data) async {
    final response = await _client.post('/goals', data: data);
    return Goal.fromJson(response.data['data']);
  }

  Future<Goal> updateGoal(String id, Map<String, dynamic> data) async {
    final response = await _client.patch('/goals/$id', data: data);
    return Goal.fromJson(response.data['data']);
  }

  Future<void> deleteGoal(String id) async {
    await _client.delete('/goals/$id');
  }

  Future<Map<String, dynamic>> contributeToGoal(String id, double amount, {String? note, String? transactionId}) async {
    final response = await _client.post('/goals/$id/contribute', data: {
      'amount': amount,
      'note': note,
      'transactionId': transactionId,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getGoalProgress(String id) async {
    final response = await _client.get('/goals/$id/progress');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getGoalAnalytics() async {
    final response = await _client.get('/goals/analytics');
    return response.data['data'];
  }
}
