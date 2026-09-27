enum IconType {
  travel,
  flight,
  hotel,
  food,
  restaurant,
  shopping,
  transportation,
  fuel,
  office,
  equipment,
  software,
  education,
  health,
  entertainment,
  other,
}

class Category {
  Category({
    this.id = 0,
    required this.name,
    required this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final int id;
  final String name;
  final IconType icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category copyWith({
    int? id,
    String? name,
    IconType? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
