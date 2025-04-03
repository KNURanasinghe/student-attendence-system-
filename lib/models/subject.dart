class Subject {
  final int id;
  final String name;
  final bool isBasket;

  Subject({
    required this.id,
    required this.name,
    required this.isBasket,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      isBasket: json['is_basket'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_basket': isBasket,
    };
  }
}