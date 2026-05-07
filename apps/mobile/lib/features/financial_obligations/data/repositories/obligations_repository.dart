import '../../../../core/network/dio_client.dart';
import '../../domain/models/financial_obligation.dart';

class ObligationsRepository {
  final DioClient _dioClient;

  ObligationsRepository(this._dioClient);

  Future<List<FinancialObligation>> getObligations({String? type}) async {
    final response = await _dioClient.get(
      '/obligations',
      queryParameters: type != null ? {'type': type} : null,
    );
    final List data = response.data['data'];
    return data.map((json) => FinancialObligation.fromJson(json)).toList();
  }

  Future<ObligationsSummary> getSummary() async {
    final response = await _dioClient.get('/obligations/summary');
    return ObligationsSummary.fromJson(response.data['data']);
  }

  Future<FinancialObligation> createObligation(Map<String, dynamic> data) async {
    final response = await _dioClient.post('/obligations', data: data);
    return FinancialObligation.fromJson(response.data['data']);
  }

  Future<FinancialObligation> updateObligation(String id, Map<String, dynamic> data) async {
    final response = await _dioClient.put('/obligations/$id', data: data);
    return FinancialObligation.fromJson(response.data['data']);
  }

  Future<void> deleteObligation(String id) async {
    await _dioClient.delete('/obligations/$id');
  }

  Future<void> markAsPaid(String id, double amount) async {
    await _dioClient.post('/obligations/$id/pay', data: {'amount': amount});
  }
}
