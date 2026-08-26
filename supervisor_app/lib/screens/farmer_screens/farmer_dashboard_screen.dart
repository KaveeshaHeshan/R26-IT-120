import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login_screen.dart';
import 'core/farmer_connectivity_chip.dart';
import 'core/farmer_settings.dart';
import 'core/farmer_theme.dart';
import 'dashboard_home_screen.dart';
import 'profile_screen.dart';
import 'tapping_records_screen.dart';
import 'task_manager_screen.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({
    required this.userId,
    required this.welcomeMessage,
    super.key,
  });

  final String userId;
  final String welcomeMessage;

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = <Widget>[
    DashboardHomeScreen(
      userId: widget.userId,
      welcomeMessage: widget.welcomeMessage,
      onNavigateToTab: (int index) => setState(() => _selectedIndex = index),
    ),
    TaskManagerScreen(userId: widget.userId),
    TappingRecordsScreen(userId: widget.userId),
    ProfileScreen(userId: widget.userId),
  ];

  Future<void> _logout(FarmerSettings settings) async {
    final FarmerPalette p = settings.palette;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            settings.t('Log out?', 'ඉවත් වන්නද?'),
            style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w900),
          ),
          content: Text(
            settings.t("You'll need to sign in again to access the farmer app.", 'නැවත ඇතුළු වීමට අවශ්‍ය වේ.'),
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
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(settings.t('Log Out', 'ඉවත් වන්න')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // FarmerSettings is provided once, above the app's root Navigator (see
    // main.dart), so every route — including ones pushed from inside a tab,
    // like the tapping record form — stays a descendant of the scope.
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          _titleForIndex(settings, _selectedIndex),
          style: TextStyle(fontWeight: FontWeight.w900, color: p.textPrimary),
        ),
        actions: <Widget>[
          const FarmerConnectivityChip(),
          const SizedBox(width: 10),
          IconButton(
            tooltip: settings.t('Logout', 'ඉවත් වන්න'),
            onPressed: () => _logout(settings),
            icon: Icon(Icons.logout_rounded, color: p.textPrimary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _FarmerNavBar(
        palette: p,
        settings: settings,
        selectedIndex: _selectedIndex,
        onSelected: (int index) => setState(() => _selectedIndex = index),
      ),
    );
  }

  String _titleForIndex(FarmerSettings settings, int index) {
    switch (index) {
      case 1:
        return settings.t('Tasks', 'කාර්යයන්');
      case 2:
        return settings.t('Tapping Records', 'ටැපිං වාර්තා');
      case 3:
        return settings.t('Profile', 'පැතිකඩ');
      default:
        return settings.t('Farmer Dashboard', 'ගොවි උපකරණ පුවරුව');
    }
  }
}

// ============================================================
// CUSTOM INDUSTRIAL BOTTOM NAV
// ============================================================

class _FarmerNavBar extends StatelessWidget {
  const _FarmerNavBar({
    required this.palette,
    required this.settings,
    required this.selectedIndex,
    required this.onSelected,
  });

  final FarmerPalette palette;
  final FarmerSettings settings;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const List<IconData> _icons = <IconData>[
    Icons.home_rounded,
    Icons.checklist_rounded,
    Icons.water_drop_rounded,
    Icons.person_rounded,
  ];

  List<String> _labels() => <String>[
        settings.t('Home', 'මුල් පිටුව'),
        settings.t('Tasks', 'කාර්යයන්'),
        settings.t('Records', 'ලේඛන'),
        settings.t('Profile', 'පැතිකඩ'),
      ];

  @override
  Widget build(BuildContext context) {
    final List<String> labels = _labels();

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom > 0 ? 8 : 12, top: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: palette.shadow, blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(_icons.length, (int index) {
          final bool selected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onSelected(index),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? palette.primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(_icons[index], color: selected ? palette.primary : palette.textMuted, size: 23),
                  const SizedBox(height: 3),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? palette.primary : palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
