import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/shift_model.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  // Mock data for demonstration
  final List<Shift> _myShifts = [
    Shift(
      event: Event(title: '週日主日崇拜', date: DateTime.now().add(const Duration(days: 2)), roles: ['音控', 'PPT', '燈控']),
      role: '音控',
    ),
    Shift(
      event: Event(title: '週五青年團契', date: DateTime.now().add(const Duration(days: 7)), roles: ['音控', 'PPT']),
      role: 'PPT',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_myShifts.isEmpty) {
      return const Center(child: Text('您目前沒有已排班的活動'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _myShifts.length,
      itemBuilder: (context, index) {
        final shift = _myShifts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(shift.event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('日期: ${DateFormat('yyyy-MM-dd').format(shift.event.date)}\n崗位: ${shift.role}'),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
