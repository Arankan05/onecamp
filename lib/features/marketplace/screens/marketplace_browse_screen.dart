import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../routes/app_routes.dart';
import '../models/marketplace_item.dart';
import '../repositories/marketplace_repository.dart';
import '../theme/marketplace_theme.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/item_card.dart';

/// Main browse screen for OneCamp Marketplace redesigned according to Figma specifications.
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

  void _showNavigationNotice(String tabName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$tabName module will be accessible via main navigation.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. App Bar Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: MarketplaceTheme.primaryLight,
                    backgroundImage: _currentUser?.photoURL != null
                        ? NetworkImage(_currentUser!.photoURL!)
                        : null,
                    child: _currentUser?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            color: MarketplaceTheme.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Marketplace',
                          style: TextStyle(
                            color: MarketplaceTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Buy nearby, sell easily',
                          style: TextStyle(
                            color: MarketplaceTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: MarketplaceTheme.textPrimary,
                    ),
                    onPressed: () => _showNavigationNotice('Inbox'),
                  ),
                ],
              ),
            ),

            // 2. Search Field Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: MarketplaceTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: MarketplaceTheme.cardShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search books, tech, furniture...',
                    hintStyle: const TextStyle(
                      color: MarketplaceTheme.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: MarketplaceTheme.primary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : const Icon(
                            Icons.tune,
                            color: MarketplaceTheme.textSecondary,
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

            // 3. Category Filter Chips
            CategoryFilterChips(
              selectedCategory: _selectedCategory,
              onCategorySelected: _onCategorySelected,
            ),

            const SizedBox(height: 8),

            // 4. Trust Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: MarketplaceTheme.successBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: MarketplaceTheme.successText,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Campus marketplace for students',
                        style: TextStyle(
                          color: MarketplaceTheme.successText,
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

            // 5. Listings Feed Stream
            Expanded(
              child: StreamBuilder<List<MarketplaceItem>>(
                stream: _repository.getAvailableItemsStream(
                  category: _selectedCategory == 'All'
                      ? null
                      : _selectedCategory,
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
                                  color: MarketplaceTheme.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  size: 40,
                                  color: MarketplaceTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Sign in to view campus listings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: MarketplaceTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'OneCamp requires an authenticated session to browse student listings.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: MarketplaceTheme.textSecondary,
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
                                  backgroundColor: MarketplaceTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                              Icons.error_outline,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Failed to load marketplace listings.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: MarketplaceTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: MarketplaceTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: MarketplaceTheme.primary,
                      ),
                    );
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
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Fresh on campus',
                              style: TextStyle(
                                color: MarketplaceTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                              style: const TextStyle(
                                color: MarketplaceTheme.textSecondary,
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
                                      const Icon(
                                        Icons.storefront_outlined,
                                        size: 56,
                                        color: MarketplaceTheme.textMuted,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No listings available',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: MarketplaceTheme.textPrimary,
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
                                        style: const TextStyle(
                                          color: MarketplaceTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  80,
                                ),
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
      ),

      // 6. Bottom Floating Promotional Banner & Navigation
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sell Banner Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: MarketplaceTheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: MarketplaceTheme.floatingShadow,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.amberAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Clear space, earn cash',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onAddListingPressed,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Sell'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: MarketplaceTheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Floating Navigation Bar Container
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: MarketplaceTheme.cardBackground,
                borderRadius: BorderRadius.circular(28),
                boxShadow: MarketplaceTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home_outlined),
                    color: MarketplaceTheme.textSecondary,
                    onPressed: () => _showNavigationNotice('Home'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.explore),
                    color: MarketplaceTheme.primary, // Active purple style
                    onPressed: () {},
                  ),
                  GestureDetector(
                    onTap: _onAddListingPressed,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: MarketplaceTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: MarketplaceTheme.textSecondary,
                    onPressed: () => _showNavigationNotice('Messages'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    color: MarketplaceTheme.textSecondary,
                    onPressed: () => _showNavigationNotice('Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
