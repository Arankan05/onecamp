import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/onecamp_back_button.dart';
import '../../../../routes/app_routes.dart';
import '../models/marketplace_item.dart';
import '../repositories/marketplace_repository.dart';
import '../widgets/item_card.dart';

/// Main browse screen for OneCamp Marketplace redesigned to match the Messages screen master reference.
class MarketplaceBrowseScreen extends StatefulWidget {
  final MarketplaceRepository? repository;

  const MarketplaceBrowseScreen({super.key, this.repository});

  @override
  State<MarketplaceBrowseScreen> createState() =>
      _MarketplaceBrowseScreenState();
}

class _MarketplaceBrowseScreenState extends State<MarketplaceBrowseScreen> {
  late final MarketplaceRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<User?>? _authSubscription;

  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isSigningIn = false;

  final List<String> _categories = const [
    'All',
    'Textbooks',
    'Electronics',
    'Furniture',
    'Clothing',
    'School Supplies',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? MarketplaceRepository();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _signInAsGuest() async {
    setState(() => _isSigningIn = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign in: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onAddListingPressed() {
    if (_currentUser == null) {
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
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Marketplace'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: Navigator.canPop(context) ? const OneCampBackButton() : null,
      ),
      body: Column(
        children: [
          // 1. Search Field Container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0C7C3AED),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search textbooks, tech, furniture...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : const Icon(
                          Icons.tune_rounded,
                          color: AppTheme.primaryColor,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // 2. Category Filter Chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1F2937),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  onSelected: (_) => _onCategorySelected(category),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // 3. Trust Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.successBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: AppTheme.successTextColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified campus marketplace for students',
                      style: TextStyle(
                        color: AppTheme.successTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 4. Listings Feed Stream
          Expanded(
            child: StreamBuilder<List<MarketplaceItem>>(
              stream: _repository.getAvailableItemsStream(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final errStr = snapshot.error.toString();
                  final isPermissionDenied =
                      errStr.contains('permission-denied') ||
                      errStr.contains('Missing or insufficient permissions');

                  if (isPermissionDenied || _currentUser == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sign in to view campus listings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'OneCamp requires an authenticated student session to browse listings.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _isSigningIn ? null : _signInAsGuest,
                              icon: _isSigningIn
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.login, size: 18),
                              label: Text(
                                _isSigningIn
                                    ? 'Connecting...'
                                    : 'Browse as Campus Guest',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load marketplace listings.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var items = snapshot.data ?? [];

                // Apply client-side search query filtering
                if (_searchQuery.isNotEmpty) {
                  items = items.where((item) {
                    final titleMatch = item.title.toLowerCase().contains(
                      _searchQuery,
                    );
                    final descMatch = item.description.toLowerCase().contains(
                      _searchQuery,
                    );
                    final catMatch = item.category.toLowerCase().contains(
                      _searchQuery,
                    );
                    return titleMatch || descMatch || catMatch;
                  }).toList();
                }

                return Column(
                  children: [
                    // Section Header with Actual Count
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Fresh on campus',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.storefront_outlined,
                                      size: 56,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No listings available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No items match "$_searchQuery".'
                                          : _selectedCategory == 'All'
                                          ? 'Be the first student to post a listing!'
                                          : 'No items in $_selectedCategory.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.70,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
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
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // 5. Floating Action Bar
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_shopping_cart_rounded, size: 22),
        label: const Text(
          'Post Listing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _onAddListingPressed,
      ),
    );
  }
}
