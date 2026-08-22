import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({required this.userId, super.key});

  final String userId;

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  Future<void> _openTaskForm({
    String? docId,
    String? currentTitle,
    String? currentDetails,
    DateTime? currentDueDate,
    bool completed = false,
  }) async {
    final TextEditingController titleController = TextEditingController(
      text: currentTitle ?? '',
    );
    final TextEditingController detailsController = TextEditingController(
      text: currentDetails ?? '',
    );
    DateTime? dueDate = currentDueDate;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(docId == null ? 'Create Task' : 'Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Task title',
                        prefixIcon: Icon(Icons.task_alt_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailsController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Details',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: Text(
                        dueDate == null
                            ? 'Due date required'
                            : 'Due ${_formatDate(dueDate)}',
                      ),
                      trailing: IconButton(
                        tooltip: 'Choose due date',
                        onPressed: () async {
                          final DateTime today = DateTime.now();
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime(today.year - 1),
                            lastDate: DateTime(today.year + 5),
                            initialDate: dueDate ?? today,
                          );
                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
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
                    final NavigatorState navigator = Navigator.of(
                      context,
                      rootNavigator: true,
                    );
                    final String title = titleController.text.trim();
                    final String details = detailsController.text.trim();

                    if (title.isEmpty || dueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a task title and choose a due date.',
                          ),
                        ),
                      );
                      return;
                    }

                    final CollectionReference<Map<String, dynamic>> tasksRef =
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .collection('tasks');

                    if (docId == null) {
                      await tasksRef.add(<String, dynamic>{
                        'title': title,
                        'details': details,
                        'dueDate': Timestamp.fromDate(dueDate!),
                        'completed': false,
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await tasksRef.doc(docId).update(<String, dynamic>{
                        'title': title,
                        'details': details,
                        'dueDate': Timestamp.fromDate(dueDate!),
                        'updatedAt': FieldValue.serverTimestamp(),
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
      },
    );

    titleController.dispose();
    detailsController.dispose();
  }

  Future<void> _toggleTask(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    await document.reference.update(<String, dynamic>{
      'completed': !(document.data()['completed'] as bool? ?? false),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteTask(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This task will be permanently removed.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await document.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('tasks')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load tasks.'));
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
                          child: Text(
                            'No tasks available yet. Tap New Task to create one.',
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final QueryDocumentSnapshot<Map<String, dynamic>> doc =
                        docs[index];
                    final Map<String, dynamic> item = doc.data();
                    final bool completed = item['completed'] as bool? ?? false;
                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: completed,
                          onChanged: (_) => _toggleTask(doc),
                        ),
                        title: Text(
                          _stringOrDefault(item['title']),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          '${_formatDate(item['createdAt'])}\n${_stringOrDefault(item['details'])}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (String action) {
                            if (action == 'edit') {
                              _openTaskForm(
                                docId: doc.id,
                                currentTitle: _stringOrDefault(item['title']),
                                currentDetails: _stringOrDefault(
                                  item['details'],
                                ),
                                currentDueDate: _dateValue(item['dueDate']),
                                completed: completed,
                              );
                            } else {
                              _deleteTask(doc);
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              const <PopupMenuEntry<String>>[
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit task'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete task'),
                                ),
                              ],
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
            onPressed: () => _openTaskForm(),
            icon: const Icon(Icons.add_task),
            label: const Text('New Task'),
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

  DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  String _two(int value) => value.toString().padLeft(2, '0');

  String _stringOrDefault(dynamic value) {
    if (value == null) {
      return '-';
    }
    return value.toString();
  }
}
