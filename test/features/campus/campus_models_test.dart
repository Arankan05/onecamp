import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/features/campus/models/campus_update_model.dart';

void main() {
  group('CampusUpdateModel Tests', () {
    test('Serializes and deserializes campus update fields properly', () {
      final now = DateTime(2026, 11, 15, 9, 0);
      final update = CampusUpdateModel(
        id: 'upd_456',
        title: 'Library Extended Hours',
        body: 'The central library will remain open 24/7 during finals week.',
        category: 'Academic',
        authorId: 'usr_staff_1',
        authorName: 'Library Staff',
        imageUrl: null,
        isUrgent: true,
        createdAt: now,
      );

      final map = update.toMap();

      expect(map['title'], equals('Library Extended Hours'));
      expect(map['category'], equals('Academic'));
      expect(map['authorId'], equals('usr_staff_1'));
      expect(map['isUrgent'], isTrue);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isNull);

      final restored = CampusUpdateModel.fromMap('upd_456', map);

      expect(restored.id, equals('upd_456'));
      expect(restored.title, equals('Library Extended Hours'));
      expect(restored.authorId, equals('usr_staff_1'));
      expect(restored.isUrgent, isTrue);
      expect(restored.category, equals('Academic'));
    });

    test('Defaults isUrgent to false when unspecified', () {
      final minimalMap = <String, dynamic>{
        'title': 'General Notice',
        'body': 'Water supply maintenance notice.',
        'authorId': 'usr_admin',
        'createdAt': Timestamp.now(),
      };

      final update = CampusUpdateModel.fromMap('upd_min', minimalMap);

      expect(update.id, equals('upd_min'));
      expect(update.isUrgent, isFalse);
      expect(update.category, equals('General'));
    });
  });
}

