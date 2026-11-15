import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../routes/app_routes.dart';
import '../models/marketplace_item.dart';
import '../repositories/marketplace_repository.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/item_card.dart';

/// Main browse screen for OneCamp Marketplace.
class MarketplaceBrowseScreen extends StatefulWidget {
  final MarketplaceRepository? repository;

  const MarketplaceBrowseScreen({super.key, this.repository});

  @override
  State<MarketplaceBrowseScreen> createState() =>
      _MarketplaceBrowseScreenState();
}

class _MarketplaceBrowseScreenState extends State<MarketplaceBrowseScreen> {
  late final MarketplaceRepository _repository;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MarketplaceRepository();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onAddListingPressed() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sign-in is required before posting a marketplace listing.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pushNamed(context, AppRoutes.marketplaceCreate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category Filter Chips Bar
          CategoryFilterChips(
            selectedCategory: _selectedCategory,
            onCategorySelected: _onCategorySelected,
          ),

          const Divider(height: 1),

          // Real-time Listings Stream
          Expanded(
            child: StreamBuilder<List<MarketplaceItem>>(
              stream: _repository.getAvailableItemsStream(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load marketplace listings.',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items available',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedCategory == 'All'
                                ? 'Be the first to list an item on OneCamp Marketplace!'
                                : 'No listings available under $_selectedCategory.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ItemCard(
                      item: item,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.marketplaceDetail,
                          arguments: item,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddListingPressed,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Post Item'),
      ),
    );
  }
}
