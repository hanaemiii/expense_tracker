import 'package:isar/isar.dart';

import '../../domain/entities/expense.dart';
import '../../domain/errors/validation_exception.dart';
import '../../domain/usecases/expense_actions.dart';
import '../models/category_record.dart';
import '../models/expense_record.dart';

class ExpenseLocalDataSource {
  ExpenseLocalDataSource(this.isar);

  final Isar isar;

  Future<Expense> create(Expense expense) => isar.writeTxn(() async {
    if (expense.id != 0 || expense.status != ExpenseStatus.draft) {
      throw const ValidationException('New expenses must start as drafts.');
    }
    ExpenseActions.validateFields(expense);
    await _requireCategory(expense.categoryId);
    final now = DateTime.now();
    final record = ExpenseRecord.fromEntity(
      expense.copyWith(
        name: expense.name.trim(),
        currency: expense.currency.trim(),
        createdAt: now,
        updatedAt: now,
        submittedAt: null,
        reviewedAt: null,
        adminId: null,
        rejectionReason: null,
      ),
    );
    record.id = await isar.expenseRecords.put(record);
    return record.toEntity();
  });

  Future<Expense> update(Expense expense) => isar.writeTxn(() async {
    ExpenseActions.validateFields(expense);
    final old = await _required(expense.id);
    ExpenseActions.validateEdit(old.toEntity(), expense);
    if (old.updatedAt != expense.updatedAt) {
      throw const ValidationException(
        'This expense changed. Reload it before saving.',
      );
    }
    await _requireCategory(expense.categoryId);
    final record = ExpenseRecord.fromEntity(
      expense.copyWith(
        name: expense.name.trim(),
        currency: expense.currency.trim(),
        updatedAt: DateTime.now(),
      ),
    );
    await isar.expenseRecords.put(record);
    return record.toEntity();
  });

  Future<void> delete(int id) => isar.writeTxn(() async {
    final record = await _required(id);
    ExpenseActions.validateCanEdit(record.toEntity());
    await isar.expenseRecords.delete(id);
  });

  Future<Expense?> get(int id) async =>
      (await isar.expenseRecords.get(id))?.toEntity();

  Stream<List<Expense>> watch() => isar.expenseRecords
      .where()
      .watch(fireImmediately: true)
      .map(
        (records) => List<Expense>.unmodifiable(
          records.map((record) => record.toEntity()),
        ),
      );

  Future<void> submit(Set<int> ids) => isar.writeTxn(() async {
    if (ids.isEmpty) {
      throw const ValidationException('Select at least one expense to submit.');
    }
    final records = <ExpenseRecord>[];
    for (final id in ids) {
      final record = await _required(id);
      final expense = record.toEntity();
      ExpenseActions.validateTransition(expense, ExpenseStatus.submitted);
      ExpenseActions.validateFields(expense);
      await _requireCategory(expense.categoryId);
      records.add(record);
    }
    final now = DateTime.now();
    for (final record in records) {
      record
        ..status = ExpenseStatus.submitted.name
        ..submittedAt = now
        ..reviewedAt = null
        ..adminId = null
        ..rejectionReason = null
        ..updatedAt = now;
    }
    await isar.expenseRecords.putAll(records);
  });

  Future<void> startReview(int id) => _transition(id, ExpenseStatus.inProgress);

  Future<void> finish(int id) => _transition(id, ExpenseStatus.finished);

  Future<void> reject(int id, {String? reason}) =>
      _transition(id, ExpenseStatus.rejected, reason: reason);

  Future<void> _transition(int id, ExpenseStatus next, {String? reason}) =>
      isar.writeTxn(() async {
        final record = await _required(id);
        ExpenseActions.validateTransition(record.toEntity(), next);
        final now = DateTime.now();
        record
          ..status = next.name
          ..adminId = 1
          ..updatedAt = now
          ..reviewedAt = now
          ..rejectionReason = next == ExpenseStatus.rejected
              ? (reason?.trim().isEmpty == true ? null : reason?.trim())
              : null;
        await isar.expenseRecords.put(record);
      });

  Future<ExpenseRecord> _required(int id) async {
    final record = await isar.expenseRecords.get(id);
    if (record == null) {
      throw const ValidationException('This expense no longer exists.');
    }
    return record;
  }

  Future<void> _requireCategory(int id) async {
    if (id <= 0 || await isar.categoryRecords.get(id) == null) {
      throw const ValidationException(
        'This category no longer exists. Choose another category.',
      );
    }
  }
}
