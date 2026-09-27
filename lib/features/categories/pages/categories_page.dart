import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../bloc/user_data_cubit.dart';
import '../widgets/category_editor.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<UserDataCubit, UserDataState>(
        builder: (context, state) {
          final hasCategories = state.categories.isNotEmpty;
          return Scaffold(
            appBar: AppBar(title: const Text('Categories')),
            floatingActionButton: hasCategories
                ? FloatingActionButton(
                    heroTag: 'add-category',
                    tooltip: 'New category',
                    onPressed: () => showCategoryEditor(context),
                    child: const Icon(CupertinoIcons.add),
                  )
                : null,
            body: state.error != null
                ? ErrorState(onRetry: context.read<UserDataCubit>().reload)
                : state.loading
                ? const Center(child: CircularProgressIndicator())
                : _CategoriesContent(state: state),
          );
        },
      );
}

class _CategoriesContent extends StatelessWidget {
  const _CategoriesContent({required this.state});

  final UserDataState state;

  @override
  Widget build(BuildContext context) {
    final hasCategories = state.categories.isNotEmpty;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, hasCategories ? 116 : 40),
      children: [
        if (hasCategories) ...[
          _TotalExpensesCard(state: state),
          const SizedBox(height: 28),
        ],
        if (!hasCategories)
          EmptyState(
            icon: Icons.layers_outlined,
            title: 'No categories yet',
            subtitle: 'Create your first category.',
            action: FilledButton.icon(
              onPressed: () => showCategoryEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Category'),
            ),
          )
        else ...[
          ...state.categories.map((category) {
            final expenses = state.expenses
                .where((expense) => expense.categoryId == category.id)
                .toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SwipeActions(
                key: ValueKey(category.id),
                actions: [
                  IosAction(
                    label: 'Edit',
                    icon: CupertinoIcons.pencil,
                    onPressed: () => showCategoryEditor(context, category),
                  ),
                  IosAction(
                    label: 'Delete',
                    icon: CupertinoIcons.delete,
                    destructive: true,
                    onPressed: () async {
                      if (expenses.isNotEmpty) {
                        showFeedback(
                          context,
                          'Move or delete this category’s expenses first.',
                          error: true,
                        );
                        return;
                      }
                      if (await confirmAction(
                            context,
                            title: 'Delete ${category.name}?',
                            message:
                                'This category will be removed from your device.',
                            action: 'Delete',
                            destructive: true,
                          ) &&
                          context.mounted) {
                        context.read<UserDataCubit>().deleteCategory(category);
                      }
                    },
                  ),
                ],
                child: _CategoryTile(category: category, expenses: expenses),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _TotalExpensesCard extends StatelessWidget {
  const _TotalExpensesCard({required this.state});

  final UserDataState state;

  @override
  Widget build(BuildContext context) {
    final total = state.expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final count = state.expenses.length;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF2755FF), Color(0xFF597BFF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white70,
          ),
          const SizedBox(height: 18),
          const Text(
            'TOTAL EXPENSES',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            money(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count ${count == 1 ? 'expense' : 'expenses'} across ${state.categories.length} ${state.categories.length == 1 ? 'category' : 'categories'}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.expenses});

  final Category category;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    return AppCard(
      padding: const EdgeInsets.all(18),
      onTap: () => context.push('/category/${category.id}'),
      child: Row(
        children: [
          CategoryIcon(type: category.icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${expenses.length} ${expenses.length == 1 ? 'expense' : 'expenses'}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(total),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.muted,
                size: 14,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
