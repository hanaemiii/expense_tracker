import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/expense.dart';
import '../bloc/admin_expenses_cubit.dart';

class AdminExpenseDetailPage extends StatelessWidget {
  const AdminExpenseDetailPage({super.key, required this.expenseId});

  final int expenseId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AdminExpensesCubit(context.read<AppDependencies>()),
    child: _AdminExpenseDetailView(expenseId: expenseId),
  );
}

class _AdminExpenseDetailView extends StatelessWidget {
  const _AdminExpenseDetailView({required this.expenseId});
  final int expenseId;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<AdminExpensesCubit, AdminExpensesState>(
    listenWhen: (previous, current) => previous.noticeId != current.noticeId,
    listener: (context, state) =>
        showFeedback(context, state.notice ?? '', error: state.noticeIsError),
    builder: (context, state) {
      Expense? expense;
      for (final item in state.expenses) {
        if (item.id == expenseId) {
          expense = item;
          break;
        }
      }
      final item = expense;
      return Scaffold(
        appBar: AppBar(title: const Text('Expense review')),
        body: state.error != null
            ? ErrorState(onRetry: context.read<AdminExpensesCubit>().reload)
            : state.loading
            ? const Center(child: CircularProgressIndicator())
            : item == null || item.status == ExpenseStatus.draft
            ? const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Expense unavailable',
                subtitle:
                    'This submission may have been removed or returned to drafts.',
              )
            : AdminExpenseDetails(item: item, state: state),
        bottomNavigationBar:
            item == null ||
                state.loading ||
                state.error != null ||
                (item.status != ExpenseStatus.submitted &&
                    item.status != ExpenseStatus.inProgress)
            ? null
            : AdminReviewActionBar(
                expense: item,
                busy: state.busy,
                onStartReview: (id) =>
                    context.read<AdminExpensesCubit>().startReview(id),
                onFinish: (id) => context.read<AdminExpensesCubit>().finish(id),
                onReject: (id, reason) => context
                    .read<AdminExpensesCubit>()
                    .reject(id, reason: reason),
              ),
      );
    },
  );
}

class AdminExpenseDetails extends StatelessWidget {
  const AdminExpenseDetails({
    super.key,
    required this.item,
    required this.state,
  });
  final Expense item;
  final AdminExpensesState state;

  @override
  Widget build(BuildContext context) {
    final category = state.categoryFor(item.categoryId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF597BFF)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EXPENSE REVIEW',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                money(item.amount, item.currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: item.status),
                ],
              ),
              const SizedBox(height: 18),
              _DetailRow(
                'Submitted by',
                state.profile?.fullName.isNotEmpty == true
                    ? state.profile!.fullName
                    : 'Local user',
              ),
              _DetailRow(
                'User email',
                state.profile?.email.trim().isNotEmpty == true
                    ? state.profile!.email
                    : 'No email on file',
              ),
              _DetailRow('Category', category?.name ?? 'Uncategorized'),
              _DetailRow('Expense name', item.name),
              _DetailRow('Amount', money(item.amount, item.currency)),
              _DetailRow('Currency', item.currency),
              _DetailRow('Expense date', shortDate(item.date)),
              _DetailRow('Created', shortDate(item.createdAt)),
              _DetailRow(
                'Submitted',
                item.submittedAt == null ? '—' : shortDate(item.submittedAt!),
              ),
              if (item.reviewedAt != null)
                _DetailRow('Reviewed', shortDate(item.reviewedAt!)),
              if (item.adminId != null)
                _DetailRow('Reviewer ID', '${item.adminId}'),
              if (item.description?.trim().isNotEmpty == true) ...[
                const Divider(height: 28),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(item.description!),
              ],
              if (item.rejectionReason?.trim().isNotEmpty == true) ...[
                const Divider(height: 28),
                const Text(
                  'Reason for rejection',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(item.rejectionReason!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('Receipt', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _ReceiptPreview(path: item.imagePath),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.path});
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.trim().isEmpty || !File(path!).existsSync()) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.hide_image_rounded, color: AppColors.muted, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'No receipt available',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _ReceiptFullScreen(path: path!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.file(
              File(path!),
              height: 210,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                height: 210,
                child: Center(child: Text('Receipt could not be opened')),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(
                  Icons.zoom_out_map_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'View full screen',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptFullScreen extends StatelessWidget {
  const _ReceiptFullScreen({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: const Text('Receipt'),
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
    ),
    body: Center(
      child: InteractiveViewer(
        minScale: 0.7,
        maxScale: 5,
        child: Image.file(
          File(path),
          errorBuilder: (_, _, _) => const Text(
            'Receipt no longer available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    ),
  );
}

class AdminReviewActionBar extends StatelessWidget {
  const AdminReviewActionBar({
    super.key,
    required this.expense,
    required this.busy,
    required this.onStartReview,
    required this.onFinish,
    required this.onReject,
  });

  final Expense expense;
  final bool busy;
  final Future<bool> Function(int id) onStartReview;
  final Future<bool> Function(int id) onFinish;
  final Future<bool> Function(int id, String? reason) onReject;

  @override
  Widget build(BuildContext context) {
    if (expense.status != ExpenseStatus.submitted &&
        expense.status != ExpenseStatus.inProgress) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _reject(context),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : () => _advance(context),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        expense.status == ExpenseStatus.submitted
                            ? Icons.play_arrow_rounded
                            : Icons.check_rounded,
                      ),
                label: Text(
                  expense.status == ExpenseStatus.submitted
                      ? 'Start Review'
                      : 'Finish',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _advance(BuildContext context) async {
    final submitted = expense.status == ExpenseStatus.submitted;
    final confirmed = await confirmAction(
      context,
      title: submitted ? 'Start Review?' : 'Finish expense?',
      message: submitted
          ? 'This expense will move to In review.'
          : 'This expense will be marked as finished.',
      action: submitted ? 'Start Review' : 'Finish',
    );
    if (!confirmed || !context.mounted) return;
    if (submitted) {
      await onStartReview(expense.id);
    } else {
      await onFinish(expense.id);
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await _askRejectionReason(context);
    if (reason == null || !context.mounted) return;
    final confirmed = await confirmAction(
      context,
      title: 'Reject expense?',
      message:
          'This will return the expense to the user.${reason.isEmpty ? '' : ' Your reason will be included.'}',
      action: 'Reject',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    await onReject(expense.id, reason.isEmpty ? null : reason);
  }

  Future<String?> _askRejectionReason(BuildContext context) =>
      showCupertinoDialog<String>(
        context: context,
        builder: (dialogContext) => const _RejectionReasonDialog(),
      );
}

class _RejectionReasonDialog extends StatefulWidget {
  const _RejectionReasonDialog();

  @override
  State<_RejectionReasonDialog> createState() => _RejectionReasonDialogState();
}

class _RejectionReasonDialogState extends State<_RejectionReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoAlertDialog(
    title: const Text('Reason for rejection'),
    content: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CupertinoTextField(
        controller: _controller,
        maxLength: 500,
        maxLines: 3,
        placeholder: 'Optional: explain what needs to change',
      ),
    ),
    actions: [
      CupertinoDialogAction(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      CupertinoDialogAction(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('Continue'),
      ),
    ],
  );
}
