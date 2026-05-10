import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/app_theme.dart';
import '../models/farm.dart';
import '../widgets/hotspot_indicator.dart';
import 'verify_screen.dart';

class MapScreen extends StatefulWidget {
  final Farm farm;
  final int stopNumber;

  const MapScreen({
    super.key,
    required this.farm,
    required this.stopNumber,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;

  static const LatLng _supervisorLocation = LatLng(6.8211, 80.1200);

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('supervisor'),
          position: _supervisorLocation,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        Marker(
          markerId: MarkerId(widget.farm.farmId),
          position: LatLng(widget.farm.lat, widget.farm.lng),
          infoWindow: InfoWindow(
            title: widget.farm.farmerName,
            snippet: 'VFA: ${widget.farm.vfaResult.toStringAsFixed(2)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      };

  Set<Polyline> get _polylines => {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            _supervisorLocation,
            LatLng(widget.farm.lat, widget.farm.lng),
          ],
          color: AppTheme.primary,
          width: 4,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
        ),
      };

  double get _distanceKm {
    final latDiff = (widget.farm.lat - _supervisorLocation.latitude).abs();
    final lngDiff = (widget.farm.lng - _supervisorLocation.longitude).abs();
    return ((latDiff + lngDiff) * 111).roundToDouble();
  }

  int get _etaMinutes => (_distanceKm * 2.5).round();

  @override
  Widget build(BuildContext context) {
    final riskColor = AppTheme.riskColor(widget.farm.riskLevel);
    final riskLabel = AppTheme.riskLabel(widget.farm.riskLevel);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'LatexGuard',
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: const [
          HotspotIndicator(),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // ── Farm Info Card ────────────────────────────────
          Container(
            color: AppTheme.surface,
            child: Column(
              children: [
                Container(height: 4, color: riskColor),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: riskColor.withOpacity(0.12),
                              border: Border.all(
                                color: riskColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.stopNumber}',
                                style: GoogleFonts.jetBrainsMono(
                                  color: riskColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.farm.farmerName,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Farm ID: ${widget.farm.farmId}',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: riskColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: riskColor),
                                ),
                                child: Text(
                                  riskLabel,
                                  style: GoogleFonts.jetBrainsMono(
                                    color: riskColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'VFA: ${widget.farm.vfaResult.toStringAsFixed(2)}',
                                style: GoogleFonts.jetBrainsMono(
                                  color: riskColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppTheme.divider),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoPill(
                              icon: Icons.straighten,
                              label: 'Distance',
                              value: '${_distanceKm.toStringAsFixed(1)} km',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoPill(
                              icon: Icons.access_time,
                              label: 'ETA',
                              value: '$_etaMinutes min',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoPill(
                              icon: Icons.grade,
                              label: 'Grade',
                              value: widget.farm.grade,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.divider),

          // ── Google Map ────────────────────────────────────
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  (_supervisorLocation.latitude + widget.farm.lat) / 2,
                  (_supervisorLocation.longitude + widget.farm.lng) / 2,
                ),
                zoom: 13,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),

          // ── Bottom Button ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.divider),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Collect highest VFA risk farm first',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VerifyScreen(
                            farm: widget.farm,
                            stopNumber: widget.stopNumber,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      'Arrived — Verify Collection',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}