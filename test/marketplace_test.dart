import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/features/marketplace/models/marketplace_item.dart';
import 'package:onecamp/features/marketplace/widgets/item_card.dart';

void main() {
  group('Marketplace Model & Utility Tests', () {
    test('generateKeywords correctly normalizes, tokenizes and deduplicates text', () {
      final keywords = MarketplaceItem.generateKeywords(
        'Calculus Textbook!',
        'Used 2nd Edition book in good condition.',
        'Textbooks',
      );

      expect(keywords.contains('calculus'), true);
      expect(keywords.contains('textbook'), true);
      expect(keywords.contains('textbooks'), true);
      expect(keywords.contains('edition'), true);
      expect(keywords.contains('condition'), true);
      // Verify punctuation is removed
      expect(keywords.contains('textbook!'), false);
    });

    test('formatLkrPrice correctly formats numbers with LKR prefix and thousands separators', () {
      expect(ItemCard.formatLkrPrice(0), 'Free');
      expect(ItemCard.formatLkrPrice(-5), 'Free');
      expect(ItemCard.formatLkrPrice(500), 'Rs. 500');
      expect(ItemCard.formatLkrPrice(1500), 'Rs. 1,500');
      expect(ItemCard.formatLkrPrice(125000.50), 'Rs. 125,000.50');
      expect(ItemCard.formatLkrPrice(1000000), 'Rs. 1,000,000');
    });

    test('MarketplaceItem serialization and copyWith', () {
      const item = MarketplaceItem(
        id: 'item_123',
        title: 'Laptop Stand',
        description: 'Aluminum portable stand',
        price: 3500.0,
        category: 'Electronics',
        condition: 'Like New',
        imageUrls: ['https://cloudinary.com/sample.jpg'],
        sellerId: 'user_456',
        sellerName: 'John Doe',
        sellerEmail: 'john@campus.edu',
        searchKeywords: ['laptop', 'stand', 'electronics'],
      );

      expect(item.isAvailable, true);
      expect(item.isSold, false);

      final updated = item.copyWith(status: 'sold');
      expect(updated.isSold, true);
      expect(updated.isAvailable, false);
      expect(updated.price, 3500.0);
    });
  });
}
