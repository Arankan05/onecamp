import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../../../core/constants/app_constants.dart';

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Generate a stable client-side document ID for idempotency and retry handling.
  String generateMessageId(String chatId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc()
        .id;
  }

  /// Stream all chats for a specific user ID.
  /// Enforces security rule requirement: participantIds arrayContains authenticated UID.
  Stream<List<ChatModel>> getChatsStream(String userId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromDocument(doc))
              .where((chat) => !chat.isHiddenFor(userId))
              .toList();

          // Client-side sort: Pinned chats first, then by lastMessageAt descending
          chats.sort((a, b) {
            final aPinned = a.isPinnedFor(userId);
            final bPinned = b.isPinnedFor(userId);
            if (aPinned && !bPinned) return -1;
            if (!aPinned && bPinned) return 1;

            final aDate =
                a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bDate.compareTo(aDate);
          });

          return chats;
        });
  }

  /// Stream messages for a given chat room, ordered by sentAt descending (newest first for chat list UI).
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    final activeUid = currentUserId;
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromDocument(doc))
              .where(
                (msg) =>
                    activeUid == null || !msg.hiddenFor.contains(activeUid),
              )
              .toList();
        });
  }

  /// Creates a 1:1 direct chat between currentUserId and otherUserId.
  /// If a direct chat already exists between these two users, returns the existing chatId.
  Future<String> createDirectChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    if (currentUserId.isEmpty || otherUserId.isEmpty) {
      throw ArgumentError('User IDs cannot be empty.');
    }

    // Check if either user has blocked the other
    final isBlocked = await isDirectChatBlocked(otherUserId);
    if (isBlocked) {
      throw SecurityException(
        'Cannot start a direct chat with a blocked user.',
      );
    }

    // Check for existing direct chat between the two users
    final querySnapshot = await _firestore
        .collection(AppConstants.chatsCollection)
        .where('type', isEqualTo: 'direct')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (final doc in querySnapshot.docs) {
      final participantIds =
          (doc.data()['participantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (participantIds.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Create a new direct chat document
    final docRef = await _firestore
        .collection(AppConstants.chatsCollection)
        .add({
          'type': 'direct',
          'participantIds': [currentUserId, otherUserId],
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'mutedBy': [],
          'pinnedBy': [],
          'hiddenFor': [],
        });

    return docRef.id;
  }

  /// Creates a multi-user group chat.
  Future<String> createGroupChat({
    required String currentUserId,
    required List<String> participantIds,
    required String groupName,
    String? groupImage,
  }) async {
    if (groupName.trim().isEmpty) {
      throw ArgumentError('Group name cannot be empty.');
    }

    final Set<String> fullParticipants = {currentUserId, ...participantIds};

    if (fullParticipants.length < 2) {
      throw ArgumentError('Group chat requires at least 2 participants.');
    }

    final docRef = await _firestore
        .collection(AppConstants.chatsCollection)
        .add({
          'type': 'group',
          'participantIds': fullParticipants.toList(),
          'groupName': groupName.trim(),
          'groupImage': groupImage ?? '',
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'mutedBy': [],
          'pinnedBy': [],
          'hiddenFor': [],
        });

    return docRef.id;
  }

  /// Sends a text message using a safe, idempotent strategy that preserves existing server fields on retry.
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? clientMessageId,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToText,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null || activeUid != senderId) {
      throw SecurityException('Cannot send message as a different user.');
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    // Enforce blocking check for direct chats before sending
    final chatDoc = await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .get();
    if (chatDoc.exists && chatDoc.data()?['type'] == 'direct') {
      final participantIds =
          (chatDoc.data()?['participantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final otherUid = participantIds.firstWhere(
        (id) => id != senderId,
        orElse: () => '',
      );
      if (otherUid.isNotEmpty) {
        final blocked = await isDirectChatBlocked(otherUid);
        if (blocked) {
          throw SecurityException(
            'Cannot send message in a blocked conversation.',
          );
        }
      }
    }

    final Map<String, dynamic> messageData = {
      'senderId': senderId,
      'text': trimmedText,
      'messageType': 'text',
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
      'isDeleted': false,
      'hiddenFor': [],
      'status': 'sent',
    };
    if (replyToMessageId != null) {
      messageData['replyToMessageId'] = replyToMessageId;
    }
    if (replyToSenderName != null) {
      messageData['replyToSenderName'] = replyToSenderName;
    }
    if (replyToText != null) {
      messageData['replyToText'] = replyToText;
    }

    final targetId = clientMessageId ?? generateMessageId(chatId);
    final docRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(targetId);

    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set(messageData);
    } else {
      await docRef.update({'status': 'sent', 'text': trimmedText});
    }

    // 2. Update parent chat lastMessage, lastMessageAt & reset hiddenFor
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'lastMessage': trimmedText,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'hiddenFor': [],
        });
  }

  /// Sends an image message using a safe, idempotent strategy that preserves existing server fields on retry.
  Future<void> sendImageMessage({
    required String chatId,
    required String senderId,
    required String imageUrl,
    String? clientMessageId,
    String? caption,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null || activeUid != senderId) {
      throw SecurityException('Cannot send message as a different user.');
    }

    if (imageUrl.trim().isEmpty) {
      throw ArgumentError('Image URL cannot be empty.');
    }

    final chatDoc = await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .get();
    if (chatDoc.exists && chatDoc.data()?['type'] == 'direct') {
      final participantIds =
          (chatDoc.data()?['participantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final otherUid = participantIds.firstWhere(
        (id) => id != senderId,
        orElse: () => '',
      );
      if (otherUid.isNotEmpty) {
        final blocked = await isDirectChatBlocked(otherUid);
        if (blocked) {
          throw SecurityException(
            'Cannot send image in a blocked conversation.',
          );
        }
      }
    }

    final displayText = caption != null && caption.trim().isNotEmpty
        ? '📷 ${caption.trim()}'
        : '📷 Image';

    final targetId = clientMessageId ?? generateMessageId(chatId);
    final docRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(targetId);

    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set({
        'senderId': senderId,
        'text': caption?.trim() ?? '',
        'imageUrl': imageUrl.trim(),
        'messageType': 'image',
        'sentAt': FieldValue.serverTimestamp(),
        'readBy': [senderId],
        'isDeleted': false,
        'hiddenFor': [],
        'status': 'sent',
      });
    } else {
      await docRef.update({
        'status': 'sent',
        'imageUrl': imageUrl.trim(),
        if (caption != null) 'text': caption.trim(),
      });
    }

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'lastMessage': displayText,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'hiddenFor': [],
        });
  }

  /// Sends a document message containing a download URL and document metadata.
  Future<void> sendDocumentMessage({
    required String chatId,
    required String senderId,
    required String mediaUrl,
    required String fileName,
    required int fileSize,
    required String fileExtension,
    String? clientMessageId,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null || activeUid != senderId) {
      throw SecurityException('Cannot send message as a different user.');
    }

    final targetId = clientMessageId ?? generateMessageId(chatId);
    final docRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(targetId);

    final messageData = {
      'senderId': senderId,
      'text': fileName,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileExtension': fileExtension,
      'messageType': 'document',
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
      'isDeleted': false,
      'hiddenFor': [],
      'status': 'sent',
    };

    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set(messageData);
    } else {
      await docRef.update({'status': 'sent', 'mediaUrl': mediaUrl});
    }

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'lastMessage': '📄 $fileName',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'hiddenFor': [],
        });
  }

  /// Sends an audio file message (MP3, WAV, M4A).
  Future<void> sendAudioMessage({
    required String chatId,
    required String senderId,
    required String mediaUrl,
    required String fileName,
    required int fileSize,
    required int durationSeconds,
    String? clientMessageId,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null || activeUid != senderId) {
      throw SecurityException('Cannot send message as a different user.');
    }

    final targetId = clientMessageId ?? generateMessageId(chatId);
    final docRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(targetId);

    final messageData = {
      'senderId': senderId,
      'text': fileName,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'durationSeconds': durationSeconds,
      'messageType': 'audio',
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
      'isDeleted': false,
      'hiddenFor': [],
      'status': 'sent',
    };

    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set(messageData);
    } else {
      await docRef.update({'status': 'sent', 'mediaUrl': mediaUrl});
    }

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'lastMessage': '🎵 Audio file',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'hiddenFor': [],
        });
  }

  /// Sends a voice recording message.
  Future<void> sendVoiceMessage({
    required String chatId,
    required String senderId,
    required String mediaUrl,
    required int durationSeconds,
    String? clientMessageId,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null || activeUid != senderId) {
      throw SecurityException('Cannot send message as a different user.');
    }

    final targetId = clientMessageId ?? generateMessageId(chatId);
    final docRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(targetId);

    final messageData = {
      'senderId': senderId,
      'text': 'Voice Message',
      'mediaUrl': mediaUrl,
      'durationSeconds': durationSeconds,
      'messageType': 'voice',
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [senderId],
      'isDeleted': false,
      'hiddenFor': [],
      'status': 'sent',
    };

    final docSnap = await docRef.get();
    if (!docSnap.exists) {
      await docRef.set(messageData);
    } else {
      await docRef.update({'status': 'sent', 'mediaUrl': mediaUrl});
    }

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'lastMessage': '🎤 Voice message',
          'lastMessageAt': FieldValue.serverTimestamp(),
          'hiddenFor': [],
        });
  }

  /// Forward a message to a destination chat room.
  Future<void> forwardMessage({
    required String targetChatId,
    required MessageModel originalMessage,
    String? senderName,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null) {
      throw SecurityException('Must be signed in to forward messages.');
    }

    final newMsgId = generateMessageId(targetChatId);
    final Map<String, dynamic> messageData = {
      'senderId': activeUid,
      'text': originalMessage.text,
      'messageType': originalMessage.messageType,
      'isForwarded': true,
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [activeUid],
      'isDeleted': false,
      'hiddenFor': [],
      'status': 'sent',
    };
    if (originalMessage.imageUrl != null)
      messageData['imageUrl'] = originalMessage.imageUrl;
    if (originalMessage.mediaUrl != null)
      messageData['mediaUrl'] = originalMessage.mediaUrl;
    if (originalMessage.fileName != null)
      messageData['fileName'] = originalMessage.fileName;
    if (originalMessage.fileSize != null)
      messageData['fileSize'] = originalMessage.fileSize;
    if (originalMessage.fileExtension != null)
      messageData['fileExtension'] = originalMessage.fileExtension;
    if (originalMessage.durationSeconds != null)
      messageData['durationSeconds'] = originalMessage.durationSeconds;
    if (senderName != null) messageData['forwardedFrom'] = senderName;

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(targetChatId)
        .collection('messages')
        .doc(newMsgId)
        .set(messageData);

    String lastMsgText = originalMessage.text;
    if (originalMessage.isImage) lastMsgText = '📷 Photo';
    if (originalMessage.isDocument)
      lastMsgText = '📄 ${originalMessage.fileName ?? "Document"}';
    if (originalMessage.isAudio) lastMsgText = '🎵 Audio file';
    if (originalMessage.isVoice) lastMsgText = '🎤 Voice message';

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(targetChatId)
        .update({
          'lastMessage': lastMsgText,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'hiddenFor': [],
        });
  }

  /// Record a call history entry into the chat timeline.
  Future<void> addCallMessage({
    required String chatId,
    required String callerId,
    required String targetId,
    required bool isVideo,
    required String callOutcome, // 'completed', 'missed', 'declined'
    required int durationSeconds,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    final newMsgId = generateMessageId(chatId);

    String callText;
    if (callOutcome == 'missed') {
      callText = isVideo ? 'Missed video call' : 'Missed voice call';
    } else if (callOutcome == 'declined') {
      callText = isVideo ? 'Declined video call' : 'Declined voice call';
    } else {
      final mins = (durationSeconds / 60).floor().toString().padLeft(2, '0');
      final secs = (durationSeconds % 60).toString().padLeft(2, '0');
      final durStr = '$mins:$secs';
      callText = isVideo ? 'Video call • $durStr' : 'Voice call • $durStr';
    }

    final Map<String, dynamic> messageData = {
      'senderId': callerId,
      'text': callText,
      'messageType': 'call',
      'sentAt': FieldValue.serverTimestamp(),
      'readBy': [activeUid],
      'isDeleted': false,
      'hiddenFor': [],
      'status': 'sent',
      'durationSeconds': durationSeconds,
    };

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(newMsgId)
        .set(messageData);

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'lastMessage': callText,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'hiddenFor': [],
        });
  }

  /// Delete message for me: hides message from current user's view.
  Future<void> hideMessageForMe({
    required String chatId,
    required String messageId,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'hiddenFor': FieldValue.arrayUnion([activeUid]),
        });
  }

  /// Delete message for everyone: replaces content with placeholder. Only original sender can invoke.
  Future<void> deleteMessageForEveryone({
    required String chatId,
    required String messageId,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    final docRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final doc = await docRef.get();
    if (!doc.exists) return;

    if (doc.data()?['senderId'] != activeUid) {
      throw SecurityException(
        'Only the original sender can delete a message for everyone.',
      );
    }

    await docRef.update({
      'text': 'This message was deleted',
      'isDeleted': true,
      'imageUrl': null,
      'mediaUrl': null,
    });
  }

  /// Toggle conversation Mute status for the current user.
  Future<void> toggleMuteChat({
    required String chatId,
    required bool isMuted,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'mutedBy': isMuted
              ? FieldValue.arrayUnion([activeUid])
              : FieldValue.arrayRemove([activeUid]),
        });
  }

  /// Toggle conversation Pin status for the current user.
  Future<void> togglePinChat({
    required String chatId,
    required bool isPinned,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'pinnedBy': isPinned
              ? FieldValue.arrayUnion([activeUid])
              : FieldValue.arrayRemove([activeUid]),
        });
  }

  /// Hide conversation for current user ("Delete chat for me").
  Future<void> hideChatForMe({required String chatId}) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({
          'hiddenFor': FieldValue.arrayUnion([activeUid]),
        });
  }

  /// Block a user persistently in `users/{currentUid}/blocked_users/{targetUid}`.
  Future<void> blockUser(String targetUid) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(activeUid)
        .collection('blocked_users')
        .doc(targetUid)
        .set({'uid': targetUid, 'blockedAt': FieldValue.serverTimestamp()});
  }

  /// Unblock a user.
  Future<void> unblockUser(String targetUid) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(activeUid)
        .collection('blocked_users')
        .doc(targetUid)
        .delete();
  }

  /// Check if current user has blocked targetUid.
  Future<bool> isUserBlocked(String targetUid) async {
    final activeUid = currentUserId;
    if (activeUid == null) return false;

    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(activeUid)
        .collection('blocked_users')
        .doc(targetUid)
        .get();

    return doc.exists;
  }

  /// Stream list of blocked user IDs for the current user.
  Stream<List<String>> getBlockedUserIdsStream() {
    final activeUid = currentUserId;
    if (activeUid == null) return Stream.value([]);

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(activeUid)
        .collection('blocked_users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Check if direct chat between current user and target user is blocked in either direction.
  Future<bool> isDirectChatBlocked(String targetUid) async {
    final activeUid = currentUserId;
    if (activeUid == null) return false;

    // Check if activeUid blocked targetUid
    final iBlocked = await isUserBlocked(targetUid);
    if (iBlocked) return true;

    // Check if targetUid blocked activeUid
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(targetUid)
        .collection('blocked_users')
        .doc(activeUid)
        .get();

    return doc.exists;
  }

  /// Submit a report against a user.
  Future<void> reportUser({
    required String targetUid,
    required String reason,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null) return;

    await _firestore.collection('reports').add({
      'reporterId': activeUid,
      'targetUid': targetUid,
      'reason': reason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch a single user profile from the `users` collection.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  /// Fetch profiles for a list of user IDs.
  Future<Map<String, Map<String, dynamic>>> getUsersProfiles(
    List<String> userIds,
  ) async {
    final Map<String, Map<String, dynamic>> result = {};

    for (final id in userIds) {
      final profile = await getUserProfile(id);
      if (profile != null) {
        result[id] = profile;
      }
    }

    return result;
  }

  /// Adds the current user's UID to the message's `readBy` array.
  Future<void> markMessageAsRead({
    required String chatId,
    required String messageId,
  }) async {
    final activeUid = currentUserId;
    if (activeUid == null || activeUid.isEmpty) {
      return;
    }

    try {
      await _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'readBy': FieldValue.arrayUnion([activeUid]),
          });
    } catch (e) {
      // Safely ignore read receipt write failures
    }
  }

  /// Stream all registered users from the `users` collection except the current user.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    final activeUid = currentUserId;
    return _firestore.collection(AppConstants.usersCollection).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => {'uid': doc.id, ...doc.data()})
          .where((user) => user['uid'] != activeUid)
          .toList();
    });
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
