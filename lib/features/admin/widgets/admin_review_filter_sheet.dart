import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/expense.dart';
import '../bloc/admin_expenses_cubit.dart';

Future<void> showAdminReviewFilters(
  BuildContext context,
  AdminExpensesState state,
) async {
  final cubit = context.read<AdminExpensesCubit>();
  await showIosSheet<void>(
    context,
    (_) => AdminReviewFilterSheet(
      state: state,
      onApply: (sort, status, from, through) {
        cubit.setSort(sort);
        cubit.setStatus(status);
        if (from == null || through == null) {
          cubit.clearRange();
        } else {
          cubit.setRange(from, through);
        }
      },
    ),
  );
}

class AdminReviewFilterSheet extends StatefulWidget {
  const AdminReviewFilterSheet({
    super.key,
    required this.state,
    required this.onApply,
  });

  final AdminExpensesState state;
  final void Function(
    AdminSort sort,
    ExpenseStatus? status,
    DateTime? from,
    DateTime? through,
  )
  onApply;

  @override
  State<AdminReviewFilterSheet> createState() => _AdminReviewFilterSheetState();
}

class _AdminReviewFilterSheetState extends State<AdminReviewFilterSheet> {
  late AdminSort _sort;
  ExpenseStatus? _status;
  DateTime? _from;
  DateTime? _through;

  @override
  void initState() {
    super.initState();
    _sort = widget.state.sort;
    _status = widget.state.status;
    _from = widget.state.from;
    _through = widget.state.through;
  }

  Future<void> _pickRange() async {
    final from = await pickIosDate(
      context,
      initialDate: _from ?? DateTime.now(),
      maximumDate: DateTime(DateTime.now().year + 10),
    );
    if (from == null || !mounted) return;
    final through = await pickIosDate(
      context,
      initialDate: _through != null && !_through!.isBefore(from)
          ? _through!
          : from,
      minimumDate: from,
      maximumDate: DateTime(DateTime.now().year + 10),
    );
    if (through != null && mounted) {
      setState(() {
        _from = from;
        _through = through;
      });
    }
  }

  void _apply(
    AdminSort sort,
    ExpenseStatus? status,
    DateTime? from,
    DateTime? to,
  ) {
    widget.onApply(sort, status, from, to);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter & sort',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose which submissions to review.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _FilterRow(
            label: _status == null ? 'All' : statusLabel(_status!),
            onPressed: () => showIosActions(context, [
              IosAction(
                label: 'All',
                icon: _status == null
                    ? CupertinoIcons.check_mark
                    : CupertinoIcons.circle,
                onPressed: () => setState(() => _status = null),
              ),
              for (final status in ExpenseStatus.values.where(
                (value) => value != ExpenseStatus.draft,
              ))
                IosAction(
                  label: statusLabel(status),
                  icon: _status == status
                      ? CupertinoIcons.check_mark
                      : CupertinoIcons.circle,
                  onPressed: () => setState(() => _status = status),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _FilterRow(
            label: _sortLabel(_sort),
            onPressed: () => showIosActions(context, [
              for (final sort in AdminSort.values)
                IosAction(
                  label: _sortLabel(sort),
                  icon: _sort == sort
                      ? CupertinoIcons.check_mark
                      : CupertinoIcons.sort_down,
                  onPressed: () => setState(() => _sort = sort),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          _FilterRow(
            label: 'Expense date range',
            detail: _from == null || _through == null
                ? 'Any date'
                : '${shortDate(_from!)} – ${shortDate(_through!)}',
            onPressed: _pickRange,
          ),
          if (_from != null)
            CupertinoButton(
              onPressed: () => setState(() {
                _from = null;
                _through = null;
              }),
              child: const Text('Clear dates'),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              CupertinoButton(
                onPressed: () => _apply(AdminSort.newest, null, null, null),
                child: const Text('Reset'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: () => _apply(_sort, _status, _from, _through),
                  child: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _sortLabel(AdminSort sort) => switch (sort) {
  AdminSort.newest => 'Newest date',
  AdminSort.oldest => 'Oldest date',
  AdminSort.name => 'Name A–Z',
  AdminSort.nameDescending => 'Name Z–A',
  AdminSort.status => 'Status',
};

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.label, required this.onPressed, this.detail});

  final String label;
  final String? detail;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    onPressed: onPressed,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.ink)),
              if (detail != null)
                Text(detail!, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
        const Icon(CupertinoIcons.chevron_right, size: 17),
      ],
    ),
  );
}
