import 'package:flutter/material.dart';
import 'chat_colors.dart';

class ChatTextStyles {
  static const TextStyle headerTitle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: ChatColors.textPrimary,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: ChatColors.textPrimary,
  );

  static const TextStyle appBarSubtitle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: ChatColors.textSecondary,
  );

  static const TextStyle chatTileTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: ChatColors.textPrimary,
  );

  static const TextStyle chatTileSubtitle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: ChatColors.textSecondary,
  );

  static const TextStyle chatTileTime = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: ChatColors.textLight,
  );

  static const TextStyle senderMessage = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: ChatColors.textOnPrimary,
  );

  static const TextStyle receiverMessage = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: ChatColors.textPrimary,
  );

  static const TextStyle messageTimeSender = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w300,
    color: Color(0xD0FFFFFF),
  );

  static const TextStyle messageTimeReceiver = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w300,
    color: ChatColors.textSecondary,
  );

  static const TextStyle unreadCount = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
