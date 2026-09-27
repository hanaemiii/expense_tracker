import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../expenses/bloc/expense_filter_cubit.dart';
import '../../expenses/widgets/expense_filter_sheet.dart';
import '../../expenses/widgets/expense_tile.dart';
import '../bloc/user_data_cubit.dart';

class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage({super.key, required this.categoryId});

  final int categoryId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ExpenseFilterCubit(),
    child: _CategoryDetailContent(categoryId: categoryId),
  );
}

class _CategoryDetailContent extends StatelessWidget {
  const _CategoryDetailContent({required this.categoryId});

  final int categoryId;

  void _enterSubmitFlow(BuildContext context, List<Expense> expenses) {
    final filters = context.read<ExpenseFilterCubit>();
    final eligible = expenses
        .where(canEditExpense)
        .map((expense) => expense.id)
        .toSet();
    if (eligible.isEmpty) {
      showFeedback(
        context,
        'There are no draft or rejected expenses to submit.',
        error: true,
      );
    } else {
      filters.selectAll(eligible);
    }
  }

  Future<void> _submit(BuildContext context, Set<int> ids) async {
    final selected = context.read<ExpenseFilterCubit>().state.selected;
    if (selected.difference(ids).isNotEmpty) {
      showFeedback(
        context,
        'Only draft or rejected expenses can be submitted. Deselect read-only expenses.',
        error: true,
      );
      return;
    }
    if (ids.isEmpty) {
      showFeedback(
        context,
        'Select a draft or rejected expense first.',
        error: true,
      );
      return;
    }
    final confirmed = await confirmAction(
      context,
      title: 'Submit selected expenses for review?',
      message:
          'Submitted expenses become read-only while they are reviewed. You can edit them again only if rejected.',
      action: 'Submit for review',
    );
    if (!confirmed || !context.mounted) return;
    final success = await context.read<UserDataCubit>().submitExpenses(ids);
    if (success && context.mounted) {
      context.read<ExpenseFilterCubit>().removeSelected(ids);
    }
  }

