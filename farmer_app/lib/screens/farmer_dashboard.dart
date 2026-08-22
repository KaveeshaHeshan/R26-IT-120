import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashboard_home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'tapping_records_screen.dart';
import '../theme/app_theme.dart';

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
      onNavigateToTab: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    ),
    HistoryScreen(userId: widget.userId),
    TappingRecordsScreen(userId: widget.userId),
    ProfileScreen(userId: widget.userId),
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_selectedIndex)),
        actions: <Widget>[
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.pageBackground(),
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            label: 'Tapping Records',
          ),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    if (index == 1) {
      return 'History';
    }
    if (index == 2) {
      return 'Tapping Records';
    }
    if (index == 3) {
      return 'Profile';
    }
    return 'Farmer Dashboard';
  }
}
