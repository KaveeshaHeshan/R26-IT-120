import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>?> _loadFarmerDetails() async {
    final DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(widget.userId)
        .get();

    return userDoc.data();
  }

  Future<void> _openEditProfileForm(Map<String, dynamic> currentData) async {
    final TextEditingController nameController =
        TextEditingController(text: _stringOrDefault(currentData['name']));
    final TextEditingController phoneController =
        TextEditingController(text: _stringOrDefault(currentData['phone']));
    final TextEditingController addressController =
        TextEditingController(text: _stringOrDefault(currentData['address']));
    final TextEditingController districtController =
        TextEditingController(text: _stringOrDefault(currentData['district']));
    final TextEditingController landSizeController =
        TextEditingController(text: _stringOrDefault(currentData['landSize']));
    final TextEditingController rubberTreesController = TextEditingController(
      text: _stringOrDefault(currentData['rubberTrees']),
    );
    final TextEditingController experienceController = TextEditingController(
      text: _stringOrDefault(currentData['experience']),
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: districtController,
                  decoration: const InputDecoration(labelText: 'District'),
                ),
                TextField(
                  controller: landSizeController,
                  decoration: const InputDecoration(labelText: 'Land Size'),
                ),
                TextField(
                  controller: rubberTreesController,
                  decoration: const InputDecoration(labelText: 'Rubber Trees'),
                ),
                TextField(
                  controller: experienceController,
                  decoration: const InputDecoration(labelText: 'Experience'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final NavigatorState navigator =
                    Navigator.of(context, rootNavigator: true);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .update(<String, dynamic>{
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'address': addressController.text.trim(),
                  'district': districtController.text.trim(),
                  'landSize': landSizeController.text.trim(),
                  'rubberTrees': rubberTreesController.text.trim(),
                  'experience': experienceController.text.trim(),
                  'updatedAt': Timestamp.now(),
                });

                navigator.pop();
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    districtController.dispose();
    landSizeController.dispose();
    rubberTreesController.dispose();
    experienceController.dispose();
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
          return const Center(child: Text('Failed to load profile details.'));
        }

        final Map<String, dynamic> data = snapshot.data ?? <String, dynamic>{};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(Icons.person, color: Colors.green.shade700),
                ),
                title: Text(_stringOrDefault(data['name'])),
                subtitle: Text('Profile details • ${_stringOrDefault(data['district'])}'),
                trailing: ElevatedButton.icon(
                  onPressed: () => _openEditProfileForm(data),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _detailTile('Login ID (UID)', widget.userId),
            _detailTile('Name', _stringOrDefault(data['name'])),
            _detailTile('Email', _stringOrDefault(data['email'])),
            _detailTile('NIC', _stringOrDefault(data['nic'])),
            _detailTile('Phone', _stringOrDefault(data['phone'])),
            _detailTile('Address', _stringOrDefault(data['address'])),
            _detailTile('District', _stringOrDefault(data['district'])),
            _detailTile('Land Size', _stringOrDefault(data['landSize'])),
            _detailTile('Rubber Trees', _stringOrDefault(data['rubberTrees'])),
            _detailTile('Experience', _stringOrDefault(data['experience'])),
            _detailTile('Role', _stringOrDefault(data['role'])),
          ],
        );
      },
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
