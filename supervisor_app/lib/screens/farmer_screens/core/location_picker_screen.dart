import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'farmer_settings.dart';
import 'farmer_theme.dart';

// ================================================================
// LOCATION PICKER
// ================================================================
//
// Lets a farmer choose (or simply view) a GPS point on a Google Map.
// Tap anywhere on the map, drag the marker, or use the "my location"
// button to drop the pin, then confirm to return the LatLng to the
// caller (e.g. the tapping record form, which stores it as
// latitude/longitude fields).
// ================================================================

/// Default map center when no location has been picked yet
/// (roughly the rubber-growing wet zone of Sri Lanka).
const LatLng kDefaultFarmLocation = LatLng(6.8211, 80.1200);

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    this.initialLocation,
    this.readOnly = false,
    super.key,
  });

  final LatLng? initialLocation;
  final bool readOnly;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  late LatLng _picked;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _picked = widget.initialLocation ?? kDefaultFarmLocation;
  }

  Future<void> _useCurrentLocation() async {
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;

    setState(() => _locating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage(p, settings.t(
          'Please turn on location services.',
          'කරුණාකර ස්ථාන සේවා සක්‍රිය කරන්න.',
        ));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(p, settings.t(
          'Location permission is required to use this feature.',
          'මෙම විශේෂාංගය භාවිතා කිරීමට ස්ථාන අවසරය අවශ්‍යයි.',
        ));
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final LatLng current = LatLng(position.latitude, position.longitude);

      setState(() => _picked = current);

      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(current, 17));
    } catch (_) {
      _showMessage(p, settings.t(
        'Could not get your current location.',
        'ඔබේ වත්මන් ස්ථානය ලබාගත නොහැක.',
      ));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMessage(FarmerPalette p, String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: p.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        title: Text(
          widget.readOnly
              ? settings.t('Tapping Location', 'ටැපිං ස්ථානය')
              : settings.t('Select Tapping Location', 'ටැපිං ස්ථානය තෝරන්න'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: <Widget>[
          if (!widget.readOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: p.background,
              child: Text(
                settings.t(
                  'Tap on the map, drag the pin, or use your current location to mark where this tapping session took place.',
                  'මෙම ටැපිං සැසිය සිදු වූ ස්ථානය සලකුණු කිරීමට සිතියම මත තට්ටු කරන්න, පින් ඇදගෙන යන්න, හෝ ඔබේ වත්මන් ස්ථානය භාවිතා කරන්න.',
                ),
                style: TextStyle(fontSize: 11.5, height: 1.4, color: p.textSecondary),
              ),
            ),
          Expanded(
            child: Stack(
              children: <Widget>[
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _picked, zoom: 15),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: <Marker>{
                    Marker(
                      markerId: const MarkerId('picked'),
                      position: _picked,
                      draggable: !widget.readOnly,
                      onDragEnd: widget.readOnly
                          ? null
                          : (LatLng position) => setState(() => _picked = position),
                    ),
                  },
                  onTap: widget.readOnly
                      ? null
                      : (LatLng position) => setState(() => _picked = position),
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),

                if (!widget.readOnly)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton(
                      heroTag: 'locate-me',
                      backgroundColor: p.surface,
                      foregroundColor: p.primary,
                      onPressed: _locating ? null : _useCurrentLocation,
                      child: _locating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: p.primary),
                            )
                          : const Icon(Icons.my_location_rounded),
                    ),
                  ),

                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: p.cardShadow,
                    ),
                    child: Text(
                      '${_picked.latitude.toStringAsFixed(6)}, ${_picked.longitude.toStringAsFixed(6)}',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!widget.readOnly)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: FarmerMetrics.buttonHeight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _picked),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.check_circle_outline_rounded),
                      const SizedBox(width: 8),
                      Text(
                        settings.t('Confirm Location', 'ස්ථානය තහවුරු කරන්න'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
