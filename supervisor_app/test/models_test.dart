import 'package:flutter_test/flutter_test.dart';

import 'package:supervisor_app/core/app_theme.dart';
import 'package:supervisor_app/models/collection_stop.dart';
import 'package:supervisor_app/models/farm.dart';
import 'package:supervisor_app/models/farmer_tapping_snapshot.dart';
import 'package:supervisor_app/models/tapping_detail.dart';
import 'package:supervisor_app/models/user_profile.dart';

/// Stands in for a Firestore GeoPoint, which exposes latitude/longitude.
class _FakeGeoPoint {
  final double latitude;
  final double longitude;
  const _FakeGeoPoint(this.latitude, this.longitude);
}

/// Stands in for a Firestore Timestamp, which exposes toDate().
class _Ts {
  final DateTime _d;
  const _Ts(this._d);
  DateTime toDate() => _d;
}

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

  group('TappingDetail location', () {
    test('is absent — not zero — when the farmer app has not written it', () {
      // Critical: defaulting to (0, 0) would place the farm in the Atlantic
      // and corrupt route distances.
      final t = TappingDetail.fromMap('doc6', {});

      expect(t.lat, isNull);
      expect(t.lng, isNull);
      expect(t.hasLocation, isFalse);
    });

    test('reads the latitude/longitude names the farmer app writes', () {
      final t = TappingDetail.fromMap('doc7a', {
        'latitude': 6.8211,
        'longitude': 80.1367,
      });

      expect(t.hasLocation, isTrue);
      expect(t.lat, 6.8211);
      expect(t.lng, 80.1367);
    });

    test('reads top-level lat/lng numbers', () {
      final t = TappingDetail.fromMap('doc7', {'lat': 6.8211, 'lng': 80.1367});

      expect(t.hasLocation, isTrue);
      expect(t.lat, 6.8211);
      expect(t.lng, 80.1367);
    });

    test('reads integer coordinates', () {
      final t = TappingDetail.fromMap('doc8', {'lat': 7, 'lng': 80});
      expect(t.lat, 7.0);
      expect(t.lng, 80.0);
    });

    test('falls back to a GeoPoint under `location`', () {
      final t = TappingDetail.fromMap('doc9', {
        'location': const _FakeGeoPoint(6.9, 79.9),
      });

      expect(t.hasLocation, isTrue);
      expect(t.lat, 6.9);
      expect(t.lng, 79.9);
    });

    test('copyWith preserves coordinates', () {
      final t = TappingDetail.fromMap('doc10', {'lat': 6.5, 'lng': 80.5})
          .copyWith(farmerName: 'Sunil');

      expect(t.lat, 6.5);
      expect(t.hasLocation, isTrue);
    });
  });

  group('Farm.hasLocation', () {
    test('honours an explicit has_location flag', () {
      final f = Farm.fromMap({'lat': 0.0, 'lng': 0.0, 'has_location': false});
      expect(f.hasLocation, isFalse);
    });

    test('infers true from non-zero coordinates on older documents', () {
      final f = Farm.fromMap({'lat': 6.82, 'lng': 80.13});
      expect(f.hasLocation, isTrue);
    });

    test('infers false from zeroed coordinates on older documents', () {
      final f = Farm.fromMap({'lat': 0, 'lng': 0});
      expect(f.hasLocation, isFalse);
    });
  });

  group('Farmer id from users', () {
    test('reads the backend farmer id off a farmer document', () {
      final p = UserProfile.fromMap('uid1', {
        'name': 'Sunil',
        'role': 'farmer',
        'district': 'Galle',
        'experience': '3-5 years',
        kFarmerIdField: 'F001',
      });

      expect(p.isFarmer, isTrue);
      expect(p.farmerId, 'F001');
      expect(p.district, 'Galle');
      expect(p.experience, '3-5 years');
    });

    test('farmerId is empty when the field is absent', () {
      final p = UserProfile.fromMap('uid2', {'role': 'farmer'});
      expect(p.farmerId, isEmpty);
    });

    test('trims stray whitespace around the id', () {
      final p = UserProfile.fromMap('uid3', {kFarmerIdField: '  F007 '});
      expect(p.farmerId, 'F007');
    });

    test('coerces a non-string id', () {
      // Guards against the field being saved as a number in Firestore.
      final p = UserProfile.fromMap('uid4', {kFarmerIdField: 7});
      expect(p.farmerId, '7');
    });
  });

  group('FarmerTappingSnapshot', () {
    FarmerTappingSnapshot make({
      String farmerId = 'F001',
      String district = 'Galle',
      String experience = '3-5 years',
      TappingDetail? tapping,
    }) =>
        FarmerTappingSnapshot(
          farmerId: farmerId,
          userId: 'uid1',
          farmerName: 'Sunil',
          district: district,
          experience: experience,
          tapping: tapping,
        );

    test('flags a farmer with no tapping record', () {
      final s = make();
      expect(s.hasTapping, isFalse);
      expect(s.missingFields, contains('tapping record'));
    });

    test('flags blank profile fields the model would score as zero', () {
      final s = make(district: '', experience: '   ');
      expect(s.missingFields, containsAll(['district', 'experience']));
    });

    test('is complete when everything is present', () {
      final s = make(tapping: TappingDetail.fromMap('t1', {}));
      expect(s.hasFarmerId, isTrue);
      expect(s.missingFields, isEmpty);
    });
  });

  group('hours_since_tapping', () {
    test('combines the date day with the startTime clock', () {
      final t = TappingDetail.fromMap('t1', {
        'date': _Ts(DateTime(2026, 8, 20)),
        'startTime': '06:30',
      });

      expect(t.tappingStart, DateTime(2026, 8, 20, 6, 30));
      final hours = t.hoursSinceTapping(DateTime(2026, 8, 20, 12, 30));
      expect(hours, 6.0);
    });

    test('falls back to createdAt when startTime is unusable', () {
      final created = DateTime(2026, 8, 20, 5);
      final t = TappingDetail.fromMap('t2', {
        'date': _Ts(DateTime(2026, 8, 20)),
        'startTime': 'not-a-time',
        'createdAt': _Ts(created),
      });

      expect(t.tappingStart, created);
    });

    test('rejects an out-of-range clock rather than building a bad date', () {
      final created = DateTime(2026, 8, 20, 5);
      final t = TappingDetail.fromMap('t3', {
        'date': _Ts(DateTime(2026, 8, 20)),
        'startTime': '99:99',
        'createdAt': _Ts(created),
      });

      expect(t.tappingStart, created);
    });

    test('is null with no usable timestamp, so 0 is never guessed', () {
      final t = TappingDetail.fromMap('t4', {});
      expect(t.tappingStart, isNull);
      expect(t.hoursSinceTapping(DateTime(2026, 8, 20)), isNull);
    });

    test('reports fractional hours', () {
      final t = TappingDetail.fromMap('t5', {
        'date': _Ts(DateTime(2026, 8, 20)),
        'startTime': '06:00',
      });
      expect(t.hoursSinceTapping(DateTime(2026, 8, 20, 7, 30)), 1.5);
    });
  });

  group('CollectionStop', () {
    Map<String, dynamic> backendStop({double score = 50}) => {
          'order': 1,
          'farmer_id': 'F001',
          'latitude': 6.5769,
          'longitude': 79.9959,
          'spoilage_risk_score': score,
        };

    test('parses a backend stop and takes the resolved farmer name', () {
      final s = CollectionStop.fromBackend(backendStop(score: 66.5),
          farmerName: 'Sunil');

      expect(s.order, 1);
      expect(s.farmerId, 'F001');
      expect(s.farmerName, 'Sunil');
      expect(s.spoilageScore, 66.5);
    });

    test('falls back to the farmer id when no name is known', () {
      final s = CollectionStop.fromBackend(backendStop());
      expect(s.farmerName, 'F001');
    });

    test('has no VFA until a sensor reports — never a fabricated 0', () {
      // A defaulted 0.0 would read as pristine latex, which is worse than
      // showing nothing at all.
      final s = CollectionStop.fromBackend(backendStop());

      expect(s.vfaResult, isNull);
      expect(s.grade, isNull);
      expect(s.hasSensorReading, isFalse);
    });

    test('carries VFA and spoilage as separate figures', () {
      final s = CollectionStop.fromBackend(backendStop(score: 96.6))
          .copyWith(vfaResult: 0.92, grade: 'C');

      expect(s.hasSensorReading, isTrue);
      expect(s.vfaResult, 0.92);
      // The 0-100 spoilage prediction must survive alongside the 0-1 reading.
      expect(s.spoilageScore, 96.6);
    });

    test('derives risk bands from the spoilage score', () {
      expect(CollectionStop.fromBackend(backendStop(score: 80)).riskLevel,
          'high');
      expect(CollectionStop.fromBackend(backendStop(score: 50)).riskLevel,
          'medium');
      expect(CollectionStop.fromBackend(backendStop(score: 20)).riskLevel,
          'safe');
    });

    test('band boundaries are exclusive, matching the map colours', () {
      expect(CollectionStop.fromBackend(backendStop(score: 60)).riskLevel,
          'medium');
      expect(CollectionStop.fromBackend(backendStop(score: 40)).riskLevel,
          'safe');
    });

    test('copyWith leaves untouched fields alone', () {
      final s = CollectionStop.fromBackend(backendStop(score: 33),
              farmerName: 'Kamal')
          .copyWith(vfaResult: 0.4);

      expect(s.farmerName, 'Kamal');
      expect(s.spoilageScore, 33);
      expect(s.latitude, 6.5769);
    });
  });

  group('Risk presentation', () {
    test('pending never reads as safe', () {
      // A farm with no sensor reading must not be shown in reassuring green.
      expect(AppTheme.riskColor('pending'), AppTheme.riskPending);
      expect(AppTheme.riskColor('pending'), isNot(AppTheme.riskSafe));
      expect(AppTheme.riskLabel('pending'), 'AWAITING READING');
    });

    test('unrecognised levels fall back to pending, not safe', () {
      expect(AppTheme.riskColor('wat'), AppTheme.riskPending);
      expect(AppTheme.riskLabel('wat'), 'AWAITING READING');
    });

    test('known levels keep their existing meaning', () {
      expect(AppTheme.riskColor('high'), AppTheme.riskHigh);
      expect(AppTheme.riskColor('medium'), AppTheme.riskMedium);
      expect(AppTheme.riskColor('safe'), AppTheme.riskSafe);
      expect(AppTheme.riskLabel('safe'), 'SAFE');
    });
  });
}
