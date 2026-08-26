import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    // FarmerSettings is provided once, above the app's root Navigator (see
    // main.dart), so every route — including ones pushed from inside a tab,
    // like the tapping record form — stays a descendant of the scope.
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;

    // Bottom navigation is the only way to move between sections — each tab
    // already shows its own title in its header card, and account actions
    // (including logout) live on the Profile tab, so there is no separate
    // top app bar to duplicate that navigation.
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: _FarmerNavBar(
        palette: p,
        settings: settings,
        selectedIndex: _selectedIndex,
        onSelected: (int index) => setState(() => _selectedIndex = index),
      ),
    );
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
