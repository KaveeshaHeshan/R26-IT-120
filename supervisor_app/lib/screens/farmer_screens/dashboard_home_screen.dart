import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/farmer_connectivity_chip.dart';
import 'core/farmer_settings.dart';
import 'core/farmer_theme.dart';

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
  // Supplied at build time. Enable both Geocoding API and Weather API for
  // this restricted key: --dart-define=GOOGLE_WEATHER_API_KEY=...
  static const String _googleApiKey = String.fromEnvironment('GOOGLE_WEATHER_API_KEY');

  // RRISL is the official source for Colombo auction prices. For Flutter web,
  // configure a same-origin CORS proxy with RUBBER_MARKET_FEED_URL if needed.
  static const String _rubberMarketFeedUrl = String.fromEnvironment(
    'RUBBER_MARKET_FEED_URL',
    defaultValue: 'https://www.anrpc.org/anrpc-daily-price',
  );

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

    if (_googleApiKey.isEmpty) {
      return _loadOpenMeteoWeather(address);
    }

    try {
      final Uri geocodeUrl = Uri.https(
        'maps.googleapis.com',
        '/maps/api/geocode/json',
        <String, String>{'address': address, 'key': _googleApiKey},
      );

      final http.Response geocodeResponse = await http.get(geocodeUrl).timeout(const Duration(seconds: 10));

      if (geocodeResponse.statusCode != 200) return _loadOpenMeteoWeather(address);

      final Map<String, dynamic> geocodeData = jsonDecode(geocodeResponse.body) as Map<String, dynamic>;

      final List<dynamic> results = geocodeData['results'] is List<dynamic>
          ? geocodeData['results'] as List<dynamic>
          : <dynamic>[];

      if (results.isEmpty) return _loadOpenMeteoWeather(address);

      final Map<String, dynamic> firstResult = results.first as Map<String, dynamic>;

      final Map<String, dynamic> geometry = firstResult['geometry'] is Map<String, dynamic>
          ? firstResult['geometry'] as Map<String, dynamic>
          : <String, dynamic>{};

      final Map<String, dynamic> location = geometry['location'] is Map<String, dynamic>
          ? geometry['location'] as Map<String, dynamic>
          : <String, dynamic>{};

      final dynamic latitude = location['lat'];
      final dynamic longitude = location['lng'];

      if (latitude == null || longitude == null) return _loadOpenMeteoWeather(address);

      final Uri weatherUrl = Uri.https(
        'weather.googleapis.com',
        '/v1/currentConditions:lookup',
        <String, String>{
          'key': _googleApiKey,
          'location.latitude': latitude.toString(),
          'location.longitude': longitude.toString(),
          'unitsSystem': 'METRIC',
          'languageCode': 'en',
        },
      );

      final http.Response weatherResponse = await http.get(weatherUrl).timeout(const Duration(seconds: 10));

      if (weatherResponse.statusCode != 200) return _loadOpenMeteoWeather(address);

      return jsonDecode(weatherResponse.body) as Map<String, dynamic>;
    } catch (_) {
      return _loadOpenMeteoWeather(address);
    }
  }

  Future<Map<String, dynamic>?> _loadOpenMeteoWeather(String address) async {
    try {
      final Uri geocodeUrl = Uri.https('geocoding-api.open-meteo.com', '/v1/search', <String, String>{'name': address, 'count': '1'});
      final http.Response geocodeResponse = await http.get(geocodeUrl).timeout(const Duration(seconds: 10));
      if (geocodeResponse.statusCode != 200) return null;
      final Map<String, dynamic> geocode = jsonDecode(geocodeResponse.body) as Map<String, dynamic>;
      final List<dynamic> results = geocode['results'] is List<dynamic> ? geocode['results'] as List<dynamic> : <dynamic>[];
      if (results.isEmpty) return null;
      final Map<String, dynamic> location = results.first as Map<String, dynamic>;
      final Uri weatherUrl = Uri.https('api.open-meteo.com', '/v1/forecast', <String, String>{
        'latitude': location['latitude'].toString(),
        'longitude': location['longitude'].toString(),
        'current': 'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
        'wind_speed_unit': 'kmh',
      });
      final http.Response weatherResponse = await http.get(weatherUrl).timeout(const Duration(seconds: 10));
      if (weatherResponse.statusCode != 200) return null;
      final Map<String, dynamic> weather = jsonDecode(weatherResponse.body) as Map<String, dynamic>;
      final Map<String, dynamic> current = weather['current'] is Map<String, dynamic> ? weather['current'] as Map<String, dynamic> : <String, dynamic>{};
      final int code = current['weather_code'] is num ? (current['weather_code'] as num).toInt() : -1;
      final String description = code == 0 ? 'Clear sky' : code <= 2 ? 'Partly cloudy' : code == 3 ? 'Overcast' : code >= 95 ? 'Thunderstorm' : code >= 80 ? 'Rain showers' : code >= 51 ? 'Rain' : 'Current weather';
      return <String, dynamic>{
        'weatherCondition': <String, dynamic>{'description': <String, dynamic>{'text': description}},
        'temperature': <String, dynamic>{'degrees': current['temperature_2m']},
        'relativeHumidity': current['relative_humidity_2m'],
        'wind': <String, dynamic>{'speed': <String, dynamic>{'value': current['wind_speed_10m'], 'unit': 'km/h'}},
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadRubberMarketPrice() async {
    try {
      final http.Response response = await http.get(Uri.parse(_rubberMarketFeedUrl)).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;

      final String body = response.body.trim();
      if (body.startsWith('{')) {
        final Map<String, dynamic> market = jsonDecode(body) as Map<String, dynamic>;
        final dynamic price = market['price'] ?? market['priceLkr'] ?? market['rss3Price'];
        if (price == null) return null;
        return <String, dynamic>{
          'place': _stringOrDefault(market['place'] ?? market['market'], fallback: 'Colombo auction'),
          'price': price is num ? 'LKR ${price.toStringAsFixed(2)} / kg' : price.toString(),
          'updatedAt': _stringOrDefault(market['updatedAt'] ?? market['date'], fallback: 'latest auction'),
        };
      }

      final String text = body.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll('&nbsp;', ' ').replaceAll(RegExp(r'\s+'), ' ');
      final RegExpMatch? date = RegExp(r'Date of Auction\s*:?\s*([0-9]{2}-[0-9]{2}-[0-9]{4})', caseSensitive: false).firstMatch(text);
      final RegExpMatch? price = RegExp(r'(?:RSS\s*3|RSS\s*1|RSS\s*2|RSS\s*4|Latex Crepe)[^0-9]{0,80}([0-9]{2,3}(?:\.[0-9]{1,2})?)', caseSensitive: false).firstMatch(text);
      if (price == null) return null;

      return <String, dynamic>{
        'place': 'ANRPC RSS3 market',
        'price': 'USD ${price.group(1)} / kg',
        'updatedAt': date?.group(1) ?? 'latest market update',
      };
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

    return FarmerScreenBackground(child: FutureBuilder<Map<String, dynamic>?>(
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

        final List<dynamic> savedAlerts = data['alerts'] is List<dynamic> ? data['alerts'] as List<dynamic> : <dynamic>[];

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _watchLstmForecastAlerts(),
          builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> modelSnapshot) {
            final List<dynamic> alerts = <dynamic>[...savedAlerts, ...(modelSnapshot.data ?? <Map<String, dynamic>>[])];
            final int notificationCount = _notificationCount(data, alerts);

            return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            // =====================================================
            // HEADER
            // =====================================================
            Align(
              alignment: Alignment.centerRight,
              child: FarmerConnectivityChip(),
            ),

            const SizedBox(height: 10),

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
            FutureBuilder<Map<String, dynamic>?>(
              future: _loadRubberMarketPrice(),
              builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> marketSnapshot) {
                if (marketSnapshot.connectionState == ConnectionState.waiting) {
                  return _marketLoadingCard(p, settings);
                }
                return _marketCard(p, settings, marketSnapshot.data ?? <String, dynamic>{});
              },
            ),

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
      },
    ));
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

  Widget _marketLoadingCard(FarmerPalette p, FarmerSettings settings) {
    return _card(
      p,
      Row(
        children: <Widget>[
          SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: p.primary)),
          const SizedBox(width: 14),
          Text(settings.t('Loading Colombo auction prices...', 'වෙළඳපොළ මිල පූරණය කරමින්...'), style: TextStyle(color: p.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

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
    String severity = '';

    if (alert is Map<String, dynamic>) {
      text = _stringOrDefault(alert['message'] ?? alert['title'], fallback: 'New farm alert');
      severity = _stringOrDefault(alert['severity'], fallback: '').toLowerCase();

      final String date = _stringOrDefault(alert['date'] ?? alert['createdAt'], fallback: '');

      if (date.isNotEmpty) subtitle = date;
    } else {
      text = alert.toString();
    }

    final bool isCritical = severity == 'critical' || severity == 'high';
    final Color alertColor = isCritical ? p.danger : p.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(p.isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: alertColor.withOpacity(0.28)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: alertColor.withOpacity(0.14), shape: BoxShape.circle),
          child: Icon(isCritical ? Icons.priority_high_rounded : Icons.info_outline_rounded, color: alertColor, size: 20),
        ),
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

  /// Reads only this component's LSTM forecast result. It deliberately does
  /// not subscribe to the VFA, anomaly-detection, or route-model collections.
  ///
  /// Expected document: `quality_forecasts/{farmer Firebase UID}`
  /// Required fields: `riskLevel` and/or `predictedVfa`.
  /// Optional fields: `forecastDate`, `trend`, `updatedAt`.
  Stream<List<Map<String, dynamic>>> _watchLstmForecastAlerts() {
    return FirebaseFirestore.instance.collection('quality_forecasts').doc(userId).snapshots().map(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        final Map<String, dynamic>? forecast = snapshot.data();
        if (forecast == null) return <Map<String, dynamic>>[];

        final String risk = _stringOrDefault(forecast['riskLevel'] ?? forecast['risk_level'], fallback: '').toLowerCase();
        final String trend = _stringOrDefault(forecast['trend'], fallback: '');
        final num? predictedVfa = forecast['predictedVfa'] is num
            ? forecast['predictedVfa'] as num
            : forecast['predicted_vfa'] is num
                ? forecast['predicted_vfa'] as num
                : num.tryParse(_stringOrDefault(forecast['predictedVfa'] ?? forecast['predicted_vfa'], fallback: ''));
        final num? riskProbability = forecast['riskProbability'] is num
            ? forecast['riskProbability'] as num
            : forecast['risk_probability'] is num
                ? forecast['risk_probability'] as num
                : num.tryParse(_stringOrDefault(forecast['riskProbability'] ?? forecast['risk_probability'], fallback: ''));
        const double vfaAlertThreshold = 0.06;
        const double riskProbabilityThreshold = 0.28;
        final bool needsAlert = risk == 'medium' ||
            risk == 'high' ||
            risk == 'critical' ||
            (predictedVfa != null && predictedVfa >= vfaAlertThreshold) ||
            (riskProbability != null && riskProbability >= riskProbabilityThreshold);
        if (!needsAlert) return <Map<String, dynamic>>[];

        final bool isHighRisk = risk == 'critical' ||
            risk == 'high' ||
            (predictedVfa != null && predictedVfa >= vfaAlertThreshold);
        final String label = isHighRisk ? 'LSTM quality forecast alert' : 'LSTM quality forecast notice';
        final String date = _stringOrDefault(forecast['forecastDate'] ?? forecast['forecast_date'], fallback: 'the next collection');
        final DateTime? updatedAt = forecast['updatedAt'] is Timestamp
            ? (forecast['updatedAt'] as Timestamp).toDate()
            : forecast['updated_at'] is Timestamp
                ? (forecast['updated_at'] as Timestamp).toDate()
                : null;

        return <Map<String, dynamic>>[
          <String, dynamic>{
            'title': label,
            'message': 'Forecast for $date: ${predictedVfa == null ? 'quality risk is $risk' : 'predicted VFA is ${predictedVfa.toStringAsFixed(3)}'}${riskProbability == null ? '' : ' (risk probability: ${(riskProbability * 100).toStringAsFixed(0)}%)'}${trend.isEmpty ? '' : ' ($trend trend)'}.',
            'createdAt': updatedAt?.toIso8601String() ?? '',
            'severity': risk,
            'source': 'lstm_quality_forecast',
          },
        ];
      },
    );
  }

  Map<String, dynamic> _mapValue(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};

  int _notificationCount(Map<String, dynamic> data, [List<dynamic>? activeAlerts]) {
    if (activeAlerts != null) return activeAlerts.length;

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
