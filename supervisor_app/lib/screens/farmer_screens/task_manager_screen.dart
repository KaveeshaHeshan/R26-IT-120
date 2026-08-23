import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'core/farmer_settings.dart';
import 'core/farmer_theme.dart';

// ============================================================
// PRIORITY
// ============================================================

class _Priority {
  const _Priority(this.key, this.label, this.labelSi, this.color, this.icon);

  final String key;
  final String label;
  final String labelSi;
  final Color color;
  final IconData icon;
}

const List<_Priority> _priorities = <_Priority>[
  _Priority('low', 'Low', 'අඩු', Color(0xFF3E8EDE), Icons.south_rounded),
  _Priority('medium', 'Medium', 'මධ්‍යම', Color(0xFFE0951E), Icons.remove_rounded),
  _Priority('high', 'High', 'ඉහළ', Color(0xFFDA4B4B), Icons.north_rounded),
];

_Priority _priorityFor(String? key) {
  for (final _Priority p in _priorities) {
    if (p.key == key) return p;
  }
  return _priorities[1];
}

enum _Filter { all, pending, completed, overdue }

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({required this.userId, super.key});

  final String userId;

  @override
  State<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  _Filter _filter = _Filter.all;

  // ============================================================
  // TASK FORM
  // ============================================================

  Future<void> _openTaskForm(
    FarmerSettings settings, {
    String? docId,
    String? currentTitle,
    String? currentDetails,
    DateTime? currentDueDate,
    String? currentPriority,
  }) async {
    final FarmerPalette p = settings.palette;

    final TextEditingController titleController = TextEditingController(text: currentTitle ?? '');
    final TextEditingController detailsController = TextEditingController(text: currentDetails ?? '');
    DateTime? dueDate = currentDueDate;
    String priority = currentPriority ?? 'medium';

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: p.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Text(
                docId == null ? settings.t('Create Task', 'කාර්යයක් සාදන්න') : settings.t('Edit Task', 'කාර්යය සංස්කරණය'),
                style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: titleController,
                        style: TextStyle(color: p.textPrimary),
                        decoration: _fieldDecoration(
                          p: p,
                          label: settings.t('Task title', 'කාර්ය මාතෘකාව'),
                          icon: Icons.task_alt_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: detailsController,
                        minLines: 2,
                        maxLines: 4,
                        style: TextStyle(color: p.textPrimary),
                        decoration: _fieldDecoration(
                          p: p,
                          label: settings.t('Details', 'විස්තර'),
                          icon: Icons.notes_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        settings.t('Priority', 'ප්‍රමුඛතාවය'),
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: p.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _priorities.map((option) {
                          final bool selected = option.key == priority;
                          return GestureDetector(
                            onTap: () => setDialogState(() => priority = option.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: selected ? option.color : option.color.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: selected ? option.color : option.color.withOpacity(0.25)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(option.icon, size: 15, color: selected ? Colors.white : option.color),
                                  const SizedBox(width: 6),
                                  Text(
                                    settings.t(option.label, option.labelSi),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: selected ? Colors.white : p.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(13),
                        onTap: () async {
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                          decoration: BoxDecoration(
                            color: p.background,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: p.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.event_outlined, size: 19, color: p.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dueDate == null
                                      ? settings.t('Select due date', 'නියමිත දිනය තෝරන්න')
                                      : settings.t('Due ${_formatShortDate(dueDate!)}', 'නියමිත දිනය ${_formatShortDate(dueDate!)}'),
                                  style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: p.textMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(settings.t('Cancel', 'අවලංගු කරන්න')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primary,
                    foregroundColor: p.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final NavigatorState navigator = Navigator.of(context, rootNavigator: true);
                    final String title = titleController.text.trim();
                    final String details = detailsController.text.trim();

                    if (title.isEmpty || dueDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(settings.t('Enter a task title and choose a due date.', 'මාතෘකාවක් සහ නියමිත දිනයක් ඇතුළත් කරන්න.')),
                          backgroundColor: p.danger,
                        ),
                      );
                      return;
                    }

                    final CollectionReference<Map<String, dynamic>> tasksRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('tasks');

                    if (docId == null) {
                      await tasksRef.add(<String, dynamic>{
                        'title': title,
                        'details': details,
                        'priority': priority,
                        'dueDate': Timestamp.fromDate(dueDate!),
                        'completed': false,
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await tasksRef.doc(docId).update(<String, dynamic>{
                        'title': title,
                        'details': details,
                        'priority': priority,
                        'dueDate': Timestamp.fromDate(dueDate!),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    }

                    navigator.pop();
                  },
                  child: Text(settings.t('Save', 'සුරකින්න')),
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

  InputDecoration _fieldDecoration({required FarmerPalette p, required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: p.textSecondary),
      prefixIcon: Icon(icon, color: p.primary),
      filled: true,
      fillColor: p.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: p.primary, width: 1.5)),
    );
  }

  Future<void> _toggleTask(QueryDocumentSnapshot<Map<String, dynamic>> document) async {
    await document.reference.update(<String, dynamic>{
      'completed': !(document.data()['completed'] as bool? ?? false),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> _confirmDelete(FarmerSettings settings) async {
    final FarmerPalette p = settings.palette;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(settings.t('Delete task?', 'කාර්යය මකන්නද?'), style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w900)),
        content: Text(
          settings.t('This task will be permanently removed.', 'මෙම කාර්යය ස්ථිරවම ඉවත් කරනු ලැබේ.'),
          style: TextStyle(color: p.textSecondary),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(settings.t('Cancel', 'අවලංගු කරන්න'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(settings.t('Delete', 'මකන්න')),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;
    final DateTime today = DateTime.now();

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: <Widget>[
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('tasks')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: p.primary));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(settings.t('Unable to load tasks.', 'කාර්යයන් පූරණය කළ නොහැක.'), style: TextStyle(color: p.textPrimary)),
                );
              }

              final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs =
                  snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              final int pendingCount = allDocs.where((d) => !(d.data()['completed'] as bool? ?? false)).length;
              final int completedCount = allDocs.length - pendingCount;
              final int overdueCount = allDocs.where((d) {
                final bool completed = d.data()['completed'] as bool? ?? false;
                final DateTime? due = _dateValue(d.data()['dueDate']);
                return !completed && due != null && _isBeforeDay(due, today);
              }).length;

              final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = allDocs.where((d) {
                final bool completed = d.data()['completed'] as bool? ?? false;
                final DateTime? due = _dateValue(d.data()['dueDate']);

                switch (_filter) {
                  case _Filter.all:
                    return true;
                  case _Filter.pending:
                    return !completed;
                  case _Filter.completed:
                    return completed;
                  case _Filter.overdue:
                    return !completed && due != null && _isBeforeDay(due, today);
                }
              }).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: <Widget>[
                  _StatsHeader(
                    p: p,
                    settings: settings,
                    total: allDocs.length,
                    pending: pendingCount,
                    completed: completedCount,
                    overdue: overdueCount,
                  ),
                  const SizedBox(height: 16),
                  _FilterRow(
                    p: p,
                    settings: settings,
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: 14),
                  if (docs.isEmpty)
                    _EmptyTasks(p: p, settings: settings)
                  else
                    ...docs.map((doc) {
                      final Map<String, dynamic> item = doc.data();
                      final bool completed = item['completed'] as bool? ?? false;
                      final DateTime? due = _dateValue(item['dueDate']);
                      final bool overdue = !completed && due != null && _isBeforeDay(due, today);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Dismissible(
                          key: ValueKey<String>(doc.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(color: p.danger, borderRadius: BorderRadius.circular(18)),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          confirmDismiss: (_) => _confirmDelete(settings),
                          onDismissed: (_) => doc.reference.delete(),
                          child: _TaskCard(
                            p: p,
                            settings: settings,
                            title: _stringOrDefault(item['title']),
                            details: _stringOrDefault(item['details']),
                            priority: _priorityFor(item['priority'] as String?),
                            dueDate: due,
                            completed: completed,
                            overdue: overdue,
                            onToggle: () => _toggleTask(doc),
                            onEdit: () => _openTaskForm(
                              settings,
                              docId: doc.id,
                              currentTitle: _stringOrDefault(item['title']),
                              currentDetails: _stringOrDefault(item['details']),
                              currentDueDate: due,
                              currentPriority: item['priority'] as String?,
                            ),
                            onDelete: () async {
                              if (await _confirmDelete(settings)) {
                                await doc.reference.delete();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openTaskForm(settings),
              backgroundColor: p.primary,
              foregroundColor: p.onPrimary,
              icon: const Icon(Icons.add_task),
              label: Text(settings.t('New Task', 'නව කාර්යය'), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  bool _isBeforeDay(DateTime date, DateTime today) {
    final DateTime d = DateTime(date.year, date.month, date.day);
    final DateTime t = DateTime(today.year, today.month, today.day);
    return d.isBefore(t);
  }

  String _stringOrDefault(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }
}

String _formatShortDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// ============================================================
// STATS HEADER
// ============================================================

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.p,
    required this.settings,
    required this.total,
    required this.pending,
    required this.completed,
    required this.overdue,
  });

  final FarmerPalette p;
  final FarmerSettings settings;
  final int total;
  final int pending;
  final int completed;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[p.primaryDark, p.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[BoxShadow(color: p.primary.withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(settings.t('Task Manager', 'කාර්ය කළමනාකරු'), style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(
                      total == 0
                          ? settings.t('No tasks yet', 'තවම කාර්යයන් නැත')
                          : settings.t('$pending pending · $completed done', 'ඉතිරි $pending · නිමකළ $completed'),
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (overdue > 0) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(11)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 7),
                  Text(
                    settings.t('$overdue task${overdue == 1 ? '' : 's'} overdue', 'කාර්යයන් $overdue ක් කල් ඉකුත් වී ඇත'),
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// FILTER ROW
// ============================================================

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.p, required this.settings, required this.selected, required this.onSelected});

  final FarmerPalette p;
  final FarmerSettings settings;
  final _Filter selected;
  final ValueChanged<_Filter> onSelected;

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<_Filter, String>> items = <MapEntry<_Filter, String>>[
      MapEntry<_Filter, String>(_Filter.all, settings.t('All', 'සියල්ල')),
      MapEntry<_Filter, String>(_Filter.pending, settings.t('Pending', 'ඉතිරි')),
      MapEntry<_Filter, String>(_Filter.completed, settings.t('Completed', 'නිමකළ')),
      MapEntry<_Filter, String>(_Filter.overdue, settings.t('Overdue', 'කල් ඉකුත්')),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((entry) {
          final bool isSelected = entry.key == selected;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? p.primary : p.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? p.primary : p.border),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : p.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============================================================
// TASK CARD
// ============================================================

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.p,
    required this.settings,
    required this.title,
    required this.details,
    required this.priority,
    required this.dueDate,
    required this.completed,
    required this.overdue,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final FarmerPalette p;
  final FarmerSettings settings;
  final String title;
  final String details;
  final _Priority priority;
  final DateTime? dueDate;
  final bool completed;
  final bool overdue;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: overdue ? p.danger.withOpacity(0.4) : p.border),
        boxShadow: p.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 26,
                height: 26,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? p.primary : Colors.transparent,
                  border: Border.all(color: completed ? p.primary : p.border, width: 2),
                ),
                child: completed ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: completed ? p.textMuted : p.textPrimary,
                            decoration: completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      _PriorityChip(priority: priority, settings: settings),
                    ],
                  ),
                  if (details.trim().isNotEmpty && details != '-') ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: p.textSecondary, height: 1.35),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(Icons.event_outlined, size: 13, color: overdue ? p.danger : p.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        dueDate == null ? '-' : _formatShortDate(dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: overdue ? p.danger : p.textMuted,
                        ),
                      ),
                      if (overdue) ...<Widget>[
                        const SizedBox(width: 6),
                        Text(
                          settings.t('· overdue', '· කල් ඉකුත්'),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: p.danger),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: p.textSecondary, size: 20),
              color: p.surface,
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Text(settings.t('Edit task', 'සංස්කරණය'), style: TextStyle(color: p.textPrimary)),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text(settings.t('Delete task', 'මකන්න'), style: TextStyle(color: p.danger)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority, required this.settings});

  final _Priority priority;
  final FarmerSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(priority.icon, size: 11, color: priority.color),
          const SizedBox(width: 3),
          Text(
            settings.t(priority.label, priority.labelSi),
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: priority.color),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.p, required this.settings});

  final FarmerPalette p;
  final FarmerSettings settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(26)),
            child: Icon(Icons.task_alt_outlined, size: 40, color: p.primary),
          ),
          const SizedBox(height: 16),
          Text(
            settings.t('No tasks here', 'මෙහි කාර්යයන් නැත'),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: p.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            settings.t('Tap New Task to add one.', 'එකක් එකතු කිරීමට නව කාර්යය ඔබන්න.'),
            style: TextStyle(fontSize: 12.5, color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
