import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../local/category_local_data_source.dart';

class IsarCategoryRepository implements CategoryRepository {
  IsarCategoryRepository(this.source);

  final CategoryLocalDataSource source;

  @override
  Future<Category> create(String name, IconType icon) =>
      source.create(name, icon);

  @override
  Future<Category> update(Category category) => source.update(category);

  @override
  Future<void> delete(int id) => source.delete(id);

  @override
  Future<Category?> get(int id) => source.get(id);

  @override
  Future<bool> hasExpenses(int id) => source.hasExpenses(id);

  @override
  Stream<List<Category>> watch() => source.watch();
}
