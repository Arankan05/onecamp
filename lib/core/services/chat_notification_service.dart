import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../../routes/app_routes.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Executed in background isolate when message arrives
}

class ChatNotificationService {
  static final ChatNotificationService _instance =
      ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Active chat room ID currently visible on screen. Used to suppress duplicate foreground banners.
  static String? activeChatId;

  /// Initialize FCM notification handlers, permissions, token sync, and routing.
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey;

    // 1. Request Push Notification Permissions
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _syncFcmToken();
    }

    // 2. Listen to Auth State changes to save FCM Token per logged-in user
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _syncFcmToken();
      }
    });

    // 3. Listen to FCM Token Refresh
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });

    // 4. Foreground Message Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 5. Message Opened App (Background -> Foreground via Notification Tap)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 6. Terminated App Launch via Notification Tap
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Sync FCM token to current user profile in Firestore `users/{uid}`.
  Future<void> _syncFcmToken() async {
    try {
      final String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (_) {}
  }

  /// Save FCM token to Firestore document `users/{uid}`.
  Future<void> _saveTokenToFirestore(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update(
        {
          'fcmToken': token,
          'fcmTokenLastUpdated': FieldValue.serverTimestamp(),
        },
      );
    } catch (_) {
      // If update fails (e.g. document doesn't exist yet), set with merge
      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'fcmToken': token,
        'fcmTokenLastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Handle incoming foreground messages while user is active in the app.
  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final String? incomingChatId = data['chatId'] as String?;

    // Rule 9: Avoid duplicate notifications if user is already viewing the relevant chat room
    if (incomingChatId != null && incomingChatId == activeChatId) {
      return;
    }

    final RemoteNotification? notification = message.notification;
    final String title =
        notification?.title ?? data['senderName'] ?? 'OneCamp Chat';
    final String body =
        notification?.body ?? data['body'] ?? 'New message received';

    final BuildContext? context = _navigatorKey?.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF29213F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Color(0xFFE5DCF6)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE5DCF6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'OPEN',
            textColor: const Color(0xFF80DEEA),
            onPressed: () => _handleNotificationTap(message),
          ),
        ),
      );
    }
  }

  /// Handle notification tap action from background/terminated states to open the target ChatRoom.
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final String? chatId = data['chatId'] as String?;
    if (chatId == null || chatId.isEmpty) return;

    final String title = data['senderName'] ?? data['title'] ?? 'Chat';
    final bool isGroup = data['isGroup'] == 'true';
    final String? otherUserId = data['senderId'];
    final List<String> participantIds =
        (data['participantIds'] as String?)?.split(',') ?? [];

    if (_navigatorKey != null && _navigatorKey!.currentState != null) {
      _navigatorKey!.currentState!.pushNamed(
        AppRoutes.chatRoom,
        arguments: {
          'chatId': chatId,
          'title': title,
          'isGroup': isGroup,
          'participantIds': participantIds,
          'otherUserId': otherUserId,
        },
      );
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}
