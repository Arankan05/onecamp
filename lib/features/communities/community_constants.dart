class CommunityConstants {
  // Sub-collection names inside communities/{communityId}
  static const String membersCollection = 'members';
  static const String postsCollection = 'posts';
  static const String announcementsCollection = 'announcements';

  // Member roles
  static const String roleCreator = 'creator';
  static const String roleMember = 'member';

  // Community categories
  static const List<String> categories = [
    'Academic',
    'Faculty',
    'Degree',
    'Interest',
    'Sports',
    'Other',
  ];
}
