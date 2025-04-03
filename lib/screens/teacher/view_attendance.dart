import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../widgets/app_widgets.dart';

class ViewAttendanceScreen extends StatefulWidget {
  final dynamic teacherData;

  const ViewAttendanceScreen({super.key, required this.teacherData});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen>
    with WidgetsBindingObserver {
  List<dynamic> _attendanceRecords = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = true;
  bool _isFilteringStudents = false;
  DateTime _lastRefreshTime = DateTime.now();

  // Date filter variables
  DateTime? _startDate;
  DateTime? _endDate;
  bool _dateFilterActive = false;

  @override
  void initState() {
    super.initState();
    // Register as an observer to detect when app comes to foreground
    WidgetsBinding.instance.addObserver(this);
    _fetchData();

    // Set up a refresh timer to periodically check for updates
    _setupRefreshTimer();
  }

  void _setupRefreshTimer() {
    // Check every 10 seconds if we need to refresh
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        // Check if we're visible (the active tab)
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          _fetchData();
        }
        _setupRefreshTimer(); // Schedule next check
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _fetchData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(ViewAttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Refetch when filters change
    if (oldWidget.teacherData['assigned_class'] !=
            widget.teacherData['assigned_class'] ||
        oldWidget.teacherData['assigned_subject'] !=
            widget.teacherData['assigned_subject'] ||
        oldWidget.teacherData['selected_grade'] !=
            widget.teacherData['selected_grade']) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    // Don't refresh too frequently (max once every 3 seconds)
    final now = DateTime.now();
    if (now.difference(_lastRefreshTime).inSeconds < 3) {
      return;
    }
    _lastRefreshTime = now;

    // If we're already loading, don't start another load
    if (_isLoading && !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final className = widget.teacherData['assigned_class'];
      final subjectId = widget.teacherData['assigned_subject'];

      if (subjectId == null) {
        setState(() {
          _attendanceRecords = [];
          _filteredStudents = [];
          _isLoading = false;
        });
        return;
      }

      // Fetch attendance records
      final attendanceData =
          await ApiService.get('attendance/subject/$subjectId');

      // Fetch students based on filters
      await _fetchStudents();

      // Filter attendance records by student IDs if needed
      List<dynamic> filteredAttendance = attendanceData;
      if (_filteredStudents.isNotEmpty) {
        final studentIds =
            _filteredStudents.map<int>((s) => s['id'] as int).toSet();
        filteredAttendance = attendanceData
            .where((record) => studentIds.contains(record['student_id']))
            .toList();
      }

      // Apply date filter if active
      if (_dateFilterActive && (_startDate != null || _endDate != null)) {
        filteredAttendance = _filterByDateRange(filteredAttendance);
      }

      if (mounted) {
        setState(() {
          _attendanceRecords = filteredAttendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error loading attendance records: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Filter records by date range
  List<dynamic> _filterByDateRange(List<dynamic> records) {
    return records.where((record) {
      if (record['date'] == null) return false;

      final DateTime recordDate = DateTime.parse(record['date']);

      // Check if record date is within the range
      bool inRange = true;

      if (_startDate != null) {
        // Remove time component for comparison
        final DateTime startDate =
            DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        inRange = inRange && !recordDate.isBefore(startDate);
      }

      if (_endDate != null) {
        // Add 1 day and subtract 1 second to include the end date fully
        final DateTime endDate =
            DateTime(_endDate!.year, _endDate!.month, _endDate!.day)
                .add(const Duration(days: 1))
                .subtract(const Duration(seconds: 1));
        inRange = inRange && !recordDate.isAfter(endDate);
      }

      return inRange;
    }).toList();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isFilteringStudents = true;
    });

    try {
      final className = widget.teacherData['assigned_class'];
      final subjectId = widget.teacherData['assigned_subject'];
      final selectedGrade = widget.teacherData['selected_grade'];

      if (className == null || subjectId == null) {
        setState(() {
          _filteredStudents = [];
          _isFilteringStudents = false;
        });
        return;
      }

      // Get students matching the filters
      final studentsData =
          await ApiService.get('class-subject-students/$className/$subjectId');

      // Apply grade filter if selected
      final filteredStudents = selectedGrade == null
          ? studentsData
          : studentsData
              .where((student) => student['grade'] == selectedGrade)
              .toList();

      setState(() {
        _filteredStudents = filteredStudents;
        _isFilteringStudents = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error filtering students: ${e.toString()}')),
        );
        setState(() {
          _isFilteringStudents = false;
        });
      }
    }
  }

  // Open date filter dialog
  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter by Date Range'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date filter toggle
                SwitchListTile(
                  title: const Text('Enable Date Filter'),
                  value: _dateFilterActive,
                  onChanged: (value) {
                    setDialogState(() {
                      _dateFilterActive = value;
                    });
                  },
                ),
                const Divider(),
                if (_dateFilterActive) ...[
                  // Start date
                  ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_startDate != null
                        ? DateFormat('MMM d, yyyy').format(_startDate!)
                        : 'Not set (no lower limit)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                _startDate = pickedDate;
                              });
                            }
                          },
                        ),
                        if (_startDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setDialogState(() {
                                _startDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  // End date
                  ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_endDate != null
                        ? DateFormat('MMM d, yyyy').format(_endDate!)
                        : 'Not set (no upper limit)'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (pickedDate != null) {
                              setDialogState(() {
                                _endDate = pickedDate;
                              });
                            }
                          },
                        ),
                        if (_endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setDialogState(() {
                                _endDate = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),

                  // Quick date presets
                  const Divider(),
                  const Text('Quick Presets:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildDatePresetButton('Today', setDialogState, () {
                        final today = DateTime.now();
                        setDialogState(() {
                          _startDate = today;
                          _endDate = today;
                        });
                      }),
                      _buildDatePresetButton('Last 7 Days', setDialogState, () {
                        final today = DateTime.now();
                        setDialogState(() {
                          _startDate = today.subtract(const Duration(days: 6));
                          _endDate = today;
                        });
                      }),
                      _buildDatePresetButton('This Month', setDialogState, () {
                        final today = DateTime.now();
                        setDialogState(() {
                          _startDate = DateTime(today.year, today.month, 1);
                          _endDate = today;
                        });
                      }),
                      _buildDatePresetButton('Clear', setDialogState, () {
                        setDialogState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      }),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchData();
                },
                child: const Text('APPLY'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper to build date preset buttons
  Widget _buildDatePresetButton(
      String label, StateSetter setDialogState, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Attendance Records',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.date_range,
                              color:
                                  _dateFilterActive ? Colors.blue : Colors.grey,
                            ),
                            onPressed: _showDateFilterDialog,
                            tooltip: 'Filter by Date',
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _fetchData,
                            tooltip: 'Refresh Data',
                          ),
                        ],
                      ),
                  ],
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
                if (_dateFilterActive) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(_getDateRangeText()),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: _showDateFilterDialog,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Total Records: ${_attendanceRecords.length}'),
                  ],
                ),
                if (_filteredStudents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Filtered Students: ${_filteredStudents.length}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildAttendanceContent(),
        ),
      ],
    );
  }

  // Get formatted date range text
  String _getDateRangeText() {
    if (!_dateFilterActive) return 'No date filter';

    final dateFormat = DateFormat('MMM d, yyyy');

    if (_startDate != null && _endDate != null) {
      if (_startDate!.year == _endDate!.year &&
          _startDate!.month == _endDate!.month &&
          _startDate!.day == _endDate!.day) {
        return 'Date: ${dateFormat.format(_startDate!)}';
      }
      return 'Date: ${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
    } else if (_startDate != null) {
      return 'Date: From ${dateFormat.format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Date: Until ${dateFormat.format(_endDate!)}';
    } else {
      return 'All Dates';
    }
  }

  Widget _buildAttendanceContent() {
    if (_isLoading && _attendanceRecords.isEmpty) {
      return const LoadingIndicator(message: 'Loading attendance records...');
    }

    if (_attendanceRecords.isEmpty) {
      return const EmptyState(
        message: 'No attendance records found for the selected filters',
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
    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: _isFilteringStudents
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final records = groupedRecords[date]!;
                final DateTime parsedDate = DateTime.parse(date);
                final String formattedDate =
                    DateFormat('EEEE, MMM d, yyyy').format(parsedDate);

                // Check if today
                final isToday =
                    DateTime.now().difference(parsedDate).inDays == 0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  // Highlight today's record
                  color: isToday ? Colors.blue.shade50 : null,
                  child: ExpansionTile(
                    // Auto-expand today's record
                    initiallyExpanded: isToday,
                    title: Row(
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isToday)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
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
                                _buildStatusCounter(
                                    'Present',
                                    records
                                        .where((r) => r['status'] == 'present')
                                        .length,
                                    Colors.green),
                                _buildStatusCounter(
                                    'Absent',
                                    records
                                        .where((r) => r['status'] == 'absent')
                                        .length,
                                    Colors.red),
                                _buildStatusCounter(
                                    'Late',
                                    records
                                        .where((r) => r['status'] == 'late')
                                        .length,
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
                                    backgroundColor:
                                        _getStatusColor(record['status'])
                                            .withOpacity(0.2),
                                    child: Icon(
                                      _getStatusIcon(record['status']),
                                      color: _getStatusColor(record['status']),
                                    ),
                                  ),
                                  title: Text(record['student_name']),
                                  trailing:
                                      StatusBadge(status: record['status']),
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

// Custom widget for displaying status badges
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'present':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Present';
        icon = Icons.check_circle;
        break;
      case 'absent':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Absent';
        icon = Icons.cancel;
        break;
      case 'late':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        label = 'Late';
        icon = Icons.access_time;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        label = 'Unknown';
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
