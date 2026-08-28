import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_theme.dart';
import '../models/farm.dart';
import '../services/firestore_service.dart';
import '../widgets/hotspot_indicator.dart';
import 'map_screen.dart';

class StopListScreen extends StatefulWidget {
  final List<Farm> farms;
  const StopListScreen({super.key, required this.farms});

  @override
  State<StopListScreen> createState() => _StopListScreenState();
}

class _StopListScreenState extends State<StopListScreen> {
  late List<Farm> _sortedFarms;

  @override
  void initState() {
    super.initState();
    _sortedFarms = List.from(widget.farms)
      ..sort((a, b) {
        // 'pending' outranks 'safe': a farm with no sensor reading yet might
        // turn out to be urgent, so it must not sink below farms already
        // confirmed safe.
        const order = {'high': 0, 'medium': 1, 'pending': 2, 'safe': 3};
        return (order[a.riskLevel] ?? 2).compareTo(order[b.riskLevel] ?? 2);
      });
  }

  int get _highCount =>
      _sortedFarms.where((f) => f.riskLevel == 'high').length;
  int get _mediumCount =>
      _sortedFarms.where((f) => f.riskLevel == 'medium').length;
  int get _safeCount =>
      _sortedFarms.where((f) => f.riskLevel == 'safe').length;
  int get _pendingCount =>
      _sortedFarms.where((f) => f.riskLevel == 'pending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            await FirestoreService().resetSession();
            if (context.mounted) Navigator.pop(context);
          },
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
          // ── Summary Bar ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection Stop List',
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ordered by VFA urgency — collect red farms first',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildSummaryPill(
                      count: _highCount,
                      label: 'Urgent',
                      color: AppTheme.riskHigh,
                    ),
                    _buildSummaryPill(
                      count: _mediumCount,
                      label: 'Watch',
                      color: AppTheme.riskMedium,
                    ),
                    if (_pendingCount > 0)
                      _buildSummaryPill(
                        count: _pendingCount,
                        label: 'Awaiting',
                        color: AppTheme.riskPending,
                      ),
                    _buildSummaryPill(
                      count: _safeCount,
                      label: 'Safe',
                      color: AppTheme.riskSafe,
                    ),
                    Text(
                      '${_sortedFarms.length} total',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.divider),

          // ── Farm List ─────────────────────────────────────
          Expanded(
            child: _sortedFarms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          color: AppTheme.textMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No farms available',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sortedFarms.length,
                    itemBuilder: (context, index) {
                      return _FarmCard(
                        farm: _sortedFarms[index],
                        stopNumber: index + 1,
                      );
                    },
                  ),
          ),

          // ── Bottom Action Bar ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                top: BorderSide(color: AppTheme.divider),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sortedFarms.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapScreen(
                              farm: _sortedFarms.first,
                              stopNumber: 1,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: Text(
                  'Start Collection Route',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPill({
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmCard extends StatelessWidget {
  final Farm farm;
  final int stopNumber;

  const _FarmCard({required this.farm, required this.stopNumber});

  @override
  Widget build(BuildContext context) {
    final riskColor = AppTheme.riskColor(farm.riskLevel);
    final riskLabel = AppTheme.riskLabel(farm.riskLevel);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MapScreen(
            farm: farm,
            stopNumber: stopNumber,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: riskColor.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Risk color bar at top of card
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: riskColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Stop Number Circle
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: riskColor.withOpacity(0.12),
                      border: Border.all(color: riskColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$stopNumber',
                        style: GoogleFonts.jetBrainsMono(
                          color: riskColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Farm Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.farmerName,
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Farm ID: ${farm.farmId}',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side: Badge + VFA + Grade
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
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'VFA: ${farm.vfaResult.toStringAsFixed(2)}',
                        style: GoogleFonts.jetBrainsMono(
                          color: riskColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Grade ${farm.grade}',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
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
    );
  }
}