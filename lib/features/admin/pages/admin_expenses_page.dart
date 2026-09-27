import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../bloc/admin_expenses_cubit.dart';
import '../widgets/admin_review_filter_sheet.dart';

class AdminExpensesPage extends StatelessWidget {
  const AdminExpensesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AdminExpensesCubit(context.read<AppDependencies>()),
    child: const _AdminExpensesView(),
  );
}

class _AdminExpensesView extends StatelessWidget {
  const _AdminExpensesView();

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AdminExpensesCubit, AdminExpensesState>(
    builder: (context, state) {
      final items = state.visible;
      final submitted = state.expenses
          .where((item) => item.status == ExpenseStatus.submitted)
          .length;
      final inReview = state.expenses
          .where((item) => item.status == ExpenseStatus.inProgress)
          .length;
      return Scaffold(
        appBar: AppBar(title: const Text('Review expenses')),
        body: state.error != null
            ? ErrorState(onRetry: context.read<AdminExpensesCubit>().reload)
            : state.loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: context.read<AdminExpensesCubit>().reload,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 116),
                  children: [
                    _ReviewOverview(submitted: submitted, inReview: inReview),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'All submissions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Text(
                          '${items.length}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () => showAdminReviewFilters(context, state),
                        icon: const Icon(Icons.tune_rounded),
                        label: Text(
                          state.status != null ||
                                  state.from != null ||
                                  state.sort != AdminSort.newest
                              ? 'Filter & sort · Active'
                              : 'Filter & sort',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      AppCard(
                        child: EmptyState(
                          icon: Icons.inbox_rounded,
                          title:
                              state.expenses.every(
                                (item) => item.status == ExpenseStatus.draft,
                              )
                              ? "You're all caught up."
                              : 'No matching expenses',
                          subtitle:
                              state.expenses.every(
                                (item) => item.status == ExpenseStatus.draft,
                              )
                              ? 'Submitted expenses will appear here as soon as they are ready for review.'
                              : 'Try another status or date range to see more expenses.',
                          action:
                              state.from != null ||
                                  state.status != null ||
                                  state.sort != AdminSort.newest
                              ? TextButton(
                                  onPressed: () {
                                    final cubit = context
                                        .read<AdminExpensesCubit>();
                                    cubit.clearRange();
                                    cubit.setStatus(null);
                                    cubit.setSort(AdminSort.newest);
                                  },
                                  child: const Text('Clear filters'),
                                )
                              : null,
                        ),
                      )
                    else
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ReviewTile(expense: item, state: state),
                        ),
                      ),
                  ],
                ),
              ),
      );
    },
  );
}

class _ReviewOverview extends StatelessWidget {
  const _ReviewOverview({required this.submitted, required this.inReview});
  final int submitted;
  final int inReview;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFF597BFF)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.fact_check_rounded, color: Colors.white70, size: 28),
        const SizedBox(height: 18),
        const Text(
          'REVIEW QUEUE',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${submitted + inReview}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$submitted awaiting review  ·  $inReview in progress',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.expense, required this.state});
  final Expense expense;
  final AdminExpensesState state;

  @override
  Widget build(BuildContext context) {
    final category = state.categoryFor(expense.categoryId);
    return AppCard(
      padding: const EdgeInsets.all(17),
      onTap: () => context.push('/admin/expense/${expense.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(type: category?.icon ?? IconType.other),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  '${state.profile?.fullName.isNotEmpty == true ? state.profile!.fullName : 'Local user'} · ${category?.name ?? 'Uncategorized'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(child: StatusBadge(status: expense.status)),
                    const SizedBox(width: 8),
                    Text(
                      shortDate(expense.date),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            money(expense.amount, expense.currency),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
