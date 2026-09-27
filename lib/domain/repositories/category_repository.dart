import '../entities/category.dart';

abstract class CategoryRepository {
  Future<Category> create(String name, IconType icon);
  Future<Category> update(Category category);
  Future<void> delete(int id);
  Future<Category?> get(int id);
  Future<bool> hasExpenses(int id);
  Stream<List<Category>> watch();
}
