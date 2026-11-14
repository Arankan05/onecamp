import 'package:flutter/material.dart';
import 'chat_colors.dart';
import 'chat_dimensions.dart';

class ChatDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: ChatColors.cardBackground,
    borderRadius: BorderRadius.circular(ChatDimensions.radiusCard),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0C4F1BAA),
        blurRadius: 12.0,
        spreadRadius: 0.0,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration senderBubbleDecoration = const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        ChatColors.senderBubble,
        ChatColors.senderBubbleGradientEnd,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(ChatDimensions.radiusL),
      topRight: Radius.circular(ChatDimensions.radiusL),
      bottomLeft: Radius.circular(ChatDimensions.radiusL),
      bottomRight: Radius.circular(ChatDimensions.radiusS),
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0x207B38E0),
        blurRadius: 8.0,
        offset: Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration receiverBubbleDecoration = const BoxDecoration(
    color: ChatColors.receiverBubble,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(ChatDimensions.radiusL),
      topRight: Radius.circular(ChatDimensions.radiusL),
      bottomLeft: Radius.circular(ChatDimensions.radiusS),
      bottomRight: Radius.circular(ChatDimensions.radiusL),
    ),
    boxShadow: [
      BoxShadow(
        color: Color(0x084F1BAA),
        blurRadius: 8.0,
        offset: Offset(0, 2),
      ),
    ],
  );

  static InputDecoration inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: ChatColors.textLight,
        fontSize: 14.0,
      ),
      filled: true,
      fillColor: ChatColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ChatDimensions.paddingL,
        vertical: ChatDimensions.paddingM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChatDimensions.radiusXL),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ChatDimensions.radiusXL),
        borderSide: const BorderSide(color: ChatColors.primaryPurple, width: 1.5),
      ),
    );
  }
}
