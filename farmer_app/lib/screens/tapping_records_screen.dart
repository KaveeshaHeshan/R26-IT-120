import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TappingRecordsScreen extends StatefulWidget {
  const TappingRecordsScreen({required this.userId, super.key});

  final String userId;

  @override
  State<TappingRecordsScreen> createState() => _TappingRecordsScreenState();
}

class _TappingRecordsScreenState extends State<TappingRecordsScreen> {
  Future<void> _openRecordForm({
    String? docId,
    String? currentLatexKg,
    String? currentBlock,
    String? currentNote,
  }) async {
    final TextEditingController latexKgController =
        TextEditingController(text: currentLatexKg ?? '');
    final TextEditingController blockController =
        TextEditingController(text: currentBlock ?? '');
    final TextEditingController noteController =
        TextEditingController(text: currentNote ?? '');

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(docId == null ? 'Add Tapping Record' : 'Edit Tapping Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: latexKgController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Latex (kg)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: blockController,
                  decoration: const InputDecoration(labelText: 'Block / Field'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
                final String latexKg = latexKgController.text.trim();
                final String block = blockController.text.trim();
                final String note = noteController.text.trim();

                if (latexKg.isEmpty) {
                  return;
                }

                final CollectionReference<Map<String, dynamic>> tapRef =
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('tapping_records');

                if (docId == null) {
                  await tapRef.add(<String, dynamic>{
                    'latexKg': latexKg,
                    'block': block,
                    'note': note,
                    'date': Timestamp.now(),
                    'updatedAt': Timestamp.now(),
                  });
                } else {
                  await tapRef.doc(docId).update(<String, dynamic>{
                    'latexKg': latexKg,
                    'block': block,
                    'note': note,
                    'updatedAt': Timestamp.now(),
                  });
                }

                navigator.pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    latexKgController.dispose();
    blockController.dispose();
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('tapping_records')
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Unable to load tapping records.'));
            }

            final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            if (docs.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const <Widget>[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No tapping records available yet. Tap Add Record to create one.'),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: docs.length,
              itemBuilder: (BuildContext context, int index) {
                final QueryDocumentSnapshot<Map<String, dynamic>> doc = docs[index];
                final Map<String, dynamic> item = doc.data();
                final String amount = _stringOrDefault(item['latexKg']);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.agriculture, color: Colors.green.shade700),
                    ),
                    title: Text('Latex: $amount kg'),
                    subtitle: Text(
                      '${_formatDate(item['date'])}\nBlock: ${_stringOrDefault(item['block'])} | ${_stringOrDefault(item['note'])}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openRecordForm(
                        docId: doc.id,
                        currentLatexKg: _stringOrDefault(item['latexKg']),
                        currentBlock: _stringOrDefault(item['block']),
                        currentNote: _stringOrDefault(item['note']),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _openRecordForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add Record'),
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final DateTime dt = value.toDate();
      return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
    }
    return _stringOrDefault(value);
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _stringOrDefault(dynamic value) {
    if (value == null) {
      return '-';
    }
    return value.toString();
  }
}
