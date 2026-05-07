import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';
import 'dart:io';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.content, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? sessionId;

  ChatState({
    required this.messages,
    this.isLoading = false,
    this.sessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? sessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;

  ChatNotifier(this._ref)
      : super(ChatState(messages: [
          ChatMessage(
            content: "Hi! I'm FinanceAI 🤖\n\nI can help you:\n- Understand your spending patterns\n- Give saving tips based on your data\n- Add transactions via natural language (text or voice)\n- Analyze receipts and bills from photos\n- Answer financial questions\n\nHow can I help you today?",
            isUser: false,
          )
        ]));

  Future<void> sendMessage({
    String? text,
    File? image,
    String? audioPath,
  }) async {
    if ((text == null || text.trim().isEmpty) && image == null && audioPath == null) return;
    if (state.isLoading) return;

    final userMessages = [...state.messages];
    if (text != null && text.trim().isNotEmpty) {
      userMessages.add(ChatMessage(content: text.trim(), isUser: true));
    }
    if (image != null) {
      userMessages.add(ChatMessage(content: '📷 Image attached', isUser: true));
    }
    if (audioPath != null) {
      userMessages.add(ChatMessage(content: '🎤 Voice message', isUser: true));
    }

    state = state.copyWith(messages: userMessages, isLoading: true);

    try {
      final client = _ref.read(dioClientProvider);
      
      final formData = FormData.fromMap({
        'message': text ?? '',
        'sessionId': state.sessionId,
      });

      if (image != null) {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
        ));
      } else if (audioPath != null) {
        formData.files.add(MapEntry(
          'file',
          await MultipartFile.fromFile(audioPath, filename: 'audio.m4a'),
        ));
      }

      final response = await client.post(ApiConstants.aiChat, data: formData);

      final data = response.data['data'];
      final newSessionId = data['sessionId'];
      final aiMessage = data['message'] ?? 'I couldn\'t process that request.';

      final updatedMessages = [...state.messages, ChatMessage(content: aiMessage, isUser: false)];

      // Check for action completion
      if (data['action'] != null) {
        final actionType = data['action']['type'];
        String successText = '✅ Action completed successfully!';
        
        if (actionType == 'ADD_TRANSACTION') {
          successText = '✅ Transaction added successfully!';
        } else if (actionType == 'ADD_CATEGORY') {
          successText = '✅ Category created successfully!';
        } else if (actionType == 'ADD_BUDGET') {
          successText = '✅ Budget set successfully!';
        } else if (actionType == 'ADD_GOAL') {
          successText = '✅ Goal created successfully!';
        }

        updatedMessages.add(ChatMessage(content: successText, isUser: false));
      }

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        sessionId: newSessionId,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(content: '❌ Sorry, I encountered an error. Please try again.', isUser: false)
        ],
        isLoading: false,
      );
    }
  }

  void clearSession() {
    state = ChatState(messages: [
      ChatMessage(
        content: "Hi! I'm FinanceAI 🤖\n\nI can help you:\n- Understand your spending patterns\n- Give saving tips based on your data\n- Add transactions via natural language (text or voice)\n- Analyze receipts and bills from photos\n- Answer financial questions\n\nHow can I help you today?",
        isUser: false,
      )
    ]);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
