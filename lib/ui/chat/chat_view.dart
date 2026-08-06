import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/glass_container.dart';
import '../theme/app_colors.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _textController.clear();
      _focusNode.requestFocus();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final messages = ref.watch(chatProvider);
    ref.listen(chatProvider, (previous, next) {
      if (previous?.length != next.length || (next.isNotEmpty && next.last.isStreaming)) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return ChatMessageBubble(message: messages[index]);
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: BorderRadius.circular(24),
        opacity: 0.1,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.textSecondary),
              onPressed: () {},
              tooltip: 'Attach File',
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Message Falcon...',
                  hintStyle: TextStyle(color: AppColors.textDisabled),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.mic, color: AppColors.textSecondary),
              onPressed: () {},
              tooltip: 'Voice Input',
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.cyanGlow),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
