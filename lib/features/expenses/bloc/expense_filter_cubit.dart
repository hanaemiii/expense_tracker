import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/expense.dart';

enum ExpenseView { active, history, all }

enum ExpenseSort { newest, nameAscending, nameDescending }

enum ExpenseDatePreset { any, today, thisWeek, thisMonth, custom }

({DateTime from, DateTime to}) expenseDateBounds(
  ExpenseDatePreset preset,
  DateTime now,
) {
  final day = DateTime(now.year, now.month, now.day);
  return switch (preset) {
    ExpenseDatePreset.today => (from: day, to: day),
    ExpenseDatePreset.thisWeek => (
      from: DateTime(day.year, day.month, day.day - day.weekday + 1),
      to: DateTime(day.year, day.month, day.day - day.weekday + 7),
    ),
    ExpenseDatePreset.thisMonth => (
      from: DateTime(day.year, day.month, 1),
      to: DateTime(day.year, day.month + 1, 0),
    ),
    ExpenseDatePreset.any || ExpenseDatePreset.custom =>
      throw ArgumentError.value(preset, 'preset', 'Choose a calendar preset'),
  };
}

String expenseSortLabel(ExpenseSort sort) => switch (sort) {
  ExpenseSort.newest => 'Newest first',
  ExpenseSort.nameAscending => 'Name A→Z',
  ExpenseSort.nameDescending => 'Name Z→A',
};

class ExpenseFilterState {
  const ExpenseFilterState({
    this.view = ExpenseView.active,
    this.statuses = const {},
    this.query = '',
    this.from,
    this.to,
    this.sort = ExpenseSort.newest,
    this.datePreset = ExpenseDatePreset.any,
    this.selected = const {},
  });

  final ExpenseView view;
  final Set<ExpenseStatus> statuses;
  final String query;
  final DateTime? from;
  final DateTime? to;
  final ExpenseSort sort;
  final ExpenseDatePreset datePreset;
  final Set<int> selected;

  bool accepts(Expense expense) {
    if (view == ExpenseView.active && expense.status != ExpenseStatus.draft) {
      return false;
    }
    if (view == ExpenseView.history && expense.status == ExpenseStatus.draft) {
      return false;
    }
    if (statuses.isNotEmpty && !statuses.contains(expense.status)) return false;
    if (!expense.name.toLowerCase().contains(query.trim().toLowerCase())) {
      return false;
    }
    final day = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    if (from != null &&
        day.isBefore(DateTime(from!.year, from!.month, from!.day))) {
      return false;
    }
    if (to != null && day.isAfter(DateTime(to!.year, to!.month, to!.day))) {
      return false;
    }
    return true;
  }

  List<Expense> visibleExpenses(Iterable<Expense> expenses) => apply(expenses);

  List<Expense> apply(Iterable<Expense> expenses) {
    final visible = expenses.where(accepts).toList();
    visible.sort((a, b) {
      final result = switch (sort) {
        ExpenseSort.newest => b.date.compareTo(a.date),
        ExpenseSort.nameAscending => _compareNames(a.name, b.name),
        ExpenseSort.nameDescending => _compareNames(b.name, a.name),
      };
      return result == 0 ? a.id.compareTo(b.id) : result;
    });
    return visible;
  }

  ExpenseFilterState copyWith({
    ExpenseView? view,
    Set<ExpenseStatus>? statuses,
    String? query,
    DateTime? from,
    DateTime? to,
    ExpenseSort? sort,
    ExpenseDatePreset? datePreset,
    bool clearDates = false,
    Set<int>? selected,
  }) => ExpenseFilterState(
    view: view ?? this.view,
    statuses: statuses ?? this.statuses,
    query: query ?? this.query,
    from: clearDates ? null : from ?? this.from,
    to: clearDates ? null : to ?? this.to,
    sort: sort ?? this.sort,
    datePreset: datePreset ?? this.datePreset,
    selected: selected ?? this.selected,
  );

  static int _compareNames(String first, String second) =>
      first.trim().toLowerCase().compareTo(second.trim().toLowerCase());
}

class ExpenseFilterCubit extends Cubit<ExpenseFilterState> {
  ExpenseFilterCubit({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const ExpenseFilterState());

  final DateTime Function() _now;

  void setView(ExpenseView view) =>
      emit(state.copyWith(view: view, selected: {}));

  void setQuery(String query) =>
      emit(state.copyWith(query: query, selected: {}));

  void setStatuses(Set<ExpenseStatus> statuses) =>
      emit(state.copyWith(statuses: {...statuses}, selected: {}));

  void setSort(ExpenseSort sort) =>
      emit(state.copyWith(sort: sort, selected: {}));

  void setDates(DateTime? from, DateTime? to) => applyFilters(
    query: state.query,
    statuses: state.statuses,
    sort: state.sort,
    datePreset: from == null && to == null
        ? ExpenseDatePreset.any
        : ExpenseDatePreset.custom,
    from: from,
    to: to,
  );

  ({DateTime from, DateTime to}) previewDateBounds(ExpenseDatePreset preset) =>
      expenseDateBounds(preset, _now());

  void setDatePreset(ExpenseDatePreset preset, [DateTime? now]) => applyFilters(
    query: state.query,
    statuses: state.statuses,
    sort: state.sort,
    datePreset: preset,
    now: now,
  );

  void applyFilters({
    required String query,
    required Set<ExpenseStatus> statuses,
    required ExpenseSort sort,
    required ExpenseDatePreset datePreset,
    DateTime? from,
    DateTime? to,
    DateTime? now,
  }) {
    if (datePreset != ExpenseDatePreset.any &&
        datePreset != ExpenseDatePreset.custom) {
      final bounds = expenseDateBounds(datePreset, now ?? _now());
      from = bounds.from;
      to = bounds.to;
    }
    emit(
      ExpenseFilterState(
        view: state.view,
        statuses: {...statuses},
        query: query,
        sort: sort,
        datePreset: datePreset,
        from: datePreset == ExpenseDatePreset.any ? null : from,
        to: datePreset == ExpenseDatePreset.any ? null : to,
      ),
    );
  }

  void setFilters({
    required String query,
    required Set<ExpenseStatus> statuses,
    required DateTime? from,
    required DateTime? to,
    required ExpenseSort sort,
  }) {
    emit(
      ExpenseFilterState(
        view: state.view,
        statuses: {...statuses},
        query: query,
        from: from,
        to: to,
        sort: sort,
        selected: const {},
      ),
    );
  }

  void clear() => emit(const ExpenseFilterState());

  void toggle(int id) {
    final next = {...state.selected};
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(selected: next));
  }

  void selectAll(Iterable<int> ids) => emit(state.copyWith(selected: {...ids}));

  void deselectAll() => emit(state.copyWith(selected: {}));

  void removeSelected(Set<int> ids) =>
      emit(state.copyWith(selected: {...state.selected}..removeAll(ids)));
}
