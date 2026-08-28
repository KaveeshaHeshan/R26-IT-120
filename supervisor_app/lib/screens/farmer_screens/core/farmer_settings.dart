import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'farmer_theme.dart';

// ================================================================
// FARMER SETTINGS
// ================================================================
//
// A single, app-wide source of truth for the preferences exposed on
// the Profile screen (appearance + language). Every farmer screen
// reads from this notifier through `FarmerSettingsScope.of(context)`,
// so a change made in Profile is reflected everywhere immediately,
// and is persisted to disk so it survives app restarts.
// ================================================================

enum FarmerLanguage { english, sinhala }

class FarmerSettings extends ChangeNotifier {
  static const String _kDarkModeKey = 'farmer_dark_mode';
  static const String _kLanguageKey = 'farmer_language';

  bool _darkMode = false;
  FarmerLanguage _language = FarmerLanguage.english;
  bool _loaded = false;

  bool get darkMode => _darkMode;
  FarmerLanguage get language => _language;
  bool get loaded => _loaded;

  FarmerPalette get palette => FarmerPalette.of(dark: _darkMode);

  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    _darkMode = prefs.getBool(_kDarkModeKey) ?? false;
    _language = (prefs.getString(_kLanguageKey) == 'si')
        ? FarmerLanguage.sinhala
        : FarmerLanguage.english;
    _loaded = true;

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;

    _darkMode = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, value);
  }

  Future<void> setLanguage(FarmerLanguage value) async {
    if (_language == value) return;

    _language = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kLanguageKey,
      value == FarmerLanguage.sinhala ? 'si' : 'en',
    );
  }

  /// Translate helper: `t('English text', 'සිංහල පෙළ')`.
  String t(String english, String sinhala) {
    return _language == FarmerLanguage.sinhala ? sinhala : english;
  }
}

/// Provides [FarmerSettings] to the whole farmer-screen subtree and
/// rebuilds dependents automatically whenever it changes.
class FarmerSettingsScope extends InheritedNotifier<FarmerSettings> {
  const FarmerSettingsScope({
    required FarmerSettings settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static FarmerSettings of(BuildContext context) {
    final FarmerSettingsScope? scope =
        context.dependOnInheritedWidgetOfExactType<FarmerSettingsScope>();

    assert(scope != null, 'FarmerSettingsScope not found in context');

    return scope!.notifier!;
  }
}
