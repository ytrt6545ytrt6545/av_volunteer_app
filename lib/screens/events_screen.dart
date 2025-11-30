import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/volunteer_model.dart';

class EventsScreen extends StatelessWidget {
  final Volunteer? currentUser;

  const EventsScreen({super.key, required this.currentUser});

  // Mock data for demonstration
  static final List<Event> _events = [
    Event(title: '週日主日崇拜', date: DateTime.now().add(const Duration(days: 2)), roles: ['音控', 'PPT', '燈控']),
    Event(title: '週五青年團契', date: DateTime.now().add(const Duration(days: 7)), roles: ['音控', 'PPT']),
    Event(title: '特別聚會：聖誕晚會', date: DateTime.now().add(const Duration(days: 30)), roles: ['音控', 'PPT', '燈控', '直播']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('yyyy-MM-dd (E) HH:mm').format(event.date)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to event details screen
              },
            ),
          );
        },
      ),
      floatingActionButton: currentUser?.isAdmin ?? false
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Implement add event functionality
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
