import 'package:flutter/material.dart';
import 'tapping_entry_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const TappingEntryScreen(),
    const HistoryScreen(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.grass), label: 'Tapping'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ───────────────────────────────────────────
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 55, 24, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning! 👋',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Mihisarani',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Today summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Trees', value: '250', icon: Icons.park),
                        _Divider(),
                        _StatItem(label: 'Land (Acres)', value: '3.5', icon: Icons.landscape),
                        _Divider(),
                        _StatItem(label: 'Today', value: 'Tap ✓', icon: Icons.check_circle),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _ActionCard(
                        icon: Icons.grass,
                        label: 'Tapping Entry',
                        color: const Color(0xFF2E7D32),
                        onTap: () {},
                      ),
                      _ActionCard(
                        icon: Icons.local_shipping,
                        label: 'Delivery',
                        color: const Color(0xFF1565C0),
                        onTap: () {},
                      ),
                      _ActionCard(
                        icon: Icons.science,
                        label: 'Quality Check',
                        color: const Color(0xFFE65100),
                        onTap: () {},
                      ),
                      _ActionCard(
                        icon: Icons.bar_chart,
                        label: 'View History',
                        color: const Color(0xFF6A1B9A),
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Activity
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _ActivityCard(
                    title: 'Tapping Completed',
                    subtitle: 'Latex collected: 4.5 kg',
                    time: 'Today 6:30 AM',
                    icon: Icons.grass,
                    color: const Color(0xFF2E7D32),
                  ),
                  _ActivityCard(
                    title: 'Delivery Made',
                    subtitle: 'Delivered to collection center',
                    time: 'Yesterday 2:00 PM',
                    icon: Icons.local_shipping,
                    color: const Color(0xFF1565C0),
                  ),
                  _ActivityCard(
                    title: 'Quality Alert',
                    subtitle: 'VFA level slightly high',
                    time: '2 days ago',
                    icon: Icons.warning,
                    color: const Color(0xFFE65100),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROFILE TAB ────────────────────────────────────────
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 55, 24, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mihisarani A K S',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Rubber Farmer', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ProfileItem(icon: Icons.credit_card, label: 'NIC', value: '200XXXXXXXX'),
                  _ProfileItem(icon: Icons.phone, label: 'Phone', value: '+94 7X XXX XXXX'),
                  _ProfileItem(icon: Icons.email, label: 'Email', value: 'mihisarani@email.com'),
                  _ProfileItem(icon: Icons.location_on, label: 'District', value: 'Kegalle'),
                  _ProfileItem(icon: Icons.landscape, label: 'Land Size', value: '3.5 Acres'),
                  _ProfileItem(icon: Icons.park, label: 'Rubber Trees', value: '250 Trees'),
                  _ProfileItem(icon: Icons.work, label: 'Experience', value: '3 - 5 years'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HELPER WIDGETS ─────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.white30);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  const _ActivityCard({
    required this.title, required this.subtitle,
    required this.time, required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}