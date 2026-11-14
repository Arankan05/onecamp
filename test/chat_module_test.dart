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
  });
}
