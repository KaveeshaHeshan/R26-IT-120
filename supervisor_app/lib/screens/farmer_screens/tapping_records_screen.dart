import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'core/farmer_settings.dart';
import 'core/farmer_theme.dart';
import 'core/location_picker_screen.dart';

// ============================================================
// OPTIONS
// ============================================================

class _Condition {
  const _Condition(this.name, this.nameSi, this.icon, this.color);

  final String name;
  final String nameSi;
  final IconData icon;
  final Color color;
}

const List<_Condition> _weatherOptions = <_Condition>[
  _Condition('Sunny', 'අව්ව', Icons.wb_sunny_rounded, Color(0xFFF5A623)),
  _Condition('Cloudy', 'වළාකුළු', Icons.cloud_rounded, Color(0xFF78909C)),
  _Condition('Drizzle', 'සිහින් වැස්ස', Icons.grain_rounded, Color(0xFF4FC3F7)),
  _Condition('Rainy', 'වැසි', Icons.water_drop_rounded, Color(0xFF1E88E5)),
  _Condition('Stormy', 'කුණාටු', Icons.thunderstorm_rounded, Color(0xFF5C6BC0)),
];

const List<_Condition> _treeOptions = <_Condition>[
  _Condition('Healthy', 'නීරෝගී', Icons.eco_rounded, Color(0xFF43A047)),
  _Condition('Stressed', 'පීඩාකාරී', Icons.warning_amber_rounded, Color(0xFFFF9800)),
  _Condition('Diseased', 'රෝගී', Icons.bug_report_rounded, Color(0xFFE53935)),
  _Condition('Damaged', 'හානි වූ', Icons.report_problem_rounded, Color(0xFFD84315)),
  _Condition('Recovering', 'සුවය ලබන', Icons.healing_rounded, Color(0xFF00897B)),
];

// ============================================================
// HELPERS
// ============================================================

const List<String> _kMonths = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> _kWeekdays = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

String _dateText(DateTime date) {
  return '${_kWeekdays[date.weekday - 1]}, '
      '${date.day} ${_kMonths[date.month - 1]} ${date.year}';
}

String _timeText(TimeOfDay time) {
  final String h = time.hour.toString().padLeft(2, '0');
  final String m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

TimeOfDay? _parseTime(dynamic value) {
  if (value is! String) return null;

  final List<String> parts = value.split(':');
  if (parts.length != 2) return null;

  final int? hour = int.tryParse(parts[0]);
  final int? minute = int.tryParse(parts[1]);

  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23) return null;
  if (minute < 0 || minute > 59) return null;

  return TimeOfDay(hour: hour, minute: minute);
}

DateTime? _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

