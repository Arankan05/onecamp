import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import '../../../routes/app_routes.dart';
import '../../chat/repositories/chat_repository.dart';
import '../models/marketplace_item.dart';
import '../repositories/marketplace_repository.dart';

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
  final ChatRepository _chatRepository = ChatRepository();
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

      if (doc.exists && doc.data() != null && mounted) {
        setState(() {
          _sellerProfile = doc.data();
        });
      }
    } catch (_) {}
  }

  String get _timeAgo {
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
              _item.isAvailable
                  ? 'Item marked as Available.'
                  : 'Item marked as Sold.',
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

  void _onSharePressed() async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'Check out "${_item.title}" for \$${_item.price.toStringAsFixed(2)} on OneCamp Marketplace!',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Listing details for "${_item.title}" copied to clipboard.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onContactSellerPressed() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to message the seller.')),
      );
      return;
    }

    if (currentUser.uid == _item.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This is your own marketplace listing.')),
      );
      return;
    }

    try {
      final chatId = await _chatRepository.createDirectChat(
        currentUserId: currentUser.uid,
        otherUserId: _item.sellerId,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.chatRoom,
        arguments: {
          'chatId': chatId,
          'title': _sellerProfile?['name'] as String? ?? _item.sellerName,
          'isGroup': false,
          'avatarUrl': _sellerProfile?['profileImageUrl'] as String?,
          'participantIds': [currentUser.uid, _item.sellerId],
          'otherUserId': _item.sellerId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open seller conversation: $e')),
      );
    }
  }

  Future<void> _onMakeOfferPressed() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to make an offer.')),
      );
      return;
    }

    final offerController = TextEditingController(
      text: _item.price.toStringAsFixed(2),
    );

    final bool? shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Make an Offer for ${_item.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your offer price in \$:',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: offerController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  labelText: 'Offer Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );

    if (shouldSend == true && mounted) {
      try {
        final chatId = await _chatRepository.createDirectChat(
          currentUserId: currentUser.uid,
          otherUserId: _item.sellerId,
        );

        await _chatRepository.sendMessage(
          chatId: chatId,
          senderId: currentUser.uid,
          text:
              'Hi! I would like to offer \$${offerController.text.trim()} for your "${_item.title}". Is it still available?',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer sent to seller via Direct Message!'),
          ),
        );

        Navigator.pushNamed(
          context,
          AppRoutes.chatRoom,
          arguments: {
            'chatId': chatId,
            'title': _sellerProfile?['name'] as String? ?? _item.sellerName,
            'isGroup': false,
            'avatarUrl': _sellerProfile?['profileImageUrl'] as String?,
            'participantIds': [currentUser.uid, _item.sellerId],
            'otherUserId': _item.sellerId,
          },
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not send offer: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _item.imageUrls;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Item details'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: const OneCampBackButton(),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppTheme.primaryColor,
            ),
            onPressed: _onSharePressed,
          ),
          if (_isOwner) ...[
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primaryColor,
              ),
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
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isLoading ? null : _confirmDelete,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel with Page Indicator
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  color: Colors.white,
                  child: images.isNotEmpty
                      ? PageView.builder(
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
                              errorBuilder: (_, _, _) => const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (index) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? AppTheme.primaryColor
                                : Colors.white70,
                          ),
                        );
                      }),
                    ),
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _item.isAvailable ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _item.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Text(
                        '\$${_item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Posted Time and Category
                  Row(
                    children: [
                      Text(
                        _timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '•',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          _item.category,
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _item.description.isNotEmpty
                              ? _item.description
                              : 'No description provided.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Seller Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.secondaryColor,
                          backgroundImage:
                              _sellerProfile?['profileImageUrl'] != null
                              ? NetworkImage(_sellerProfile!['profileImageUrl'])
                              : null,
                          child: _sellerProfile?['profileImageUrl'] == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _sellerProfile?['name'] as String? ??
                                    _item.sellerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _sellerProfile?['university'] as String? ??
                                    'Verified Student',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_isOwner)
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _toggleStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _item.isAvailable
                            ? Colors.orange
                            : Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: Icon(
                        _item.isAvailable
                            ? Icons.check_circle_outline
                            : Icons.replay,
                      ),
                      label: Text(
                        _item.isAvailable
                            ? 'Mark as Sold'
                            : 'Mark as Available',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _onMakeOfferPressed,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.local_offer_outlined),
                            label: const Text('Make Offer'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _onContactSellerPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Message Seller'),
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
    );
  }
}
