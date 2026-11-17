import 'package:flutter/material.dart';

import '../models/marketplace_item.dart';
import '../theme/marketplace_theme.dart';

/// Card widget displaying a summary of a marketplace item in the grid feed.
class ItemCard extends StatelessWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

  /// Formats price in LKR with thousands separators (e.g. Rs. 1,500 or Free).
  static String formatLkrPrice(double price) {
    if (price <= 0) return 'Free';

    final isWhole = price.truncateToDouble() == price;
    final parts = price.toStringAsFixed(isWhole ? 0 : 2).split('.');

    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInteger = integerPart.replaceAllMapped(
      regExp,
      (Match m) => '${m[1]},',
    );

    return 'Rs. $formattedInteger$decimalPart';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        item.imageUrls.isNotEmpty && item.imageUrls.first.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: MarketplaceTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MarketplaceTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Square Image Thumbnail Stack
              AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Image.network(
                        item.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImagePlaceholder(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: MarketplaceTheme.background,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MarketplaceTheme.primary,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      _buildImagePlaceholder(),

                    // Favorite Heart Icon Placeholder (Visual Only)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: MarketplaceTheme.primary,
                        ),
                      ),
                    ),

                    // Condition Badge Tag
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MarketplaceTheme.successBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.condition,
                          style: const TextStyle(
                            color: MarketplaceTheme.successText,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Item Metadata Container
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Formatted LKR Price
                    Text(
                      formatLkrPrice(item.price),
                      style: const TextStyle(
                        color: MarketplaceTheme.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Title
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MarketplaceTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // Category Tag / Location Info
                    Text(
                      (item.location != null && item.location!.isNotEmpty)
                          ? item.location!
                          : item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: MarketplaceTheme.background,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: MarketplaceTheme.textMuted.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
