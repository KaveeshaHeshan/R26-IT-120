import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';
import '../models/tapping_detail.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../widgets/hotspot_indicator.dart';
// Dark mode is stored in FarmerSettings, which already scopes the whole app.
import 'farmer_screens/core/farmer_settings.dart';
import 'login_screen.dart';
import 'supervisor_route_screen.dart';

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
  bool _starting = false;
  String? _error;

  /// Ids of the tapping records the supervisor has picked for this round.
  final Set<String> _selected = {};

  /// Ids currently being deleted, so the card shows progress and repeat taps
  /// are ignored while the write is in flight.
  final Set<String> _deleting = {};

  /// Free-text filter over farmer names, for when the list gets long.
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  /// Records matching the current search. Selection is tracked by record id,
  /// so filtering never silently drops a farmer the supervisor already ticked.
  List<TappingDetail> get _visibleTappings {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _tappings;
    return _tappings
        .where((t) => t.farmerName.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TappingDetail> get _selectedTappings =>
      _tappings.where((t) => _selected.contains(t.id)).toList();

  /// Selected farms the DQN cannot route yet, because the farmer app has not
  /// written coordinates for them.
  int get _selectedWithoutLocation =>
      _selectedTappings.where((t) => !t.hasLocation).length;

  double get _selectedVolume =>
      _selectedTappings.fold(0.0, (sum, t) => sum + t.latexVolumeL);

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
        // Drop selections whose records no longer exist after a refresh.
        _selected.retainAll(tappings.map((t) => t.id));
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

  Future<void> _startSession() async {
    final selected = _selectedTappings;
    if (selected.isEmpty || _starting) return;

    setState(() => _starting = true);
    try {
      // Records which farms are in this round for the IoT sensor pipeline,
      // which watches the live session document.
      await _service.startSessionForFarms(selected);
      if (!mounted) return;
      setState(() => _starting = false);

      // The route screen plans the order over exactly these farmers; the rest
      // are masked out of the DQN, so no full 12-farmer roster is needed.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupervisorRouteScreen(
            selectedUserIds: selected.map((t) => t.userId).toSet(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start the session. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // ── Deleting a tapping record ────────────────────────

  /// Asks before deleting, naming the record so the wrong row cannot be
  /// removed by a mistimed tap.
  Future<void> _confirmDelete(TappingDetail t) async {
    if (_deleting.contains(t.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete this record?',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Several farmers may submit on the same day, so identify the
            // record by more than its owner's name.
            Text(
              '${t.farmerName} — ${_formatDate(t.date)}',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${t.latexVolumeL.toStringAsFixed(1)} L from ${t.treesCount} trees',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "This removes the farmer's submission from Firestore. You can "
              'undo it for a few seconds afterwards.',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteTapping(t);
  }

  Future<void> _deleteTapping(TappingDetail t) async {
    // Remember the position: the list is ordered by tapping date, not by
    // insertion, so an undo has to put the record back where it was.
    final index = _tappings.indexWhere((r) => r.id == t.id);

    setState(() => _deleting.add(t.id));

    try {
      final data = await _service.deleteTappingDetail(t.id);
      if (!mounted) return;

      setState(() {
        _deleting.remove(t.id);
        _tappings.removeWhere((r) => r.id == t.id);
        // The stats row and the round selection both derive from _tappings
        // and _selected, so both correct themselves here.
        _selected.remove(t.id);
      });

      if (data == null) {
        _snack('That record had already been deleted.', AppTheme.textMuted);
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text("Deleted ${t.farmerName}'s record."),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppTheme.accent,
              onPressed: () => _restoreTapping(t, data, index),
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting.remove(t.id));
      _snack('Could not delete the record. Please try again.', AppTheme.error);
    }
  }

  Future<void> _restoreTapping(
    TappingDetail t,
    Map<String, dynamic> data,
    int index,
  ) async {
    try {
      await _service.restoreTappingDetail(t.id, data);
      if (!mounted) return;

      setState(() {
        // The list may have been refreshed while the snackbar was showing, so
        // the remembered index is a hint rather than a guarantee.
        var at = index;
        if (at < 0 || at > _tappings.length) at = _tappings.length;
        if (!_tappings.any((r) => r.id == t.id)) _tappings.insert(at, t);
      });
    } catch (e) {
      if (!mounted) return;
      _snack(
        'Could not restore the record. Pull down to refresh.',
        AppTheme.error,
      );
    }
  }

  void _snack(String message, Color background) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: background),
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
          const SizedBox(width: 4),
          Builder(
            builder: (context) {
              final settings = FarmerSettingsScope.of(context);
              return IconButton(
                icon: Icon(
                  settings.darkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                tooltip: settings.darkMode ? 'Light mode' : 'Dark mode',
                onPressed: () => settings.setDarkMode(!settings.darkMode),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
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
                  if (_tappings.isNotEmpty) ...[
                    _buildSearchField(),
                    const SizedBox(height: 10),
                  ],
                  if (_error != null)
                    _buildMessage(_error!, Icons.error_outline, AppTheme.error)
                  else if (_tappings.isEmpty)
                    _buildMessage(
                      'No tapping records submitted yet.',
                      Icons.inbox_outlined,
                      AppTheme.textMuted,
                    )
                  else if (_visibleTappings.isEmpty)
                    _buildMessage(
                      'No farmers match "$_query".',
                      Icons.search_off,
                      AppTheme.textMuted,
                    )
                  else
                    ..._visibleTappings.map(_buildTappingCard),
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

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v),
      style: GoogleFonts.inter(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search farmers',
        hintStyle: GoogleFonts.inter(
            fontSize: 13, color: AppTheme.textMuted),
        prefixIcon:
            Icon(Icons.search, size: 18, color: AppTheme.textMuted),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    final allSelected =
        _tappings.isNotEmpty && _selected.length == _tappings.length;

    return Row(
      children: [
        Flexible(
          child: Text(
            'SELECT FARMS TO COLLECT',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textMuted,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Spacer(),
        if (_tappings.isNotEmpty)
          TextButton(
            onPressed: () {
              setState(() {
                if (allSelected) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(_tappings.map((t) => t.id));
                }
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              allSelected ? 'Clear' : 'Select all',
              style: GoogleFonts.inter(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTappingCard(TappingDetail t) {
    final isSelected = _selected.contains(t.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selected.remove(t.id);
          } else {
            _selected.add(t.id);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farmer + date
          Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
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
              const SizedBox(width: 2),
              _buildDeleteButton(t),
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
              Icon(
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
              if (!t.hasLocation)
                _buildChip(
                  Icons.location_off_outlined,
                  'Location pending',
                  AppTheme.riskMedium,
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
      ),
    );
  }

  /// Delete affordance on a card. The IconButton consumes its own tap, so
  /// pressing it does not also toggle the card's round selection.
  Widget _buildDeleteButton(TappingDetail t) {
    if (_deleting.contains(t.id)) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.error,
          ),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
      tooltip: 'Delete record',
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () => _confirmDelete(t),
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
    final count = _selected.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected volume, and a warning when some stops can't be routed.
            if (count > 0) ...[
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${_selectedVolume.toStringAsFixed(1)} L selected',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedWithoutLocation > 0)
                    Flexible(
                      child: Text(
                        '$_selectedWithoutLocation without location',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppTheme.riskMedium,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (count == 0 || _starting) ? null : _startSession,
                icon: _starting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sensors, size: 18),
                label: Text(
                  count == 0
                      ? 'Select farms to collect from'
                      : 'Start Collection Session ($count ${count == 1 ? 'farm' : 'farms'})',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.divider,
                  disabledForegroundColor: AppTheme.textMuted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
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
