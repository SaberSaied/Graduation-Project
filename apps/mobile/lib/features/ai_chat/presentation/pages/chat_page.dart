import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../core/constants/api_constants.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.content, required this.isUser, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String? _sessionId;
  bool _isLoading = false;

  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      content: "Hi! I'm FinanceAI 🤖\n\nI can help you:\n- Understand your spending patterns\n- Give saving tips based on your data\n- Add transactions via natural language (text or voice)\n- Analyze receipts and bills from photos\n- Answer financial questions\n\nHow can I help you today?",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _sendMultimodalMessage(audioPath: path);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/recording.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _sendMultimodalMessage({String? audioPath}) async {
    final text = _controller.text.trim();
    final image = _selectedImage;
    
    if (text.isEmpty && image == null && audioPath == null) return;
    if (_isLoading) return;

    setState(() {
      if (text.isNotEmpty) _messages.add(ChatMessage(content: text, isUser: true));
      if (image != null) _messages.add(ChatMessage(content: '📷 Image attached', isUser: true));
      if (audioPath != null) _messages.add(ChatMessage(content: '🎤 Voice message', isUser: true));
      _isLoading = true;
      _selectedImage = null;
    });
    
    _controller.clear();
    _scrollToBottom();

    try {
      final client = ref.read(dioClientProvider);
      
      final formData = FormData.fromMap({
        'message': text,
        'sessionId': _sessionId,
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
      _sessionId = data['sessionId'];
      final aiMessage = data['message'] ?? 'I couldn\'t process that request.';

      setState(() {
        _messages.add(ChatMessage(content: aiMessage, isUser: false));
      });

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

        setState(() {
          _messages.add(ChatMessage(
            content: successText,
            isUser: false,
          ));
        });
      }
    } catch (e) {
      debugPrint('AI Chat Error: $e');
      setState(() {
        _messages.add(ChatMessage(
          content: '❌ Sorry, I encountered an error. Please try again.',
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() => _sendMultimodalMessage();

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('FinanceAI'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _TypingIndicator(isDark: isDark);
                }
                return _ChatBubble(message: _messages[index], isDark: isDark);
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: 8, right: 8, top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              border: Border(top: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 8),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_selectedImage!, width: 60, height: 60, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: -10,
                              right: -10,
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: Icon(Icons.image_outlined, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _toggleRecording,
                      icon: Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic_none_rounded,
                        color: _isRecording ? Colors.red : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: _isRecording ? 'Recording...' : 'Ask me anything...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDark;

  const _ChatBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isUser
              ? (isDark ? AppColors.primaryDark : AppColors.primaryLight)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
          border: message.isUser ? null : Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
        ),
        child: message.isUser
            ? Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 14.5))
            : MarkdownBody(
                data: message.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 14.5),
                ),
              ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: widget.isDark ? AppColors.dividerDark : AppColors.dividerLight),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.2;
                final value = ((_controller.value + delay) % 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                        .withValues(alpha: 0.3 + (value * 0.7)),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
