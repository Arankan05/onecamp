import 'package:flutter/material.dart';

/// Figma Design System constants and styles for OneCamp Marketplace.
class MarketplaceTheme {
  // Brand & Surface Colors
  static const Color background = Color(0xFFF4EFFF); // Light Lavender
  static const Color primary = Color(0xFF7C3AED); // Deep Purple
  static const Color primaryLight = Color(0xFFDDD6FE); // Soft Purple Accent
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure White

  // Status & Success Colors
  static const Color successBackground = Color(0xFFE6F4EA); // Soft Mint Green
  static const Color successText = Color(0xFF107C41); // Emerald Green

  // Typography Colors
  static const Color textPrimary = Color(
    0xFF1E1B4B,
  ); // Dark Charcoal / Deep Indigo
  static const Color textSecondary = Color(0xFF6B7280); // Medium Grey
  static const Color textMuted = Color(0xFF9CA3AF); // Muted Light Grey

  // Border & Shadow
  static const Color outline = Color(0xFFE5E7EB);
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
