// Supervisor Route Screen
// -----------------------------------------------------------------------------
// Calls the backend POST /plan-collection, then draws the collection route on a
// map: depot -> farmers (in DQN order) -> depot, with numbered markers coloured
// by spoilage score.
//
// Packages (add to pubspec.yaml):
//   http: ^1.2.0
//   flutter_map: ^7.0.0
//   latlong2: ^0.9.1
//
// Targets flutter_map v7. If you are on v5/older:
//   - MapOptions(initialCenter:)  ->  center:
//   - MapOptions(initialZoom:)    ->  zoom:
//   - Marker(child:)              ->  Marker(builder: (ctx) => ...)
//
// IMPORTANT (Android): the hotspot uses http (not https). Android 9+ blocks
// cleartext by default, so the request will silently fail unless you add
//   android:usesCleartextTraffic="true"
// to <application> in android/app/src/main/AndroidManifest.xml.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/collection_stop.dart';
import '../models/user_profile.dart' show kFarmerIdField;
import '../services/firestore_service.dart';
import 'verify_screen.dart';

// Backend address.
//
// 'localhost' is correct when the app and the backend run on the same machine
// (Chrome via `flutter run -d chrome`), and it does not break when the laptop's
// IP changes on reconnect.
//
// For a physical phone on the shared hotspot, replace this with the laptop's
// current LAN IP from `ipconfig` (Windows) or `ifconfig`/`ip addr` — the phone
// cannot reach 'localhost', which on the phone means the phone itself.
const String kBackendBaseUrl = 'http://localhost:5000';

// Set true to send the synthetic 12-farmer sample instead of Firestore data,
// which is useful for checking the map renders without touching the database.
const bool kUseDemoData = false;

// The DQN was trained on a fixed roster of 12 farmers (backend/farmers.json).
// plan_route() looks up every one of those ids in the request, so a payload
// missing any of them makes the backend raise KeyError and return HTTP 500.
const int kExpectedFarmerCount = 12;

// Farmer ids come from the `users` collection (role: farmer), read from the
// field named by kFarmerIdField in models/user_profile.dart.

class SupervisorRouteScreen extends StatefulWidget {
  /// Firestore user ids the supervisor picked on the dashboard. Null means
  /// "route every farmer that can be routed", which is what the dashboard's
  /// standalone "Collection Route" tile does.
  final Set<String>? selectedUserIds;

  const SupervisorRouteScreen({super.key, this.selectedUserIds});

  @override
  State<SupervisorRouteScreen> createState() => _SupervisorRouteScreenState();
}

class _SupervisorRouteScreenState extends State<SupervisorRouteScreen> {
  bool _loading = false;
  String? _error;
  String? _warning;
  LatLng? _depot;
  List<CollectionStop> _stops = [];

  /// Farmer ids already collected — greyed out and skipped as "next stop".
  /// Seeded from today's `collections` so progress survives a restart.
  Set<String> _completed = {};

  /// Farmer id -> display name, so stops show people rather than "F007".
  Map<String, String> _names = {};

  @override
  void initState() {
    super.initState();
    _loadCompleted();
  }

  Future<void> _loadCompleted() async {
    try {
      final done = await _firestore.getFarmIdsCollectedToday();
      if (mounted) setState(() => _completed = done);
    } catch (_) {
      // Non-fatal: worst case a finished stop looks pending.
    }
  }

  /// First stop of the planned order that has not been collected yet.
  CollectionStop? get _nextStop {
    for (final s in _stops) {
      if (!_completed.contains(s.farmerId)) return s;
    }
    return null;
  }

  final FirestoreService _firestore = FirestoreService();

