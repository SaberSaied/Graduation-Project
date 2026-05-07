import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(dioClientProvider);
  final response = await client.get(ApiConstants.analyticsDashboard);
  return response.data['data'] as Map<String, dynamic>;
});
