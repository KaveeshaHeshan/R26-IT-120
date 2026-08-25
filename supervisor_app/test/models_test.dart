import 'package:flutter_test/flutter_test.dart';

import 'package:supervisor_app/models/tapping_detail.dart';
import 'package:supervisor_app/models/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('parses a supervisor record', () {
      final p = UserProfile.fromMap('uid1', {
        'name': 'Nimal Perera',
        'email': 'nimal@example.com',
        'phone': '0771234567',
        'nic': '991234567V',
        'role': 'supervisor',
        'employeeId': 'EMP-01',
      });

      expect(p.isSupervisor, isTrue);
      expect(p.initial, 'N');
      expect(p.employeeId, 'EMP-01');
    });

    test('falls back safely on an empty document', () {
      final p = UserProfile.fromMap('uid2', {});

      expect(p.name, 'Unknown');
      expect(p.isSupervisor, isFalse);
      expect(p.initial, 'U'); // from the "Unknown" fallback
    });

    test('initial does not crash on a whitespace-only name', () {
      final p = UserProfile.fromMap('uid3', {'name': '   '});
      expect(p.initial, '?');
    });
  });

  group('TappingDetail', () {
    test('parses a full record', () {
      final t = TappingDetail.fromMap('doc1', {
        'userId': 'farmer1',
        'startTime': '19:23',
        'endTime': '20:23',
        'durationMinutes': 60,
        'latexVolumeL': 0.5,
        'treesCount': 1,
        'treeCondition': 'Healthy',
        'weatherCondition': 'Sunny',
        'notes': 'test note',
      }, farmerName: 'Sunil');

      expect(t.farmerName, 'Sunil');
      expect(t.durationMinutes, 60);
      expect(t.latexVolumeL, 0.5);
      expect(t.litresPerTree, 0.5);
    });

    test('coerces ints written where a double is expected', () {
      // Firestore returns a plain int when a whole number is stored,
      // so latexVolumeL must survive arriving as `2` rather than `2.0`.
      final t = TappingDetail.fromMap('doc2', {'latexVolumeL': 2});
      expect(t.latexVolumeL, 2.0);
    });

    test('litresPerTree is null when tree count is zero', () {
      final t = TappingDetail.fromMap('doc3', {
        'latexVolumeL': 5.0,
        'treesCount': 0,
      });
      expect(t.litresPerTree, isNull);
    });

    test('falls back safely on an empty document', () {
      final t = TappingDetail.fromMap('doc4', {});

      expect(t.latexVolumeL, 0.0);
      expect(t.treesCount, 0);
      expect(t.startTime, '--:--');
      expect(t.treeCondition, 'Unknown');
      expect(t.date, isNull);
    });

    test('copyWith replaces only the farmer name', () {
      final t = TappingDetail.fromMap('doc5', {'latexVolumeL': 1.5})
          .copyWith(farmerName: 'Kamal');

      expect(t.farmerName, 'Kamal');
      expect(t.latexVolumeL, 1.5);
    });
  });
}
