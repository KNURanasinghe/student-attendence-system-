import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../widgets/app_widgets.dart';

class ViewAttendanceScreen extends StatefulWidget {
  final dynamic teacherData;

  const ViewAttendanceScreen({Key? key, required this.teacherData}) : super(key: key);

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  List<dynamic> _attendanceRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceRecords();
  }

  Future<void> _fetchAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subjectId = widget.teacherData['assigned_subject'];

      // Add debug print statements
      print('Teacher data: ${widget.teacherData}');
      print('Fetching attendance for subject ID: $subjectId');

      if (subjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher has no assigned subject')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = await ApiService.get('attendance/subject/$subjectId');
      print('Received attendance data: $data');

      setState(() {
        _attendanceRecords = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance records: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading attendance records...');
    }

    if (_attendanceRecords.isEmpty) {
      return const EmptyState(
        message: 'No attendance records found',
        icon: Icons.event_busy,
      );
    }

    // Group attendance records by date
    Map<String, List<dynamic>> groupedRecords = {};
    for (var record in _attendanceRecords) {
      final String date = record['date'];
      if (!groupedRecords.containsKey(date)) {
        groupedRecords[date] = [];
      }
      groupedRecords[date]!.add(record);
    }

    // Sort dates in descending order
    final sortedDates = groupedRecords.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attendance Records',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.class_, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Class: ${widget.teacherData['assigned_class']}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.book, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Subject: ${widget.teacherData['subject_name']}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Total Records: ${_attendanceRecords.length}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAttendanceRecords,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final records = groupedRecords[date]!;
                final DateTime parsedDate = DateTime.parse(date);
                final String formattedDate = DateFormat('EEEE, MMM d, yyyy').format(parsedDate);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Text('${records.length} students'),
                        const SizedBox(width: 16),
                        _buildAttendanceSummary(records),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatusCounter('Present',
                                    records.where((r) => r['status'] == 'present').length,
                                    Colors.green),
                                _buildStatusCounter('Absent',
                                    records.where((r) => r['status'] == 'absent').length,
                                    Colors.red),
                                _buildStatusCounter('Late',
                                    records.where((r) => r['status'] == 'late').length,
                                    Colors.orange),
                              ],
                            ),
                            const Divider(height: 32),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: records.length,
                              itemBuilder: (context, i) {
                                final record = records[i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(record['status']).withOpacity(0.2),
                                    child: Icon(
                                      _getStatusIcon(record['status']),
                                      color: _getStatusColor(record['status']),
                                    ),
                                  ),
                                  title: Text(record['student_name']),
                                  trailing: StatusBadge(status: record['status']),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary(List<dynamic> records) {
    int present = records.where((r) => r['status'] == 'present').length;
    int absent = records.where((r) => r['status'] == 'absent').length;
    int late = records.where((r) => r['status'] == 'late').length;

    return Row(
      children: [
        Icon(Icons.check_circle, size: 14, color: Colors.green.shade400),
        Text(' $present  '),
        Icon(Icons.cancel, size: 14, color: Colors.red.shade400),
        Text(' $absent  '),
        Icon(Icons.access_time, size: 14, color: Colors.orange.shade400),
        Text(' $late'),
      ],
    );
  }

  Widget _buildStatusCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}