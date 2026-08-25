import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../models/tapping_detail.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../widgets/hotspot_indicator.dart';
import 'login_screen.dart';
import 'sync_screen.dart';

/// Landing screen after login. Shows who is signed in and the tapping records
/// submitted by farmers, before the supervisor starts a collection session.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _service = FirestoreService();

  UserProfile? _profile;
  List<TappingDetail> _tappings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _service.getCurrentUserProfile();
      final tappings = await _service.getTappingDetails();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _tappings = tappings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load dashboard data. Pull down to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  double get _totalVolume =>
      _tappings.fold(0.0, (sum, t) => sum + t.latexVolumeL);

  int get _totalTrees =>
      _tappings.fold(0, (sum, t) => sum + t.treesCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
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
            Flexible(
              child: Text(
                'LatexGuard',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          const HotspotIndicator(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _buildSupervisorCard(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  _buildSectionHeader(),
                  const SizedBox(height: 10),
                  if (_error != null)
                    _buildMessage(_error!, Icons.error_outline, AppTheme.error)
                  else if (_tappings.isEmpty)
                    _buildMessage(
                      'No tapping records submitted yet.',
                      Icons.inbox_outlined,
                      AppTheme.textMuted,
                    )
                  else
                    ..._tappings.map(_buildTappingCard),
                ],
              ),
            ),
      bottomNavigationBar: _buildStartBar(),
    );
  }

  // ── Supervisor identity ──────────────────────────────────────

  Widget _buildSupervisorCard() {
    final p = _profile;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  p?.initial ?? '?',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.name ?? 'Unknown user',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (p?.role ?? 'unknown').toUpperCase(),
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.25), height: 1),
          const SizedBox(height: 12),
          if (p != null) ...[
            if (p.employeeId.isNotEmpty)
              _buildProfileRow(Icons.badge_outlined, 'Employee ID', p.employeeId),
            if (p.email.isNotEmpty)
              _buildProfileRow(Icons.email_outlined, 'Email', p.email),
            if (p.phone.isNotEmpty)
              _buildProfileRow(Icons.phone_outlined, 'Phone', p.phone),
          ] else
            Text(
              'Profile details unavailable.',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.white.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(
            '$label  ',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary stats ────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatTile(
          icon: Icons.description_outlined,
          value: '${_tappings.length}',
          label: 'Records',
        ),
        const SizedBox(width: 10),
        _buildStatTile(
          icon: Icons.water_drop_outlined,
          value: _totalVolume.toStringAsFixed(1),
          label: 'Litres',
        ),
        const SizedBox(width: 10),
        _buildStatTile(
          icon: Icons.park_outlined,
          value: '$_totalTrees',
          label: 'Trees',
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
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
            Text(
              value,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tapping details ──────────────────────────────────────────

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Text(
          'FARMER TAPPING DETAILS',
          style: GoogleFonts.jetBrainsMono(
            color: AppTheme.textMuted,
            fontSize: 11,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          '${_tappings.length} total',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildTappingCard(TappingDetail t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farmer + date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.agriculture,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.farmerName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatDate(t.date),
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Core metrics
          Row(
            children: [
              _buildMetric(
                Icons.water_drop_outlined,
                '${t.latexVolumeL.toStringAsFixed(1)} L',
                'Volume',
              ),
              _buildMetric(
                Icons.park_outlined,
                '${t.treesCount}',
                'Trees',
              ),
              _buildMetric(
                Icons.schedule_outlined,
                '${t.durationMinutes} min',
                'Duration',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Time window
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 13,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                '${t.startTime} — ${t.endTime}',
                style: GoogleFonts.jetBrainsMono(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (t.litresPerTree != null)
                Text(
                  '${t.litresPerTree!.toStringAsFixed(2)} L/tree',
                  style: GoogleFonts.jetBrainsMono(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Condition chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildChip(
                Icons.eco_outlined,
                t.treeCondition,
                _conditionColor(t.treeCondition),
              ),
              _buildChip(
                Icons.wb_sunny_outlined,
                t.weatherCondition,
                AppTheme.textSecondary,
              ),
            ],
          ),

          if (t.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                t.notes,
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.primary),
              const SizedBox(width: 5),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
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

  Widget _buildMessage(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Start session CTA ────────────────────────────────────────

  Widget _buildStartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncScreen()),
              );
            },
            icon: const Icon(Icons.sensors, size: 18),
            label: Text(
              'Start Collection Session',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime? d) {
    if (d == null) return '--';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  Color _conditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'healthy':
        return AppTheme.riskSafe;
      case 'diseased':
      case 'damaged':
      case 'poor':
        return AppTheme.riskHigh;
      case 'average':
      case 'moderate':
        return AppTheme.riskMedium;
      default:
        return AppTheme.textSecondary;
    }
  }
}
