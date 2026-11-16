import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/features/communities/models/community.dart';
import 'package:onecamp/features/communities/models/community_post.dart';

void main() {
  group('Community', () {
    test('toMap and fromMap keep the same data', () {
      final original = Community(
        id: 'abc',
        name: 'Photography Club',
        description: 'For people who love photos',
        category: 'Interest',
        createdBy: 'user1',
        createdAt: DateTime(2026, 11, 15),
      );

      final copy = Community.fromMap('abc', original.toMap());

      expect(copy.id, 'abc');
      expect(copy.name, 'Photography Club');
      expect(copy.category, 'Interest');
      expect(copy.createdBy, 'user1');
      expect(copy.createdAt, DateTime(2026, 11, 15));
    });

    test('fromMap uses safe defaults when fields are missing', () {
      final community = Community.fromMap('x', {});

      expect(community.name, '');
      expect(community.category, 'Other');
      expect(community.createdBy, '');
    });

    test('toMap uses the field name createdBy required by the rules', () {
      final community = Community(
        id: 'a',
        name: 'Test',
        description: 'Test description',
        category: 'Other',
        createdBy: 'user1',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(community.toMap()['createdBy'], 'user1');
      expect(community.toMap()['createdAt'], isA<Timestamp>());
    });
  });

  group('CommunityPost', () {
    test('toMap uses the field name authorId required by the rules', () {
      final post = CommunityPost(
        id: '',
        authorId: 'user1',
        text: 'Hello',
        createdAt: DateTime(2026, 1, 1),
      );

      expect(post.toMap()['authorId'], 'user1');
      expect(post.toMap()['text'], 'Hello');
    });
  });
}