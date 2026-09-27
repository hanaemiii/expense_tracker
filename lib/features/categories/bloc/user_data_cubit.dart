import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/errors/validation_exception.dart';

class UserDataState {
  const UserDataState({
    this.categories = const [],
    this.expenses = const [],
    this.categoriesReady = false,
    this.expensesReady = false,
    this.busy = false,
    this.error,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
  });

  final List<Category> categories;
  final List<Expense> expenses;
  final bool categoriesReady;
  final bool expensesReady;
  final bool busy;
  final String? error;
  final String? notice;
  final bool noticeIsError;
  final int noticeId;

  bool get loading => !categoriesReady || !expensesReady;

  UserDataState copyWith({
    List<Category>? categories,
    List<Expense>? expenses,
    bool? categoriesReady,
    bool? expensesReady,
    bool? busy,
    String? error,
    bool clearError = false,
    String? notice,
    bool? noticeIsError,
    int? noticeId,
  }) => UserDataState(
    categories: categories ?? this.categories,
    expenses: expenses ?? this.expenses,
    categoriesReady: categoriesReady ?? this.categoriesReady,
    expensesReady: expensesReady ?? this.expensesReady,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    notice: notice ?? this.notice,
    noticeIsError: noticeIsError ?? this.noticeIsError,
    noticeId: noticeId ?? this.noticeId,
  );
}

class UserDataCubit extends Cubit<UserDataState> {
  UserDataCubit(AppDependencies dependencies)
    : _dependencies = dependencies,
      super(const UserDataState()) {
    reload();
  }

  UserDataCubit.seeded(super.initialState) : _dependencies = null;

  final AppDependencies? _dependencies;

  AppDependencies get dependencies => _dependencies!;
  StreamSubscription<List<Category>>? _categoriesSubscription;
  StreamSubscription<List<Expense>>? _expensesSubscription;

  Future<void> reload() async {
    await _categoriesSubscription?.cancel();
    await _expensesSubscription?.cancel();
    if (isClosed) return;
    emit(
      state.copyWith(
        categoriesReady: false,
        expensesReady: false,
        clearError: true,
      ),
    );
    _categoriesSubscription = dependencies.categories.watch().listen((
      categories,
    ) {
      if (!isClosed) {
        emit(
          state.copyWith(
            categories: categories,
            categoriesReady: true,
            clearError: true,
          ),
        );
      }
    }, onError: _streamError);
    _expensesSubscription = dependencies.expenses.watch().listen((expenses) {
      if (!isClosed) {
        emit(
          state.copyWith(
            expenses: expenses,
            expensesReady: true,
            clearError: true,
          ),
        );
      }
    }, onError: _streamError);
  }

  void _streamError(Object error) {
    if (!isClosed) emit(state.copyWith(error: friendlyError(error)));
  }

  void _notice(String message, {bool error = false}) {
    if (!isClosed) {
      emit(
        state.copyWith(
          notice: message,
          noticeIsError: error,
          noticeId: state.noticeId + 1,
        ),
      );
    }
  }

  Future<bool> _perform(Future<void> Function() action, String success) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true));
    try {
      await action();
      _notice(success);
      return true;
    } catch (error) {
      _notice(friendlyError(error), error: true);
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<bool> createCategory(String name, IconType icon) => _perform(() async {
    await dependencies.categories.create(name: name, icon: icon);
  }, 'Category created');

  Future<bool> updateCategory(Category category) => _perform(() async {
    await dependencies.categories.update(category);
  }, 'Category updated');

  Future<bool> deleteCategory(Category category) => _perform(() async {
    if (state.expenses.any((expense) => expense.categoryId == category.id)) {
      throw const ValidationException(
        'Move or delete this category’s expenses first.',
      );
    }
    await dependencies.categories.delete(category.id);
  }, 'Category deleted');

  Future<bool> saveExpense(Expense expense) => _perform(() async {
    if (expense.id == 0) {
      await dependencies.expenses.create(expense);
    } else {
      await dependencies.expenses.update(expense);
    }
  }, expense.id == 0 ? 'Expense added' : 'Expense updated');

  Future<bool> deleteExpense(Expense expense) => _perform(
    () => dependencies.expenses.delete(expense.id),
    'Expense deleted',
  );

  Future<bool> submitExpenses(Set<int> ids) => _perform(
    () => dependencies.expenses.submit(ids),
    'Expenses submitted successfully.',
  );

  Future<bool> exportExpenses(Category category, List<Expense> expenses) =>
      _perform(() async {
        if (expenses.isEmpty) {
          throw const ValidationException(
            'Choose at least one expense to export.',
          );
        }
        final profile = await dependencies.profiles.get();
        final file = await dependencies.pdf.create(
          expenses: List.unmodifiable(expenses),
          category: category,
          profile: profile,
        );
        await dependencies.pdf.share(file);
      }, 'PDF ready to share');

  @override
  Future<void> close() async {
    await _categoriesSubscription?.cancel();
    await _expensesSubscription?.cancel();
    await super.close();
  }
}
