import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shift_model.dart';
import '../models/volunteer_model.dart';

class ScheduleScreen extends StatefulWidget {
  final Volunteer? currentUser;
  final List<Shift> shifts;
  final Future<void> Function(Shift, String, String) onUpdateShift;

  const ScheduleScreen({
    super.key,
    required this.currentUser,
    required this.shifts,
    required this.onUpdateShift,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showReportDialog(Shift shift) {
    final notesController = TextEditingController(text: shift.notes ?? '');
    String? selectedStatus = shift.status;
    final List<String> statusOptions = ['已完成', '遲到', '早退', '缺席'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('回報服事狀況'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: selectedStatus,
                      hint: const Text('選擇狀態'),
                      isExpanded: true,
                      items: statusOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setDialogState(() {
                          selectedStatus = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '備註或心得',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(child: const Text('取消'), onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  child: const Text('儲存'),
                  onPressed: () async {
                    if (selectedStatus != null) {
                      await widget.onUpdateShift(shift, selectedStatus!, notesController.text.trim());
                      if (mounted) Navigator.of(context).pop();
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
    final myShifts = widget.shifts.where((shift) => shift.volunteerId == widget.currentUser?.id).toList();
    myShifts.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: myShifts.isEmpty
          ? const Center(child: Text('您目前沒有已排班的活動\n向下滑動來重新整理'))
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: myShifts.length,
              itemBuilder: (context, index) {
                final shift = myShifts[index];
                final isPastEvent = shift.eventDate.isBefore(DateTime.now());
                final statusColor = shift.status == '已完成' ? Colors.green : (shift.status == '缺席' ? Colors.red : Colors.orange);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shift.eventTitle, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('日期: ${DateFormat('yyyy-MM-dd').format(shift.eventDate)}'),
                        Text('崗位: ${shift.role}'),
                        if (shift.status != null)
                           Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Chip(label: Text(shift.status!), backgroundColor: statusColor.withOpacity(0.2)),
                           ),
                        if (shift.notes != null && shift.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('備註: ${shift.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          ),
                        if (isPastEvent)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showReportDialog(shift),
                              child: const Text('回報狀況'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
