import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/category.dart';
import '../bloc/user_data_cubit.dart';

Future<void> showCategoryEditor(
  BuildContext context, [
  Category? original,
]) async {
  final data = context.read<UserDataCubit>();
  await showIosSheet<void>(
    context,
    (sheetContext) => BlocProvider.value(
      value: data,
      child: _CategoryEditor(original: original),
    ),
  );
}

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({this.original});

  final Category? original;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late IconType _icon;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.original?.name ?? '');
    _icon = widget.original?.icon ?? IconType.food;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final data = context.read<UserDataCubit>();
    final success = widget.original == null
        ? await data.createCategory(_name.text, _icon)
        : await data.updateCategory(
            widget.original!.copyWith(name: _name.text, icon: _icon),
          );
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.select((UserDataCubit cubit) => cubit.state.busy);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.original == null ? 'New category' : 'Edit category',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  autofocus: widget.original == null,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    hintText: 'e.g. Travel',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a category name'
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose an icon',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: IconType.values.map((type) {
                    final selected = type == _icon;
                    return Tooltip(
                      message: iconLabel(type),
                      child: Semantics(
                        label: iconLabel(type),
                        selected: selected,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => _icon = type),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFDBE4FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? Theme.of(context).colorScheme.primary
                                    : const Color(0xFFE7EBF5),
                              ),
                            ),
                            child: Icon(
                              categoryIcon(type),
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : _save,
                    child: Text(
                      widget.original == null
                          ? 'Create category'
                          : 'Save changes',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
