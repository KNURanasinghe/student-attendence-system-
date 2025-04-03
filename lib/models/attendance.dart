class Attendance {
  final int id;
  final int studentId;
  final int subjectId;
  final String date;
  final String status;
  final String? studentName;
  final String? subjectName;

  Attendance({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.date,
    required this.status,
    this.studentName,
    this.subjectName,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      studentId: json['student_id'],
      subjectId: json['subject_id'],
      date: json['date'],
      status: json['status'],
      studentName: json['student_name'],
      subjectName: json['subject_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'subject_id': subjectId,
      'date': date,
      'status': status,
    };
  }
}