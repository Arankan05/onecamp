import 'package:flutter/material.dart';
import '../features/chat/screens/dev_chat_entry_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_room_screen.dart';
import '../features/chat/screens/new_chat_screen.dart';
import '../features/chat/screens/create_group_screen.dart';
import '../features/chat/screens/chat_details_screen.dart';

class AppRoutes {
  static const String initial = '/';

  // Chat module routes
  static const String chatList = '/chat_list';
  static const String chatRoom = '/chat_room';
  static const String newChat = '/new_chat';
  static const String createGroup = '/create_group';
  static const String chatDetails = '/chat_details';

  static Map<String, WidgetBuilder> get routes {
    return {
      chatList: (context) => const ChatListScreen(),
      newChat: (context) => const NewChatScreen(),
      createGroup: (context) => const CreateGroupScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(
          builder: (_) => const DevChatEntryScreen(),
        );

      case chatList:
        return MaterialPageRoute(
          builder: (_) => const ChatListScreen(),
        );

      case newChat:
        return MaterialPageRoute(
          builder: (_) => const NewChatScreen(),
        );

      case createGroup:
        return MaterialPageRoute(
          builder: (_) => const CreateGroupScreen(),
        );

      case chatRoom:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            chatId: args['chatId'] as String? ?? '',
            title: args['title'] as String? ?? 'Chat',
            isGroup: args['isGroup'] as bool? ?? false,
            avatarUrl: args['avatarUrl'] as String?,
            participantIds: (args['participantIds'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
            otherUserId: args['otherUserId'] as String?,
          ),
        );

      case chatDetails:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ChatDetailsScreen(
            chatId: args['chatId'] as String? ?? '',
            title: args['title'] as String? ?? 'Chat Info',
            isGroup: args['isGroup'] as bool? ?? false,
            avatarUrl: args['avatarUrl'] as String?,
            participantIds: (args['participantIds'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
            otherUserId: args['otherUserId'] as String?,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
