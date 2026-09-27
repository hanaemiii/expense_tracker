import '../entities/expense.dart';
import '../errors/validation_exception.dart';
import '../repositories/expense_repository.dart';

class ExpenseActions {
  ExpenseActions(this.repository);

  final ExpenseRepository repository;

  Future<Expense> create(Expense expense) {
    if (expense.id != 0 || expense.status != ExpenseStatus.draft) {
      throw const ValidationException('New expenses must start as drafts.');
    }
    validateFields(expense);
    return repository.create(expense);
  }

  Future<Expense> update(Expense expense) async {
    if (expense.id <= 0) {
      throw const ValidationException('Choose an expense to edit.');
    }
    validateFields(expense);
    final current = await repository.get(expense.id);
    if (current == null) {
      throw const ValidationException('This expense no longer exists.');
    }
    validateEdit(current, expense);
    return repository.update(expense);
  }

  Future<void> delete(int id) async {
    final current = await _required(id);
    validateCanEdit(current);
    await repository.delete(id);
  }

  Future<Expense?> get(int id) => repository.get(id);

  Stream<List<Expense>> watch() => repository.watch();

  Future<void> submit(Set<int> ids) async {
    if (ids.isEmpty) {
      throw const ValidationException('Select at least one expense to submit.');
    }
    for (final id in ids) {
      final expense = await _required(id);
      validateTransition(expense, ExpenseStatus.submitted);
      validateFields(expense);
    }
    await repository.submit(ids);
  }

  Future<void> startReview(int id) => _transition(id, ExpenseStatus.inProgress);

  Future<void> finish(int id) => _transition(id, ExpenseStatus.finished);

  Future<void> reject(int id, {String? reason}) async {
    final expense = await _required(id);
    validateTransition(expense, ExpenseStatus.rejected);
    await repository.reject(id, reason: reason?.trim());
  }

  Future<void> _transition(int id, ExpenseStatus next) async {
    final expense = await _required(id);
    validateTransition(expense, next);
    switch (next) {
      case ExpenseStatus.inProgress:
        await repository.startReview(id);
      case ExpenseStatus.finished:
        await repository.finish(id);
      default:
        throw StateError('Unsupported transition: $next');
    }
  }

  Future<Expense> _required(int id) async {
    final expense = await repository.get(id);
    if (expense == null) {
      throw const ValidationException('This expense no longer exists.');
    }
    return expense;
  }

  static void validateFields(Expense expense) {
    if (expense.categoryId <= 0) {
      throw const ValidationException('Choose a category for this expense.');
    }
    if (!expense.amount.isFinite || expense.amount <= 0) {
      throw const ValidationException('Enter an amount greater than zero.');
    }
    if (expense.currency != 'USD') {
      throw const ValidationException('Only USD is supported for expenses.');
    }
  }

  static void validateCanEdit(Expense expense) {
    if (expense.status != ExpenseStatus.draft &&
        expense.status != ExpenseStatus.rejected) {
      throw const ValidationException(
        'Only draft or rejected expenses can be edited or deleted.',
      );
    }
  }

  static void validateEdit(Expense current, Expense edited) {
    validateCanEdit(current);
    if ((current.currency != edited.currency &&
            !(current.currency != 'USD' && edited.currency == 'USD')) ||
        current.status != edited.status ||
        current.createdAt != edited.createdAt ||
        current.submittedAt != edited.submittedAt ||
        current.reviewedAt != edited.reviewedAt ||
        current.adminId != edited.adminId ||
        current.rejectionReason != edited.rejectionReason) {
      throw const ValidationException(
        'Currency or review details cannot be edited directly.',
      );
    }
    if (current.updatedAt != edited.updatedAt) {
      throw const ValidationException(
        'This expense changed. Reload it before saving.',
      );
    }
  }

  static void validateTransition(Expense expense, ExpenseStatus next) {
    final valid = switch ((expense.status, next)) {
      (ExpenseStatus.draft, ExpenseStatus.submitted) => true,
      (ExpenseStatus.rejected, ExpenseStatus.submitted) => true,
      (ExpenseStatus.submitted, ExpenseStatus.inProgress) => true,
      (ExpenseStatus.inProgress, ExpenseStatus.finished) => true,
      (ExpenseStatus.submitted, ExpenseStatus.rejected) => true,
      (ExpenseStatus.inProgress, ExpenseStatus.rejected) => true,
      _ => false,
    };
    if (!valid) {
      throw ValidationException(
        'Cannot change this expense from ${_label(expense.status)} to ${_label(next)}.',
      );
    }
  }

  static String _label(ExpenseStatus status) => switch (status) {
    ExpenseStatus.draft => 'Draft',
    ExpenseStatus.submitted => 'Submitted',
    ExpenseStatus.inProgress => 'In Progress',
    ExpenseStatus.finished => 'Finished',
    ExpenseStatus.rejected => 'Rejected',
  };
}
