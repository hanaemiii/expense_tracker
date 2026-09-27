import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/expense.dart';
import '../../categories/bloc/user_data_cubit.dart';
import '../widgets/receipt_image.dart';

class ExpenseDetailPage extends StatelessWidget {
  const ExpenseDetailPage({super.key, required this.expenseId});

  final int expenseId;

  Future<void> _delete(BuildContext context, Expense expense) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this expense?',
      message: 'This will permanently remove ${expense.name} from your device.',
      action: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    if (await context.read<UserDataCubit>().deleteExpense(expense) &&
        context.mounted) {
      context.pop();
    }
  }

  Future<void> _submit(BuildContext context, Expense expense) async {
    final confirmed = await confirmAction(
      context,
      title: 'Submit expense?',
      message: 'This expense will become read-only while it is being reviewed.',
      action: 'Submit for review',
    );
    if (confirmed && context.mounted) {
      await context.read<UserDataCubit>().submitExpenses({expense.id});
    }
  }

  Future<void> _showActions(BuildContext context, Expense expense) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (sheetContext) => CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.light,
          primaryColor: AppColors.primary,
        ),
        child: CupertinoActionSheet(
          title: const Text('Expense actions'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(sheetContext, 'edit'),
              child: const Text('Edit expense'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(sheetContext, 'delete'),
              child: const Text('Delete expense'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Cancel'),
          ),
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') context.push('/expense/$expenseId/edit');
    if (action == 'delete') await _delete(context, expense);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserDataCubit>().state;
    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(onRetry: context.read<UserDataCubit>().reload),
      );
    }
    Expense? expense;
    for (final item in state.expenses) {
      if (item.id == expenseId) expense = item;
    }
    if (expense == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Expense not found',
          subtitle: 'This expense may have been removed.',
        ),
      );
    }
    Category? category;
    for (final item in state.categories) {
      if (item.id == expense.categoryId) category = item;
    }
    final currentExpense = expense;
    final currentCategory = category;
    final editable = canEditExpense(currentExpense);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense details'),
        actions: [
          if (editable)
            IconButton(
              tooltip: 'Expense actions',
              onPressed: () => _showActions(context, currentExpense),
              icon: const Icon(CupertinoIcons.ellipsis),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 50),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long_rounded, color: Colors.white70),
                const SizedBox(height: 18),
                Text(
                  currentExpense.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  money(currentExpense.amount, currentExpense.currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'USD',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                if (currentExpense.status != ExpenseStatus.draft) ...[
                  _InfoRow(
                    label: 'Status',
                    value: StatusBadge(status: currentExpense.status),
                  ),
                  const Divider(height: 28),
                ],
                _InfoRow(
                  label: 'Date',
                  value: Text(shortDate(currentExpense.date)),
                ),
                const Divider(height: 28),
                _InfoRow(
                  label: 'Created',
                  value: Text(shortDate(currentExpense.createdAt)),
                ),
                const Divider(height: 28),
                const _InfoRow(label: 'Currency', value: Text('USD')),
                const Divider(height: 28),
                _InfoRow(
                  label: 'Category',
                  value: Text(currentCategory?.name ?? 'Removed category'),
                ),
                if (currentExpense.submittedAt != null) ...[
                  const Divider(height: 28),
                  _InfoRow(
                    label: 'Submitted',
                    value: Text(shortDate(currentExpense.submittedAt!)),
                  ),
                ],
                if (currentExpense.reviewedAt != null) ...[
                  const Divider(height: 28),
                  _InfoRow(
                    label: 'Reviewed',
                    value: Text(shortDate(currentExpense.reviewedAt!)),
                  ),
                ],
              ],
            ),
          ),
          if (currentExpense.description?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            Text(
              'Description',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  currentExpense.description!,
                  style: const TextStyle(color: AppColors.ink),
                ),
              ),
            ),
          ],
          if (currentExpense.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 24),
            Text(
              'Review note',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  currentExpense.rejectionReason!,
                  style: const TextStyle(color: AppColors.ink),
                ),
              ),
            ),
          ],
          if (currentExpense.imagePath != null) ...[
            const SizedBox(height: 24),
            Text(
              'Receipt',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            ReceiptImage(
              path: currentExpense.imagePath!,
              onTap: () => showReceiptImage(context, currentExpense.imagePath!),
            ),
          ],
          const SizedBox(height: 26),
          if (currentCategory != null)
            OutlinedButton.icon(
              onPressed: state.busy
                  ? null
                  : () => context.read<UserDataCubit>().exportExpenses(
                      currentCategory,
                      [currentExpense],
                    ),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Export to PDF'),
            ),
          if (editable) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: state.busy
                  ? null
                  : () => _submit(context, currentExpense),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Submit for review'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: state.busy
                  ? null
                  : () => _delete(context, currentExpense),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete expense'),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Submitted expenses are read-only. Rejected expenses can be edited and resubmitted.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted)),
      const Spacer(),
      Flexible(
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.ink),
          child: value,
        ),
      ),
    ],
  );
}
