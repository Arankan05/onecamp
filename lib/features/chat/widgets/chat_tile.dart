import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';
import 'chat_avatar.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String title;
  final String? avatarUrl;
  final String? otherUserId;
  final bool isOnline;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.title,
    this.avatarUrl,
    this.otherUserId,
    this.isOnline = false,
    required this.onTap,
  });

  String _formatCompactTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes <= 0 ? 1 : difference.inMinutes;
      return '${mins}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ChatDimensions.paddingL,
        vertical: 6.0,
      ),
      decoration: ChatDecorations.cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ChatDimensions.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(ChatDimensions.radiusCard),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatDimensions.paddingL,
              vertical: ChatDimensions.paddingM,
            ),
            child: Row(
              children: [
                ChatAvatar(
                  name: title,
                  imageUrl: avatarUrl,
                  userId: otherUserId,
                  size: ChatDimensions.avatarMedium,
                  isGroup: chat.isGroup,
                  isOnline: isOnline,
                ),
                const SizedBox(width: ChatDimensions.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ChatTextStyles.chatTileTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        chat.lastMessage != null && chat.lastMessage!.isNotEmpty
                            ? chat.lastMessage!
                            : (chat.isGroup ? 'Group created' : 'Start a conversation'),
                        style: ChatTextStyles.chatTileSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ChatDimensions.paddingS),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatCompactTime(chat.lastMessageAt),
                      style: ChatTextStyles.chatTileTime,
                    ),
                    const SizedBox(height: 6.0),
                    const Icon(
                      Icons.done_all,
                      size: 16.0,
                      color: ChatColors.primaryPurple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
