// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../core/screens/main_navigation_screen.dart';
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
import '../features/communities/screens/community_details_screen.dart';
import '../features/communities/screens/community_list_screen.dart';
import '../features/communities/screens/create_community_screen.dart';
import '../features/events/models/event_model.dart';
import '../features/events/screens/create_event_screen.dart';
import '../features/events/screens/event_details_screen.dart';
import '../features/events/screens/events_list_screen.dart';
import '../features/marketplace/models/marketplace_item.dart';
import '../features/marketplace/screens/create_edit_item_screen.dart';
import '../features/marketplace/screens/item_detail_screen.dart';
import '../features/marketplace/screens/marketplace_browse_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../main.dart';

class AppRoutes {
  static const String initial = '/';
  static const String mainNavigation = '/main';

  // Auth & Profile routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String communityList = '/communities';
  static const String communityDetails = '/community-details';
  static const String createCommunity = '/create-community';

  // Chat module routes
  static const String chatList = '/chat_list';
  static const String chatRoom = '/chat_room';
  static const String newChat = '/new_chat';
  static const String createGroup = '/create_group';
  static const String chatDetails = '/chat_details';
  static const String devChatEntry = '/dev_chat_entry';

  // Events & Campus Feature Routes
  static const String eventsList = '/events';
  static const String createEvent = '/events/create';
  static const String eventDetails = '/events/details';
  static const String campusUpdates = '/campus_updates';

  // Marketplace Feature Routes
  static const String marketplace = '/marketplace';
  static const String marketplaceDetail = '/marketplace/detail';
  static const String marketplaceCreate = '/marketplace/create';
  static const String marketplaceEdit = '/marketplace/edit';

  static Map<String, WidgetBuilder> get routes {
    return {
      mainNavigation: (context) => const MainNavigationScreen(),
      chatList: (context) => const ChatListScreen(),
      newChat: (context) => const NewChatScreen(),
      createGroup: (context) => const CreateGroupScreen(),
      eventsList: (context) => const EventsListScreen(),
      campusUpdates: (context) => const CampusUpdatesScreen(),
      marketplace: (context) => const MarketplaceBrowseScreen(),
      devChatEntry: (context) => const DevChatEntryScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
          settings: settings,
        );

      case mainNavigation:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
          settings: settings,
        );

      case devChatEntry:
        return MaterialPageRoute(
          builder: (_) => const DevChatEntryScreen(),
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

      case communityList:
        return MaterialPageRoute(
          builder: (_) => const CommunityListScreen(),
          settings: settings,
        );

      case communityDetails:
        final args = settings.arguments;
        final communityId = args is String
            ? args
            : (args is Map<String, dynamic>
                ? args['communityId'] as String? ?? ''
                : '');
        return MaterialPageRoute(
          builder: (_) => CommunityDetailsScreen(communityId: communityId),
          settings: settings,
        );

      case createCommunity:
        return MaterialPageRoute(
          builder: (_) => const CreateCommunityScreen(),
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

      case marketplace:
        return MaterialPageRoute(
          builder: (_) => const MarketplaceBrowseScreen(),
          settings: settings,
        );

      case marketplaceDetail:
        final item = settings.arguments as MarketplaceItem?;
        if (item == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Error: No item specified.')),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => ItemDetailScreen(item: item),
          settings: settings,
        );

      case marketplaceCreate:
        return MaterialPageRoute(
          builder: (_) => const CreateEditItemScreen(isEditing: false),
          settings: settings,
        );

      case marketplaceEdit:
        final item = settings.arguments as MarketplaceItem?;
        if (item == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Error: No item specified for editing.'),
              ),
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => CreateEditItemScreen(isEditing: true, item: item),
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
