import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
        title: const Text(
          'Tapping History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please login first'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tapping_records')
                  .where('farmerId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                // No data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grass,
                            size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No tapping records yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first tapping record\nfrom the Tapping tab',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final records = snapshot.data!.docs;

                return Column(
                  children: [
                    // Summary card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryItem(
                            label: 'Total Records',
                            value: records.length.toString(),
                            icon: Icons.list_alt,
                          ),
                          _SummaryItem(
                            label: 'Total Latex',
                            value:
                                '${records.fold(0.0, (sum, doc) => sum + (doc['latexQuantity'] ?? 0)).toStringAsFixed(1)} kg',
                            icon: Icons.water_drop,
                          ),
                          _SummaryItem(
                            label: 'This Month',
                            value: records
                                .where((doc) {
                                  final date = DateTime.parse(
                                      doc['tappingDate'].toString());
                                  final now = DateTime.now();
                                  return date.month == now.month &&
                                      date.year == now.year;
                                })
                                .length
                                .toString(),
                            icon: Icons.calendar_month,
                          ),
                        ],
                      ),
                    ),

                    // Records list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final doc = records[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final date = DateTime.parse(
                              data['tappingDate'].toString());
                          final formattedDate =
                              '${date.day}/${date.month}/${date.year}';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.grass,
                                    color: Color(0xFF2E7D32)),
                              ),
                              title: Text(
                                'Tapping — $formattedDate',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                '${data['latexQuantity']} kg — ${data['tappingTime']}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                                  child: Column(
                                    children: [
                                      const Divider(),
                                      _DetailRow(
                                        icon: Icons.access_time,
                                        label: 'Tapping Time',
                                        value: data['tappingTime'] ?? '-',
                                      ),
                                      _DetailRow(
                                        icon: Icons.timer,
                                        label: 'Collection Time',
                                        value: data['collectionTime'] ?? '-',
                                      ),
                                      _DetailRow(
                                        icon: Icons.hourglass_bottom,
                                        label: 'Collection Gap',
                                        value:
                                            '${data['collectionGapHours']} hrs',
                                      ),
                                      _DetailRow(
                                        icon: Icons.water_drop,
                                        label: 'Latex Quantity',
                                        value: '${data['latexQuantity']} kg',
                                      ),
                                      _DetailRow(
                                        icon: Icons.science,
                                        label: 'Container Type',
                                        value: data['containerType'] ?? '-',
                                      ),
                                      _DetailRow(
                                        icon: Icons.water,
                                        label: 'Ammonia Added',
                                        value: (data['ammoniaAdded'] == true)
                                            ? 'Yes — ${data['ammoniaAmount']} ml'
                                            : 'No',
                                      ),
                                      if (data['notes'] != null &&
                                          data['notes'].toString().isNotEmpty)
                                        _DetailRow(
                                          icon: Icons.notes,
                                          label: 'Notes',
                                          value: data['notes'],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// Summary item widget
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _SummaryItem(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

// Detail row widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}