import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../login_screen.dart';
import 'mark_attendance.dart';
import 'view_attendance.dart';

class TeacherDashboard extends StatefulWidget {
  final int userId;

  const TeacherDashboard({super.key, required this.userId});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  dynamic _teacherData;
  bool _isLoading = true;
  int _selectedIndex = 0;

  // Filter data
  List<String> _availableClasses = [];
  List<String> _availableGrades = [];
  List<dynamic> _availableSubjects = [];

  // Selected filter values
  String? _selectedClass;
  String? _selectedGrade;
  int? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load teacher data
      final teacherData =
          await ApiService.get('teachers/user/${widget.userId}');

      // Load all students from the database to get available classes and grades
      final studentsData = await ApiService.get('students');

      // Load all subjects from the database
      final subjectsData = await ApiService.get('subjects');

      // Extract available classes from students table and ensure uniqueness
      final Set<String> classes = {};
      for (final student in studentsData) {
        if (student['class'] != null &&
            student['class'].toString().isNotEmpty) {
          classes.add(student['class'].toString());
        }
      }

      // Extract available grades from students table and ensure uniqueness
      final Set<String> grades = {};
      for (final student in studentsData) {
        if (student['grade'] != null &&
            student['grade'].toString().isNotEmpty) {
          grades.add(student['grade'].toString());
        }
      }

      // Get unique subjects
      final uniqueSubjects = <int, dynamic>{};
      for (final subject in subjectsData) {
        uniqueSubjects[subject['id']] = subject;
      }

      final sortedClasses = classes.toList()
        ..sort((a, b) => int.tryParse(a) != null && int.tryParse(b) != null
            ? int.parse(a).compareTo(int.parse(b))
            : a.compareTo(b));

      final sortedGrades = grades.toList()..sort();

      setState(() {
        _teacherData = teacherData;
        _availableClasses = sortedClasses;
        _availableGrades = sortedGrades;
        _availableSubjects = uniqueSubjects.values.toList();

        // Set initial filters based on teacher's assignments if they exist in our lists
        _selectedClass = teacherData['assigned_class'] != null &&
                classes.contains(teacherData['assigned_class'].toString())
            ? teacherData['assigned_class'].toString()
            : null;

        final assignedSubjectId = teacherData['assigned_subject'];
        _selectedSubjectId = assignedSubjectId != null &&
                uniqueSubjects.containsKey(assignedSubjectId)
            ? assignedSubjectId
            : null;

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filter Options',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading data...')
          : _buildDashboard(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Mark Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'View Records',
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    // Create a local copy of current selections for the dialog
    String? dialogClass = _selectedClass;
    String? dialogGrade = _selectedGrade;
    int? dialogSubjectId = _selectedSubjectId;

    // Debug: Check if any value is invalid
    if (dialogClass != null && !_availableClasses.contains(dialogClass)) {
      print("Warning: Selected class '$dialogClass' not in available classes");
      dialogClass = null;
    }

    if (dialogGrade != null && !_availableGrades.contains(dialogGrade)) {
      print("Warning: Selected grade '$dialogGrade' not in available grades");
      dialogGrade = null;
    }

    if (dialogSubjectId != null &&
        !_availableSubjects.any((s) => s['id'] == dialogSubjectId)) {
      print(
          "Warning: Selected subject ID '$dialogSubjectId' not in available subjects");
      dialogSubjectId = null;
    }

    // Now show the dialog with validated selections
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filter Options'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class filter
                  const Text(
                    'Select Class:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: dialogClass,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Classes'),
                      ),
                      ..._availableClasses
                          .map((className) => DropdownMenuItem<String>(
                                value: className,
                                child: Text('Class $className'),
                              )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        dialogClass = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Grade filter
                  const Text(
                    'Select Grade:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: dialogGrade,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Grades'),
                      ),
                      ..._availableGrades
                          .map((grade) => DropdownMenuItem<String>(
                                value: grade,
                                child: Text('Grade $grade'),
                              )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        dialogGrade = value;
                      });
                    },
                  ),

                  if (_selectedIndex == 1 && _availableSubjects.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    // Subject filter (only visible in view records tab)
                    const Text(
                      'Select Subject:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: dialogSubjectId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: _availableSubjects
                          .map((subject) {
                            // Ensure we have a valid id
                            final id = subject['id'] is int
                                ? subject['id']
                                : int.tryParse(subject['id'].toString());
                            if (id == null) {
                              print(
                                  "Warning: Invalid subject ID: ${subject['id']}");
                              return null;
                            }
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(subject['name']?.toString() ??
                                  'Unknown Subject'),
                            );
                          })
                          .whereType<DropdownMenuItem<int>>()
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          dialogSubjectId = value;
                        });
                      },
                    ),
                  ],
                ],
              ),
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
                  // Update state with new filter selections
                  setState(() {
                    _selectedClass = dialogClass;
                    _selectedGrade = dialogGrade;
                    _selectedSubjectId = dialogSubjectId;
                  });
                },
                child: const Text('APPLY'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboard() {
    // Check if teacher has basic assignments
    if (_teacherData == null) {
      return const EmptyState(
        message: 'Your teacher profile is not properly configured.',
        icon: Icons.warning,
      );
    }

    // Create a copy of teacher data with filter selections
    final filteredTeacherData = Map<String, dynamic>.from(_teacherData);

    // Apply class filter if selected
    if (_selectedClass != null) {
      filteredTeacherData['assigned_class'] = _selectedClass;
    }

    // Apply grade filter
    filteredTeacherData['selected_grade'] = _selectedGrade;

    // Apply subject filter for view records tab
    if (_selectedIndex == 1 && _selectedSubjectId != null) {
      filteredTeacherData['assigned_subject'] = _selectedSubjectId;

      // Get subject name for the selected ID
      final selectedSubject = _availableSubjects.firstWhere(
        (subject) => subject['id'] == _selectedSubjectId,
        orElse: () => {'name': 'Unknown Subject'},
      );
      filteredTeacherData['subject_name'] = selectedSubject['name'];
    }

    // Display filtering info
    return Column(
      children: [
        // Show active filters card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Active Filters:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _showFilterDialog,
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.class_, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Class: ${_selectedClass != null ? 'Class $_selectedClass' : 'All Classes'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.grade, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Grade: ${_selectedGrade != null ? 'Grade $_selectedGrade' : 'All Grades'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (_selectedIndex == 1) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.book, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Subject: ${_selectedSubjectId != null ? _availableSubjects.firstWhere(
                            (subject) => subject['id'] == _selectedSubjectId,
                            orElse: () => {'name': 'Unknown Subject'},
                          )['name'] : 'All Subjects'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Show the selected screen with filtered data
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              MarkAttendanceScreen(teacherData: filteredTeacherData),
              ViewAttendanceScreen(teacherData: filteredTeacherData),
            ],
          ),
        ),
      ],
    );
  }
}