  // ---------------------------------------------------------------------------
  // Request body, built from each farmer's most recent `tapping_details`
  // document. The JSON keys below are what backend/app.py reads — do not
  // rename them.
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _buildFarmersPayload() async {
    if (kUseDemoData) return _buildDemoFarmersPayload();

    final snapshots = await _firestore.getLatestTappingPerFarmer();
    if (snapshots.isEmpty) {
      throw Exception(
        'No users with role "farmer" were found, so there is nothing to plan.',
      );
    }

    // Remember names so stops read as people, not "F007".
    _names = {
      for (final s in snapshots)
        if (s.hasFarmerId) s.farmerId: s.farmerName,
    };

    final now = DateTime.now();
    final payload = <Map<String, dynamic>>[];
    final notEnrolled = <String>[];
    final incomplete = <String>[];
    final missingTime = <String>[];

    final selection = widget.selectedUserIds;
    final notSelected = <String>[];
    final noCoordinates = <String>[];

    for (final s in snapshots) {
      // When the supervisor picked farmers on the dashboard, route only those.
      if (selection != null && !selection.contains(s.userId)) {
        notSelected.add(s.farmerName);
        continue;
      }

      // A farmer needs either a slot in farmers.json or their own coordinates.
      // With neither, the backend cannot place them on the map.
      final tapping = s.tapping;
      final hasCoords = tapping?.hasLocation ?? false;
      if (!s.hasFarmerId && !hasCoords) {
        notEnrolled.add(s.farmerName);
        continue;
      }
      if (!hasCoords && !s.hasFarmerId) noCoordinates.add(s.farmerName);

      final hours = tapping?.hoursSinceTapping(now);
      final id = s.hasFarmerId ? s.farmerId : s.userId;
      if (tapping != null && hours == null) missingTime.add(id);
      if (s.missingFields.isNotEmpty) {
        incomplete.add('$id: ${s.missingFields.join(", ")}');
      }
      _names[id] = s.farmerName;

      payload.add({
        'farmer_id': id,
        'hours_since_tapping': hours ?? 0.0,
        'weatherCondition': tapping?.weatherCondition ?? '',
        'district': s.district,
        'experience': s.experience,
        'treeCondition': tapping?.treeCondition ?? '',
        // Routing inputs, not model features. Sent when the farmer app has
        // recorded them; the backend falls back to farmers.json otherwise.
        if (hasCoords) 'latitude': tapping!.lat,
        if (hasCoords) 'longitude': tapping!.lng,
      });
    }

    if (payload.isEmpty) {
      throw Exception(
        'No farmers could be routed. Select at least one farmer who has '
        'either a $kFarmerIdField or recorded coordinates.',
      );
    }

    // Two farmers on the same slot would silently collapse into one stop.
    final duplicates = <String>{};
    final seen = <String>{};
    for (final p in payload) {
      if (!seen.add(p['farmer_id'] as String)) {
        duplicates.add(p['farmer_id'] as String);
      }
    }
    if (duplicates.isNotEmpty) {
      throw Exception(
        'More than one farmer shares the same $kFarmerIdField: '
        '${(duplicates.toList()..sort()).join(", ")}.\n\n'
        'Each id must belong to exactly one farmer, otherwise a farm is '
        'silently dropped from the route.',
      );
    }

    if (payload.length > kExpectedFarmerCount) {
      throw Exception(
        'The route model can plan at most $kExpectedFarmerCount stops at once, '
        'but ${payload.length} farmers were selected. Deselect '
        '${payload.length - kExpectedFarmerCount} of them.',
      );
    }

    // Surface quietly-degrading data rather than letting the model score it.
    final warnings = <String>[
      if (notEnrolled.isNotEmpty)
        'Skipped (no $kFarmerIdField and no coordinates): '
            '${notEnrolled.join(", ")}',
      if (notSelected.isNotEmpty && notSelected.length <= 5)
        'Not selected: ${notSelected.join(", ")}',
      if (missingTime.isNotEmpty)
        'No usable tapping time for: ${missingTime.join(", ")} (sent as 0 h)',
      if (incomplete.isNotEmpty)
        'Incomplete data — ${incomplete.join("; ")}',
    ];
    if (warnings.isNotEmpty && mounted) {
      setState(() => _warning = warnings.join('\n'));
    }

    return payload;
  }

  /// Synthetic sample used only when [kUseDemoData] is true.
  List<Map<String, dynamic>> _buildDemoFarmersPayload() {
    const weathers = ['Sunny', 'Cloudy', 'Rainy', 'Stormy'];
    const exps = ['1 - 3 years', '3 - 5 years', '5 - 10 years', 'More than 10 years'];
    return List.generate(kExpectedFarmerCount, (i) {
      final id = 'F${(i + 1).toString().padLeft(3, '0')}';
      return {
        'farmer_id': id,
        'hours_since_tapping': (2 + i % 8).toDouble(),
        'weatherCondition': weathers[i % weathers.length],
        'district': 'Galle',
        'experience': exps[i % exps.length],
        'treeCondition': i.isEven ? 'Healthy' : 'Stressed',
      };
    });
  }

