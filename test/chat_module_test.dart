import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/features/chat/models/chat_model.dart';
import 'package:onecamp/features/chat/models/message_model.dart';

void main() {
  group('ChatModel Tests', () {
    test('ChatModel.fromMap correctly parses direct chat', () {
      final map = {
        'type': 'direct',
        'participantIds': ['user1', 'user2'],
        'lastMessage': 'Hello there',
        'lastMessageAt': 1600000000000,
        'createdAt': 1600000000000,
      };

      final chat = ChatModel.fromMap(map, 'chat123');

      expect(chat.chatId, 'chat123');
      expect(chat.type, 'direct');
      expect(chat.isGroup, false);
      expect(chat.participantIds, ['user1', 'user2']);
      expect(chat.lastMessage, 'Hello there');
      expect(chat.lastMessageAt, isNotNull);
    });

    test('ChatModel.fromMap correctly parses group chat', () {
      final map = {
        'type': 'group',
        'groupName': 'Study Group',
        'participantIds': ['user1', 'user2', 'user3'],
        'lastMessage': 'Welcome all!',
      };

      final chat = ChatModel.fromMap(map, 'group456');

      expect(chat.chatId, 'group456');
      expect(chat.type, 'group');
      expect(chat.isGroup, true);
      expect(chat.groupName, 'Study Group');
      expect(chat.participantIds.length, 3);
    });

    test('Per-user chat deletion and independent hiding state', () {
      final chat = ChatModel(
        chatId: 'chat_test',
        type: 'direct',
        participantIds: ['alice_uid', 'bob_uid'],
        hiddenFor: ['alice_uid'], // Hidden for Alice, but visible for Bob
      );

      expect(chat.isHiddenFor('alice_uid'), true);
      expect(chat.isHiddenFor('bob_uid'), false);

      final groupChat = ChatModel(
        chatId: 'group_test',
        type: 'group',
        participantIds: ['alice_uid', 'bob_uid', 'charlie_uid'],
        hiddenFor: ['bob_uid'], // Hidden only for Bob
      );

      expect(groupChat.isHiddenFor('alice_uid'), false);
      expect(groupChat.isHiddenFor('bob_uid'), true);
      expect(groupChat.isHiddenFor('charlie_uid'), false);
    });
  });

  group('MessageModel Tests', () {
    test('MessageModel.fromMap correctly parses text message', () {
      final map = {
        'senderId': 'user1',
        'text': 'Hello world',
        'messageType': 'text',
        'readBy': ['user1'],
      };

      final message = MessageModel.fromMap(map, 'msg123');

      expect(message.messageId, 'msg123');
      expect(message.senderId, 'user1');
      expect(message.text, 'Hello world');
      expect(message.isImage, false);
      expect(message.readBy, ['user1']);
    });

    test('MessageModel.fromMap correctly identifies image message', () {
      final map = {
        'senderId': 'user2',
        'text': 'Check this out',
        'imageUrl': 'https://example.com/photo.jpg',
        'messageType': 'image',
      };

      final message = MessageModel.fromMap(map, 'msg456');

      expect(message.messageId, 'msg456');
      expect(message.isImage, true);
      expect(message.imageUrl, 'https://example.com/photo.jpg');
    });

    test('Emoji preservation and rendering data', () {
      const emojiText = 'Hello! 😀😂👍🏽👨‍👩‍👧‍👦❤️‍🔥';
      final map = {
        'senderId': 'user1',
        'text': emojiText,
        'messageType': 'text',
      };

      final message = MessageModel.fromMap(map, 'msg_emoji');

      expect(message.text, emojiText);
      final mapOutput = message.toMap();
      expect(mapOutput['text'], emojiText);
    });

    test('Forwarding text message preserves text and adds forward metadata', () {
      final map = {
        'senderId': 'alice_uid',
        'text': 'Original message text',
        'messageType': 'text',
        'isForwarded': true,
        'forwardedFrom': 'Alice Smith',
      };

      final message = MessageModel.fromMap(map, 'msg_fwd_1');

      expect(message.isForwarded, true);
      expect(message.forwardedFrom, 'Alice Smith');
      expect(message.text, 'Original message text');
      expect(message.messageType, 'text');
    });

    test('Forwarding image message preserves imageUrl and caption', () {
      final map = {
        'senderId': 'alice_uid',
        'text': 'Image caption',
        'imageUrl': 'https://res.cloudinary.com/o5k43wz7/image/upload/sample.jpg',
        'messageType': 'image',
        'isForwarded': true,
        'forwardedFrom': 'Alice Smith',
      };

      final message = MessageModel.fromMap(map, 'msg_fwd_img');

      expect(message.isForwarded, true);
      expect(message.isImage, true);
      expect(message.imageUrl, 'https://res.cloudinary.com/o5k43wz7/image/upload/sample.jpg');
      expect(message.text, 'Image caption');
    });

    test('Forwarding document message preserves mediaUrl and file metadata', () {
      final map = {
        'senderId': 'alice_uid',
        'text': 'Syllabus.pdf',
        'mediaUrl': 'https://res.cloudinary.com/o5k43wz7/raw/upload/Syllabus.pdf',
        'fileName': 'Syllabus.pdf',
        'fileSize': 1048576,
        'fileExtension': 'pdf',
        'messageType': 'document',
        'isForwarded': true,
        'forwardedFrom': 'Alice Smith',
      };

      final message = MessageModel.fromMap(map, 'msg_fwd_doc');

      expect(message.isForwarded, true);
      expect(message.isDocument, true);
      expect(message.mediaUrl, 'https://res.cloudinary.com/o5k43wz7/raw/upload/Syllabus.pdf');
      expect(message.fileName, 'Syllabus.pdf');
      expect(message.fileSize, 1048576);
      expect(message.fileExtension, 'pdf');
    });

    test('Forwarding audio and voice messages preserves duration and mediaUrl', () {
      final audioMap = {
        'senderId': 'alice_uid',
        'text': 'audio_track.mp3',
        'mediaUrl': 'https://res.cloudinary.com/o5k43wz7/video/upload/audio_track.mp3',
        'fileName': 'audio_track.mp3',
        'fileSize': 2097152,
        'durationSeconds': 180,
        'messageType': 'audio',
        'isForwarded': true,
      };

      final audioMsg = MessageModel.fromMap(audioMap, 'msg_fwd_audio');
      expect(audioMsg.isAudio, true);
      expect(audioMsg.durationSeconds, 180);
      expect(audioMsg.isForwarded, true);

      final voiceMap = {
        'senderId': 'alice_uid',
        'text': 'Voice Message',
        'mediaUrl': 'https://res.cloudinary.com/o5k43wz7/video/upload/voice.m4a',
        'durationSeconds': 15,
        'messageType': 'voice',
        'isForwarded': true,
      };

      final voiceMsg = MessageModel.fromMap(voiceMap, 'msg_fwd_voice');
      expect(voiceMsg.isVoice, true);
      expect(voiceMsg.durationSeconds, 15);
      expect(voiceMsg.isForwarded, true);
    });
  });
}
