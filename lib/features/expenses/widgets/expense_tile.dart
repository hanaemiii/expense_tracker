import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/expense.dart';

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onTap,
    this.onLongPress,
    this.actions = const [],
    this.selected,
    this.onSelected,
  });

  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final List<IosAction> actions;
  final bool? selected;
  final ValueChanged<bool?>? onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SwipeActions(
      key: ValueKey(expense.id),
      actions: actions,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          children: [
            if (selected != null) ...[
              CupertinoCheckbox(value: selected!, onChanged: onSelected),
              const SizedBox(width: 2),
            ],
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF1FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shortDate(expense.date),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(expense.amount, expense.currency),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                if (expense.status != ExpenseStatus.draft)
                  StatusBadge(status: expense.status),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
