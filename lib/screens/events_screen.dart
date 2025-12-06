import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/shift_model.dart';
import '../models/volunteer_model.dart';

class EventsScreen extends StatefulWidget {
  final Volunteer? currentUser;
  final List<Event> events;
  final List<Shift> shifts;
  final Future<void> Function(Event) onAddEvent;
  final Future<void> Function(Event) onUpdateEvent;
  final Future<void> Function(Event, String?) onDeleteEvent;
  final Future<void> Function(Event, String) onSignUp;
  final Future<void> Function(Shift) onCancelSignUp;
  final Function(Event) onSendNotification;
  final List<String> allRoles;

  const EventsScreen({
    super.key,
    required this.currentUser,
    required this.events,
    required this.shifts,
    required this.onAddEvent,
    required this.onUpdateEvent,
    required this.onDeleteEvent,
    required this.onSignUp,
    required this.onCancelSignUp,
    required this.onSendNotification,
    required this.allRoles,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showEventDetails(BuildContext context, Event event) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(event.title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('日期: ${DateFormat('yyyy-MM-dd (E) HH:mm').format(event.date)}'),
                  const SizedBox(height: 16),
                  Text('需要崗位:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...event.roles.map((role) {
                    final shiftForRole = widget.shifts.where((s) => s.eventId == event.id && s.role == role).firstOrNull;
                    final isCurrentUserSignedUp = shiftForRole?.volunteerId == widget.currentUser?.id;
                    return ListTile(
                      title: Text(role),
                      trailing: (shiftForRole == null)
                          ? (widget.currentUser != null && !widget.currentUser!.isAdmin)
                              ? ElevatedButton(onPressed: () => widget.onSignUp(event, role).then((_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('報名成功！')))), child: const Text('報名'))
                              : null
                          : isCurrentUserSignedUp
                              ? ElevatedButton(onPressed: () => widget.onCancelSignUp(shiftForRole).then((_) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消報名')))), child: const Text('取消報名', style: TextStyle(color: Colors.red)))
                              : Text(shiftForRole.volunteerName),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            if (widget.currentUser?.isAdmin ?? false)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                    child: const Text('編輯'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showEventFormDialog(existingEvent: event);
                    },
                  ),
                  TextButton(
                    child: const Text('刪除', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showDeleteConfirmationDialog(event);
                    },
                  ),
                ],
              ),
            const Spacer(),
            TextButton(
              child: const Text('關閉'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Event event) {
    final bool hasSignups = widget.shifts.any((shift) => shift.eventId == event.id);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('確認取消活動'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('您確定要取消 "${event.title}" 這個活動嗎？'),
                if (hasSignups)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(labelText: '取消原因 (必填)', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '由於已有人報名，請務必填寫取消原因';
                        }
                        return null;
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(child: const Text('返回'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('確認取消', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                if (hasSignups) {
                  if (formKey.currentState?.validate() ?? false) {
                    await widget.onDeleteEvent(event, reasonController.text.trim());
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('活動已取消')));
                    }
                  }
                } else {
                  await widget.onDeleteEvent(event, null);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('活動已刪除')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEventFormDialog({Event? existingEvent}) {
    final isEditing = existingEvent != null;
    final titleController = TextEditingController(text: isEditing ? existingEvent.title : '');
    DateTime selectedDate = isEditing ? existingEvent.date : DateTime.now();
    final Set<String> selectedRoles = isEditing ? existingEvent.roles.toSet() : {};

    showDialog(
      context: context,
      useSafeArea: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? '編輯活動' : '新增活動'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: '活動標題')),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('日期: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (picked != null && picked != selectedDate) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('選擇需要崗位:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...widget.allRoles.map((role) {
                      return CheckboxListTile(
                        title: Text(role),
                        value: selectedRoles.contains(role),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) { selectedRoles.add(role); } 
                            else { selectedRoles.remove(role); }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: const Text('取消'), onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  child: const Text('儲存'),
                  onPressed: () => _handleSave(titleController.text, selectedDate, selectedRoles, isEditing, existingEvent, false),
                ),
                ElevatedButton(
                  child: const Text('儲存並發送通知'),
                  onPressed: () => _handleSave(titleController.text, selectedDate, selectedRoles, isEditing, existingEvent, true),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleSave(String title, DateTime date, Set<String> roles, bool isEditing, Event? existingEvent, bool sendNotification) async {
    if (title.isNotEmpty && roles.isNotEmpty) {
      final eventData = Event(
        id: isEditing ? existingEvent!.id : null,
        title: title,
        date: date,
        roles: roles.toList(),
      );

      if (isEditing) {
        await widget.onUpdateEvent(eventData);
      } else {
        await widget.onAddEvent(eventData);
      }

      if (mounted) {
         Navigator.of(context).pop();
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('活動已${isEditing ? '更新' : '新增'}！')));
      }

      if (sendNotification) {
        widget.onSendNotification(eventData);
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在發送通知...')));
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: widget.events.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '目前沒有任何活動',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    if (widget.currentUser?.isAdmin ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '點擊右下角的 "+" 來新增活動',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: widget.events.length,
                itemBuilder: (context, index) {
                  final event = widget.events[index];
                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                      title: Text(event.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('yyyy-MM-dd (E) HH:mm').format(event.date),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
                      onTap: () => _showEventDetails(context, event),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: widget.currentUser?.isAdmin ?? false
          ? FloatingActionButton(onPressed: () => _showEventFormDialog(), child: const Icon(Icons.add))
          : null,
    );
  }
}
