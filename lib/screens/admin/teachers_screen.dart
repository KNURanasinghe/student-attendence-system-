import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../widgets/app_widgets.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  List<dynamic> _teachers = [];
  List<dynamic> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teachersData = await ApiService.get('teachers');
      final subjectsData = await ApiService.get('subjects');

      setState(() {
        _teachers = teachersData;
        _subjects = subjectsData;
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
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeacherForm(null),
        tooltip: 'Add Teacher',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading teachers...');
    }

    if (_teachers.isEmpty) {
      return const EmptyState(
        message: 'No teachers found. Add your first teacher!',
        icon: Icons.people,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _teachers.length,
        itemBuilder: (context, index) {
          final teacher = _teachers[index];
          final subjectName = teacher['subject_name'] ?? 'No subject assigned';

          return DataListItem(
            title: teacher['name'],
            subtitle:
                '${teacher['email']} • ${teacher['assigned_class'] ?? 'No class'} • $subjectName',
            leadingIcon: Icons.person,
            trailing: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showTeacherForm(teacher),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteTeacher(teacher['id']),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTeacherForm(dynamic teacher) {
    final nameController = TextEditingController(text: teacher?['name'] ?? '');
    final emailController =
        TextEditingController(text: teacher?['email'] ?? '');
    final passwordController = TextEditingController();
    final classController =
        TextEditingController(text: teacher?['assigned_class'] ?? '');

    int? selectedSubjectId = teacher?['assigned_subject'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(teacher == null ? 'Add Teacher' : 'Edit Teacher'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Name',
                icon: Icons.person,
                controller: nameController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                icon: Icons.email,
                controller: emailController,
              ),
              const SizedBox(height: 16),
              if (teacher == null) ...[
                AppTextField(
                  label: 'Password',
                  icon: Icons.lock,
                  controller: passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
              ],
              AppTextField(
                label: 'Assigned Class',
                icon: Icons.class_,
                controller: classController,
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and email are required')),
                );
                return;
              }

              if (teacher == null && passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password is required')),
                );
                return;
              }

              try {
                if (teacher == null) {
                  // Create new user with teacher role
                  final userResponse = await ApiService.post('users', {
                    'name': nameController.text,
                    'email': emailController.text,
                    'password': passwordController.text,
                    'role': 'teacher',
                  });

                  // Create teacher with assignments
                  await ApiService.post('teachers', {
                    'user_id': userResponse['id'],
                    'assigned_class': classController.text,
                    'assigned_subject': selectedSubjectId,
                  });
                } else {
                  // Update user
                  await ApiService.put('users/${teacher['user_id']}', {
                    'name': nameController.text,
                    'email': emailController.text,
                  });

                  // Update teacher
                  await ApiService.put('teachers/${teacher['id']}', {
                    'assigned_class': classController.text,
                    'assigned_subject': selectedSubjectId,
                  });
                }

                // Refresh teacher list
                if (!mounted) return;
                Navigator.pop(context);
                _loadData();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(teacher == null
                          ? 'Teacher added successfully'
                          : 'Teacher updated successfully')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
            child: Text(teacher == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _deleteTeacher(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: const Text('Are you sure you want to delete this teacher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.delete('teachers/$id');
                if (!mounted) return;
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Teacher deleted successfully')),
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

  @override
  void dispose() {
    super.dispose();
  }
}
