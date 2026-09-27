import '../entities/category.dart';
import '../errors/validation_exception.dart';
import '../repositories/category_repository.dart';

class CategoryActions {
  CategoryActions(this.repository);

  final CategoryRepository repository;

  Future<Category> create({required String name, required IconType icon}) {
    validateName(name);
    return repository.create(name.trim(), icon);
  }

  Future<Category> update(Category category) {
    if (category.id <= 0) {
      throw const ValidationException('Choose a category to edit.');
    }
    validateName(category.name);
    return repository.update(category.copyWith(name: category.name.trim()));
  }

  Future<void> delete(int id) async {
    if (id <= 0) {
      throw const ValidationException('Choose a category to delete.');
    }
    if (await repository.get(id) == null) {
      throw const ValidationException('This category no longer exists.');
    }
    if (await repository.hasExpenses(id)) {
      throw const ValidationException(
        'Move or delete expenses in this category before deleting it.',
      );
    }
    await repository.delete(id);
  }

  Future<Category?> get(int id) => repository.get(id);

  Stream<List<Category>> watch() => repository.watch();

  static void validateName(String name) {
    if (name.trim().isEmpty) {
      throw const ValidationException('Enter a category name.');
    }
  }
}
