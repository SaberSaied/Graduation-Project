import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/ai_commands_repository.dart';
import '../../domain/models/ai_command_models.dart';

final aiCommandsRepositoryProvider = Provider<AICommandsRepository>((ref) {
  return AICommandsRepository(ref.watch(dioClientProvider));
});

class AICommandState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final AICommandResponse? pendingResponse;
  final String? error;

  AICommandState({
    this.messages = const [],
    this.isLoading = false,
    this.pendingResponse,
    this.error,
  });

  AICommandState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    AICommandResponse? pendingResponse,
    String? error,
  }) {
    return AICommandState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      pendingResponse: pendingResponse,
      error: error,
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class AICommandNotifier extends StateNotifier<AICommandState> {
  final AICommandsRepository _repository;

  AICommandNotifier(this._repository) : super(AICommandState());

  Future<void> sendPrompt(String prompt) async {
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: prompt, isUser: true, timestamp: DateTime.now())],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _repository.processPrompt(prompt);
      state = state.copyWith(
        isLoading: false,
        pendingResponse: response,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        messages: [...state.messages, ChatMessage(text: "Sorry, I had trouble parsing that. Could you try again?", isUser: false, timestamp: DateTime.now())],
      );
    }
  }

  Future<void> confirmActions() async {
    if (state.pendingResponse == null) return;
    
    final actions = state.pendingResponse!.actions;
    final summary = state.pendingResponse!.summary;
    
    state = state.copyWith(isLoading: true);
    
    try {
      await _repository.executeActions(actions);
      state = state.copyWith(
        isLoading: false,
        pendingResponse: null,
        messages: [...state.messages, ChatMessage(text: "Done! $summary", isUser: false, timestamp: DateTime.now())],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Execution failed: ${e.toString()}",
      );
    }
  }

  void cancelActions() {
    state = state.copyWith(pendingResponse: null);
  }
  
  void updateAction(int index, AICommandAction updatedAction) {
    if (state.pendingResponse == null) return;
    final actions = [...state.pendingResponse!.actions];
    actions[index] = updatedAction;
    state = state.copyWith(
      pendingResponse: AICommandResponse(
        actions: actions,
        summary: state.pendingResponse!.summary,
      ),
    );
  }

  void removeAction(int index) {
    if (state.pendingResponse == null) return;
    final actions = [...state.pendingResponse!.actions];
    actions.removeAt(index);
    state = state.copyWith(
      pendingResponse: AICommandResponse(
        actions: actions,
        summary: state.pendingResponse!.summary,
      ),
    );
  }
}

final aiCommandProvider = StateNotifierProvider<AICommandNotifier, AICommandState>((ref) {
  return AICommandNotifier(ref.watch(aiCommandsRepositoryProvider));
});
