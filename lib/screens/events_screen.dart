import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/volunteer_model.dart';

class EventsScreen extends StatefulWidget {
  final Volunteer? currentUser;
  final List<Event> events;
  final Function(Event) onAddEvent;
  final Function(Event) onDeleteEvent;
  final List<String> allRoles;

  const EventsScreen({
    super.key,
    required this.currentUser,
    required this.events,
    required this.onAddEvent,
    required this.onDeleteEvent,
    required this.allRoles,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // Function to handle the refresh action
  Future<void> _handleRefresh() async {
    // Simulate a network request for fresh data
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, you would fetch data from a server here.
    // Since our state is managed by HomeScreen, we don't need to call setState.
    // The UI will reflect the latest data from the parent.
  }

  void _showEventDetails(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event.title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('日期: ${DateFormat('yyyy-MM-dd (E) HH:mm').format(event.date)}'),
                const SizedBox(height: 16),
                Text('需要崗位:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...event.roles.map((role) => Text('• $role')),
              ],
            ),
          ),
          actions: <Widget>[
            if (widget.currentUser?.isAdmin ?? false)
              TextButton(
                child: const Text('刪除', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showDeleteConfirmationDialog(event);
                },
              ),
            const Spacer(),
            TextButton(
              child: const Text('關閉'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (widget.currentUser != null && !widget.currentUser!.isAdmin)
              TextButton(
                child: const Text('報名'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認刪除'),
          content: Text('您確定要刪除 "${event.title}" 這個活動嗎？此操作無法復原。'),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('確認刪除', style: TextStyle(color: Colors.red)),
              onPressed: () {
                widget.onDeleteEvent(event);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final Set<String> selectedRoles = {};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('新增活動'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: '活動標題'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('日期: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030));
                        if (picked != null && picked != selectedDate) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('選擇需要崗位:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...widget.allRoles.map((role) {
                      return CheckboxListTile(
                        title: Text(role),
                        value: selectedRoles.contains(role),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedRoles.add(role);
                            } else {
                              selectedRoles.remove(role);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('取消'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('儲存'),
                  onPressed: () {
                    if (titleController.text.isNotEmpty && selectedRoles.isNotEmpty) {
                      final newEvent = Event(
                        title: titleController.text,
                        date: selectedDate,
                        roles: selectedRoles.toList(),
                      );
                      widget.onAddEvent(newEvent);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: widget.events.length,
          itemBuilder: (context, index) {
            final event = widget.events[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(DateFormat('yyyy-MM-dd (E) HH:mm').format(event.date)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showEventDetails(context, event);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: widget.currentUser?.isAdmin ?? false
          ? FloatingActionButton(
              onPressed: _showAddEventDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
