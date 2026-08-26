import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/farmer_settings.dart';
import 'core/farmer_theme.dart';
import 'tapping_records_screen.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({
    required this.userId,
    required this.welcomeMessage,
    required this.onNavigateToTab,
    super.key,
  });

  final String userId;
  final String welcomeMessage;

  // Kept so your existing parent screen does not need to be changed.
  final ValueChanged<int> onNavigateToTab;

  // ------------------------------------------------------------
  // GOOGLE WEATHER API KEY
  // ------------------------------------------------------------
  //
  // IMPORTANT:
  // Replace this with your Google Weather API key.
  //
  // For a production app, do NOT leave a web-service key directly
  // in the Flutter source code. Use a secure backend/proxy.
  //
  static const String _googleApiKey = 'YOUR_GOOGLE_API_KEY';

  Future<Map<String, dynamic>?> _loadFarmerDetails() async {
    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    return userDoc.data();
  }

  // ------------------------------------------------------------
  // GET WEATHER USING FARMER ADDRESS
  // ------------------------------------------------------------

  Future<Map<String, dynamic>?> _loadWeatherFromAddress(String address) async {
    if (address.trim().isEmpty || address == 'Address not added') {
      return null;
    }

    if (_googleApiKey == 'YOUR_GOOGLE_API_KEY') {
      return null;
    }

    try {
      final Uri geocodeUrl = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        <String, String>{'address': address, 'key': _googleApiKey},
      );

      final http.Response geocodeResponse = await http.get(geocodeUrl).timeout(const Duration(seconds: 10));

      if (geocodeResponse.statusCode != 200) return null;

      final Map<String, dynamic> geocodeData = jsonDecode(geocodeResponse.body) as Map<String, dynamic>;

      final List<dynamic> results = geocodeData['results'] is List<dynamic>
          ? geocodeData['results'] as List<dynamic>
          : <dynamic>[];

      if (results.isEmpty) return null;

      final Map<String, dynamic> firstResult = results.first as Map<String, dynamic>;

      final Map<String, dynamic> geometry = firstResult['geometry'] is Map<String, dynamic>
          ? firstResult['geometry'] as Map<String, dynamic>
          : <String, dynamic>{};

      final Map<String, dynamic> location = geometry['location'] is Map<String, dynamic>
          ? geometry['location'] as Map<String, dynamic>
          : <String, dynamic>{};

      final dynamic latitude = location['lat'];
      final dynamic longitude = location['lng'];

      if (latitude == null || longitude == null) return null;

      final Uri weatherUrl = Uri.parse(
        'https://weather.googleapis.com/v1/currentConditions:lookup'
        '?key=${Uri.encodeQueryComponent(_googleApiKey)}'
        '&location.latitude=$latitude'
        '&location.longitude=$longitude',
      );

      final http.Response weatherResponse = await http.get(weatherUrl).timeout(const Duration(seconds: 10));

      if (weatherResponse.statusCode != 200) return null;

      return jsonDecode(weatherResponse.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _getTimeGreeting(FarmerSettings settings) {
    final int hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) return settings.t('Good morning', 'සුභ උදෑසනක්');
    if (hour >= 12 && hour < 17) return settings.t('Good afternoon', 'සුභ දහවලක්');
    if (hour >= 17 && hour < 21) return settings.t('Good evening', 'සුභ සන්ධ්‍යාවක්');

    return settings.t('Good night', 'සුභ රාත්‍රියක්');
  }

  @override
  Widget build(BuildContext context) {
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadFarmerDetails(),
      builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: p.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              settings.t('Failed to load dashboard data.', 'උපකරණ පුවරුව පූරණය කළ නොහැක.'),
              style: TextStyle(color: p.textPrimary),
            ),
          );
        }

        final Map<String, dynamic> data = snapshot.data ?? <String, dynamic>{};

        final String name = _stringOrDefault(data['name'], fallback: settings.t('Farmer', 'ගොවියා'));
        final String address = _stringOrDefault(data['address'], fallback: settings.t('Address not added', 'ලිපිනය එකතු කර නැත'));

        final List<dynamic> alerts = data['alerts'] is List<dynamic> ? data['alerts'] as List<dynamic> : <dynamic>[];

        final int notificationCount = _notificationCount(data);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            // =====================================================
            // HEADER
            // =====================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _getTimeGreeting(settings),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.textSecondary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        name,
                        style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: p.textPrimary),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: <Widget>[
                          Icon(Icons.location_on_outlined, size: 16, color: p.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: p.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(color: p.surface, shape: BoxShape.circle, border: Border.all(color: p.border)),
                      child: IconButton(
                        tooltip: settings.t('Notifications', 'දැනුම්දීම්'),
                        onPressed: () => _showNotifications(context, p, settings, alerts),
                        icon: Icon(Icons.notifications_none_rounded, size: 26, color: p.textPrimary),
                      ),
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: 3,
                        top: 1,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: p.danger, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            '$notificationCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =====================================================
            // QUICK ACTIONS
            // =====================================================
            _QuickActions(p: p, settings: settings, userId: userId, onNavigateToTab: onNavigateToTab),

            const SizedBox(height: 22),

            // =====================================================
            // ALERTS
            // =====================================================
            _sectionHeader(
              p,
              settings.t('Alerts', 'අනතුරු ඇඟවීම්'),
              alerts.isEmpty ? settings.t('No active alerts', 'ක්‍රියාකාරී අනතුරු ඇඟවීම් නැත') : settings.t('${alerts.length} active', '${alerts.length} ක්‍රියාකාරී'),
            ),

            const SizedBox(height: 10),

            if (alerts.isEmpty) _emptyAlert(p, settings) else ...alerts.take(3).map((a) => _alertTile(p, a)),

            const SizedBox(height: 22),

            // =====================================================
            // WEATHER
            // =====================================================
            FutureBuilder<Map<String, dynamic>?>(
              future: _loadWeatherFromAddress(address),
              builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> weatherSnapshot) {
                if (weatherSnapshot.connectionState == ConnectionState.waiting) {
                  return _weatherLoadingCard(settings, address);
                }

                final Map<String, dynamic> weather = weatherSnapshot.data ?? <String, dynamic>{};

                return _weatherCard(settings, weather, address);
              },
            ),

            const SizedBox(height: 14),

            // =====================================================
            // RUBBER MARKET
            // =====================================================
            _marketCard(p, settings, _mapValue(data['rubberMarket'])),

            const SizedBox(height: 22),

            // =====================================================
            // 7-DAY PRODUCTION TREND (unique feature)
            // =====================================================
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('tapping_details')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> tapSnapshot) {
                final List<QueryDocumentSnapshot<Map<String, dynamic>>> tapDocs =
                    tapSnapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                if (tapDocs.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: _ProductionSummaryCard(p: p, settings: settings, docs: tapDocs),
                );
              },
            ),

            // =====================================================
            // UPCOMING TASKS
            // =====================================================
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('tasks')
                  .orderBy('dueDate')
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> taskSnapshot) {
                final DateTime today = DateTime.now();

                final List<QueryDocumentSnapshot<Map<String, dynamic>>> tasks = taskSnapshot.data?.docs.where(
                      (QueryDocumentSnapshot<Map<String, dynamic>> task) {
                        final DateTime? dueDate = _taskDueDate(task.data()['dueDate']);
                        return !(task.data()['completed'] as bool? ?? false) &&
                            dueDate != null &&
                            !_isBeforeToday(dueDate, today) &&
                            (_isToday(dueDate) || _isTomorrow(dueDate));
                      },
                    ).toList() ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                final int tomorrowCount = tasks
                    .where((QueryDocumentSnapshot<Map<String, dynamic>> task) => _isTomorrow(_taskDueDate(task.data()['dueDate'])!))
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _sectionHeader(
                      p,
                      settings.t('Upcoming tasks', 'ඉදිරි කාර්යයන්'),
                      tomorrowCount > 0
                          ? settings.t('$tomorrowCount tomorrow', 'හෙට $tomorrowCount ක්')
                          : settings.t('${tasks.length} scheduled', '${tasks.length} සැලසුම් කර ඇත'),
                    ),
                    const SizedBox(height: 10),
                    if (taskSnapshot.connectionState == ConnectionState.waiting)
                      Center(child: CircularProgressIndicator(color: p.primary))
                    else if (tasks.isEmpty)
                      _emptyUpcomingTask(p, settings)
                    else
                      ...tasks.take(5).map((t) => _taskDocumentTile(p, settings, t)),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // UPCOMING TASK EMPTY CARD
  // ------------------------------------------------------------

  Widget _emptyUpcomingTask(FarmerPalette p, FarmerSettings settings) {
    return _card(
      p,
      Row(
        children: <Widget>[
          Icon(Icons.task_alt_outlined, color: p.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              settings.t('No upcoming tasks scheduled.', 'ඉදිරි කාර්යයන් සැලසුම් කර නැත.'),
              style: TextStyle(color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskDocumentTile(FarmerPalette p, FarmerSettings settings, QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final Map<String, dynamic> task = document.data();
    final DateTime? dueDate = _taskDueDate(task['dueDate']);
    final String details = _stringOrDefault(task['details'], fallback: '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: p.surfaceAlt,
          child: Icon(Icons.event_available_outlined, color: p.primary),
        ),
        title: Text(
          _stringOrDefault(task['title'], fallback: settings.t('Farm task', 'ගොවිපළ කාර්යය')),
          style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
        ),
        subtitle: Text(
          details.isEmpty ? '${settings.t('Due', 'නියමිත දිනය')} ${_formatTaskDate(dueDate!)}' : details,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: p.textSecondary),
        ),
        trailing: Text(
          _formatTaskDate(dueDate!),
          style: TextStyle(color: p.primary, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  DateTime? _taskDueDate(dynamic value) => value is Timestamp ? value.toDate() : null;

  bool _isTomorrow(DateTime date) {
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  bool _isBeforeToday(DateTime date, DateTime today) {
    final DateTime taskDay = DateTime(date.year, date.month, date.day);
    final DateTime currentDay = DateTime(today.year, today.month, today.day);
    return taskDay.isBefore(currentDay);
  }

  bool _isToday(DateTime date) {
    final DateTime today = DateTime.now();
    return date.year == today.year && date.month == today.month && date.day == today.day;
  }

  String _formatTaskDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------

  Widget _sectionHeader(FarmerPalette p, String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.textPrimary)),
        Text(trailing, style: TextStyle(fontSize: 12, color: p.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _card(FarmerPalette p, Widget child) {
    return Container(
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // WEATHER
  // ------------------------------------------------------------

  Widget _weatherLoadingCard(FarmerSettings settings, String address) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: <Color>[Color(0xFF176B73), Color(0xFF2E9B91)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                settings.t('FIELD WEATHER', 'ක්ෂේත්‍ර කාලගුණය'),
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
              const SizedBox(width: 12),
              Text(settings.t('Getting weather...', 'කාලගුණය ලබා ගනිමින්...'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(address, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _weatherCard(FarmerSettings settings, Map<String, dynamic> weather, String address) {
    final bool available = weather.isNotEmpty;

    final Map<String, dynamic> weatherCondition = _mapValue(weather['weatherCondition']);
    final Map<String, dynamic> description = _mapValue(weatherCondition['description']);
    final Map<String, dynamic> temperature = _mapValue(weather['temperature']);
    final Map<String, dynamic> wind = _mapValue(weather['wind']);
    final Map<String, dynamic> windSpeed = _mapValue(wind['speed']);

    final String temperatureValue = available ? '${_numberOrDefault(temperature['degrees'])}°' : '--°';
    final String condition = available
        ? _stringOrDefault(description['text'], fallback: settings.t('Current weather', 'වත්මන් කාලගුණය'))
        : settings.t('Weather unavailable', 'කාලගුණය නොමැත');
    final String humidity = available ? '${_numberOrDefault(weather['relativeHumidity'])}%' : '--';
    final String windValue = available ? '${_numberOrDefault(windSpeed['value'])} ${_stringOrDefault(windSpeed['unit'], fallback: '')}' : '--';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: <Color>[Color(0xFF176B73), Color(0xFF2E9B91)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                settings.t('FIELD WEATHER', 'ක්ෂේත්‍ර කාලගුණය'),
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(temperatureValue, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, height: .95)),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(condition, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            available ? address : settings.t('Weather could not be loaded for this address.', 'මෙම ලිපිනය සඳහා කාලගුණය ලබා ගත නොහැක.'),
            style: const TextStyle(color: Colors.white70),
          ),
          if (available) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _weatherMetric(Icons.water_drop_outlined, '$humidity ${settings.t('humidity', 'තෙතමනය')}'),
                const SizedBox(width: 20),
                _weatherMetric(Icons.air, '$windValue ${settings.t('wind', 'සුළං')}'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _weatherMetric(IconData icon, String label) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // ------------------------------------------------------------
  // RUBBER MARKET CARD
  // ------------------------------------------------------------

  Widget _marketCard(FarmerPalette p, FarmerSettings settings, Map<String, dynamic> market) {
    final bool available = market.isNotEmpty;

    return _card(
      p,
      Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.show_chart_rounded, color: p.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  settings.t('RUBBER MARKET', 'රබර් වෙළඳපොළ'),
                  style: TextStyle(fontSize: 11, color: p.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 5),
                Text(
                  available ? _stringOrDefault(market['place'], fallback: settings.t('Current market', 'වත්මන් වෙළඳපොළ')) : settings.t('Market data unavailable', 'වෙළඳපොළ දත්ත නොමැත'),
                  style: TextStyle(fontWeight: FontWeight.w700, color: p.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  available
                      ? '${settings.t('Updated', 'යාවත්කාලීන කළේ')} ${_stringOrDefault(market['updatedAt'], fallback: settings.t('recently', 'මෑතකදී'))}'
                      : settings.t('Connect a market feed to see prices', 'මිල දැක ගැනීමට වෙළඳපොළ සම්බන්ධ කරන්න'),
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            available ? _stringOrDefault(market['price'], fallback: '--') : '--',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.primary),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY ALERT / ALERT TILE
  // ------------------------------------------------------------

  Widget _emptyAlert(FarmerPalette p, FarmerSettings settings) {
    return _card(
      p,
      Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline, color: p.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              settings.t('You are all caught up. No active alerts.', 'ඔබ දැනටමත් යාවත්කාලීනයි. අනතුරු ඇඟවීම් නැත.'),
              style: TextStyle(color: p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertTile(FarmerPalette p, dynamic alert) {
    String text = 'New farm alert';
    String? subtitle;

    if (alert is Map<String, dynamic>) {
      text = _stringOrDefault(alert['message'] ?? alert['title'], fallback: 'New farm alert');

      final String date = _stringOrDefault(alert['date'] ?? alert['createdAt'], fallback: '');

      if (date.isNotEmpty) subtitle = date;
    } else {
      text = alert.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: p.warning),
        title: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: p.textPrimary)),
        subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: p.textSecondary)),
        dense: true,
      ),
    );
  }

  // ------------------------------------------------------------
  // NOTIFICATIONS
  // ------------------------------------------------------------

  void _showNotifications(BuildContext context, FarmerPalette p, FarmerSettings settings, List<dynamic> alerts) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: p.surface,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                settings.t('Notifications', 'දැනුම්දීම්'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: p.textPrimary),
              ),
              const SizedBox(height: 14),
              if (alerts.isEmpty)
                Text(settings.t('No new notifications.', 'නව දැනුම්දීම් නැත.'), style: TextStyle(color: p.textSecondary))
              else
                ...alerts.map((a) => _alertTile(p, a)),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  Map<String, dynamic> _mapValue(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

  int _notificationCount(Map<String, dynamic> data) {
    final dynamic count = data['notificationCount'];
    if (count is int) return count;

    final dynamic notifications = data['notifications'];
    if (notifications is List<dynamic>) return notifications.length;

    final dynamic alerts = data['alerts'];
    if (alerts is List<dynamic>) return alerts.length;

    return 0;
  }

  String _stringOrDefault(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;

    final String result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _numberOrDefault(dynamic value, {String fallback = '--'}) {
    if (value == null) return fallback;

    if (value is num) {
      if (value % 1 == 0) return value.toInt().toString();
      return value.toStringAsFixed(1);
    }

    final String result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }
}

// ============================================================
// QUICK ACTIONS (unique feature)
// ============================================================

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.p,
    required this.settings,
    required this.userId,
    required this.onNavigateToTab,
  });

  final FarmerPalette p;
  final FarmerSettings settings;
  final String userId;
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.add_circle_outline_rounded,
            label: settings.t('Add Record', 'වාර්තාව'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TappingRecordFormScreen(userId: userId)),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.add_task_rounded,
            label: settings.t('New Task', 'කාර්යය'),
            onTap: () => onNavigateToTab(1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            context,
            icon: Icons.water_drop_outlined,
            label: settings.t('Records', 'ලේඛන'),
            onTap: () => onNavigateToTab(2),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: p.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRODUCTION SUMMARY (unique feature) — last 7 days at a glance
// ============================================================

class _ProductionSummaryCard extends StatelessWidget {
  const _ProductionSummaryCard({required this.p, required this.settings, required this.docs});

  final FarmerPalette p;
  final FarmerSettings settings;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  @override
  Widget build(BuildContext context) {
    final DateTime cutoff = DateTime.now().subtract(const Duration(days: 7));

    double weekVolume = 0;
    int weekSessions = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
      final dynamic rawDate = doc.data()['date'];
      final DateTime? date = rawDate is Timestamp ? rawDate.toDate() : null;

      if (date == null || date.isBefore(cutoff)) continue;

      weekSessions++;

      final dynamic volume = doc.data()['latexVolumeL'];
      if (volume is num) weekVolume += volume.toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: p.border)),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.trending_up_rounded, color: p.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  settings.t('LAST 7 DAYS', 'පසුගිය දින 7'),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: p.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.t(
                    '${weekVolume.toStringAsFixed(1)} L from $weekSessions session${weekSessions == 1 ? '' : 's'}',
                    'සැසි $weekSessions කින් ලැටෙක්ස් ${weekVolume.toStringAsFixed(1)} L',
                  ),
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
