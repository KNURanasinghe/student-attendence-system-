import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../widgets/app_widgets.dart';
import '../login_screen.dart';
import 'mark_attendance.dart';
import 'view_attendance.dart';

class TeacherDashboard extends StatefulWidget {
  final int userId;

  const TeacherDashboard({Key? key, required this.userId}) : super(key: key);

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  dynamic _teacherData;
  bool _isLoading = true;
  int _selectedIndex = 0;

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
      final data = await ApiService.get('teachers/user/${widget.userId}');
      setState(() {
        _teacherData = data;
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

  Widget _buildDashboard() {
    // Check if teacher has class and subject assignments
    if (_teacherData == null ||
        _teacherData['assigned_class'] == null ||
        _teacherData['assigned_subject'] == null) {
      return const EmptyState(
        message: 'You are not assigned to any class or subject yet.',
        icon: Icons.warning,
      );
    }

    // Show the selected screen
    return IndexedStack(
      index: _selectedIndex,
      children: [
        MarkAttendanceScreen(teacherData: _teacherData),
        ViewAttendanceScreen(teacherData: _teacherData),
      ],
    );
  }
}