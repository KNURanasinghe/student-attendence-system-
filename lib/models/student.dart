class Student {
  final int id;
  final String name;
  final String grade;
  final String studentClass;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.studentClass,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      grade: json['grade'],
      studentClass: json['class'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'class': studentClass,
    };
  }
}