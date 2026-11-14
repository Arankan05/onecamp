import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSender;
  final String? senderName;
  final Function(MessageModel message)? onReply;
  final Function(MessageModel message)? onDeleteForMe;
  final Function(MessageModel message)? onDeleteForEveryone;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSender,
    this.senderName,
    this.onReply,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
  });

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildStatusIcon() {
    final isReadByOther = message.readBy.any((id) => id != message.senderId);

    if (isReadByOther) {
      return const Icon(
        Icons.done_all,
        size: 14.0,
        color: Color(0xFF80DEEA),
      );
    }

    return const Icon(
      Icons.done,
      size: 14.0,
      color: Color(0xB3FFFFFF),
    );
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: ChatColors.primaryPurple),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                if (onReply != null) onReply!(message);
              },
            ),
            if (message.text.isNotEmpty && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.copy, color: ChatColors.primaryPurple),
                title: const Text('Copy text'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied to clipboard')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orangeAccent),
              title: const Text('Delete for me'),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmDelete(
                  context: context,
                  title: 'Delete for me?',
                  content: 'This message will be hidden from your view only.',
                  onConfirm: () {
                    if (onDeleteForMe != null) onDeleteForMe!(message);
                  },
                );
              },
            ),
            if (isSender && !message.isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Delete for everyone'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _confirmDelete(
                    context: context,
                    title: 'Delete for everyone?',
                    content: 'This will replace the message text for all participants.',
                    onConfirm: () {
                      if (onDeleteForEveryone != null) onDeleteForEveryone!(message);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openFullImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: ChatColors.primaryPurple),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    color: Colors.white70,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxWidth = mediaQuery.size.width * ChatDimensions.maxBubbleWidthFactor;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showActionMenu(context),
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          margin: const EdgeInsets.symmetric(
            horizontal: ChatDimensions.paddingL,
            vertical: ChatDimensions.paddingXS,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ChatDimensions.bubblePaddingHorizontal,
            vertical: ChatDimensions.bubblePaddingVertical,
          ),
          decoration: isSender
              ? ChatDecorations.senderBubbleDecoration
              : ChatDecorations.receiverBubbleDecoration,
          child: Column(
            crossAxisAlignment:
                isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isSender && senderName != null && senderName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: ChatDimensions.paddingXS),
                  child: Text(
                    senderName!,
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: ChatColors.primaryDarkPurple,
                    ),
                  ),
                ),

              // Reply Preview Bubble
              if (message.replyToText != null && message.replyToText!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 6.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isSender ? const Color(0x26FFFFFF) : ChatColors.lightLavender,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border(
                      left: BorderSide(
                        color: isSender ? Colors.white : ChatColors.primaryPurple,
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyToSenderName ?? 'Reply',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: isSender ? Colors.white : ChatColors.primaryDarkPurple,
                        ),
                      ),
                      Text(
                        message.replyToText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isSender ? Colors.white70 : ChatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Image Content
              if (message.isImage && message.imageUrl != null && !message.isDeleted)
                GestureDetector(
                  onTap: () => _openFullImagePreview(context, message.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ChatDimensions.radiusS),
                    child: Image.network(
                      message.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          color: Colors.black12,
                          child: const Center(
                            child: CircularProgressIndicator(color: ChatColors.primaryPurple),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: Colors.black12,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                color: ChatColors.textLight,
                                size: 36,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Failed to load image',
                                style: TextStyle(fontSize: 11, color: ChatColors.textLight),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Message Text Content
              if (message.isDeleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block,
                      size: 14,
                      color: isSender ? Colors.white70 : ChatColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'This message was deleted',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14.0,
                        color: isSender ? Colors.white70 : ChatColors.textLight,
                      ),
                    ),
                  ],
                )
              else if (message.text.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                    top: message.isImage ? ChatDimensions.paddingS : 0,
                  ),
                  child: Text(
                    message.text,
                    style: isSender
                        ? ChatTextStyles.senderMessage
                        : ChatTextStyles.receiverMessage,
                  ),
                ),

              const SizedBox(height: 2.0),

              // Timestamp & Status Icon Row
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    _formatTimestamp(message.sentAt),
                    style: isSender
                        ? ChatTextStyles.messageTimeSender
                        : ChatTextStyles.messageTimeReceiver,
                  ),
                  if (isSender) ...[
                    const SizedBox(width: 4.0),
                    _buildStatusIcon(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
