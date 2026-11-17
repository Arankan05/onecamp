import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/presence_service.dart';
import '../../../core/services/call_service.dart';
import '../../../core/services/chat_notification_service.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import 'call_screen.dart';
import '../models/message_model.dart';
import '../repositories/chat_repository.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_dimensions.dart';
import '../theme/chat_text_styles.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final bool isGroup;
  final String? avatarUrl;
  final List<String> participantIds;
  final String? otherUserId;
  final ChatRepository? chatRepository;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.isGroup = false,
    this.avatarUrl,
    this.participantIds = const [],
    this.otherUserId,
    this.chatRepository,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final ChatRepository _chatRepository;
  final CallService _callService = CallService();
  final Map<String, String> _senderNamesCache = {};
  final Set<String> _processedReadMessageIds = {};
  final Map<String, MessageModel> _localPendingMessages = {};

  StreamSubscription<List<String>>? _blockedUsersSubscription;
  StreamSubscription<CallModel?>? _incomingCallSubscription;

  MessageModel? _replyingToMessage;
  String? _replyingToSenderName;
  bool _isSearchActive = false;
  String _roomSearchQuery = '';
  bool _isBlocked = false;
  bool _iBlocked = false;
  bool _isMuted = false;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    ChatNotificationService.activeChatId = widget.chatId;
    _chatRepository = widget.chatRepository ?? ChatRepository();
    _loadParticipantNames();
    _checkBlockAndPreferences();
    _listenForIncomingCalls();

    if (!widget.isGroup && widget.otherUserId != null) {
      _blockedUsersSubscription = _chatRepository
          .getBlockedUserIdsStream()
          .listen((_) {
            _checkBlockAndPreferences();
          });
    }
  }

  void _listenForIncomingCalls() {
    _incomingCallSubscription = _callService.getIncomingCallsStream().listen((
      call,
    ) {
      if (call != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CallScreen(initialCall: call, isIncoming: true),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    if (ChatNotificationService.activeChatId == widget.chatId) {
      ChatNotificationService.activeChatId = null;
    }
    _blockedUsersSubscription?.cancel();
    _incomingCallSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkBlockAndPreferences() async {
    final activeUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null) return;

    if (!widget.isGroup && widget.otherUserId != null) {
      final iBlocked = await _chatRepository.isUserBlocked(widget.otherUserId!);
      final directBlocked = await _chatRepository.isDirectChatBlocked(
        widget.otherUserId!,
      );
      if (mounted) {
        setState(() {
          _iBlocked = iBlocked;
          _isBlocked = directBlocked;
        });
      }
    }
  }

  void _markUnreadMessagesAsRead(
    List<MessageModel> messages,
    String activeUid,
  ) {
    for (final message in messages) {
      if (message.senderId != activeUid &&
          !message.readBy.contains(activeUid) &&
          !_processedReadMessageIds.contains(message.messageId)) {
        _processedReadMessageIds.add(message.messageId);
        _chatRepository.markMessageAsRead(
          chatId: widget.chatId,
          messageId: message.messageId,
        );
      }
    }
  }

  Future<void> _loadParticipantNames() async {
    if (widget.participantIds.isEmpty) return;
    final profiles = await _chatRepository.getUsersProfiles(
      widget.participantIds,
    );
    if (mounted) {
      setState(() {
        profiles.forEach((id, data) {
          _senderNamesCache[id] =
              data['name'] as String? ??
              data['displayName'] as String? ??
              data['email'] as String? ??
              'User';
        });
      });
    }
  }

  void _startCall({required bool isVideo}) {
    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot initiate call in a blocked conversation.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (widget.otherUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          targetId: widget.otherUserId,
          targetName: widget.title,
          chatId: widget.chatId,
          isVideo: isVideo,
          isIncoming: false,
        ),
      ),
    );
  }

  Future<void> _handleSendText(String text) async {
    final activeUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null || text.trim().isEmpty) return;

    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send messages in a blocked conversation.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final clientMessageId = _chatRepository.generateMessageId(widget.chatId);
    final pendingMsg = MessageModel(
      messageId: clientMessageId,
      senderId: activeUid,
      text: text.trim(),
      sentAt: DateTime.now(),
      status: 'pending',
      readBy: [activeUid],
      replyToMessageId: _replyingToMessage?.messageId,
      replyToSenderName: _replyingToSenderName,
      replyToText: _replyingToMessage?.text,
    );

    setState(() {
      _localPendingMessages[clientMessageId] = pendingMsg;
      _replyingToMessage = null;
      _replyingToSenderName = null;
    });

    try {
      await _chatRepository.sendMessage(
        chatId: widget.chatId,
        senderId: activeUid,
        text: text,
        clientMessageId: clientMessageId,
        replyToMessageId: pendingMsg.replyToMessageId,
        replyToSenderName: pendingMsg.replyToSenderName,
        replyToText: pendingMsg.replyToText,
      );

      if (mounted) {
        setState(() {
          _localPendingMessages.remove(clientMessageId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localPendingMessages[clientMessageId] = pendingMsg.copyWith(
            status: 'failed',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleSendImage(String imageUrl) async {
    final activeUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null || imageUrl.trim().isEmpty) return;

    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send image in a blocked conversation.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final clientMessageId = _chatRepository.generateMessageId(widget.chatId);
    final pendingMsg = MessageModel(
      messageId: clientMessageId,
      senderId: activeUid,
      text: '',
      imageUrl: imageUrl,
      messageType: 'image',
      sentAt: DateTime.now(),
      status: 'pending',
      readBy: [activeUid],
    );

    setState(() {
      _localPendingMessages[clientMessageId] = pendingMsg;
    });

    try {
      await _chatRepository.sendImageMessage(
        chatId: widget.chatId,
        senderId: activeUid,
        imageUrl: imageUrl,
        clientMessageId: clientMessageId,
      );

      if (mounted) {
        setState(() {
          _localPendingMessages.remove(clientMessageId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localPendingMessages[clientMessageId] = pendingMsg.copyWith(
            status: 'failed',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleSendDocument(
    String mediaUrl,
    String fileName,
    int fileSize,
    String fileExtension,
  ) async {
    final activeUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null) return;

    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send document in a blocked conversation.'),
        ),
      );
      return;
    }

    try {
      await _chatRepository.sendDocumentMessage(
        chatId: widget.chatId,
        senderId: activeUid,
        mediaUrl: mediaUrl,
        fileName: fileName,
        fileSize: fileSize,
        fileExtension: fileExtension,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send document: $e')));
      }
    }
  }

  Future<void> _handleSendAudio(
    String mediaUrl,
    String fileName,
    int fileSize,
    int durationSeconds,
  ) async {
    final activeUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null) return;

    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send audio in a blocked conversation.'),
        ),
      );
      return;
    }

    try {
      await _chatRepository.sendAudioMessage(
        chatId: widget.chatId,
        senderId: activeUid,
        mediaUrl: mediaUrl,
        fileName: fileName,
        fileSize: fileSize,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send audio: $e')));
      }
    }
  }

  Future<void> _handleSendVoice(String mediaUrl, int durationSeconds) async {
    final activeUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null) return;

    if (_isBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot send voice message in a blocked conversation.'),
        ),
      );
      return;
    }

    try {
      await _chatRepository.sendVoiceMessage(
        chatId: widget.chatId,
        senderId: activeUid,
        mediaUrl: mediaUrl,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send voice message: $e')),
        );
      }
    }
  }

  Future<void> _handleRetry(MessageModel message) async {
    final activeUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null) return;

    setState(() {
      _localPendingMessages[message.messageId] = message.copyWith(
        status: 'pending',
      );
    });

    try {
      if (message.isImage && message.imageUrl != null) {
        await _chatRepository.sendImageMessage(
          chatId: widget.chatId,
          senderId: activeUid,
          imageUrl: message.imageUrl!,
          clientMessageId: message.messageId,
          caption: message.text,
        );
      } else {
        await _chatRepository.sendMessage(
          chatId: widget.chatId,
          senderId: activeUid,
          text: message.text,
          clientMessageId: message.messageId,
          replyToMessageId: message.replyToMessageId,
          replyToSenderName: message.replyToSenderName,
          replyToText: message.replyToText,
        );
      }

      if (mounted) {
        setState(() {
          _localPendingMessages.remove(message.messageId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localPendingMessages[message.messageId] = message.copyWith(
            status: 'failed',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleReply(MessageModel message) {
    setState(() {
      _replyingToMessage = message;
      _replyingToSenderName = _senderNamesCache[message.senderId] ?? 'User';
    });
  }

  Future<void> _handleDeleteForMe(MessageModel message) async {
    try {
      await _chatRepository.hideMessageForMe(
        chatId: widget.chatId,
        messageId: message.messageId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteForEveryone(MessageModel message) async {
    try {
      await _chatRepository.deleteMessageForEveryone(
        chatId: widget.chatId,
        messageId: message.messageId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSharedMediaSheet(List<MessageModel> messages) {
    final imageMessages = messages
        .where((m) => m.isImage && m.imageUrl != null && !m.isDeleted)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: ChatColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(ChatDimensions.paddingL),
              child: Text(
                'Shared Media (${imageMessages.length})',
                style: ChatTextStyles.chatTileTitle,
              ),
            ),
            Expanded(
              child: imageMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'No shared media yet.',
                        style: ChatTextStyles.chatTileSubtitle,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(ChatDimensions.paddingL),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: imageMessages.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageMessages[index].imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report User'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for reporting...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isNotEmpty && widget.otherUserId != null) {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(context);
                await _chatRepository.reportUser(
                  targetUid: widget.otherUserId!,
                  reason: reason,
                );
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Report submitted successfully.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChatColors.primaryPurple,
            ),
            child: const Text(
              'Submit Report',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeUid =
        _chatRepository.currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

    final isParticipant =
        widget.participantIds.isEmpty ||
        (activeUid != null && widget.participantIds.contains(activeUid));

    if (activeUid == null || !isParticipant) {
      return Scaffold(
        backgroundColor: ChatColors.pageBackground,
        appBar: AppBar(
          title: const Text('Access Denied', style: ChatTextStyles.appBarTitle),
          backgroundColor: ChatColors.cardBackground,
        ),
        body: const Center(
          child: Text('You are not a participant in this conversation.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ChatColors.pageBackground,
      appBar: AppBar(
        backgroundColor: ChatColors.cardBackground,
        elevation: 0,
        titleSpacing: 0,
        leading: const OneCampBackButton(),
        title: _isSearchActive
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search in conversation...',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() => _roomSearchQuery = val.trim().toLowerCase());
                },
              )
            : Row(
                children: [
                  ChatAvatar(
                    name: widget.title,
                    imageUrl: widget.avatarUrl,
                    userId: widget.otherUserId,
                    size: 38,
                    isGroup: widget.isGroup,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: ChatTextStyles.appBarTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.isGroup)
                          Text(
                            '${widget.participantIds.length} members',
                            style: ChatTextStyles.appBarSubtitle,
                          )
                        else if (widget.otherUserId != null)
                          StreamBuilder<Map<String, dynamic>>(
                            stream: PresenceService().getUserPresenceStream(
                              widget.otherUserId!,
                            ),
                            builder: (context, snapshot) {
                              final presence =
                                  snapshot.data ??
                                  {'isOnline': false, 'lastSeen': null};
                              final bool isOnline =
                                  presence['isOnline'] as bool? ?? false;
                              final DateTime? lastSeen =
                                  presence['lastSeen'] as DateTime?;

                              if (isOnline) {
                                return const Text(
                                  'Active now',
                                  style: ChatTextStyles.appBarSubtitle,
                                );
                              } else if (lastSeen != null) {
                                final hour = lastSeen.hour.toString().padLeft(
                                  2,
                                  '0',
                                );
                                final min = lastSeen.minute.toString().padLeft(
                                  2,
                                  '0',
                                );
                                return Text(
                                  'Offline • Last seen $hour:$min',
                                  style: ChatTextStyles.appBarSubtitle,
                                );
                              }
                              return const Text(
                                'Offline',
                                style: ChatTextStyles.appBarSubtitle,
                              );
                            },
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          if (_isSearchActive)
            IconButton(
              icon: const Icon(Icons.close, color: ChatColors.textPrimary),
              onPressed: () {
                setState(() {
                  _isSearchActive = false;
                  _roomSearchQuery = '';
                });
              },
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: ChatColors.textPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) async {
                switch (value) {
                  case 'mute':
                    setState(() => _isMuted = !_isMuted);
                    await _chatRepository.toggleMuteChat(
                      chatId: widget.chatId,
                      isMuted: _isMuted,
                    );
                    break;
                  case 'pin':
                    setState(() => _isPinned = !_isPinned);
                    await _chatRepository.togglePinChat(
                      chatId: widget.chatId,
                      isPinned: _isPinned,
                    );
                    break;
                  case 'search':
                    setState(() => _isSearchActive = true);
                    break;
                  case 'media':
                    _chatRepository.getMessagesStream(widget.chatId).first.then(
                      (msgs) {
                        if (mounted) _showSharedMediaSheet(msgs);
                      },
                    );
                    break;
                  case 'block':
                    if (widget.otherUserId != null) {
                      if (_iBlocked) {
                        await _chatRepository.unblockUser(widget.otherUserId!);
                        await _checkBlockAndPreferences();
                      } else {
                        await _chatRepository.blockUser(widget.otherUserId!);
                        await _checkBlockAndPreferences();
                      }
                    }
                    break;
                  case 'report':
                    _showReportDialog();
                    break;
                  case 'delete_chat':
                    final navigator = Navigator.of(context);
                    await _chatRepository.hideChatForMe(chatId: widget.chatId);
                    navigator.pop();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mute',
                  child: Text(
                    _isMuted ? 'Unmute notifications' : 'Mute notifications',
                  ),
                ),
                PopupMenuItem(
                  value: 'pin',
                  child: Text(
                    _isPinned ? 'Unpin conversation' : 'Pin conversation',
                  ),
                ),
                const PopupMenuItem(
                  value: 'search',
                  child: Text('Search in conversation'),
                ),
                const PopupMenuItem(
                  value: 'media',
                  child: Text('View shared media'),
                ),
                if (!widget.isGroup && widget.otherUserId != null)
                  PopupMenuItem(
                    value: 'block',
                    child: Text(_iBlocked ? 'Unblock user' : 'Block user'),
                  ),
                if (!widget.isGroup && widget.otherUserId != null)
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Report user'),
                  ),
                const PopupMenuItem(
                  value: 'delete_chat',
                  child: Text(
                    'Delete conversation for me',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Date Separator Badge Pill
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A4F1BAA),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Today',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: ChatColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Message List Stream
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatRepository.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ChatColors.primaryPurple,
                    ),
                  );
                }

                final streamedMessages = snapshot.data ?? [];

                if (streamedMessages.isNotEmpty) {
                  _markUnreadMessagesAsRead(streamedMessages, activeUid);
                }

                // Remove pending local messages that have arrived from Firestore stream
                for (final msg in streamedMessages) {
                  _localPendingMessages.remove(msg.messageId);
                }

                // Merge streamed messages with local pending/failed messages
                final Map<String, MessageModel> combinedMap = {};
                for (final msg in _localPendingMessages.values) {
                  combinedMap[msg.messageId] = msg;
                }
                for (final msg in streamedMessages) {
                  combinedMap[msg.messageId] = msg;
                }

                final messages = combinedMap.values.toList();
                messages.sort((a, b) {
                  final aDate =
                      a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bDate =
                      b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bDate.compareTo(aDate);
                });

                // Filter by room search if active
                final filteredMessages = messages.where((m) {
                  if (_roomSearchQuery.isEmpty) return true;
                  return m.text.toLowerCase().contains(_roomSearchQuery);
                }).toList();

                if (filteredMessages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages found',
                      style: ChatTextStyles.chatTileSubtitle,
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: ChatDimensions.paddingM,
                  ),
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    final message = filteredMessages[index];
                    final isSender = message.senderId == activeUid;
                    final senderName = _senderNamesCache[message.senderId];

                    return MessageBubble(
                      message: message,
                      isSender: isSender,
                      senderName: widget.isGroup ? senderName : null,
                      isGroup: widget.isGroup,
                      senderNamesCache: _senderNamesCache,
                      onReply: _handleReply,
                      onDeleteForMe: _handleDeleteForMe,
                      onDeleteForEveryone: _handleDeleteForEveryone,
                      onRetry: _handleRetry,
                    );
                  },
                );
              },
            ),
          ),

          // Blocked Banner or Message Input Bar
          if (_isBlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(ChatDimensions.paddingL),
              color: Colors.red.shade50,
              child: Row(
                children: [
                  const Icon(Icons.block, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _iBlocked
                          ? 'You have blocked this user. Unblock to send messages.'
                          : 'You cannot send messages in this conversation.',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_iBlocked)
                    TextButton(
                      onPressed: () async {
                        if (widget.otherUserId != null) {
                          await _chatRepository.unblockUser(
                            widget.otherUserId!,
                          );
                          await _checkBlockAndPreferences();
                        }
                      },
                      child: const Text(
                        'Unblock',
                        style: TextStyle(
                          color: ChatColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            MessageInput(
              onSendText: _handleSendText,
              onSendImage: _handleSendImage,
              onSendDocument: _handleSendDocument,
              onSendAudio: _handleSendAudio,
              onSendVoice: _handleSendVoice,
              replyingToMessage: _replyingToMessage,
              replyingToSenderName: _replyingToSenderName,
              onCancelReply: () {
                setState(() {
                  _replyingToMessage = null;
                  _replyingToSenderName = null;
                });
              },
            ),
        ],
      ),
    );
  }
}
