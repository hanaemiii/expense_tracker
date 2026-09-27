import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../../domain/entities/user_profile.dart';

enum AdminSort { newest, oldest, name, nameDescending, status }

List<Expense> filterAdminExpenses(
  Iterable<Expense> expenses, {
  AdminSort sort = AdminSort.newest,
  DateTime? from,
  DateTime? through,
  ExpenseStatus? status,
}) {
  final result = expenses.where((expense) {
    if (expense.status == ExpenseStatus.draft) return false;
    if (status != null && expense.status != status) return false;
    final day = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    if (from != null &&
        day.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (through != null &&
        day.isAfter(DateTime(through.year, through.month, through.day))) {
      return false;
    }
    return true;
  }).toList();
  result.sort((a, b) {
    final comparison = switch (sort) {
      AdminSort.newest => b.date.compareTo(a.date),
      AdminSort.oldest => a.date.compareTo(b.date),
      AdminSort.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      AdminSort.nameDescending => b.name.toLowerCase().compareTo(
        a.name.toLowerCase(),
      ),
      AdminSort.status => a.status.index.compareTo(b.status.index),
    };
    return comparison != 0 ? comparison : b.id.compareTo(a.id);
  });
  return result;
}

class AdminExpensesState {
  const AdminExpensesState({
    this.expenses = const [],
    this.categories = const [],
    this.profile,
    this.expensesReady = false,
    this.categoriesReady = false,
    this.profileReady = false,
    this.busy = false,
    this.error,
    this.notice,
    this.noticeIsError = false,
    this.noticeId = 0,
    this.sort = AdminSort.newest,
    this.from,
    this.through,
    this.status,
  });

  final List<Expense> expenses;
  final List<Category> categories;
  final UserProfile? profile;
  final bool expensesReady;
  final bool categoriesReady;
  final bool profileReady;
  final bool busy;
  final String? error;
  final String? notice;
  final bool noticeIsError;
  final int noticeId;
  final AdminSort sort;
  final DateTime? from;
  final DateTime? through;
  final ExpenseStatus? status;

  bool get loading => !expensesReady || !categoriesReady || !profileReady;
  List<Expense> get visible => filterAdminExpenses(
    expenses,
    sort: sort,
    from: from,
    through: through,
    status: status,
  );

  Category? categoryFor(int id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  AdminExpensesState copyWith({
    List<Expense>? expenses,
    List<Category>? categories,
    UserProfile? profile,
    bool? expensesReady,
    bool? categoriesReady,
    bool? profileReady,
    bool? busy,
    String? error,
    bool clearError = false,
    String? notice,
    bool? noticeIsError,
    int? noticeId,
    AdminSort? sort,
    DateTime? from,
    DateTime? through,
    bool clearRange = false,
    ExpenseStatus? status,
    bool clearStatus = false,
  }) => AdminExpensesState(
    expenses: expenses ?? this.expenses,
    categories: categories ?? this.categories,
    profile: profile ?? this.profile,
    expensesReady: expensesReady ?? this.expensesReady,
    categoriesReady: categoriesReady ?? this.categoriesReady,
    profileReady: profileReady ?? this.profileReady,
    busy: busy ?? this.busy,
    error: clearError ? null : error ?? this.error,
    notice: notice ?? this.notice,
    noticeIsError: noticeIsError ?? this.noticeIsError,
    noticeId: noticeId ?? this.noticeId,
    sort: sort ?? this.sort,
    from: clearRange ? null : from ?? this.from,
    through: clearRange ? null : through ?? this.through,
    status: clearStatus ? null : status ?? this.status,
  );
}

class AdminExpensesCubit extends Cubit<AdminExpensesState> {
  AdminExpensesCubit(this.dependencies) : super(const AdminExpensesState()) {
    reload();
  }

  final AppDependencies dependencies;
  StreamSubscription<List<Expense>>? _expensesSubscription;
  StreamSubscription<List<Category>>? _categoriesSubscription;
  StreamSubscription<UserProfile>? _profileSubscription;

  Future<void> reload() async {
    await _expensesSubscription?.cancel();
    await _categoriesSubscription?.cancel();
    await _profileSubscription?.cancel();
    if (isClosed) return;
    emit(
      state.copyWith(
        expensesReady: false,
        categoriesReady: false,
        profileReady: false,
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
    _profileSubscription = dependencies.profiles.watch().listen((value) {
      if (!isClosed) emit(state.copyWith(profile: value, profileReady: true));
    }, onError: _onError);
  }

  void _onError(Object error) {
    if (!isClosed) emit(state.copyWith(error: friendlyError(error)));
  }

  void setSort(AdminSort sort) => emit(state.copyWith(sort: sort));

  void setRange(DateTime from, DateTime through) =>
      emit(state.copyWith(from: from, through: through));

  void clearRange() => emit(state.copyWith(clearRange: true));

  void setStatus(ExpenseStatus? status) =>
      emit(state.copyWith(status: status, clearStatus: status == null));

  Future<bool> _perform(Future<void> Function() action, String success) async {
    if (state.busy) return false;
    emit(state.copyWith(busy: true));
    try {
      await action();
      if (!isClosed) {
        emit(
          state.copyWith(
            notice: success,
            noticeIsError: false,
            noticeId: state.noticeId + 1,
          ),
        );
      }
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            notice: friendlyError(error),
            noticeIsError: true,
            noticeId: state.noticeId + 1,
          ),
        );
      }
      return false;
    } finally {
      if (!isClosed) emit(state.copyWith(busy: false));
    }
  }

  Future<bool> startReview(int id) =>
      _perform(() => dependencies.expenses.startReview(id), 'Review started');

  Future<bool> finish(int id) =>
      _perform(() => dependencies.expenses.finish(id), 'Expense finished');

  Future<bool> reject(int id, {String? reason}) => _perform(
    () => dependencies.expenses.reject(id, reason: reason),
    'Expense rejected',
  );

  @override
  Future<void> close() async {
    await _expensesSubscription?.cancel();
    await _categoriesSubscription?.cancel();
    await _profileSubscription?.cancel();
    await super.close();
  }
}
