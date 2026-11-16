import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../routes/app_routes.dart';
import '../models/marketplace_item.dart';
import '../repositories/marketplace_repository.dart';
import '../theme/marketplace_theme.dart';
import '../widgets/item_card.dart';

/// Detailed view for a single marketplace listing redesigned according to Figma specifications.
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

  String get _formattedPostTime {
    if (_item.createdAt == null) return 'Posted recently';
    final now = DateTime.now();
    final difference = now.difference(_item.createdAt!);

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return mins <= 1 ? 'Posted just now' : 'Posted $mins mins ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Posted $hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else {
      final days = difference.inDays;
      return 'Posted $days ${days == 1 ? 'day' : 'days'} ago';
    }
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
            backgroundColor: Colors.redAccent,
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
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
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
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _onSharePressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Listing link for "${_item.title}" copied to clipboard.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _onMakeOfferPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Make Offer is a future feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _item.imageUrls;

    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      appBar: AppBar(
        title: const Text('Item details'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _onSharePressed,
          ),
          if (_isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _isLoading
                  ? null
                  : () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.marketplaceEdit,
                        arguments: _item,
                      );
                      final updated = await _repository.getItemById(_item.id);
                      if (updated != null && mounted) {
                        setState(() => _item = updated);
                      }
                    },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _confirmDelete,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: MarketplaceTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Image Carousel Stack
                  Container(
                    height: 300,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: MarketplaceTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: MarketplaceTheme.cardShadow,
                    ),
                    child: images.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
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
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) => _buildImagePlaceholder(),
                                  );
                                },
                              ),

                              // White Favorite Heart Button (Visual Placeholder)
                              Positioned(
                                bottom: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border,
                                    size: 20,
                                    color: MarketplaceTheme.primary,
                                  ),
                                ),
                              ),

                              // Image Count Badge Tag
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentImageIndex + 1} / ${images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _buildImagePlaceholder(),
                  ),

                  const SizedBox(height: 16),

                  // 2. Product Details Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MarketplaceTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: MarketplaceTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price & Condition Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ItemCard.formatLkrPrice(_item.price),
                              style: const TextStyle(
                                color: MarketplaceTheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MarketplaceTheme.successBackground,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _item.condition,
                                style: const TextStyle(
                                  color: MarketplaceTheme.successText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Title
                        Text(
                          _item.title,
                          style: const TextStyle(
                            color: MarketplaceTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Location & Posted Time Row
                        Row(
                          children: [
                            if (_item.location != null &&
                                _item.location!.isNotEmpty) ...[
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: MarketplaceTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _item.location!,
                                style: const TextStyle(
                                  color: MarketplaceTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: MarketplaceTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formattedPostTime,
                              style: const TextStyle(
                                color: MarketplaceTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 24),

                        // Description Section
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: MarketplaceTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _item.description.isNotEmpty
                              ? _item.description
                              : 'No detailed description provided.',
                          style: const TextStyle(
                            color: MarketplaceTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. Seller Information Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MarketplaceTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: MarketplaceTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: MarketplaceTheme.primaryLight,
                          backgroundImage: _sellerPhotoUrl != null
                              ? NetworkImage(_sellerPhotoUrl!)
                              : null,
                          child: _sellerPhotoUrl == null
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
                              Text(
                                _sellerDisplayName,
                                style: const TextStyle(
                                  color: MarketplaceTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Verified Student',
                                    style: TextStyle(
                                      color: MarketplaceTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Safety Reminder Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: MarketplaceTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: MarketplaceTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: MarketplaceTheme.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            color: MarketplaceTheme.primary,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Meet at a designated campus exchange point and inspect before paying.',
                            style: TextStyle(
                              color: MarketplaceTheme.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      // 5. Fixed Bottom Action Bar
      bottomSheet: Container(
        color: MarketplaceTheme.cardBackground,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          child: _isOwner
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleStatus,
                        icon: Icon(
                          _item.isAvailable
                              ? Icons.check_circle_outline
                              : Icons.storefront_outlined,
                        ),
                        label: Text(
                          _item.isAvailable ? 'Mark Sold' : 'Mark Available',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MarketplaceTheme.primary,
                          side: const BorderSide(
                            color: MarketplaceTheme.primary,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.marketplaceEdit,
                            arguments: _item,
                          );
                          final updated = await _repository.getItemById(
                            _item.id,
                          );
                          if (updated != null && mounted) {
                            setState(() => _item = updated);
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Listing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MarketplaceTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Make Offer Button (Visual Placeholder)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onMakeOfferPressed,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MarketplaceTheme.primary,
                          side: const BorderSide(
                            color: MarketplaceTheme.primary,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Make Offer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Message Seller Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _onContactSellerPressed,
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message Seller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MarketplaceTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 64,
          color: MarketplaceTheme.textMuted,
        ),
      ),
    );
  }
}
