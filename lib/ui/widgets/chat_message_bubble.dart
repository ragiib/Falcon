import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlighter/flutter_highlighter.dart';
import 'package:flutter_highlighter/themes/atom-one-dark.dart';
import 'package:markdown/markdown.dart' as md;
import '../../models/chat_message.dart';
import 'glass_container.dart';
import '../theme/app_colors.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(isUser: false),
            const SizedBox(width: 16),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  opacity: isUser ? 0.15 : 0.05,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  child: _buildContent(context, isUser),
                ),
                const SizedBox(height: 8),
                _buildActionRow(isUser),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 16),
            _buildAvatar(isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser ? AppColors.panelBackground : AppColors.cyanGlow.withOpacity(0.2),
        border: Border.all(
          color: isUser ? AppColors.glassBorder : AppColors.cyanGlow,
          width: 1,
        ),
        boxShadow: isUser ? null : [
          BoxShadow(
            color: AppColors.cyanGlow.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Icon(
        isUser ? Icons.person : Icons.auto_awesome,
        color: isUser ? AppColors.textSecondary : AppColors.cyanGlow,
        size: 20,
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isUser) {
    if (message.content.isEmpty && message.isStreaming) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyanGlow),
          ),
          const SizedBox(width: 12),
          Text(
            "Analyzing...",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }
    
    return MarkdownBody(
      data: message.content + (message.isStreaming ? " ▍" : ""),
      selectable: true,
      builders: {
        'code': CodeElementBuilder(),
      },
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6),
        h1: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        h2: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        h3: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        listBullet: const TextStyle(color: AppColors.cyanGlow),
        code: TextStyle(
          color: AppColors.cyanGlow,
          backgroundColor: AppColors.obsidian,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: AppColors.obsidian,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassBorder),
        ),
      ),
    );
  }

  Widget _buildActionRow(bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.timestamp),
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 11),
        ),
        if (!isUser) ...[
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.copy,
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.content));
            },
          ),
          const SizedBox(width: 12),
          _ActionButton(
            icon: Icons.refresh,
            onTap: () {},
          ),
        ]
      ],
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 14, color: AppColors.textDisabled),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9); // remove 'language-'
    }
    
    // For inline code
    if (language.isEmpty && !element.textContent.contains('\n')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.obsidian,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(
          element.textContent,
          style: const TextStyle(
            color: AppColors.cyanGlow,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF282C34), // atom one dark bg
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF21252B),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isNotEmpty ? language : 'text',
                  style: const TextStyle(color: AppColors.textDisabled, fontSize: 12, fontFamily: 'monospace'),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: element.textContent));
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 12, color: AppColors.textDisabled),
                      SizedBox(width: 4),
                      Text('Copy', style: TextStyle(color: AppColors.textDisabled, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
            child: HighlightView(
              element.textContent,
              language: language.isNotEmpty ? language : 'text',
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
