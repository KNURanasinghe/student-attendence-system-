import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../widgets/app_widgets.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  List<dynamic> _subjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.get('students');
      final subjectsData = await ApiService.get('subjects');

      setState(() {
        _students = data;
        _filteredStudents = data;
        _subjects = subjectsData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Error loading students: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students.where((student) {
          final name = student['name'].toString().toLowerCase();
          final grade = student['grade'].toString().toLowerCase();
          final studentClass = student['class'].toString().toLowerCase();
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              grade.contains(searchLower) ||
              studentClass.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading students...');
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterStudents('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: _filterStudents,
            ),
          ),
          Expanded(
            child: _filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.school_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No students match your search'
                              : 'No students found. Add your first student!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty)
                          TextButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Search'),
                            onPressed: () {
                              _searchController.clear();
                              _filterStudents('');
                            },
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchStudents,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student = _filteredStudents[index];
                        final initial = student['name'].toString().isNotEmpty
                            ? student['name'].toString()[0].toUpperCase()
                            : '?';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              student['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Grade ${student['grade']}',
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Class ${student['class']}',
                                      style: TextStyle(
                                        color: Colors.purple.shade800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () => _showStudentForm(student),
                                  tooltip: 'Edit Student',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _deleteStudent(student['id']),
                                  tooltip: 'Delete Student',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStudentForm(null),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'ADD STUDENT',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        tooltip: 'Add Student',
      ),
    );
  }

  void _showStudentForm(dynamic student) {
    final nameController = TextEditingController(text: student?['name'] ?? '');
    final gradeController =
        TextEditingController(text: student?['grade'] ?? '');
    final classController =
        TextEditingController(text: student?['class'] ?? '');

    int? selectedSubjectId = student?['assigned_subject'];
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          student == null ? 'Add Student' : 'Edit Student',
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: gradeController,
                  decoration: InputDecoration(
                    labelText: 'Grade',
                    prefixIcon: const Icon(Icons.grade),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Grade is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: classController,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    prefixIcon: const Icon(Icons.class_),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Class is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  decoration: InputDecoration(
                    labelText: 'Assigned Subject',
                    prefixIcon: const Icon(Icons.book),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  value: selectedSubjectId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No Subject'),
                    ),
                    ..._subjects.map<DropdownMenuItem<int>>((subject) {
                      return DropdownMenuItem<int>(
                        value: subject['id'],
                        child: Text(subject['name']),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    selectedSubjectId = value;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              try {
                if (student == null) {
                  // Create new student
                  await ApiService.post('students', {
                    'name': nameController.text,
                    'grade': gradeController.text,
                    'class': classController.text,
                  });
                } else {
                  // Update student
                  await ApiService.put('students/${student['id']}', {
                    'name': nameController.text,
                    'grade': gradeController.text,
                    'class': classController.text,
                  });
                }

                if (!mounted) return;
                Navigator.pop(context);
                _fetchStudents();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      student == null
                          ? 'Student added successfully'
                          : 'Student updated successfully',
                    ),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(student == null ? 'ADD' : 'UPDATE'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _deleteStudent(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Student',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete this student? This will also delete their attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.delete('students/$id');
                if (!mounted) return;
                Navigator.pop(context);
                _fetchStudents();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Student deleted successfully'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
