import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.userId, super.key});

  final String userId;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _openHistoryForm({
    String? docId,
    String? currentTitle,
    String? currentNote,
  }) async {
    final TextEditingController titleController =
        TextEditingController(text: currentTitle ?? '');
    final TextEditingController noteController =
        TextEditingController(text: currentNote ?? '');

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(docId == null ? 'Add History' : 'Edit History'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Note'),
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
                final String title = titleController.text.trim();
                final String note = noteController.text.trim();

                if (title.isEmpty) {
                  return;
                }

                final CollectionReference<Map<String, dynamic>> historyRef =
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('history');

                if (docId == null) {
                  await historyRef.add(<String, dynamic>{
                    'title': title,
                    'note': note,
                    'date': Timestamp.now(),
                    'updatedAt': Timestamp.now(),
                  });
                } else {
                  await historyRef.doc(docId).update(<String, dynamic>{
                    'title': title,
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

    titleController.dispose();
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
              .collection('history')
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
              return const Center(child: Text('Unable to load history.'));
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
                      child: Text('No history records available yet. Tap Add History to create one.'),
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
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.history, color: Colors.green.shade700),
                    ),
                    title: Text(_stringOrDefault(item['title'])),
                    subtitle: Text(
                      '${_formatDate(item['date'])}\n${_stringOrDefault(item['note'])}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _openHistoryForm(
                        docId: doc.id,
                        currentTitle: _stringOrDefault(item['title']),
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
            onPressed: () => _openHistoryForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add History'),
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
