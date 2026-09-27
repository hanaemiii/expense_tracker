import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<Expense> create(Expense expense);
  Future<Expense> update(Expense expense);
  Future<void> delete(int id);
  Future<Expense?> get(int id);
  Stream<List<Expense>> watch();
  Future<void> submit(Set<int> ids);
  Future<void> startReview(int id);
  Future<void> finish(int id);
  Future<void> reject(int id, {String? reason});
}