String _durationText(int minutes) {
  if (minutes < 60) return '${minutes}m';

  final int hours = minutes ~/ 60;
  final int mins = minutes % 60;

  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

_Condition? _findCondition(List<_Condition> options, String? value) {
  for (final _Condition item in options) {
    if (item.name == value) return item;
  }
  return null;
}

// ============================================================
// MAIN SCREEN
// ============================================================

class TappingRecordsScreen extends StatefulWidget {
  const TappingRecordsScreen({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  State<TappingRecordsScreen> createState() => _TappingRecordsScreenState();
}

class _TappingRecordsScreenState extends State<TappingRecordsScreen> {
  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('tapping_details');

  Future<void> _addRecord() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TappingRecordFormScreen(userId: widget.userId),
      ),
    );
  }

  Future<void> _editRecord(String id, Map<String, dynamic> data) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TappingRecordFormScreen(
          userId: widget.userId,
          docId: id,
          initialData: data,
        ),
      ),
    );
  }

  Future<void> _deleteRecord(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    FarmerSettings settings,
  ) async {
    final FarmerPalette p = settings.palette;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            settings.t('Delete Record?', 'වාර්තාව මකන්නද?'),
            style: TextStyle(fontWeight: FontWeight.w900, color: p.textPrimary),
          ),
          content: Text(
            settings.t(
              'This tapping record will be permanently deleted.',
              'මෙම ටැපිං වාර්තාව ස්ථිරවම මකා දමනු ලැබේ.',
            ),
            style: TextStyle(color: p.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(settings.t('Cancel', 'අවලංගු කරන්න')),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: p.danger),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(settings.t('Delete', 'මකන්න')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await doc.reference.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(settings.t(
            'Tapping record deleted successfully.',
            'ටැපිං වාර්තාව සාර්ථකව මකා දමන ලදී.',
          )),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(settings.t('Could not delete the record.', 'වාර්තාව මකා දැමිය නොහැක.')),
          backgroundColor: p.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;

    return Scaffold(
      backgroundColor: p.background,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          settings.t('Add Record', 'වාර්තාව එකතු කරන්න'),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: FarmerScreenBackground(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // IMPORTANT: no orderBy here to avoid a Firestore composite-index requirement.
        stream: _collection.where('userId', isEqualTo: widget.userId).snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: p.primary));
          }

          if (snapshot.hasError) {
            return _ErrorView(p: p, settings: settings, error: snapshot.error.toString());
          }

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          );

          docs.sort((a, b) {
            final DateTime? dateA = _parseDate(a.data()['date']);
            final DateTime? dateB = _parseDate(b.data()['date']);

            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;

            return dateB.compareTo(dateA);
          });

          final _Stats stats = _Stats.fromDocs(docs);

          return CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _Header(p: p, settings: settings, count: docs.length),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _StatsSection(p: p, settings: settings, stats: stats, docs: docs),
                ),
              ),

              if (docs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyView(p: p, settings: settings, onAdd: _addRecord),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final QueryDocumentSnapshot<Map<String, dynamic>> doc = docs[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _RecordCard(
                            p: p,
                            settings: settings,
                            doc: doc,
                            onEdit: () => _editRecord(doc.id, doc.data()),
                            onDelete: () => _deleteRecord(doc, settings),
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                ),
            ],
          );
        },
      )),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _Header extends StatelessWidget {
  const _Header({required this.p, required this.settings, required this.count});

  final FarmerPalette p;
  final FarmerSettings settings;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[p.primaryDark, p.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: p.primary.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 30),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  settings.t('Tapping History', 'ටැපිං ඉතිහාසය'),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  count == 0
                      ? settings.t('No tapping sessions yet', 'තවම ටැපිං සැසි නැත')
                      : settings.t(
                          '$count tapping session${count == 1 ? '' : 's'} recorded',
                          'ටැපිං සැසි $count ක් වාර්තා කර ඇත',
                        ),
                  style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATS
// ============================================================

class _Stats {
  const _Stats({required this.sessions, required this.trees, required this.volume});

  final int sessions;
  final int trees;
  final double volume;

  double get average => trees == 0 ? 0 : volume / trees;

  factory _Stats.fromDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    int trees = 0;
    double volume = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
      final Map<String, dynamic> data = doc.data();

      final dynamic treeValue = data['treesCount'];
      final dynamic volumeValue = data['latexVolumeL'];

      if (treeValue is num) trees += treeValue.toInt();
      if (volumeValue is num) volume += volumeValue.toDouble();
    }

    return _Stats(sessions: docs.length, trees: trees, volume: volume);
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.p,
    required this.settings,
    required this.stats,
    required this.docs,
  });

  final FarmerPalette p;
  final FarmerSettings settings;
  final _Stats stats;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          settings.t('Performance Overview', 'කාර්යසාධන දළ විශ්ලේෂණය'),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: p.textPrimary),
        ),

        const SizedBox(height: 10),

        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                p: p,
                icon: Icons.event_note_rounded,
                title: settings.t('Sessions', 'සැසි'),
                value: '${stats.sessions}',
                color: p.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                p: p,
                icon: Icons.water_drop_rounded,
                title: settings.t('Total Latex', 'මුළු ලැටෙක්ස්'),
                value: '${stats.volume.toStringAsFixed(1)} L',
                color: p.info,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                p: p,
                icon: Icons.park_rounded,
                title: settings.t('Trees Tapped', 'ටැප් කළ ගස්'),
                value: '${stats.trees}',
                color: const Color(0xFF6A8E23),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                p: p,
                icon: Icons.insights_rounded,
                title: settings.t('Avg / Tree', 'සාමාන්‍ය / ගස'),
                value: '${stats.average.toStringAsFixed(2)} L',
                color: p.warning,
              ),
            ),
          ],
        ),

        if (docs.length >= 2) ...<Widget>[
          const SizedBox(height: 10),
          _TrendCard(p: p, settings: settings, docs: docs),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.p,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final FarmerPalette p;
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: p.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(fontSize: 10, color: p.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TREND CARD (unique feature) — 7-session latex volume sparkline
// ============================================================

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.p, required this.settings, required this.docs});

  final FarmerPalette p;
  final FarmerSettings settings;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    // docs are sorted newest-first; take the most recent 7 and show oldest -> newest.
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> recent =
        docs.take(7).toList().reversed.toList();

    final List<double> values = recent.map((doc) {
      final dynamic v = doc.data()['latexVolumeL'];
      return v is num ? v.toDouble() : 0.0;
    }).toList();

    final double best = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  settings.t('RECENT TREND', 'මෑත ප්‍රවණතාවය'),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: p.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.t('Best: ${best.toStringAsFixed(1)} L', 'ඉහළම: ${best.toStringAsFixed(1)} L'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: p.textPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: CustomPaint(
                painter: _SparklinePainter(values: values, color: p.primary),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final double maxV = values.reduce((a, b) => a > b ? a : b);
    final double minV = values.reduce((a, b) => a < b ? a : b);
    final double range = (maxV - minV).abs() < 0.001 ? 1 : (maxV - minV);

    final double stepX = size.width / (values.length - 1);

    final Path line = Path();
    final List<Offset> points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final double normalized = (values[i] - minV) / range;
      final double x = stepX * i;
      final double y = size.height - (normalized * size.height * 0.85) - 4;

      points.add(Offset(x, y));

      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(line, linePaint);

    final Paint dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 3.4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}

// ============================================================
// RECORD CARD
// ============================================================

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.p,
    required this.settings,
    required this.doc,
    required this.onEdit,
    required this.onDelete,
  });

  final FarmerPalette p;
  final FarmerSettings settings;
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = doc.data();

    final DateTime? date = _parseDate(data['date']);

    final int trees = data['treesCount'] is num ? (data['treesCount'] as num).toInt() : 0;
    final double volume = data['latexVolumeL'] is num ? (data['latexVolumeL'] as num).toDouble() : 0.0;
    final int duration = data['durationMinutes'] is num ? (data['durationMinutes'] as num).toInt() : 0;

    final String startTime = data['startTime']?.toString() ?? '--:--';
    final String endTime = data['endTime']?.toString() ?? '--:--';
    final String notes = data['notes']?.toString() ?? '';

    final _Condition? weather = _findCondition(_weatherOptions, data['weatherCondition']?.toString());
    final _Condition? treeCondition = _findCondition(_treeOptions, data['treeCondition']?.toString());

    final double? latitude = data['latitude'] is num ? (data['latitude'] as num).toDouble() : null;
    final double? longitude = data['longitude'] is num ? (data['longitude'] as num).toDouble() : null;
    final LatLng? location = (latitude != null && longitude != null) ? LatLng(latitude, longitude) : null;

    final double yieldValue = data['yieldPerTreeL'] is num
        ? (data['yieldPerTreeL'] as num).toDouble()
        : trees > 0
            ? volume / trees
            : 0;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 8, 13),
            child: Row(
              children: <Widget>[
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: p.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: p.primary, size: 22),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        date == null ? settings.t('Date not available', 'දිනය නොමැත') : _dateText(date),
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: p.textPrimary),
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: <Widget>[
                          Icon(Icons.schedule_rounded, size: 13, color: p.textMuted),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$startTime – $endTime'
                              '${duration > 0 ? '  •  ${_durationText(duration)}' : ''}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: p.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: p.textSecondary),
                  color: p.surface,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.edit_outlined, size: 19, color: p.textPrimary),
                          const SizedBox(width: 10),
                          Text(settings.t('Edit record', 'සංස්කරණය කරන්න'), style: TextStyle(color: p.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.delete_outline_rounded, size: 19, color: p.danger),
                          const SizedBox(width: 10),
                          Text(settings.t('Delete record', 'මකන්න'), style: TextStyle(color: p.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: p.border),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _Metric(p: p, icon: Icons.park_outlined, value: '$trees', label: settings.t('Trees', 'ගස්'), color: p.primary),
                ),
                _VDivider(p: p),
                Expanded(
                  child: _Metric(p: p, icon: Icons.water_drop_outlined, value: '${volume.toStringAsFixed(1)} L', label: settings.t('Latex', 'ලැටෙක්ස්'), color: p.info),
                ),
                _VDivider(p: p),
                Expanded(
                  child: _Metric(p: p, icon: Icons.insights_rounded, value: '${yieldValue.toStringAsFixed(2)} L', label: settings.t('Per Tree', 'ගසකට'), color: p.warning),
                ),
              ],
            ),
          ),

          if (weather != null || treeCondition != null || location != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 13),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: <Widget>[
                  if (weather != null) _Badge(condition: weather, settings: settings),
                  if (treeCondition != null) _Badge(condition: treeCondition, settings: settings),
                  if (location != null)
                    _LocationBadge(p: p, settings: settings, location: location),
                ],
              ),
            ),

          if (notes.trim().isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.notes_rounded, size: 16, color: p.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, height: 1.4, color: p.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// METRIC
// ============================================================

class _Metric extends StatelessWidget {
  const _Metric({
    required this.p,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final FarmerPalette p;
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: p.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: p.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider({required this.p});

  final FarmerPalette p;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: p.border);
  }
}

// ============================================================
// CONDITION BADGE
// ============================================================

class _Badge extends StatelessWidget {
  const _Badge({required this.condition, required this.settings});

  final _Condition condition;
  final FarmerSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: condition.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: condition.color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(condition.icon, size: 13, color: condition.color),
          const SizedBox(width: 5),
          Text(
            settings.t(condition.name, condition.nameSi),
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: condition.color),
          ),
        ],
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.p, required this.settings, required this.location});

  final FarmerPalette p;
  final FarmerSettings settings;
  final LatLng location;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LocationPickerScreen(initialLocation: location, readOnly: true),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: p.info.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: p.info.withOpacity(0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.location_on_rounded, size: 13, color: p.info),
            const SizedBox(width: 5),
            Text(
              settings.t('View location', 'ස්ථානය බලන්න'),
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: p.info),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.p, required this.settings, required this.onAdd});

  final FarmerPalette p;
  final FarmerSettings settings;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(28)),
              child: Icon(Icons.water_drop_outlined, size: 44, color: p.primary),
            ),

            const SizedBox(height: 18),

            Text(
              settings.t('No tapping records yet', 'තවම ටැපිං වාර්තා නැත'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: p.textPrimary),
            ),

            const SizedBox(height: 8),

            Text(
              settings.t(
                'Start recording your tapping sessions to monitor latex production and tree performance.',
                'ලැටෙක්ස් නිෂ්පාදනය සහ ගස් කාර්යසාධනය නිරීක්ෂණය කිරීමට ටැපිං සැසි වාර්තා කිරීම අරඹන්න.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, height: 1.5, color: p.textSecondary),
            ),

            const SizedBox(height: 20),

            
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.p, required this.settings, required this.error});

  final FarmerPalette p;
  final FarmerSettings settings;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: p.danger, size: 50),

            const SizedBox(height: 14),

            Text(
              settings.t('Unable to load tapping records', 'ටැපිං වාර්තා පූරණය කළ නොහැක'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: p.textPrimary),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: p.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FORM SCREEN
// ============================================================

class TappingRecordFormScreen extends StatefulWidget {
  const TappingRecordFormScreen({
    required this.userId,
    this.docId,
    this.initialData,
    super.key,
  });

  final String userId;
  final String? docId;
  final Map<String, dynamic>? initialData;

  @override
  State<TappingRecordFormScreen> createState() => _TappingRecordFormScreenState();
}

class _TappingRecordFormScreenState extends State<TappingRecordFormScreen> {
  late DateTime _date;

  TimeOfDay? _start;
  TimeOfDay? _end;

  late TextEditingController _trees;
  late TextEditingController _volume;
  late TextEditingController _notes;

  String? _weather;
  String? _treeCondition;

  LatLng? _location;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic>? data = widget.initialData;

    _date = _parseDate(data?['date']) ?? DateTime.now();
    _start = _parseTime(data?['startTime']);
    _end = _parseTime(data?['endTime']);
    _weather = data?['weatherCondition']?.toString();
    _treeCondition = data?['treeCondition']?.toString();

    final dynamic latitudeValue = data?['latitude'];
    final dynamic longitudeValue = data?['longitude'];

    if (latitudeValue is num && longitudeValue is num) {
      _location = LatLng(latitudeValue.toDouble(), longitudeValue.toDouble());
    }

    final dynamic treesValue = data?['treesCount'];
    final dynamic volumeValue = data?['latexVolumeL'];

    _trees = TextEditingController(text: treesValue is num ? treesValue.toInt().toString() : '');
    _volume = TextEditingController(text: volumeValue is num ? volumeValue.toString() : '');
    _notes = TextEditingController(text: data?['notes']?.toString() ?? '');
  }

  @override
  void dispose() {
    _trees.dispose();
    _volume.dispose();
    _notes.dispose();
    super.dispose();
  }

  int? get _duration {
    if (_start == null || _end == null) return null;

    final int start = _start!.hour * 60 + _start!.minute;
    final int end = _end!.hour * 60 + _end!.minute;
    final int difference = end - start;

    if (difference <= 0) return null;
    return difference;
  }

  double? get _yield {
    final int? trees = int.tryParse(_trees.text.trim());
    final double? volume = double.tryParse(_volume.text.trim());

    if (trees == null || trees <= 0 || volume == null || volume <= 0) return null;
    return volume / trees;
  }

  void _error(FarmerPalette p, String message) {
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

  Future<void> _pickLocation() async {
    final LatLng? picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: _location),
      ),
    );

    if (picked == null) return;

    setState(() => _location = picked);
  }

  Future<void> _selectDate(FarmerPalette p) async {
    final DateTime now = DateTime.now();

    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: p.primary)),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() => _date = selected);
  }

  Future<void> _selectTime({required bool start}) async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: (start ? _start : _end) ?? TimeOfDay.now(),
    );

    if (selected == null) return;

    setState(() {
      if (start) {
        _start = selected;
      } else {
        _end = selected;
      }
    });
  }

  Future<void> _save(FarmerSettings settings) async {
    final FarmerPalette p = settings.palette;

    if (_start == null || _end == null) {
      _error(p, settings.t('Please select both start and end time.', 'ආරම්භක සහ අවසාන වේලාව තෝරන්න.'));
      return;
    }

    if (_duration == null) {
      _error(p, settings.t('End time must be after start time.', 'අවසාන වේලාව ආරම්භක වේලාවට පසුව විය යුතුය.'));
      return;
    }

    final int? trees = int.tryParse(_trees.text.trim());

    if (trees == null || trees <= 0) {
      _error(p, settings.t('Enter a valid number of trees.', 'වලංගු ගස් ගණනක් ඇතුළත් කරන්න.'));
      return;
    }

    final double? volume = double.tryParse(_volume.text.trim());

    if (volume == null || volume <= 0) {
      _error(p, settings.t('Enter a valid latex volume.', 'වලංගු ලැටෙක්ස් ප්‍රමාණයක් ඇතුළත් කරන්න.'));
      return;
    }

    if (_weather == null) {
      _error(p, settings.t('Please select the weather condition.', 'කාලගුණ තත්ත්වය තෝරන්න.'));
      return;
    }

    if (_treeCondition == null) {
      _error(p, settings.t('Please select the tree condition.', 'ගස් තත්ත්වය තෝරන්න.'));
      return;
    }

    if (_location == null) {
      _error(p, settings.t('Please add the tapping location.', 'ටැපිං ස්ථානය එකතු කරන්න.'));
      return;
    }

    setState(() => _saving = true);

    final Map<String, dynamic> data = <String, dynamic>{
      'userId': widget.userId,
      'date': Timestamp.fromDate(DateTime(_date.year, _date.month, _date.day)),
      'startTime': _timeText(_start!),
      'endTime': _timeText(_end!),
      'durationMinutes': _duration,
      'treesCount': trees,
      'latexVolumeL': volume,
      'yieldPerTreeL': double.parse((volume / trees).toStringAsFixed(3)),
      'weatherCondition': _weather,
      'treeCondition': _treeCondition,
      'latitude': _location!.latitude,
      'longitude': _location!.longitude,
      'notes': _notes.text.trim(),
      'updatedAt': Timestamp.now(),
    };

    try {
      final CollectionReference<Map<String, dynamic>> collection =
          FirebaseFirestore.instance.collection('tapping_details');

      if (widget.docId == null) {
        data['createdAt'] = Timestamp.now();
        await collection.add(data);
      } else {
        await collection.doc(widget.docId).update(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.docId == null
                ? settings.t('Tapping record added successfully.', 'ටැපිං වාර්තාව එකතු කරන ලදී.')
                : settings.t('Tapping record updated successfully.', 'ටැපිං වාර්තාව යාවත්කාලීන කරන ලදී.'),
          ),
          backgroundColor: p.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Tapping record save error: $e');

      if (!mounted) return;

      _error(p, settings.t('Could not save the record. Please try again.', 'වාර්තාව සුරැකිය නොහැක. නැවත උත්සාහ කරන්න.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;
    final bool editing = widget.docId != null;

    return Scaffold(
      backgroundColor: p.background,

      appBar: AppBar(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        title: Text(
          editing
              ? settings.t('Edit Tapping Record', 'ටැපිං වාර්තාව සංස්කරණය')
              : settings.t('New Tapping Record', 'නව ටැපිං වාර්තාව'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),

      body: FarmerScreenBackground(child: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 25),
                children: <Widget>[
                  _FormIntro(p: p, settings: settings, editing: editing),

                  const SizedBox(height: 15),

                  _Section(
                    p: p,
                    number: '01',
                    title: settings.t('Session Timing', 'සැසි කාලය'),
                    subtitle: settings.t('When did this tapping session take place?', 'මෙම ටැපිං සැසිය සිදු වූයේ කවදාද?'),
                    icon: Icons.schedule_rounded,
                    child: Column(
                      children: <Widget>[
                        _SelectField(
                          p: p,
                          icon: Icons.calendar_month_rounded,
                          title: settings.t('Tapping date', 'ටැපිං දිනය'),
                          value: _dateText(_date),
                          onTap: () => _selectDate(p),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _SelectField(
                                p: p,
                                icon: Icons.play_circle_outline_rounded,
                                title: settings.t('Start time', 'ආරම්භක වේලාව'),
                                value: _start == null ? settings.t('Select', 'තෝරන්න') : _timeText(_start!),
                                onTap: () => _selectTime(start: true),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: _SelectField(
                                p: p,
                                icon: Icons.stop_circle_outlined,
                                title: settings.t('End time', 'අවසාන වේලාව'),
                                value: _end == null ? settings.t('Select', 'තෝරන්න') : _timeText(_end!),
                                onTap: () => _selectTime(start: false),
                              ),
                            ),
                          ],
                        ),

                        if (_duration != null) ...<Widget>[
                          const SizedBox(height: 11),
                          _Info(p: p, text: settings.t('Session duration: ${_durationText(_duration!)}', 'සැසි කාලය: ${_durationText(_duration!)}')),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _Section(
                    p: p,
                    number: '02',
                    title: settings.t('Harvest Details', 'අස්වනු විස්තර'),
                    subtitle: settings.t('Enter the production information.', 'නිෂ්පාදන තොරතුරු ඇතුළත් කරන්න.'),
                    icon: Icons.agriculture_rounded,
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _trees,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: p.textPrimary),
                                onChanged: (_) => setState(() {}),
                                decoration: _input(
                                  p: p,
                                  label: settings.t('Trees tapped', 'ටැප් කළ ගස්'),
                                  hint: 'e.g. 10',
                                  icon: Icons.park_outlined,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: TextField(
                                controller: _volume,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: p.textPrimary),
                                onChanged: (_) => setState(() {}),
                                decoration: _input(
                                  p: p,
                                  label: settings.t('Latex volume', 'ලැටෙක්ස් ප්‍රමාණය'),
                                  hint: 'e.g. 2',
                                  icon: Icons.water_drop_outlined,
                                  suffix: 'L',
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_yield != null) ...<Widget>[
                          const SizedBox(height: 11),
                          _Yield(p: p, settings: settings, value: _yield!),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _Section(
                    p: p,
                    number: '03',
                    title: settings.t('Field Conditions', 'ක්ෂේත්‍ර තත්ත්ව'),
                    subtitle: settings.t('Record conditions during tapping.', 'ටැපිං අතරතුර තත්ත්ව සටහන් කරන්න.'),
                    icon: Icons.terrain_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _Label(p: p, icon: Icons.wb_sunny_outlined, text: settings.t('Weather condition', 'කාලගුණ තත්ත්වය')),

                        const SizedBox(height: 9),

                        _Selector(
                          p: p,
                          settings: settings,
                          options: _weatherOptions,
                          selected: _weather,
                          onSelected: (value) => setState(() => _weather = value),
                        ),

                        const SizedBox(height: 17),

                        _Label(p: p, icon: Icons.eco_outlined, text: settings.t('Tree condition', 'ගස් තත්ත්වය')),

                        const SizedBox(height: 9),

                        _Selector(
                          p: p,
                          settings: settings,
                          options: _treeOptions,
                          selected: _treeCondition,
                          onSelected: (value) => setState(() => _treeCondition = value),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _Section(
                    p: p,
                    number: '04',
                    title: settings.t('Tapping Location', 'ටැපිං ස්ථානය'),
                    subtitle: settings.t('Mark where this tapping session took place.', 'මෙම ටැපිං සැසිය සිදු වූ ස්ථානය සලකුණු කරන්න.'),
                    icon: Icons.location_on_rounded,
                    child: _SelectField(
                      p: p,
                      icon: Icons.map_rounded,
                      title: settings.t('GPS location', 'ජීපීඑස් ස්ථානය'),
                      value: _location == null
                          ? settings.t('Tap to select on map', 'සිතියමේ තෝරන්න')
                          : '${_location!.latitude.toStringAsFixed(6)}, ${_location!.longitude.toStringAsFixed(6)}',
                      onTap: _pickLocation,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _Section(
                    p: p,
                    number: '05',
                    title: settings.t('Observations', 'නිරීක්ෂණ'),
                    subtitle: settings.t('Add important field notes.', 'වැදගත් ක්ෂේත්‍ර සටහන් එකතු කරන්න.'),
                    icon: Icons.notes_rounded,
                    child: TextField(
                      controller: _notes,
                      minLines: 4,
                      maxLines: 6,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: p.textPrimary),
                      decoration: _input(
                        p: p,
                        label: settings.t('Notes', 'සටහන්'),
                        hint: settings.t('Add observations, issues, or other details...', 'නිරීක්ෂණ, ගැටළු හෝ වෙනත් විස්තර එකතු කරන්න...'),
                        icon: Icons.edit_note_rounded,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                  ),
                ],
              ),
            ),

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
                  onPressed: _saving ? null : () => _save(settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    disabledBackgroundColor: p.primary.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            ),
                            const SizedBox(width: 10),
                            Text(settings.t('Saving...', 'සුරකිමින්...'), style: const TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(Icons.check_circle_outline_rounded),
                            const SizedBox(width: 8),
                            Text(
                              editing
                                  ? settings.t('Update Tapping Record', 'වාර්තාව යාවත්කාලීන කරන්න')
                                  : settings.t('Save Tapping Record', 'වාර්තාව සුරකින්න'),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

// ============================================================
// FORM WIDGETS
// ============================================================

class _FormIntro extends StatelessWidget {
  const _FormIntro({required this.p, required this.settings, required this.editing});

  final FarmerPalette p;
  final FarmerSettings settings;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: <Widget>[
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.water_drop_rounded, color: p.primary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  editing
                      ? settings.t('Update your record', 'ඔබේ වාර්තාව යාවත්කාලීන කරන්න')
                      : settings.t('Log a tapping session', 'ටැපිං සැසියක් සටහන් කරන්න'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: p.primaryDark),
                ),
                const SizedBox(height: 3),
                Text(
                  settings.t(
                    'Keep your field data accurate for better production tracking.',
                    'වඩා හොඳ නිෂ්පාදන ලුහුබැඳීම සඳහා ක්ෂේත්‍ර දත්ත නිවැරදිව තබාගන්න.',
                  ),
                  style: TextStyle(fontSize: 11.5, height: 1.35, color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.p,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final FarmerPalette p;
  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: p.primary, size: 19),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(number, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: p.primary)),
                        const SizedBox(width: 6),
                        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: p.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 10.5, color: p.textSecondary)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          child,
        ],
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.p,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final FarmerPalette p;
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 19, color: p.primary),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: TextStyle(fontSize: 9.5, color: p.textMuted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: p.textPrimary, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right_rounded, size: 18, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}

InputDecoration _input({
  required FarmerPalette p,
  required String label,
  required String hint,
  required IconData icon,
  String? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(color: p.textSecondary),
    hintStyle: TextStyle(color: p.textMuted),
    prefixIcon: Icon(icon, size: 19, color: p.textSecondary),
    suffixText: suffix,
    filled: true,
    fillColor: p.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: p.primary, width: 1.5),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.p, required this.text});

  final FarmerPalette p;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(11)),
      child: Row(
        children: <Widget>[
          Icon(Icons.timelapse_rounded, size: 16, color: p.primary),
          const SizedBox(width: 7),
          Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: p.primary)),
        ],
      ),
    );
  }
}

class _Yield extends StatelessWidget {
  const _Yield({required this.p, required this.settings, required this.value});

  final FarmerPalette p;
  final FarmerSettings settings;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: <Widget>[
          Icon(Icons.insights_rounded, color: p.primary),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              settings.t('Calculated average yield', 'ගණනය කළ සාමාන්‍ය අස්වැන්න'),
              style: TextStyle(fontSize: 11, color: p.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),

          Text(
            '${value.toStringAsFixed(3)} L/tree',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: p.primary),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.p, required this.icon, required this.text});

  final FarmerPalette p;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 16, color: p.primary),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: p.textPrimary)),
      ],
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.p,
    required this.settings,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final FarmerPalette p;
  final FarmerSettings settings;
  final List<_Condition> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final bool isSelected = option.name == selected;

        return GestureDetector(
          onTap: () => onSelected(option.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? option.color : option.color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? option.color : option.color.withOpacity(0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(option.icon, size: 16, color: isSelected ? Colors.white : option.color),
                const SizedBox(width: 6),
                Text(
                  settings.t(option.name, option.nameSi),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : p.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
