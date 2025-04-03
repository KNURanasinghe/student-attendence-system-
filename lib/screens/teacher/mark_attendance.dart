import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../widgets/app_widgets.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final dynamic teacherData;

  const MarkAttendanceScreen({super.key, required this.teacherData});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  Map<int, String> _attendanceStatus = {};

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void didUpdateWidget(MarkAttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Refetch when filters change
    if (oldWidget.teacherData['assigned_class'] !=
            widget.teacherData['assigned_class'] ||
        oldWidget.teacherData['assigned_subject'] !=
            widget.teacherData['assigned_subject'] ||
        oldWidget.teacherData['selected_grade'] !=
            widget.teacherData['selected_grade']) {
      _fetchStudents();
    }
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final className = widget.teacherData['assigned_class'];
      final subjectId = widget.teacherData['assigned_subject'];
      final selectedGrade = widget.teacherData['selected_grade'];

      if (className == null || subjectId == null) {
        setState(() {
          _students = [];
          _isLoading = false;
        });
        return;
      }

      // Get students in the class who take the subject
      final data =
          await ApiService.get('class-subject-students/$className/$subjectId');

      // Apply grade filter if selected
      final filteredStudents = selectedGrade == null
          ? data
          : data.where((student) => student['grade'] == selectedGrade).toList();

      setState(() {
        _students = filteredStudents;
        _isLoading = false;
      });

      // Check for existing attendance records for today
      _fetchExistingAttendance();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchExistingAttendance() async {
    try {
      final subjectId = widget.teacherData['assigned_subject'];
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final data =
          await ApiService.get('attendance/subject/$subjectId/date/$date');

      Map<int, String> statuses = {};
      for (var record in data) {
        statuses[record['student_id']] = record['status'];
      }

      setState(() {
        _attendanceStatus = statuses;
      });
    } catch (e) {
      // Ignore errors, just won't show existing attendance
    }
  }

  Future<void> _saveAttendance(int studentId, String status) async {
    try {
      final subjectId = widget.teacherData['assigned_subject'];
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);

      await ApiService.post('attendance', {
        'student_id': studentId,
        'subject_id': subjectId,
        'date': date,
        'status': status,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save attendance: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _isLoading
              ? const LoadingIndicator()
              : _students.isEmpty
                  ? const EmptyState(
                      message: 'No students found with the selected filters',
                      icon: Icons.person_off,
                    )
                  : _buildStudentList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark Attendance',
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
                Text(
                    'Class: ${widget.teacherData['assigned_class'] ?? 'All Classes'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.grade, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                    'Grade: ${widget.teacherData['selected_grade'] ?? 'All Grades'}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.book, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                    'Subject: ${widget.teacherData['subject_name'] ?? 'No Subject'}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Date:'),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null && pickedDate != _selectedDate) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                      _fetchExistingAttendance();
                    }
                  },
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (_students.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Total Students: ${_students.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final studentId = student['id'];
        final studentStatus = _attendanceStatus[studentId] ?? 'present';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(student['name'][0]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Grade ${student['grade']} • Class ${student['class']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: studentStatus,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _attendanceStatus[studentId] = value;
                      });
                      _saveAttendance(studentId, value);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'present',
                      child: Text('Present',
                          style: TextStyle(color: Colors.green)),
                    ),
                    DropdownMenuItem(
                      value: 'absent',
                      child:
                          Text('Absent', style: TextStyle(color: Colors.red)),
                    ),
                    DropdownMenuItem(
                      value: 'late',
                      child:
                          Text('Late', style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                  underline: Container(
                    height: 2,
                    color: _getStatusColor(studentStatus),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
}
