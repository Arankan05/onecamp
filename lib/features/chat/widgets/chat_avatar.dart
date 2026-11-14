import 'package:flutter/material.dart';
import '../theme/chat_colors.dart';
import '../theme/chat_dimensions.dart';

class ChatAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool isOnline;
  final bool isGroup;
  final String? imageUrl; // Preserved in constructor signature for compatibility

  const ChatAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = ChatDimensions.avatarMedium,
    this.isOnline = false,
    this.isGroup = false,
  });

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (trimmed.length >= 2) {
      return trimmed.substring(0, 2).toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isGroup
                ? const LinearGradient(
                    colors: [Color(0xFF6C2BD9), Color(0xFF4C1D95)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [ChatColors.primaryPurple, Color(0xFF9D65F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A7B38E0),
                blurRadius: 6.0,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.38,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: ChatDimensions.onlineIndicatorSize,
              height: ChatDimensions.onlineIndicatorSize,
              decoration: BoxDecoration(
                color: ChatColors.onlineGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ),
      ],
    );
  }
}
