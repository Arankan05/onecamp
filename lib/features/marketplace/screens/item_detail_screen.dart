import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../routes/app_routes.dart';
import '../models/marketplace_item.dart';
import '../repositories/marketplace_repository.dart';
import '../widgets/item_card.dart';

/// Detailed view for a single marketplace listing.
class ItemDetailScreen extends StatefulWidget {
  final MarketplaceItem item;
  final MarketplaceRepository? repository;

  const ItemDetailScreen({super.key, required this.item, this.repository});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late MarketplaceItem _item;
  late final MarketplaceRepository _repository;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isLoading = false;

  Map<String, dynamic>? _sellerProfile;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _repository = widget.repository ?? MarketplaceRepository();
    _fetchSellerProfile();
  }

  bool get _isOwner {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == _item.sellerId;
  }

  Future<void> _fetchSellerProfile() async {
    if (_item.sellerId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(_item.sellerId)
          .get();

      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _sellerProfile = doc.data();
          });
        }
      }
    } catch (_) {}
  }

  String get _sellerDisplayName {
    if (_sellerProfile != null) {
      final name =
          _sellerProfile!['displayName'] as String? ??
          _sellerProfile!['name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name;
    }
    if (_item.sellerName.trim().isNotEmpty) return _item.sellerName;
    if (_item.sellerEmail.contains('@')) {
      return _item.sellerEmail.split('@').first;
    }
    return 'Campus Seller';
  }

  String? get _sellerPhotoUrl {
    if (_sellerProfile != null) {
      final photo =
          _sellerProfile!['photoUrl'] as String? ??
          _sellerProfile!['photoURL'] as String?;
      if (photo != null && photo.trim().isNotEmpty) return photo;
    }
    return _item.sellerPhotoUrl;
  }

  Future<void> _toggleStatus() async {
    final newStatus = _item.isAvailable
        ? AppConstants.statusSold
        : AppConstants.statusAvailable;

    setState(() => _isLoading = true);

    try {
      await _repository.updateItemStatus(_item.id, newStatus);
      if (mounted) {
        setState(() {
          _item = _item.copyWith(status: newStatus);
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == AppConstants.statusSold
                  ? 'Listing marked as Sold.'
                  : 'Listing marked as Available.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to delete this listing permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _repository.deleteItem(_item.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing deleted successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete listing: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _onContactSellerPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Real-time Chat feature is coming soon when the Chat module is deployed!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = _item.imageUrls;

    return Scaffold(
      appBar: AppBar(
        title: Text(_item.title),
        actions: [
          if (_isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Listing',
              onPressed: _isLoading
                  ? null
                  : () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.marketplaceEdit,
                        arguments: _item,
                      );
                      // Refetch item after edit if updated
                      final updated = await _repository.getItemById(_item.id);
                      if (updated != null && mounted) {
                        setState(() => _item = updated);
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete Listing',
              onPressed: _isLoading ? null : _confirmDelete,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel Header
                  SizedBox(
                    height: 280,
                    child: images.isNotEmpty
                        ? Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: images.length,
                                onPageChanged: (index) {
                                  setState(() => _currentImageIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    images[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) => _buildImagePlaceholder(theme),
                                  );
                                },
                              ),
                              if (images.length > 1)
                                Positioned(
                                  bottom: 12,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      images.length,
                                      (index) => Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentImageIndex == index
                                              ? theme.colorScheme.primary
                                              : Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : _buildImagePlaceholder(theme),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status & Badges Bar
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _item.isAvailable
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _item.isAvailable ? 'AVAILABLE' : 'SOLD',
                                style: TextStyle(
                                  color: _item.isAvailable
                                      ? Colors.green.shade900
                                      : Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Chip(
                              label: Text(_item.category),
                              visualDensity: VisualDensity.compact,
                            ),

                            const SizedBox(width: 8),

                            Chip(
                              label: Text(_item.condition),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Title
                        Text(
                          _item.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Formatted LKR Price
                        Text(
                          ItemCard.formatLkrPrice(_item.price),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        if (_item.location != null &&
                            _item.location!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _item.location!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const Divider(height: 32),

                        // Description Section
                        Text(
                          'Description',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _item.description.isNotEmpty
                              ? _item.description
                              : 'No description provided.',
                          style: theme.textTheme.bodyMedium,
                        ),

                        const Divider(height: 32),

                        // Seller Profile Card Section
                        Text(
                          'Seller Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Card(
                          elevation: 0,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: _sellerPhotoUrl != null
                                      ? NetworkImage(_sellerPhotoUrl!)
                                      : null,
                                  child: _sellerPhotoUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _sellerDisplayName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Verified Student',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Actions Section
                        if (_isOwner) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _toggleStatus,
                              icon: Icon(
                                _item.isAvailable
                                    ? Icons.check_circle_outline
                                    : Icons.storefront_outlined,
                              ),
                              label: Text(
                                _item.isAvailable
                                    ? 'Mark as Sold'
                                    : 'Mark as Available',
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _onContactSellerPressed,
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Contact Seller'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
