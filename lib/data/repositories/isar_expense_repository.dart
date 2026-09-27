import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../local/expense_local_data_source.dart';

class IsarExpenseRepository implements ExpenseRepository {
  IsarExpenseRepository(this.source);

  final ExpenseLocalDataSource source;

  @override
  Future<Expense> create(Expense expense) => source.create(expense);

  @override
  Future<Expense> update(Expense expense) => source.update(expense);

  @override
  Future<void> delete(int id) => source.delete(id);

  @override
  Future<Expense?> get(int id) => source.get(id);

  @override
  Stream<List<Expense>> watch() => source.watch();

  @override
  Future<void> submit(Set<int> ids) => source.submit(ids);

  @override
  Future<void> startReview(int id) => source.startReview(id);

  @override
  Future<void> finish(int id) => source.finish(id);

  @override
  Future<void> reject(int id, {String? reason}) =>
      source.reject(id, reason: reason);
}
