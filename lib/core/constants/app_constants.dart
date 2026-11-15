class AppConstants {
  static const String appName = 'OneCamp';
  static const String appTagline = 'One Campus. One Community.';

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String communitiesCollection = 'communities';
  static const String eventsCollection = 'events';
  static const String chatsCollection = 'chats';
  static const String marketplaceCollection = 'marketplace';
  static const String notificationsCollection = 'notifications';
  static const String campusUpdatesCollection = 'campus_updates';

  // Cloudinary Configuration (Unsigned Upload)
  static const String cloudinaryCloudName = 'o5k43wz7';
  static const String cloudinaryMarketplacePreset = 'onecamp_marketplace_images';
  static const String cloudinaryMarketplaceFolder = 'marketplace';
  static const String cloudinaryUploadUrl = 'https://api.cloudinary.com/v1_1/o5k43wz7/image/upload';

  // Marketplace Constants
  static const String statusAvailable = 'available';
  static const String statusSold = 'sold';

  static const List<String> marketplaceCategories = [
    'All',
    'Textbooks',
    'Electronics',
    'Furniture',
    'Clothing',
    'School Supplies',
    'Other',
  ];

  static const List<String> itemConditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
  ];
}
