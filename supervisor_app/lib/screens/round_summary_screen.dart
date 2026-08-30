import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../models/collection_stop.dart';
import '../services/firestore_service.dart';

/// End-of-round close-out: what was collected, what was skipped, and the
/// distance and time the route actually implied.
class RoundSummaryScreen extends StatefulWidget {
  final List<CollectionStop> stops;
  final Set<String> completed;

  /// Farmer id -> reason the supervisor could not collect there.
  final Map<String, String> skipped;
  final RouteEfficiency? efficiency;

  const RoundSummaryScreen({
    super.key,
    required this.stops,
    required this.completed,
    required this.skipped,
    this.efficiency,
  });

  @override
  State<RoundSummaryScreen> createState() => _RoundSummaryScreenState();
}

class _RoundSummaryScreenState extends State<RoundSummaryScreen> {
  final FirestoreService _service = FirestoreService();

  bool _loading = true;
  String? _error;

  double _litres = 0;
  int _records = 0;
  double? _avgVfa;
  int _withSensor = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Volumes live on the collection records, not on the route, so the
      // totals come from what was actually saved today.
      final records = await _service.getTodaysCollections();
      final mine = records
          .where((r) => widget.completed.contains(r['farm_id']))
          .toList();

      double litres = 0;
      double vfaSum = 0;
      int vfaCount = 0;
      for (final r in mine) {
        litres += (r['volume'] as num?)?.toDouble() ?? 0;
        final vfa = (r['vfa_result'] as num?)?.toDouble();
        if (vfa != null) {
          vfaSum += vfa;
          vfaCount++;
        }
      }

      if (!mounted) return;
      setState(() {
        _records = mine.length;
        _litres = litres;
        _withSensor = vfaCount;
        _avgVfa = vfaCount == 0 ? null : vfaSum / vfaCount;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load today\'s collections.\n$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final collected = widget.completed.length;
    final skipped = widget.skipped.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Text(
          'Round Summary',
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _headline(collected, skipped),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _tile('Litres', _litres.toStringAsFixed(1),
                        Icons.water_drop_outlined),
                    const SizedBox(width: 10),
                    _tile('Records', '$_records',
                        Icons.description_outlined),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _tile(
                        'Avg VFA',
                        _avgVfa?.toStringAsFixed(2) ?? '—',
                        Icons.science_outlined),
                    const SizedBox(width: 10),
                    _tile('Skipped', '$skipped', Icons.redo),
                  ],
                ),
                if (_avgVfa != null && _withSensor < collected) ...[
                  const SizedBox(height: 10),
                  // Averaging over a subset would otherwise read as an average
                  // over the whole round.
                  Text(
                    'Average VFA covers $_withSensor of $collected collections '
                    '— the rest were recorded without a sensor reading.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
                if (widget.efficiency != null) ...[
                  const SizedBox(height: 18),
                  _sectionLabel('ROUTE'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _tile(
                          'Planned km',
                          widget.efficiency!.dqnKm.toStringAsFixed(1),
                          Icons.route),
                      const SizedBox(width: 10),
                      _tile('Est. time',
                          '${widget.efficiency!.totalMinutes} min',
                          Icons.schedule),
                    ],
                  ),
                ],
                if (widget.skipped.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _sectionLabel('SKIPPED STOPS'),
                  const SizedBox(height: 8),
                  ...widget.skipped.entries.map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.redo,
                              size: 16, color: AppTheme.riskMedium),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_nameFor(e.key),
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                          Text(e.value,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: const TextStyle(
                          color: AppTheme.error, fontSize: 12)),
                ],
              ],
            ),
    );
  }

  String _nameFor(String farmerId) => widget.stops
      .firstWhere(
        (s) => s.farmerId == farmerId,
        orElse: () => CollectionStop(
          order: 0,
          farmerId: farmerId,
          farmerName: farmerId,
          latitude: 0,
          longitude: 0,
          spoilageScore: 0,
        ),
      )
      .farmerName;

  Widget _headline(int collected, int skipped) {
    final total = widget.stops.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('$collected of $total',
              style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1)),
          const SizedBox(height: 6),
          Text(
            skipped == 0
                ? 'farms collected'
                : 'farms collected · $skipped skipped',
            style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.jetBrainsMono(
            color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1.5),
      );

  Widget _tile(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }
}
