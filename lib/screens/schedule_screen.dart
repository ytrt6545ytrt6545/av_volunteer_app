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
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('狀況已回報，感謝您的服事！')));
                      }
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
    if (widget.currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '請先登入以查看您的班表',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final myShifts = widget.shifts.where((shift) => shift.volunteerId == widget.currentUser!.id).toList();
    myShifts.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: myShifts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '您目前沒有已排班的活動',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '快到活動列表看看有什麼可以參與的吧！',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: myShifts.length,
              itemBuilder: (context, index) {
                final shift = myShifts[index];
                final isPastEvent = shift.eventDate.isBefore(DateTime.now());
                final statusColor = shift.status == '已完成' ? Colors.green : (shift.status == '缺席' ? Colors.red : Colors.orange);

                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(vertical: 10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shift.eventTitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('日期: ${DateFormat('yyyy-MM-dd').format(shift.eventDate)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.label, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('崗位: ${shift.role}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                          ],
                        ),
                        const Divider(height: 24),
                        if (shift.status != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Chip(label: Text(shift.status!), backgroundColor: statusColor.withOpacity(0.2), padding: const EdgeInsets.symmetric(horizontal: 8.0)),
                          ),
                        if (shift.notes != null && shift.notes!.isNotEmpty)
                          Text('備註: ${shift.notes}', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[800])),
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
