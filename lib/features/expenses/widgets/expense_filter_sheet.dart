import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/expense.dart';
import '../bloc/expense_filter_cubit.dart';

Future<void> showExpenseFilters(BuildContext context) async {
  final filters = context.read<ExpenseFilterCubit>();
  await showIosSheet<void>(
    context,
    (_) =>
        BlocProvider.value(value: filters, child: const ExpenseFilterSheet()),
  );
}

class ExpenseFilterSheet extends StatefulWidget {
  const ExpenseFilterSheet({super.key});

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late Set<ExpenseStatus> _statuses;
  late ExpenseSort _sort;
  late ExpenseDatePreset _datePreset;
  DateTime? _from;
  DateTime? _to;
  late final TextEditingController _query;

  @override
  void initState() {
    super.initState();
    final filter = context.read<ExpenseFilterCubit>().state;
    _statuses = {...filter.statuses};
    _sort = filter.sort;
    _datePreset = filter.datePreset;
    _from = filter.from;
    _to = filter.to;
    _query = TextEditingController(text: filter.query);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final start = await pickIosDate(
      context,
      initialDate: _from ?? DateTime.now(),
    );
    if (start == null || !mounted) return;
    final end = await pickIosDate(
      context,
      initialDate: _to != null && !_to!.isBefore(start) ? _to! : start,
      minimumDate: start,
    );
    if (end != null && mounted) {
      setState(() {
        _from = start;
        _to = end;
        _datePreset = ExpenseDatePreset.custom;
      });
    }
  }

  void _preset(ExpenseDatePreset preset) {
    if (preset == ExpenseDatePreset.any) {
      setState(() {
        _from = null;
        _to = null;
        _datePreset = preset;
      });
      return;
    }
    final bounds = context.read<ExpenseFilterCubit>().previewDateBounds(preset);
    setState(() {
      _from = bounds.from;
      _to = bounds.to;
      _datePreset = preset;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filter expenses',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          CupertinoSearchTextField(
            controller: _query,
            placeholder: 'Search expense name',
            style: const TextStyle(color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ChoiceRow(
            label: expenseSortLabel(_sort),
            onPressed: () => showIosActions(context, [
              for (final sort in ExpenseSort.values)
                IosAction(
                  label: expenseSortLabel(sort),
                  icon: sort == _sort
                      ? CupertinoIcons.check_mark
                      : CupertinoIcons.sort_down,
                  onPressed: () => setState(() => _sort = sort),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final status in ExpenseStatus.values)
            _ChoiceRow(
              label: statusLabel(status),
              selected: _statuses.contains(status),
              onPressed: () => setState(() {
                if (!_statuses.add(status)) _statuses.remove(status);
              }),
            ),
          const SizedBox(height: 16),
          Text('Quick dates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ChoiceRow(
            label: switch (_datePreset) {
              ExpenseDatePreset.any => 'Any date',
              ExpenseDatePreset.today => 'Today',
              ExpenseDatePreset.thisWeek => 'This week',
              ExpenseDatePreset.thisMonth => 'This month',
              ExpenseDatePreset.custom => 'Custom range',
            },
            onPressed: () => showIosActions(context, [
              IosAction(
                label: 'Any date',
                icon: CupertinoIcons.calendar,
                onPressed: () => _preset(ExpenseDatePreset.any),
              ),
              IosAction(
                label: 'Today',
                icon: CupertinoIcons.calendar_today,
                onPressed: () => _preset(ExpenseDatePreset.today),
              ),
              IosAction(
                label: 'This week',
                icon: CupertinoIcons.calendar,
                onPressed: () => _preset(ExpenseDatePreset.thisWeek),
              ),
              IosAction(
                label: 'This month',
                icon: CupertinoIcons.calendar,
                onPressed: () => _preset(ExpenseDatePreset.thisMonth),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          _ChoiceRow(
            label: _from == null || _to == null
                ? 'Date range'
                : '${shortDate(_from!)} – ${shortDate(_to!)}',
            onPressed: _pickRange,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CupertinoButton(
                onPressed: () {
                  context.read<ExpenseFilterCubit>().clear();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: () {
                    context.read<ExpenseFilterCubit>().applyFilters(
                      query: _query.text,
                      statuses: _statuses,
                      datePreset: _datePreset,
                      from: _from,
                      to: _to,
                      sort: _sort,
                    );
                    Navigator.pop(context);
                  },
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

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    onPressed: onPressed,
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: AppColors.ink)),
        ),
        Icon(
          selected ? CupertinoIcons.check_mark : CupertinoIcons.chevron_right,
          size: 17,
        ),
      ],
    ),
  );
}
