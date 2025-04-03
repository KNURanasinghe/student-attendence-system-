class Teacher {
  final int id;
  final int userId;
  final String? assignedClass;
  final int? assignedSubject;
  final String? name;
  final String? email;
  final String? subjectName;

  Teacher({
    required this.id,
    required this.userId,
    this.assignedClass,
    this.assignedSubject,
    this.name,
    this.email,
    this.subjectName,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      userId: json['user_id'],
      assignedClass: json['assigned_class'],
      assignedSubject: json['assigned_subject'],
      name: json['name'],
      email: json['email'],
      subjectName: json['subject_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assigned_class': assignedClass,
      'assigned_subject': assignedSubject,
    };
  }
}