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

class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({super.key, this.expenseId, this.categoryId});

  final int? expenseId;
  final int? categoryId;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now();
  String? _imagePath;
  int? _categoryId;
  bool _initialized = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseImage(Future<String?> Function() pick) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final image = await pick();
      if (mounted && image != null) setState(() => _imagePath = image);
    } catch (error) {
      if (mounted) showFeedback(context, friendlyError(error), error: true);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _chooseDate() async {
    FocusScope.of(context).unfocus();
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);
    var picked = _date.isBefore(firstDate)
        ? firstDate
        : _date.isAfter(lastDate)
        ? lastDate
        : _date;
    final chosen = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (sheetContext) => _PickerSheet(
        title: 'Date',
        onDone: () => Navigator.pop(sheetContext, picked),
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: picked,
          minimumDate: firstDate,
          maximumDate: lastDate,
          onDateTimeChanged: (value) => picked = value,
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _date = DateTime(chosen.year, chosen.month, chosen.day));
    }
  }

  Future<int?> _chooseCategory(List<Category> categories) async {
    FocusScope.of(context).unfocus();
    var pickedId = _categoryId;
    final selectedIndex = categories.indexWhere(
      (category) => category.id == pickedId,
    );
    final initialIndex = selectedIndex < 0 ? 0 : selectedIndex;
    pickedId = categories[initialIndex].id;
    return showCupertinoModalPopup<int>(
      context: context,
      builder: (sheetContext) => _PickerSheet(
        title: 'Category',
        onDone: () => Navigator.pop(sheetContext, pickedId),
        child: _CategoryWheel(
          categories: categories,
          initialIndex: initialIndex,
          onSelected: (index) => pickedId = categories[index].id,
        ),
      ),
    );
  }

  Future<void> _save(Expense? original) async {
    if (!_form.currentState!.validate()) return;
    final amount = double.tryParse(_amount.text.trim().replaceAll(',', ''));
    if (amount == null || !amount.isFinite || amount <= 0) {
      showFeedback(context, 'Enter an amount greater than zero.', error: true);
      return;
    }
    final categoryId = _categoryId;
    if (categoryId == null) {
      showFeedback(context, 'Choose a category first.', error: true);
      return;
    }
    final expense = original == null
        ? Expense(
            categoryId: categoryId,
            name: _name.text.trim(),
            amount: amount,
            date: _date,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            imagePath: _imagePath,
          )
        : original.copyWith(
            categoryId: categoryId,
            name: _name.text.trim(),
            amount: amount,
            date: _date,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            imagePath: _imagePath,
          );
    if (await context.read<UserDataCubit>().saveExpense(expense) && mounted) {
      context.pop();
    }
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
    Expense? original;
    for (final expense in state.expenses) {
      if (expense.id == widget.expenseId) original = expense;
    }
    if (widget.expenseId != null && original == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Expense not found',
          subtitle: 'This expense may have been deleted.',
        ),
      );
    }
    if (original != null && !canEditExpense(original)) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Expense is read-only',
          subtitle: 'Only draft or rejected expenses can be edited.',
        ),
      );
    }
    if (!_initialized) {
      _initialized = true;
      _name.text = original?.name ?? '';
      _amount.text = original?.amount.toStringAsFixed(2) ?? '';
      _description.text = original?.description ?? '';
      _date = original?.date ?? DateTime.now();
      _imagePath = original?.imagePath;
      _categoryId = original?.categoryId ?? widget.categoryId;
    }
    final selectedCategory =
        state.categories.any((category) => category.id == _categoryId)
        ? _categoryId
        : null;
    final receipts = context.read<UserDataCubit>().dependencies.receipts;
    return Scaffold(
      appBar: AppBar(
        title: Text(original == null ? 'New expense' : 'Edit expense'),
      ),
      body: state.categories.isEmpty
          ? const EmptyState(
              icon: Icons.layers_outlined,
              title: 'Create a category first',
              subtitle: 'Go to Categories to create a place for this expense.',
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                children: [
                  Text(
                    original == null ? 'What did you spend?' : 'Update expense',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep the details together, including an optional receipt.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 26),
                  TextFormField(
                    controller: _name,
                    style: const TextStyle(color: AppColors.ink),
                    cursorColor: AppColors.primary,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Expense name',
                      labelStyle: TextStyle(color: AppColors.muted),
                      hintText: 'e.g. Airport taxi',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter an expense name'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amount,
                    style: const TextStyle(color: AppColors.ink),
                    cursorColor: AppColors.primary,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount (USD)',
                      labelStyle: TextStyle(color: AppColors.muted),
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(color: AppColors.ink),
                      hintText: '0.00',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(
                        (value ?? '').trim().replaceAll(',', ''),
                      );
                      return amount == null || !amount.isFinite || amount <= 0
                          ? 'Enter an amount greater than zero'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FormField<int>(
                    initialValue: selectedCategory,
                    validator: (value) =>
                        value == null ? 'Choose a category' : null,
                    builder: (field) {
                      final category = state.categories.where(
                        (item) => item.id == field.value,
                      );
                      final name = category.isEmpty
                          ? 'Choose a category'
                          : category.first.name;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final picked = await _chooseCategory(
                            state.categories,
                          );
                          if (picked == null || !mounted) return;
                          field.didChange(picked);
                          setState(() => _categoryId = picked);
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: const TextStyle(color: AppColors.muted),
                            errorText: field.errorText,
                            suffixIcon: const Icon(
                              CupertinoIcons.chevron_up_chevron_down,
                              color: AppColors.muted,
                              size: 18,
                            ),
                          ),
                          isEmpty: field.value == null,
                          child: Text(
                            name,
                            style: TextStyle(
                              color: field.value == null
                                  ? AppColors.muted
                                  : AppColors.ink,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    onTap: _chooseDate,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                shortDate(_date),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    style: const TextStyle(color: AppColors.ink),
                    cursorColor: AppColors.primary,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      labelStyle: TextStyle(color: AppColors.muted),
                      hintText: 'Add a note about this expense',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Receipt (optional)',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 10),
                  if (_imagePath != null) ...[
                    ReceiptImage(
                      path: _imagePath!,
                      height: 180,
                      onTap: () => showReceiptImage(context, _imagePath!),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _imagePath = null),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Remove receipt'),
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _picking
                              ? null
                              : () => _chooseImage(receipts.pickFromGallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _picking
                              ? null
                              : () => _chooseImage(receipts.scanReceipt),
                          icon: const Icon(Icons.document_scanner_outlined),
                          label: const Text('Scan'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  FilledButton(
                    onPressed: state.busy || _picking
                        ? null
                        : () => _save(original),
                    child: state.busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            original == null ? 'Save expense' : 'Save changes',
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CategoryWheel extends StatefulWidget {
  const _CategoryWheel({
    required this.categories,
    required this.initialIndex,
    required this.onSelected,
  });

  final List<Category> categories;
  final int initialIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_CategoryWheel> createState() => _CategoryWheelState();
}

class _CategoryWheelState extends State<_CategoryWheel> {
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(initialItem: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPicker(
    scrollController: _controller,
    itemExtent: 44,
    onSelectedItemChanged: widget.onSelected,
    children: [
      for (final category in widget.categories)
        Center(
          child: Text(
            category.name,
            style: const TextStyle(color: AppColors.ink, fontSize: 18),
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
  );
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.onDone,
    required this.child,
  });

  final String title;
  final VoidCallback onDone;
  final Widget child;

  @override
  Widget build(BuildContext context) => CupertinoTheme(
    data: const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      textTheme: CupertinoTextThemeData(
        dateTimePickerTextStyle: TextStyle(color: AppColors.ink, fontSize: 21),
      ),
    ),
    child: Container(
      height: 330,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CupertinoButton(onPressed: onDone, child: const Text('Done')),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}
