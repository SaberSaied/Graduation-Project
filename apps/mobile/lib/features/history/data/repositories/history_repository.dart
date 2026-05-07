import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/history_filter_model.dart';

class HistoryRepository {
  final DioClient _client;

  HistoryRepository(this._client);

  Future<Map<String, dynamic>> getTransactions({
    required HistoryFilter filter,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = filter.toQueryParameters();
    queryParams['page'] = page;
    queryParams['limit'] = limit;

    final response = await _client.get(
      ApiConstants.transactions,
      queryParameters: queryParams,
    );

    return response.data;
  }

  Future<Map<String, dynamic>> getStats(HistoryFilter filter) async {
    // We can use a dedicated stats endpoint or calculate from filtered transactions
    // For now, let's assume we might need a stats endpoint or use the dashboard analytics if it supports ranges
    // But since the user wants it in the history page, we'll fetch a summary.
    
    final range = filter.toQueryParameters();
    final response = await _client.get(
      ApiConstants.transactionsFilteredSummary,
      queryParameters: range,
    );
    
    return response.data;
  }
}
