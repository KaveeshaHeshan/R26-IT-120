import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';

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
      // First convert the farmer's address into latitude/longitude.
      final Uri geocodeUrl = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        <String, String>{'address': address, 'key': _googleApiKey},
      );

      final http.Response geocodeResponse = await http
          .get(geocodeUrl)
          .timeout(const Duration(seconds: 10));

      if (geocodeResponse.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> geocodeData =
          jsonDecode(geocodeResponse.body) as Map<String, dynamic>;

      final List<dynamic> results = geocodeData['results'] is List<dynamic>
          ? geocodeData['results'] as List<dynamic>
          : <dynamic>[];

      if (results.isEmpty) {
        return null;
      }

      final Map<String, dynamic> firstResult =
          results.first as Map<String, dynamic>;

      final Map<String, dynamic> geometry =
          firstResult['geometry'] is Map<String, dynamic>
          ? firstResult['geometry'] as Map<String, dynamic>
          : <String, dynamic>{};

      final Map<String, dynamic> location =
          geometry['location'] is Map<String, dynamic>
          ? geometry['location'] as Map<String, dynamic>
          : <String, dynamic>{};

      final dynamic latitude = location['lat'];
      final dynamic longitude = location['lng'];

      if (latitude == null || longitude == null) {
        return null;
      }

      // ----------------------------------------------------------
      // GET CURRENT WEATHER FROM GOOGLE WEATHER API
      // ----------------------------------------------------------

      final Uri weatherUrl = Uri.parse(
        'https://weather.googleapis.com/v1/currentConditions:lookup'
        '?key=${Uri.encodeQueryComponent(_googleApiKey)}'
        '&location.latitude=$latitude'
        '&location.longitude=$longitude',
      );

      final http.Response weatherResponse = await http
          .get(weatherUrl)
          .timeout(const Duration(seconds: 10));

      if (weatherResponse.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> weatherData =
          jsonDecode(weatherResponse.body) as Map<String, dynamic>;

      return weatherData;
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // DYNAMIC GREETING
  // ------------------------------------------------------------

  String _getTimeGreeting() {
    final int hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    }

    if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    }

    if (hour >= 17 && hour < 21) {
      return 'Good evening';
    }

    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadFarmerDetails(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<Map<String, dynamic>?> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Failed to load dashboard data.'),
              );
            }

            final Map<String, dynamic> data =
                snapshot.data ?? <String, dynamic>{};

            final String name = _stringOrDefault(
              data['name'],
              fallback: 'Farmer',
            );

            final String address = _stringOrDefault(
              data['address'],
              fallback: 'Address not added',
            );

            final List<dynamic> alerts = data['alerts'] is List<dynamic>
                ? data['alerts'] as List<dynamic>
                : <dynamic>[];

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
                            _getTimeGreeting(),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: AppColors.muted),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Notification button
                    Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => _showNotifications(context, alerts),
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 28,
                          ),
                        ),

                        if (notificationCount > 0)
                          Positioned(
                            right: 5,
                            top: 3,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD94D3F),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // =====================================================
                // 1. ALERTS — FIRST CARD
                // =====================================================
                _sectionHeader(
                  'Alerts',
                  alerts.isEmpty
                      ? 'No active alerts'
                      : '${alerts.length} active',
                ),

                const SizedBox(height: 10),

                if (alerts.isEmpty)
                  _emptyAlert()
                else
                  ...alerts.take(3).map(_alertTile),

                const SizedBox(height: 22),

                // =====================================================
                // 2. WEATHER BASED ON FARMER ADDRESS
                // =====================================================
                FutureBuilder<Map<String, dynamic>?>(
                  future: _loadWeatherFromAddress(address),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<Map<String, dynamic>?> weatherSnapshot,
                      ) {
                        if (weatherSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _weatherLoadingCard(address);
                        }

                        final Map<String, dynamic> weather =
                            weatherSnapshot.data ?? <String, dynamic>{};

                        return _weatherCard(context, weather, address);
                      },
                ),

                const SizedBox(height: 14),

                // =====================================================
                // RUBBER MARKET
                // =====================================================
                finalMarketCard(data),

                const SizedBox(height: 22),

                // =====================================================
                // 3. FARM OVERVIEW -> UPCOMING TASKS
                // =====================================================
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('tasks')
                      .orderBy('dueDate')
                      .snapshots(),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                        taskSnapshot,
                      ) {
                        final DateTime today = DateTime.now();
                        final List<QueryDocumentSnapshot<Map<String, dynamic>>>
                        tasks =
                            taskSnapshot.data?.docs.where((
                              QueryDocumentSnapshot<Map<String, dynamic>> task,
                            ) {
                              final DateTime? dueDate = _taskDueDate(
                                task.data()['dueDate'],
                              );
                              return !(task.data()['completed'] as bool? ??
                                      false) &&
                                  dueDate != null &&
                                  !_isBeforeToday(dueDate, today);
                            }).toList() ??
                            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                        final int tomorrowCount = tasks
                            .where(
                              (
                                QueryDocumentSnapshot<Map<String, dynamic>>
                                task,
                              ) => _isTomorrow(
                                _taskDueDate(task.data()['dueDate'])!,
                              ),
                            )
                            .length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _sectionHeader(
                              'Upcoming tasks',
                              tomorrowCount > 0
                                  ? '$tomorrowCount tomorrow'
                                  : '${tasks.length} scheduled',
                            ),
                            const SizedBox(height: 10),
                            if (taskSnapshot.connectionState ==
                                ConnectionState.waiting)
                              const Center(child: CircularProgressIndicator())
                            else if (tasks.isEmpty)
                              _emptyUpcomingTask()
                            else
                              ...tasks.take(5).map(_taskDocumentTile),
                          ],
                        );
                      },
                ),

                // =====================================================
                // QUICK ACTIONS REMOVED
                // =====================================================
              ],
            );
          },
    );
  }

  // ------------------------------------------------------------
  // MARKET CARD
  // ------------------------------------------------------------

  Widget finalMarketCard(Map<String, dynamic> data) {
    final Map<String, dynamic> market = _mapValue(data['rubberMarket']);

    return _marketCard(market);
  }

  // ------------------------------------------------------------
  // UPCOMING TASK EMPTY CARD
  // ------------------------------------------------------------

  Widget _emptyUpcomingTask() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const <Widget>[
            Icon(Icons.task_alt_outlined, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(child: Text('No upcoming tasks scheduled.')),
          ],
        ),
      ),
    );
  }

  Widget _taskDocumentTile(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> task = document.data();
    final DateTime? dueDate = _taskDueDate(task['dueDate']);
    final String details = _stringOrDefault(task['details'], fallback: '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE7F3E8),
          child: Icon(Icons.event_available_outlined, color: AppColors.primary),
        ),
        title: Text(
          _stringOrDefault(task['title'], fallback: 'Farm task'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          details.isEmpty ? 'Due ${_formatTaskDate(dueDate!)}' : details,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTaskDate(dueDate!),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  DateTime? _taskDueDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  bool _isTomorrow(DateTime date) {
    final DateTime tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  bool _isBeforeToday(DateTime date, DateTime today) {
    final DateTime taskDay = DateTime(date.year, date.month, date.day);
    final DateTime currentDay = DateTime(today.year, today.month, today.day);
    return taskDay.isBefore(currentDay);
  }

  String _formatTaskDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------
  // SECTION HEADER
  // ------------------------------------------------------------

  Widget _sectionHeader(String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        Text(
          trailing,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // WEATHER LOADING CARD
  // ------------------------------------------------------------

  Widget _weatherLoadingCard(String address) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF176B73), Color(0xFF2E9B91)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'FIELD WEATHER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Row(
            children: <Widget>[
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Getting weather...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(address, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // WEATHER CARD
  // ------------------------------------------------------------

  Widget _weatherCard(
    BuildContext context,
    Map<String, dynamic> weather,
    String address,
  ) {
    final bool available = weather.isNotEmpty;

    final Map<String, dynamic> weatherCondition = _mapValue(
      weather['weatherCondition'],
    );

    final Map<String, dynamic> description = _mapValue(
      weatherCondition['description'],
    );

    final Map<String, dynamic> temperature = _mapValue(weather['temperature']);

    final Map<String, dynamic> wind = _mapValue(weather['wind']);

    final Map<String, dynamic> windSpeed = _mapValue(wind['speed']);

    final String temperatureValue = available
        ? '${_numberOrDefault(temperature['degrees'])}°'
        : '--°';

    final String condition = available
        ? _stringOrDefault(description['text'], fallback: 'Current weather')
        : 'Weather unavailable';

    final String humidity = available
        ? '${_numberOrDefault(weather['relativeHumidity'])}%'
        : '--';

    final String windValue = available
        ? '${_numberOrDefault(windSpeed['value'])} '
              '${_stringOrDefault(windSpeed['unit'], fallback: '')}'
        : '--';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF176B73), Color(0xFF2E9B91)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'FIELD WEATHER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                temperatureValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: .95,
                ),
              ),

              const SizedBox(width: 12),

              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  condition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            available
                ? address
                : 'Weather could not be loaded for this address.',
            style: const TextStyle(color: Colors.white70),
          ),

          if (available) ...<Widget>[
            const SizedBox(height: 14),

            Row(
              children: <Widget>[
                _weatherMetric(Icons.water_drop_outlined, '$humidity humidity'),

                const SizedBox(width: 20),

                _weatherMetric(Icons.air, '$windValue wind'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // WEATHER METRIC
  // ------------------------------------------------------------

  Widget _weatherMetric(IconData icon, String label) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // RUBBER MARKET CARD
  // ------------------------------------------------------------

  Widget _marketCard(Map<String, dynamic> market) {
    final bool available = market.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE7F3E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.show_chart_rounded,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'RUBBER MARKET',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    available
                        ? _stringOrDefault(
                            market['place'],
                            fallback: 'Current market',
                          )
                        : 'Market data unavailable',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    available
                        ? 'Updated ${_stringOrDefault(market['updatedAt'], fallback: 'recently')}'
                        : 'Connect a market feed to see prices',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              available
                  ? _stringOrDefault(market['price'], fallback: '--')
                  : '--',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY ALERT
  // ------------------------------------------------------------

  Widget _emptyAlert() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const <Widget>[
            Icon(Icons.check_circle_outline, color: AppColors.primary),
            SizedBox(width: 12),
            Expanded(child: Text('You are all caught up. No active alerts.')),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ALERT TILE
  // ------------------------------------------------------------

  Widget _alertTile(dynamic alert) {
    String text = 'New farm alert';
    String? subtitle;

    if (alert is Map<String, dynamic>) {
      text = _stringOrDefault(
        alert['message'] ?? alert['title'],
        fallback: 'New farm alert',
      );

      final String date = _stringOrDefault(
        alert['date'] ?? alert['createdAt'],
        fallback: '',
      );

      if (date.isNotEmpty) {
        subtitle = date;
      }
    } else {
      text = alert.toString();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFB87816),
        ),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle),
        dense: true,
      ),
    );
  }

  // ------------------------------------------------------------
  // NOTIFICATIONS
  // ------------------------------------------------------------

  void _showNotifications(BuildContext context, List<dynamic> alerts) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 14),

              if (alerts.isEmpty)
                const Text('No new notifications.')
              else
                ...alerts.map(_alertTile),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  Map<String, dynamic> _mapValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    return <String, dynamic>{};
  }

  int _notificationCount(Map<String, dynamic> data) {
    final dynamic count = data['notificationCount'];

    if (count is int) {
      return count;
    }

    final dynamic notifications = data['notifications'];

    if (notifications is List<dynamic>) {
      return notifications.length;
    }

    final dynamic alerts = data['alerts'];

    if (alerts is List<dynamic>) {
      return alerts.length;
    }

    return 0;
  }

  String _stringOrDefault(dynamic value, {String fallback = '-'}) {
    if (value == null) {
      return fallback;
    }

    final String result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  String _numberOrDefault(dynamic value, {String fallback = '--'}) {
    if (value == null) {
      return fallback;
    }

    if (value is num) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }

      return value.toStringAsFixed(1);
    }

    final String result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }
}
