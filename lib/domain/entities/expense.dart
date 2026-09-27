enum ExpenseStatus { draft, submitted, inProgress, finished, rejected }

class Expense {
  Expense({
    this.id = 0,
    required this.categoryId,
    required this.name,
    required this.amount,
    this.currency = 'USD',
    this.description,
    this.imagePath,
    required this.date,
    this.status = ExpenseStatus.draft,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.submittedAt,
    this.reviewedAt,
    this.adminId,
    this.rejectionReason,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  final int id;
  final int categoryId;
  final String name;
  final double amount;
  final String currency;
  final String? description;
  final String? imagePath;
  final DateTime date;
  final ExpenseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int? adminId;
  final String? rejectionReason;

  static const _unchanged = Object();

  Expense copyWith({
    int? id,
    int? categoryId,
    String? name,
    double? amount,
    String? currency,
    Object? description = _unchanged,
    Object? imagePath = _unchanged,
    DateTime? date,
    ExpenseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? submittedAt = _unchanged,
    Object? reviewedAt = _unchanged,
    Object? adminId = _unchanged,
    Object? rejectionReason = _unchanged,
  }) => Expense(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    description: identical(description, _unchanged)
        ? this.description
        : description as String?,
    imagePath: identical(imagePath, _unchanged)
        ? this.imagePath
        : imagePath as String?,
    date: date ?? this.date,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    submittedAt: identical(submittedAt, _unchanged)
        ? this.submittedAt
        : submittedAt as DateTime?,
    reviewedAt: identical(reviewedAt, _unchanged)
        ? this.reviewedAt
        : reviewedAt as DateTime?,
    adminId: identical(adminId, _unchanged) ? this.adminId : adminId as int?,
    rejectionReason: identical(rejectionReason, _unchanged)
        ? this.rejectionReason
        : rejectionReason as String?,
  );
}
