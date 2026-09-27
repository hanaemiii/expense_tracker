import 'package:isar/isar.dart';

import '../../domain/entities/category.dart';

part 'category_record.g.dart';

@collection
class CategoryRecord {
  Id id = Isar.autoIncrement;
  late String name;
  late String icon;
  late DateTime createdAt;
  late DateTime updatedAt;

  Category toEntity() => Category(
    id: id,
    name: name,
    icon: IconType.values.firstWhere(
      (candidate) => candidate.name == icon,
      orElse: () => IconType.other,
    ),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  static CategoryRecord fromEntity(Category category) => CategoryRecord()
    ..id = category.id == 0 ? Isar.autoIncrement : category.id
    ..name = category.name
    ..icon = category.icon.name
    ..createdAt = category.createdAt
    ..updatedAt = category.updatedAt;
}
