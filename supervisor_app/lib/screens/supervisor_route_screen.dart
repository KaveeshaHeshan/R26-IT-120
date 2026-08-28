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

import '../models/user_profile.dart' show kFarmerIdField;
import '../services/firestore_service.dart';

// Change this to your laptop's IP on the shared hotspot (e.g. 192.168.43.101).
// Find it with `ipconfig` (Windows) or `ifconfig`/`ip addr` (Mac/Linux).
const String kBackendBaseUrl = 'http://192.168.x.x:5000';

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
  const SupervisorRouteScreen({super.key});

  @override
  State<SupervisorRouteScreen> createState() => _SupervisorRouteScreenState();
}

class _SupervisorRouteScreenState extends State<SupervisorRouteScreen> {
  bool _loading = false;
  String? _error;
  String? _warning;
  LatLng? _depot;
  List<_Stop> _stops = [];

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

    final now = DateTime.now();
    final payload = <Map<String, dynamic>>[];
    final withoutId = <String>[];
    final incomplete = <String>[];
    final missingTime = <String>[];

    for (final s in snapshots) {
      if (!s.hasFarmerId) {
        withoutId.add('${s.farmerName} (${s.userId})');
        continue;
      }

      final tapping = s.tapping;
      final hours = tapping?.hoursSinceTapping(now);
      if (tapping != null && hours == null) missingTime.add(s.farmerId);
      if (s.missingFields.isNotEmpty) {
        incomplete.add('${s.farmerId}: ${s.missingFields.join(", ")}');
      }

      payload.add({
        'farmer_id': s.farmerId,
        'hours_since_tapping': hours ?? 0.0,
        'weatherCondition': tapping?.weatherCondition ?? '',
        'district': s.district,
        'experience': s.experience,
        'treeCondition': tapping?.treeCondition ?? '',
      });
    }

    if (withoutId.isNotEmpty) {
      throw Exception(
        'These farmers have no "$kFarmerIdField" on their users document:\n'
        '${withoutId.join("\n")}\n\n'
        'Add the field in Firestore, or change kFarmerIdField in '
        'models/user_profile.dart if it is stored under another name.',
      );
    }

    if (payload.length != kExpectedFarmerCount) {
      throw Exception(
        'The route model expects all $kExpectedFarmerCount farmers from '
        'backend/farmers.json, but only ${payload.length} could be built. '
        'The backend would fail with a KeyError on the missing ids.',
      );
    }

    // Surface quietly-degrading data rather than letting the model score it.
    final warnings = <String>[
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
          .map((s) => _Stop.fromJson(s as Map<String, dynamic>))
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
            color: _scoreColour(s.score),
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
              height: 150,
              child: ListView.builder(
                itemCount: _stops.length,
                itemBuilder: (ctx, i) {
                  final s = _stops[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: _scoreColour(s.score),
                      child: Text('${s.order}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(s.farmerId),
                    trailing: Text('score ${s.score.toStringAsFixed(0)}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Stop {
  final int order;
  final String farmerId;
  final double latitude;
  final double longitude;
  final double score;

  _Stop({
    required this.order,
    required this.farmerId,
    required this.latitude,
    required this.longitude,
    required this.score,
  });

  factory _Stop.fromJson(Map<String, dynamic> j) => _Stop(
        order: j['order'] as int,
        farmerId: j['farmer_id'] as String,
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        score: (j['spoilage_risk_score'] as num).toDouble(),
      );
}
