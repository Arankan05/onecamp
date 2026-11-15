import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../theme/marketplace_theme.dart';

/// Horizontal scrollable list of category filter chips styled according to Figma specifications.
class CategoryFilterChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppConstants.marketplaceCategories.length,
        itemBuilder: (context, index) {
          final rawCategory = AppConstants.marketplaceCategories[index];
          final displayLabel = rawCategory == 'All' ? 'For You' : rawCategory;
          final isSelected = selectedCategory == rawCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(displayLabel),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(rawCategory),
              selectedColor: MarketplaceTheme.primary,
              backgroundColor: MarketplaceTheme.cardBackground,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? MarketplaceTheme.primary
                      : MarketplaceTheme.outline,
                ),
              ),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : MarketplaceTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}
