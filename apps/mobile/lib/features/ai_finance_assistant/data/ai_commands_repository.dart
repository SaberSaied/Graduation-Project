import '../../../../core/network/dio_client.dart';
import '../domain/models/ai_command_models.dart';

class AICommandsRepository {
  final DioClient _client;

  AICommandsRepository(this._client);

  Future<AICommandResponse> processPrompt(String prompt) async {
    final response = await _client.post('/ai-commands/process', data: {'prompt': prompt});
    return AICommandResponse.fromJson(response.data['data']);
  }

  Future<void> executeActions(List<AICommandAction> actions) async {
    await _client.post('/ai-commands/execute', data: {
      'actions': actions.map((a) => a.toJson()).toList(),
    });
  }
}
