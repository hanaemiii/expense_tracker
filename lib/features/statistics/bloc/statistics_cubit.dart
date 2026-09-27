import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';

class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.amount,
    required this.count,
    required this.percent,
  });

  final int categoryId;
  final double amount;
  final int count;
  final double percent;
}

class SpendingSummary {
  const SpendingSummary({
    required this.total,
    required this.count,
    required this.breakdown,
  });

  final double total;
  final int count;
  final List<CategoryTotal> breakdown;
}

SpendingSummary calculateSpending(
  Iterable<Expense> expenses, {
  ExpenseStatus? status,
}) {
  final amounts = <int, double>{};
  final counts = <int, int>{};
  var total = 0.0;
  var count = 0;
  for (final expense in expenses) {
    if (expense.currency != 'USD' ||
        (status != null && expense.status != status) ||
        !expense.amount.isFinite ||
        expense.amount <= 0) {
      continue;
    }
    total += expense.amount;
    count++;
    amounts.update(
      expense.categoryId,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
    counts.update(expense.categoryId, (value) => value + 1, ifAbsent: () => 1);
  }
  final breakdown =
      amounts.entries
          .map(
            (entry) => CategoryTotal(
              categoryId: entry.key,
              amount: entry.value,
              count: counts[entry.key]!,
              percent: total == 0 ? 0 : entry.value / total * 100,
            ),
          )
          .toList()
        ..sort((a, b) {
          final comparison = b.amount.compareTo(a.amount);
          return comparison != 0
              ? comparison
              : a.categoryId.compareTo(b.categoryId);
        });
  return SpendingSummary(total: total, count: count, breakdown: breakdown);
}

class StatisticsState {
  const StatisticsState({
    this.expenses = const [],
    this.categories = const [],
    this.expensesReady = false,
    this.categoriesReady = false,
    this.status,
    this.error,
  });

  final List<Expense> expenses;
  final List<Category> categories;
  final bool expensesReady;
  final bool categoriesReady;
  final ExpenseStatus? status;
  final String? error;

  bool get loading => !expensesReady || !categoriesReady;

  SpendingSummary get summary => calculateSpending(expenses, status: status);

  Category? categoryFor(int id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  StatisticsState copyWith({
    List<Expense>? expenses,
    List<Category>? categories,
    bool? expensesReady,
    bool? categoriesReady,
    ExpenseStatus? status,
    bool clearStatus = false,
    String? error,
    bool clearError = false,
  }) => StatisticsState(
    expenses: expenses ?? this.expenses,
    categories: categories ?? this.categories,
    expensesReady: expensesReady ?? this.expensesReady,
    categoriesReady: categoriesReady ?? this.categoriesReady,
    status: clearStatus ? null : status ?? this.status,
    error: clearError ? null : error ?? this.error,
  );
}

class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit(this.dependencies) : super(const StatisticsState()) {
    reload();
  }

  final AppDependencies dependencies;
  StreamSubscription<List<Expense>>? _expensesSubscription;
  StreamSubscription<List<Category>>? _categoriesSubscription;

  Future<void> reload() async {
    await _expensesSubscription?.cancel();
    await _categoriesSubscription?.cancel();
    if (isClosed) return;
    emit(
      state.copyWith(
        expensesReady: false,
        categoriesReady: false,
        clearError: true,
      ),
    );
    _expensesSubscription = dependencies.expenses.watch().listen((value) {
      if (!isClosed) emit(state.copyWith(expenses: value, expensesReady: true));
    }, onError: _onError);
    _categoriesSubscription = dependencies.categories.watch().listen((value) {
      if (!isClosed) {
        emit(state.copyWith(categories: value, categoriesReady: true));
      }
    }, onError: _onError);
  }

  void _onError(Object error) {
    if (!isClosed) emit(state.copyWith(error: friendlyError(error)));
  }

  void setStatus(ExpenseStatus? status) =>
      emit(state.copyWith(status: status, clearStatus: status == null));

  @override
  Future<void> close() async {
    await _expensesSubscription?.cancel();
    await _categoriesSubscription?.cancel();
    await super.close();
  }
}
