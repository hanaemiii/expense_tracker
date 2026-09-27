import 'package:isar/isar.dart';

import '../../domain/entities/category.dart';
import '../../domain/errors/validation_exception.dart';
import '../../domain/usecases/category_actions.dart';
import '../models/category_record.dart';
import '../models/expense_record.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this.isar);

  final Isar isar;

  Future<Category> create(String name, IconType icon) => isar.writeTxn(
    () async {
      CategoryActions.validateName(name);
      final now = DateTime.now();
      final record = CategoryRecord.fromEntity(
        Category(name: name.trim(), icon: icon, createdAt: now, updatedAt: now),
      );
      record.id = await isar.categoryRecords.put(record);
      return record.toEntity();
    },
  );

  Future<Category> update(Category category) => isar.writeTxn(() async {
    CategoryActions.validateName(category.name);
    final old = await isar.categoryRecords.get(category.id);
    if (old == null) {
      throw const ValidationException('This category no longer exists.');
    }
    if (old.updatedAt != category.updatedAt ||
        old.createdAt != category.createdAt) {
      throw const ValidationException(
        'This category changed. Reload it before saving.',
      );
    }
    final updated = CategoryRecord.fromEntity(
      category.copyWith(name: category.name.trim(), updatedAt: DateTime.now()),
    );
    await isar.categoryRecords.put(updated);
    return updated.toEntity();
  });

  Future<void> delete(int id) => isar.writeTxn(() async {
    final category = await isar.categoryRecords.get(id);
    if (category == null) {
      throw const ValidationException('This category no longer exists.');
    }
    final expenseCount = await isar.expenseRecords
        .filter()
        .categoryIdEqualTo(id)
        .count();
    if (expenseCount > 0) {
      throw const ValidationException(
        'Move or delete expenses in this category before deleting it.',
      );
    }
    await isar.categoryRecords.delete(id);
  });

  Future<Category?> get(int id) async =>
      (await isar.categoryRecords.get(id))?.toEntity();

  Future<bool> hasExpenses(int id) async =>
      await isar.expenseRecords.filter().categoryIdEqualTo(id).count() > 0;

  Stream<List<Category>> watch() => isar.categoryRecords
      .where()
      .watch(fireImmediately: true)
      .map(
        (records) => List<Category>.unmodifiable(
          records.map((record) => record.toEntity()),
        ),
      );
}
