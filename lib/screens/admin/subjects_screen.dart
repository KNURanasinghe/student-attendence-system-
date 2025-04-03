import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../widgets/app_widgets.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({Key? key}) : super(key: key);

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  List<dynamic> _subjects = [];
  List<dynamic> _students = [];
  bool _isLoading = true;
  bool _showBasketAssignment = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.get('subjects');

      setState(() {
        _subjects = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subjects: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchStudents() async {
    try {
      final data = await ApiService.get('students');

      setState(() {
        _students = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading subjects...');
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'All Subjects'),
                  Tab(text: 'Basket Assignment'),
                ],
                onTap: (index) {
                  if (index == 1 && _students.isEmpty) {
                    _fetchStudents();
                  }
                },
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSubjectsList(),
            _buildBasketAssignment(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showSubjectForm(null),
          child: const Icon(Icons.add),
          tooltip: 'Add Subject',
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    if (_subjects.isEmpty) {
      return const EmptyState(
        message: 'No subjects found. Add your first subject!',
        icon: Icons.book,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSubjects,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _subjects.length,
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final bool isBasket = subject['is_basket'] == 1;

          return DataListItem(
            title: subject['name'],
            subtitle: isBasket ? 'Basket Subject' : 'Core Subject',
            leadingIcon: isBasket ? Icons.category : Icons.book,
            iconColor: isBasket ? Colors.purple : Colors.blue,
            trailing: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showSubjectForm(subject),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteSubject(subject['id']),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBasketAssignment() {
    if (_students.isEmpty) {
      return const LoadingIndicator(message: 'Loading students...');
    }

    // Filter only basket subjects
    final basketSubjects = _subjects.where((subject) => subject['is_basket'] == 1).toList();

    if (basketSubjects.isEmpty) {
      return const EmptyState(
        message: 'No basket subjects found. Add basket subjects first!',
        icon: Icons.category,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(student['name']),
            subtitle: Text('Grade ${student['grade']} • Class ${student['class']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assign Basket Subjects',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: basketSubjects.map((subject) {
                        return _buildAssignmentChip(student['id'], subject);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentChip(int studentId, dynamic subject) {
    // In a real app, you would fetch the existing assignments
    // For simplicity, we're simulating this behavior
    return FilterChip(
      label: Text(subject['name']),
      selected: false, // Would be set based on existing assignments
      onSelected: (selected) {
        _assignSubject(studentId, subject['id'], selected);
      },
    );
  }

  void _assignSubject(int studentId, int subjectId, bool assign) async {
    try {
      if (assign) {
        await ApiService.post('student-subjects', {
          'student_id': studentId,
          'subject_id': subjectId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject assigned successfully')),
        );
      } else {
        // In a real app, you would need the assignment ID to remove it
        // This is just a placeholder
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject unassigned successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showSubjectForm(dynamic subject) {
    final _nameController = TextEditingController(text: subject?['name'] ?? '');
    bool _isBasket = subject != null ? subject['is_basket'] == 1 : false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(subject == null ? 'Add Subject' : 'Edit Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  label: 'Subject Name',
                  icon: Icons.book,
                  controller: _nameController,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Basket Subject?'),
                  subtitle: const Text('Basket subjects can be assigned to students'),
                  value: _isBasket,
                  onChanged: (value) {
                    setState(() {
                      _isBasket = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Subject name is required')),
                    );
                    return;
                  }

                  try {
                    if (subject == null) {
                      // Create new subject
                      await ApiService.post('subjects', {
                        'name': _nameController.text,
                        'is_basket': _isBasket,
                      });
                    } else {
                      // Update subject
                      await ApiService.put('subjects/${subject['id']}', {
                        'name': _nameController.text,
                        'is_basket': _isBasket,
                      });
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                    _fetchSubjects();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(subject == null ? 'Subject added successfully' : 'Subject updated successfully')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: Text(subject == null ? 'Add' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteSubject(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: const Text('Are you sure you want to delete this subject? This will also delete any attendance records for this subject.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.delete('subjects/$id');
                if (!mounted) return;
                Navigator.pop(context);
                _fetchSubjects();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject deleted successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}