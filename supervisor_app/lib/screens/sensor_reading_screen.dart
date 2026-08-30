import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../models/collection_stop.dart';
import '../models/sensor_reading.dart';
import '../services/sensor_service.dart';

/// Live sensor readings for the farm the supervisor is standing at.
///
/// Readings carry no farm identity (`farmer_id` is not populated), so the
/// supervisor capturing a reading here is what links it to this stop. Pops
/// with the captured [SensorReading], or null if they skip.
class SensorReadingScreen extends StatefulWidget {
  final CollectionStop stop;

  const SensorReadingScreen({super.key, required this.stop});

  @override
  State<SensorReadingScreen> createState() => _SensorReadingScreenState();
}

class _SensorReadingScreenState extends State<SensorReadingScreen> {
  final SensorService _service = SensorService();
  late final Stream<SensorReading?> _stream;

  /// Drives the "x seconds ago" label, which must tick even when no new
  /// reading arrives — a frozen age is exactly what we need to notice.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _stream = _service.watchLatestReading();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _capture(SensorReading reading) async {
    if (!reading.hasVfa) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This reading has no VFA value, so it cannot be used.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // A reading much older than this visit probably belongs to the previous
    // farm. Capturing it would write confidently wrong VFA into the record.
    if (reading.isStale(DateTime.now())) {
      final age = reading.ageFrom(DateTime.now());
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('This reading looks old'),
          content: Text(
            age == null
                ? 'This reading has no timestamp, so its age cannot be checked. '
                    'It may belong to a different farm.'
                : 'The last reading is ${_ageLabel(age)} old. It may be from a '
                    'previous farm rather than this one.\n\n'
                    'Dip the probe and wait for a fresh reading, or capture '
                    'anyway if you are sure.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Wait'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Capture anyway'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    Navigator.pop(context, reading);
  }

  String _ageLabel(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Sensor Reading',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<SensorReading?>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              Icons.lock_outline,
              'Could not read sensor data.\n${snapshot.error}\n\n'
              'Check that Realtime Database rules allow supervisors to read '
              '"predictions".',
              AppTheme.error,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final reading = snapshot.data;
          if (reading == null) {
            return _message(
              Icons.sensors_off,
              'No sensor readings yet.\nDip the probe at the farm and the '
              'latest reading will appear here automatically.',
              AppTheme.textMuted,
            );
          }

          return _buildReading(reading);
        },
      ),
    );
  }

  Widget _buildReading(SensorReading reading) {
    final now = DateTime.now();
    final age = reading.ageFrom(now);
    final stale = reading.isStale(now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _farmHeader(),
        const SizedBox(height: 14),
        _liveBanner(age, stale),
        const SizedBox(height: 14),
        _vfaCard(reading),
        const SizedBox(height: 12),
        Row(
          children: [
            _metric('pH', reading.ph?.toStringAsFixed(1) ?? '—',
                Icons.science_outlined),
            const SizedBox(width: 10),
            _metric(
                'Temperature',
                reading.temperature == null
                    ? '—'
                    : '${reading.temperature!.toStringAsFixed(1)}°C',
                Icons.thermostat_outlined),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _metric('Turbidity', reading.turbidity?.toStringAsFixed(0) ?? '—',
                Icons.opacity_outlined),
            const SizedBox(width: 10),
            _metric(
                'Sample',
                reading.sampleId.isEmpty ? '—' : reading.sampleId,
                Icons.tag),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _capture(reading),
            icon: const Icon(Icons.download_done, size: 18),
            label: Text(
              'Capture This Reading',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // The sensor may be unavailable; a collection must still be recordable.
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(
            'Skip — verify without a sensor reading',
            style: GoogleFonts.inter(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _farmHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.agriculture, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.stop.farmerName,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            'Stop ${widget.stop.order}',
            style: GoogleFonts.inter(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _liveBanner(Duration? age, bool stale) {
    final colour = stale ? AppTheme.riskMedium : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colour.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(stale ? Icons.warning_amber_rounded : Icons.sensors,
              size: 16, color: colour),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              age == null
                  ? 'Reading has no timestamp — age unknown'
                  : stale
                      ? 'Last reading ${_ageLabel(age)} ago — may be from '
                          'another farm'
                      : 'Live — last reading ${_ageLabel(age)} ago',
              style: GoogleFonts.inter(
                  color: colour, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vfaCard(SensorReading reading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'VFA',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reading.vfa?.toStringAsFixed(2) ?? '—',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Grade ${reading.grade ?? "—"}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                  color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(IconData icon, String text, Color colour) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: colour),
            const SizedBox(height: 14),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Skip — verify without a sensor reading'),
            ),
          ],
        ),
      ),
    );
  }
}
