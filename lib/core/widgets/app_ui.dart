import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/expense.dart';
import '../../domain/errors/validation_exception.dart';
import '../theme/app_theme.dart';

String friendlyError(Object error) {
  if (error is ValidationException) return error.message;
  return 'Something went wrong. Please try again.';
}

void showFeedback(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.danger : AppColors.ink,
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'Continue',
  bool destructive = false,
}) async {
  return await showCupertinoDialog<bool>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext, true),
              isDestructiveAction: destructive,
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

class IosAction {
  const IosAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool destructive;
  final bool enabled;
}

Future<void> showIosActions(BuildContext context, List<IosAction> actions) =>
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          for (final action in actions)
            CupertinoActionSheetAction(
              isDestructiveAction: action.destructive,
              onPressed: () {
                if (!action.enabled) return;
                Navigator.pop(sheetContext);
                action.onPressed();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    action.icon,
                    size: 20,
                    color: action.enabled ? null : AppColors.muted,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    action.label,
                    style: action.enabled
                        ? null
                        : const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );

Future<T?> showIosSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showCupertinoModalPopup<T>(
      context: context,
      builder: (popupContext) => Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(popupContext).height * .88,
            ),
            child: builder(popupContext),
          ),
        ),
      ),
    );

Future<DateTime?> pickIosDate(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? minimumDate,
  DateTime? maximumDate,
}) {
  var picked = initialDate;
  final first = minimumDate ?? DateTime(2000);
  final last = maximumDate ?? DateTime(2100, 12, 31);
  if (picked.isBefore(first)) picked = first;
  if (picked.isAfter(last)) picked = last;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (popupContext) => Container(
      height: 320,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(popupContext),
                  child: const Text('Cancel'),
                ),
                CupertinoButton(
                  onPressed: () => Navigator.pop(popupContext, picked),
                  child: const Text('Done'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: picked,
                minimumDate: first,
                maximumDate: last,
                onDateTimeChanged: (date) => picked = date,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SwipeActions extends StatefulWidget {
  const SwipeActions({super.key, required this.child, required this.actions});

  final Widget child;
  final List<IosAction> actions;

  @override
  State<SwipeActions> createState() => _SwipeActionsState();
}

class _SwipeActionsState extends State<SwipeActions> {
  double _offset = 0;

  @override
  Widget build(BuildContext context) {
    final width = widget.actions.length * 72.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          if (_offset < 0)
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final action in widget.actions)
                      SizedBox(
                        width: 72,
                        height: double.infinity,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: action.destructive
                              ? AppColors.danger
                              : AppColors.primary,
                          onPressed: action.enabled
                              ? () {
                                  setState(() => _offset = 0);
                                  action.onPressed();
                                }
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(action.icon, color: Colors.white, size: 21),
                              const SizedBox(height: 3),
                              Text(
                                action.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          GestureDetector(
            onHorizontalDragUpdate: (details) => setState(
              () => _offset = (_offset + details.delta.dx).clamp(-width, 0.0),
            ),
            onHorizontalDragEnd: (_) =>
                setState(() => _offset = _offset < -width / 3 ? -width : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

String money(double amount, [String currency = 'USD']) {
  final prefix = currency == 'USD' ? '\$' : '$currency ';
  final parts = amount.toStringAsFixed(2).split('.');
  final digits = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$prefix$digits.${parts.last}';
}

String shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

bool canEditExpense(Expense expense) =>
    expense.status == ExpenseStatus.draft ||
    expense.status == ExpenseStatus.rejected;

String statusLabel(ExpenseStatus status) => switch (status) {
  ExpenseStatus.draft => 'Draft',
  ExpenseStatus.submitted => 'Submitted',
  ExpenseStatus.inProgress => 'In review',
  ExpenseStatus.finished => 'Finished',
  ExpenseStatus.rejected => 'Rejected',
};

IconData categoryIcon(IconType type) => switch (type) {
  IconType.travel => Icons.luggage_rounded,
  IconType.flight => Icons.flight_takeoff_rounded,
  IconType.hotel => Icons.hotel_rounded,
  IconType.food => Icons.ramen_dining_rounded,
  IconType.restaurant => Icons.restaurant_rounded,
  IconType.shopping => Icons.shopping_bag_rounded,
  IconType.transportation => Icons.directions_car_rounded,
  IconType.fuel => Icons.local_gas_station_rounded,
  IconType.office => Icons.business_center_rounded,
  IconType.equipment => Icons.devices_other_rounded,
  IconType.software => Icons.code_rounded,
  IconType.education => Icons.school_rounded,
  IconType.health => Icons.favorite_rounded,
  IconType.entertainment => Icons.movie_rounded,
  IconType.other => Icons.category_rounded,
};

String iconLabel(IconType type) {
  final name = type.name;
  return '${name[0].toUpperCase()}${name.substring(1)}';
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.type, this.size = 52});

  final IconType type;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xFFEDF1FF),
      borderRadius: BorderRadius.circular(size * .32),
    ),
    child: Icon(categoryIcon(type), color: AppColors.primary, size: size * .48),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ExpenseStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ExpenseStatus.draft => AppColors.muted,
      ExpenseStatus.submitted => AppColors.primary,
      ExpenseStatus.inProgress => const Color(0xFFAD7222),
      ExpenseStatus.finished => AppColors.success,
      ExpenseStatus.rejected => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/empty_receipt.svg',
            width: 158,
            height: 148,
            semanticsLabel: title,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.wifi_off_rounded,
    title: 'Couldn’t load your data',
    subtitle: 'Your expenses are safe on this device. Try loading them again.',
    action: FilledButton(onPressed: onRetry, child: const Text('Try again')),
  );
}
