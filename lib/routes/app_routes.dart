// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/campus/screens/campus_updates_screen.dart';
import '../features/chat/screens/chat_details_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_room_screen.dart';
import '../features/chat/screens/create_group_screen.dart';
import '../features/chat/screens/dev_chat_entry_screen.dart';
import '../features/chat/screens/new_chat_screen.dart';
import '../features/events/models/event_model.dart';
import '../features/events/screens/create_event_screen.dart';
import '../features/events/screens/event_details_screen.dart';
import '../features/events/screens/events_list_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class AppRoutes {
  static const String initial = '/';

  // Auth & Profile routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  // Chat module routes
  static const String chatList = '/chat_list';
  static const String chatRoom = '/chat_room';
  static const String newChat = '/new_chat';
  static const String createGroup = '/create_group';
  static const String chatDetails = '/chat_details';

  // Events & Campus Feature Routes
  static const String eventsList = '/events';
  static const String createEvent = '/events/create';
  static const String eventDetails = '/events/details';
  static const String campusUpdates = '/campus_updates';

  static Map<String, WidgetBuilder> get routes {
    return {
      chatList: (context) => const ChatListScreen(),
      newChat: (context) => const NewChatScreen(),
      createGroup: (context) => const CreateGroupScreen(),
      eventsList: (context) => const EventsListScreen(),
      campusUpdates: (context) => const CampusUpdatesScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('OneCamp Initializing...')),
          ),
          settings: settings,
        );

      case eventsList:
        return MaterialPageRoute(
          builder: (_) => const EventsListScreen(),
          settings: settings,
        );

      case campusUpdates:
        return MaterialPageRoute(
          builder: (_) => const CampusUpdatesScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );

      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );

      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );

      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      case editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );

      case chatList:
        return MaterialPageRoute(
          builder: (_) => const ChatListScreen(),
          settings: settings,
        );

      case newChat:
        return MaterialPageRoute(
          builder: (_) => const NewChatScreen(),
          settings: settings,
        );

      case createGroup:
        return MaterialPageRoute(
          builder: (_) => const CreateGroupScreen(),
          settings: settings,
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
          settings: settings,
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
          settings: settings,
        );

      case createEvent:
        final args = settings.arguments;
        final eventToEdit = args is EventModel ? args : null;
        return MaterialPageRoute<String?>(
          builder: (_) => CreateEventScreen(eventToEdit: eventToEdit),
          settings: settings,
        );

      case eventDetails:
        final args = settings.arguments;
        if (args is! EventModel) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Invalid Event')),
              body: Center(
                child: Text(
                  args == null
                      ? 'Error: Missing event details argument.'
                      : 'Error: Invalid event details argument type (${args.runtimeType}).',
                ),
              ),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => EventDetailsScreen(event: args),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                'No route defined for ${settings.name}',
              ),
            ),
          ),
          settings: settings,
        );
    }
  }
}
