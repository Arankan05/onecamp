import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_decorations.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';
import 'chat_avatar.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isSender;
  final String? senderName;
  final bool isGroup;
  final Map<String, String>? senderNamesCache;
  final Function(MessageModel message)? onReply;
  final Function(MessageModel message)? onDeleteForMe;
  final Function(MessageModel message)? onDeleteForEveryone;
  final Function(MessageModel message)? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSender,
    this.senderName,
    this.isGroup = false,
    this.senderNamesCache,
    this.onReply,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.onRetry,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  AudioPlayer? _audioPlayer;
  bool _isPlayingAudio = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _toggleAudioPlayback(String url) async {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() => _isPlayingAudio = state == PlayerState.playing);
        }
      });
      _audioPlayer!.onPositionChanged.listen((pos) {
        if (mounted) {
          setState(() => _audioPosition = pos);
        }
      });
      _audioPlayer!.onDurationChanged.listen((dur) {
        if (mounted) {
          setState(() => _audioDuration = dur);
        }
      });
    }

    if (_isPlayingAudio) {
      await _audioPlayer!.pause();
    } else {
      await _audioPlayer!.play(UrlSource(url));
    }
  }

  Future<void> _openDocumentUrl(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Could not open document link.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  Future<void> _downloadAndSaveImage(BuildContext context, String imageUrl) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.request();
        final photosStatus = await Permission.photos.request();
        if (!storageStatus.isGranted && !photosStatus.isGranted) {
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Storage permission required to download images.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                SizedBox(width: 12),
                Text('Downloading image...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      Directory targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Pictures/OneCamp');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final String fileName = 'OneCamp_IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File savedFile = File('${targetDir.path}/$fileName');
      await savedFile.writeAsBytes(response.bodyBytes);

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Image saved to ${targetDir.path}/$fileName'),
            backgroundColor: ChatColors.onlineGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showForwardChatSelector(BuildContext context) {
    final chatRepository = ChatRepository();
    final activeUid = chatRepository.currentUserId;
    if (activeUid == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(ChatDimensions.paddingL),
              child: Text('Forward Message To...', style: ChatTextStyles.chatTileTitle),
            ),
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: chatRepository.getChatsStream(activeUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: ChatColors.primaryPurple));
                  }
                  final chats = snapshot.data ?? [];
                  if (chats.isEmpty) {
                    return const Center(child: Text('No active conversations available.', style: ChatTextStyles.chatTileSubtitle));
                  }
                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final title = chat.getDisplayName(activeUid);
                      return ListTile(
                        leading: ChatAvatar(
                          name: title,
                          size: ChatDimensions.avatarMedium,
                          isGroup: chat.isGroup,
                        ),
                        title: Text(title, style: ChatTextStyles.chatTileTitle),
                        subtitle: Text(chat.isGroup ? 'Group Conversation' : 'Direct Chat', style: ChatTextStyles.chatTileSubtitle),
                        trailing: const Icon(Icons.send_rounded, color: ChatColors.primaryPurple),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await chatRepository.forwardMessage(
                              targetChatId: chat.chatId,
                              originalMessage: widget.message,
                              senderName: widget.senderName ?? 'Student',
                            );
                            messenger.showSnackBar(
                              SnackBar(content: Text('Message forwarded to $title'), backgroundColor: ChatColors.onlineGreen),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to forward: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '$mb MB';
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _showGroupReadersModal(BuildContext context, List<String> readerIds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ChatDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seen by ${readerIds.length} member${readerIds.length == 1 ? '' : 's'}',
                style: ChatTextStyles.chatTileTitle,
              ),
              const SizedBox(height: ChatDimensions.paddingM),
              if (readerIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: ChatDimensions.paddingL),
                  child: Center(
                    child: Text(
                      'Nobody in the group has read this message yet.',
                      style: ChatTextStyles.chatTileSubtitle,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: readerIds.length,
                    itemBuilder: (context, index) {
                      final readerId = readerIds[index];
                      final readerName = widget.senderNamesCache?[readerId] ?? 'Student';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ChatAvatar(
                          name: readerName,
                          size: ChatDimensions.avatarSmall,
                        ),
                        title: Text(readerName, style: ChatTextStyles.chatTileTitle),
                        trailing: const Icon(
                          Icons.done_all,
                          size: 16.0,
                          color: ChatColors.primaryPurple,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    if (widget.message.isPending) {
      return const SizedBox(
        width: 11,
        height: 11,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Color(0xB3FFFFFF),
        ),
      );
    }

    if (widget.message.isFailed) {
      return GestureDetector(
        onTap: () {
          if (widget.onRetry != null) widget.onRetry!(widget.message);
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14.0, color: Colors.amberAccent),
            SizedBox(width: 3),
            Text(
              'Retry',
              style: TextStyle(
                fontSize: 10,
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final readers = widget.message.readBy.where((id) => id != widget.message.senderId).toList();
    final bool isReadByOthers = readers.isNotEmpty;

    if (!widget.isGroup) {
      if (isReadByOthers) {
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

    final String labelText = isReadByOthers ? 'Seen by ${readers.length}' : 'Not seen yet';

    return GestureDetector(
      onTap: () => _showGroupReadersModal(context, readers),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelText,
            style: const TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w400,
              color: Color(0xD0FFFFFF),
            ),
          ),
          const SizedBox(width: 3.0),
          Icon(
            isReadByOthers ? Icons.done_all : Icons.done,
            size: 13.0,
            color: isReadByOthers ? const Color(0xFF80DEEA) : const Color(0xB3FFFFFF),
          ),
        ],
      ),
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
              title: const Text('Reply', style: TextStyle(color: Color(0xFF29213F), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                if (widget.onReply != null) widget.onReply!(widget.message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shortcut_rounded, color: ChatColors.primaryPurple),
              title: const Text('Forward', style: TextStyle(color: Color(0xFF29213F), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showForwardChatSelector(context);
              },
            ),
            if (widget.message.isImage && widget.message.imageUrl != null && !widget.message.isDeleted)
              ListTile(
                leading: const Icon(Icons.download_rounded, color: ChatColors.primaryPurple),
                title: const Text('Download Image', style: TextStyle(color: Color(0xFF29213F), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _downloadAndSaveImage(context, widget.message.imageUrl!);
                },
              ),
            if (widget.message.text.isNotEmpty && !widget.message.isDeleted)
              ListTile(
                leading: const Icon(Icons.copy, color: ChatColors.primaryPurple),
                title: const Text('Copy text', style: TextStyle(color: Color(0xFF29213F), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Clipboard.setData(ClipboardData(text: widget.message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied to clipboard')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orangeAccent),
              title: const Text('Delete for me', style: TextStyle(color: Color(0xFF29213F), fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _confirmDelete(
                  context: context,
                  title: 'Delete for me?',
                  content: 'This message will be hidden from your view only.',
                  onConfirm: () {
                    if (widget.onDeleteForMe != null) widget.onDeleteForMe!(widget.message);
                  },
                );
              },
            ),
            if (widget.isSender && !widget.message.isDeleted)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Delete for everyone', style: TextStyle(color: Color(0xFF29213F), fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _confirmDelete(
                    context: context,
                    title: 'Delete for everyone?',
                    content: 'This will replace the message text for all participants.',
                    onConfirm: () {
                      if (widget.onDeleteForEveryone != null) widget.onDeleteForEveryone!(widget.message);
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 28),
                    onPressed: () => _downloadAndSaveImage(context, imageUrl),
                    tooltip: 'Save Image',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
      alignment: widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
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
          decoration: widget.isSender
              ? ChatDecorations.senderBubbleDecoration
              : ChatDecorations.receiverBubbleDecoration,
          child: Column(
            crossAxisAlignment:
                widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Forwarded Badge
              if (widget.message.isForwarded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shortcut_rounded,
                        size: 12,
                        color: widget.isSender ? Colors.white70 : ChatColors.primaryPurple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.message.forwardedFrom != null
                            ? 'Forwarded from ${widget.message.forwardedFrom}'
                            : 'Forwarded',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: widget.isSender ? Colors.white70 : ChatColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),

              if (!widget.isSender && widget.senderName != null && widget.senderName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: ChatDimensions.paddingXS),
                  child: Text(
                    widget.senderName!,
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: ChatColors.primaryDarkPurple,
                    ),
                  ),
                ),

              // Reply Preview Bubble
              if (widget.message.replyToText != null && widget.message.replyToText!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 6.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: widget.isSender ? const Color(0x26FFFFFF) : ChatColors.lightLavender,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border(
                      left: BorderSide(
                        color: widget.isSender ? Colors.white : ChatColors.primaryPurple,
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.message.replyToSenderName ?? 'Reply',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: widget.isSender ? Colors.white : ChatColors.primaryDarkPurple,
                        ),
                      ),
                      Text(
                        widget.message.replyToText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: widget.isSender ? Colors.white70 : ChatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Image Content
              if (widget.message.isImage && widget.message.imageUrl != null && !widget.message.isDeleted)
                GestureDetector(
                  onTap: () => _openFullImagePreview(context, widget.message.imageUrl!),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ChatDimensions.radiusS),
                    child: Image.network(
                      widget.message.imageUrl!,
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

              // Document Attachment Card
              if (widget.message.isDocument && !widget.message.isDeleted)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isSender ? const Color(0x26FFFFFF) : ChatColors.lightLavender,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.isSender ? Colors.white24 : ChatColors.primaryPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.insert_drive_file,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message.fileName ?? widget.message.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: widget.isSender ? Colors.white : const Color(0xFF29213F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(widget.message.fileExtension ?? 'doc').toUpperCase()} • ${_formatFileSize(widget.message.fileSize)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: widget.isSender ? Colors.white70 : ChatColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.message.effectiveMediaUrl != null)
                        IconButton(
                          icon: Icon(
                            Icons.download_rounded,
                            color: widget.isSender ? Colors.white : ChatColors.primaryPurple,
                          ),
                          onPressed: () => _openDocumentUrl(widget.message.effectiveMediaUrl!),
                        ),
                    ],
                  ),
                ),

              // Audio / Voice Message Card
              if ((widget.message.isAudio || widget.message.isVoice) && !widget.message.isDeleted)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isSender ? const Color(0x26FFFFFF) : ChatColors.lightLavender,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlayingAudio ? Icons.pause_circle_filled : Icons.play_circle_fill,
                          size: 36,
                          color: widget.isSender ? Colors.white : ChatColors.primaryPurple,
                        ),
                        onPressed: widget.message.effectiveMediaUrl != null
                            ? () => _toggleAudioPlayback(widget.message.effectiveMediaUrl!)
                            : null,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message.isVoice ? '🎤 Voice Message' : (widget.message.fileName ?? '🎵 Audio Track'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.isSender ? Colors.white : const Color(0xFF29213F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: _audioDuration.inMilliseconds > 0
                                  ? _audioPosition.inMilliseconds / _audioDuration.inMilliseconds
                                  : 0.0,
                              backgroundColor: widget.isSender ? Colors.white24 : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.isSender ? Colors.white : ChatColors.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isPlayingAudio
                                  ? '${_formatDuration(_audioPosition.inSeconds)} / ${_formatDuration(_audioDuration.inSeconds)}'
                                  : _formatDuration(widget.message.durationSeconds ?? 0),
                              style: TextStyle(
                                fontSize: 10,
                                color: widget.isSender ? Colors.white70 : ChatColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Message Text Content
              if (widget.message.isDeleted)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block,
                      size: 14,
                      color: widget.isSender ? Colors.white70 : ChatColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'This message was deleted',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 14.0,
                        color: widget.isSender ? Colors.white70 : ChatColors.textLight,
                      ),
                    ),
                  ],
                )
              else if (widget.message.text.isNotEmpty && !widget.message.isDocument)
                Padding(
                  padding: EdgeInsets.only(
                    top: widget.message.isImage ? ChatDimensions.paddingS : 0,
                  ),
                  child: Text(
                    widget.message.text,
                    style: widget.isSender
                        ? ChatTextStyles.senderMessage
                        : ChatTextStyles.receiverMessage,
                  ),
                ),

              const SizedBox(height: 2.0),

              // Timestamp & Status Icon Row
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: widget.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    _formatTimestamp(widget.message.sentAt),
                    style: widget.isSender
                        ? ChatTextStyles.messageTimeSender
                        : ChatTextStyles.messageTimeReceiver,
                  ),
                  if (widget.isSender) ...[
                    const SizedBox(width: 4.0),
                    _buildStatusIndicator(context),
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
