import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({
    required this.userId,
    required this.welcomeMessage,
    required this.onNavigateToTab,
    super.key,
  });

  final String userId;
  final String welcomeMessage;
  final ValueChanged<int> onNavigateToTab;

  Future<Map<String, dynamic>?> _loadFarmerDetails() async {
    final DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(userId)
        .get();

    return userDoc.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadFarmerDetails(),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load dashboard data.'));
        }

        final Map<String, dynamic> data = snapshot.data ?? <String, dynamic>{};
        final String name = _stringOrDefault(data['name']);
        final String district = _stringOrDefault(data['district']);
        final String trees = _stringOrDefault(data['rubberTrees']);
        final String land = _stringOrDefault(data['landSize']);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF1B5E20), Color(0xFF2E7D32)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      welcomeMessage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Farmer: ${name == '-' ? 'Unknown' : name}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'District: ${district == '-' ? 'N/A' : district}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _statCard(
                    icon: Icons.park,
                    label: 'Rubber Trees',
                    value: trees,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    icon: Icons.landscape,
                    label: 'Land Size',
                    value: land,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _actionButton(
              icon: Icons.history,
              title: 'Open History',
              subtitle: 'View and add activity logs',
              onTap: () => onNavigateToTab(1),
            ),
            _actionButton(
              icon: Icons.agriculture,
              title: 'Open Tapping Records',
              subtitle: 'View and add daily latex records',
              onTap: () => onNavigateToTab(2),
            ),
            _actionButton(
              icon: Icons.person,
              title: 'Update Profile',
              subtitle: 'Edit your personal and farm details',
              onTap: () => onNavigateToTab(3),
            ),
            const SizedBox(height: 8),
            _detailTile('Login ID (UID)', userId),
            _detailTile('Farmer Name', name),
            _detailTile('District', district),
            _detailTile('Land Size', land),
            _detailTile('Rubber Trees', trees),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: Colors.green.shade700),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green.shade700),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(value.isEmpty ? '-' : value),
      ),
    );
  }

  String _stringOrDefault(dynamic value) {
    if (value == null) {
      return '-';
    }
    return value.toString();
  }
}