  Future<void> _planCollection() async {
    setState(() {
      _loading = true;
      _error = null;
      _warning = null;
    });
    try {
      final farmers = await _buildFarmersPayload();

      final res = await http
          .post(
            Uri.parse('$kBackendBaseUrl/plan-collection'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'farmers': farmers}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('Backend returned ${res.statusCode}: ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final depot = data['depot'] as Map<String, dynamic>;
      final stops = (data['stops'] as List)
          .map((s) => CollectionStop.fromBackend(
                s as Map<String, dynamic>,
                farmerName: _names[s['farmer_id']] ?? '',
              ))
          .toList();

      setState(() {
        _depot = LatLng(
          (depot['latitude'] as num).toDouble(),
          (depot['longitude'] as num).toDouble(),
        );
        _stops = stops;
      });
    } catch (e) {
      setState(() => _error = 'Could not plan collection.\n$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _scoreColour(double score) {
    if (score > 60) return Colors.red;
    if (score > 40) return Colors.orange;
    return Colors.green;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    if (_depot != null) {
      markers.add(Marker(
        point: _depot!,
        width: 40,
        height: 40,
        child: const Icon(Icons.home, color: Colors.blue, size: 34),
      ));
    }

    for (final s in _stops) {
      markers.add(Marker(
        point: LatLng(s.latitude, s.longitude),
        width: 34,
        height: 34,
        child: Container(
          decoration: BoxDecoration(
            color: _scoreColour(s.spoilageScore),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '${s.order}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  List<LatLng> _routeLine() {
    final pts = <LatLng>[];
    if (_depot != null) pts.add(_depot!);
    pts.addAll(_stops.map((s) => LatLng(s.latitude, s.longitude)));
    if (_depot != null) pts.add(_depot!); // return to depot
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    final centre = _depot ?? const LatLng(6.7, 80.2); // Sri Lanka rubber belt
    return Scaffold(
      appBar: AppBar(title: const Text('Collection Route')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _planCollection,
                icon: const Icon(Icons.route),
                label: Text(_loading ? 'Planning...' : 'Plan Collection'),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_warning != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _warning!,
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centre,
                initialZoom: 9,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.lalan.rubberquality',
                ),
                if (_stops.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routeLine(),
                        strokeWidth: 3,
                        color: Colors.indigo,
                      ),
                    ],
                  ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),
          if (_stops.isNotEmpty)
            SizedBox(
              height: 170,
              child: ListView.builder(
                itemCount: _stops.length,
                itemBuilder: (ctx, i) => _buildStopTile(_stops[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStopTile(CollectionStop s) {
    final done = _completed.contains(s.farmerId);
    final isNext = !done && identical(s, _nextStop);

    return ListTile(
      dense: true,
      onTap: done ? null : () => _openArrivalSheet(s),
      tileColor: isNext ? Colors.green.withValues(alpha: 0.08) : null,
      leading: CircleAvatar(
        backgroundColor:
            done ? Colors.grey : _scoreColour(s.spoilageScore),
        child: done
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : Text('${s.order}',
                style: const TextStyle(color: Colors.white)),
      ),
      title: Text(
        s.farmerName,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
          color: done ? Colors.grey : null,
          fontWeight: isNext ? FontWeight.w700 : null,
        ),
      ),
      subtitle: Text(
        done
            ? '${s.farmerId} — collected'
            : isNext
                ? '${s.farmerId} — next stop'
                : s.farmerId,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Text(
        'risk ${s.spoilageScore.toStringAsFixed(0)}',
        style: TextStyle(color: done ? Colors.grey : null),
      ),
    );
  }

  /// Arrival sheet: confirm the stop, then hand off to verification.
  void _openArrivalSheet(CollectionStop s) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stop ${s.order} — ${s.farmerName}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(s.farmerId,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 18, color: _scoreColour(s.spoilageScore)),
                const SizedBox(width: 8),
                Text(
                  'Predicted spoilage risk '
                  '${s.spoilageScore.toStringAsFixed(0)}/100',
                  style: TextStyle(color: _scoreColour(s.spoilageScore)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Says plainly that no chemical reading exists yet, rather than
            // implying the predicted score is a measurement.
            Row(
              children: [
                const Icon(Icons.sensors, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.hasSensorReading
                        ? 'Sensor VFA ${s.vfaResult!.toStringAsFixed(2)}'
                        : 'Awaiting IoT sensor reading at the farm',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _verifyStop(s);
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Arrived — Verify Collection'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyStop(CollectionStop s) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyScreen(farm: s, stopNumber: s.order),
      ),
    );
    // VerifyScreen writes to `collections` (or the offline queue), so re-read
    // rather than assuming the collection succeeded.
    await _loadCompleted();
  }
}