  Future<void> _export(
    BuildContext context,
    Category category,
    List<Expense> expenses,
  ) async {
    if (expenses.isEmpty) {
      showFeedback(context, 'There are no expenses to export.', error: true);
      return;
    }
    await context.read<UserDataCubit>().exportExpenses(category, expenses);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserDataCubit>().state;
    final filter = context.watch<ExpenseFilterCubit>().state;
    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(onRetry: context.read<UserDataCubit>().reload),
      );
    }
    Category? category;
    for (final item in state.categories) {
      if (item.id == categoryId) category = item;
    }
    if (category == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.folder_off_outlined,
          title: 'Category not found',
          subtitle: 'This category may have been removed.',
        ),
      );
    }
    final currentCategory = category;
    final expenses = state.expenses
        .where((item) => item.categoryId == categoryId)
        .toList();
    final selecting = filter.selected.isNotEmpty;
    final visible = selecting
        ? const ExpenseFilterState(view: ExpenseView.all).apply(expenses)
        : filter.apply(expenses);
    final selected = filter.selected.intersection(
      expenses.map((expense) => expense.id).toSet(),
    );
    final submitIds = selected.intersection(
      expenses.where(canEditExpense).map((expense) => expense.id).toSet(),
    );
    final exportSelected = expenses
        .where((expense) => selected.contains(expense.id))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          selecting ? '${selected.length} selected' : currentCategory.name,
        ),
        actions: [
          if (selecting)
            CupertinoButton(
              onPressed: () => context.read<ExpenseFilterCubit>().deselectAll(),
              child: const Text('Done'),
            ),
          IconButton(
            tooltip: 'Actions',
            icon: const Icon(CupertinoIcons.ellipsis_circle),
            onPressed: () => showIosActions(context, [
              IosAction(
                label: selecting
                    ? 'Export ${selected.length} to PDF'
                    : 'Export to PDF',
                icon: CupertinoIcons.share,
                enabled:
                    !state.busy &&
                    (selecting
                        ? exportSelected.isNotEmpty
                        : expenses.isNotEmpty),
                onPressed: () => _export(
                  context,
                  currentCategory,
                  selecting ? exportSelected : expenses,
                ),
              ),
              IosAction(
                label: selecting
                    ? 'Submit ${selected.length} expenses'
                    : 'Submit expenses',
                icon: CupertinoIcons.paperplane,
                enabled: !state.busy,
                onPressed: () => selecting
                    ? _submit(context, submitIds)
                    : _enterSubmitFlow(context, expenses),
              ),
            ]),
          ),
        ],
      ),
      floatingActionButton: selecting || expenses.isEmpty
          ? null
          : FloatingActionButton(
              heroTag: 'add-expense',
              tooltip: 'Add expense',
              onPressed: () =>
                  context.push('/expense/create?categoryId=$categoryId'),
              child: const Icon(CupertinoIcons.add),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
        children: [
          if (!selecting && expenses.isNotEmpty) ...[
            CupertinoSlidingSegmentedControl<ExpenseView>(
              groupValue: filter.view,
              backgroundColor: AppColors.primary,
              thumbColor: Colors.white,
              children: {
                ExpenseView.active: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  child: Text(
                    'Created',
                    style: TextStyle(
                      color: filter.view == ExpenseView.active
                          ? AppColors.ink
                          : Colors.white,
                    ),
                  ),
                ),
                ExpenseView.history: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  child: Text(
                    'History',
                    style: TextStyle(
                      color: filter.view == ExpenseView.history
                          ? AppColors.ink
                          : Colors.white,
                    ),
                  ),
                ),
                ExpenseView.all: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  child: Text(
                    'All',
                    style: TextStyle(
                      color: filter.view == ExpenseView.all
                          ? AppColors.ink
                          : Colors.white,
                    ),
                  ),
                ),
              },
              onValueChanged: (view) {
                if (view != null) {
                  context.read<ExpenseFilterCubit>().setView(view);
                }
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Expenses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.outlined(
                  onPressed: () => showExpenseFilters(context),
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Filter expenses',
                ),
              ],
            ),
          ],
          if (selecting)
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                onPressed: () => context.read<ExpenseFilterCubit>().selectAll(
                  visible.map((expense) => expense.id),
                ),
                child: const Text('Select all visible'),
              ),
            ),
          if (visible.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: expenses.isEmpty
                  ? 'No expenses yet'
                  : 'No matching expenses',
              subtitle: expenses.isEmpty
                  ? 'Create your first expense.'
                  : 'Try another view or adjust your filters.',
              action: expenses.isEmpty
                  ? FilledButton(
                      onPressed: () => context.push(
                        '/expense/create?categoryId=$categoryId',
                      ),
                      child: const Text('Add an expense'),
                    )
                  : TextButton(
                      onPressed: () =>
                          context.read<ExpenseFilterCubit>().clear(),
                      child: const Text('Clear filters'),
                    ),
            ),
          ...visible.map(
            (expense) => ExpenseTile(
              expense: expense,
              onTap: () => selecting
                  ? context.read<ExpenseFilterCubit>().toggle(expense.id)
                  : context.push('/expense/${expense.id}'),
              onLongPress: () =>
                  context.read<ExpenseFilterCubit>().toggle(expense.id),
              selected: selecting ? selected.contains(expense.id) : null,
              onSelected: (_) =>
                  context.read<ExpenseFilterCubit>().toggle(expense.id),
              actions: selecting || !canEditExpense(expense)
                  ? const []
                  : [
                      IosAction(
                        label: 'Edit',
                        icon: CupertinoIcons.pencil,
                        onPressed: () =>
                            context.push('/expense/${expense.id}/edit'),
                      ),
                      IosAction(
                        label: 'Delete',
                        icon: CupertinoIcons.delete,
                        destructive: true,
                        onPressed: () async {
                          if (await confirmAction(
                                context,
                                title: 'Delete ${expense.name}?',
                                message:
                                    'This expense will be removed from your device.',
                                action: 'Delete',
                                destructive: true,
                              ) &&
                              context.mounted) {
                            context.read<UserDataCubit>().deleteExpense(
                              expense,
                            );
                          }
                        },
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
