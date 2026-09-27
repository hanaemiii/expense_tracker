import 'package:isar/isar.dart';

import '../../domain/entities/expense.dart';
import '../../domain/errors/validation_exception.dart';

part 'expense_record.g.dart';

@collection
class ExpenseRecord {
  Id id = Isar.autoIncrement;
  late int categoryId;
  late String name;
  late double amount;
  late String currency;
  String? description;
  String? imagePath;
  late DateTime date;
  late String status;
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? submittedAt;
  DateTime? reviewedAt;
  int? adminId;
  String? rejectionReason;

  Expense toEntity() => Expense(
    id: id,
    categoryId: categoryId,
    name: name,
    amount: amount,
    currency: currency,
    description: description,
    imagePath: imagePath,
    date: date,
    status: ExpenseStatus.values.firstWhere(
      (candidate) => candidate.name == status,
      orElse: () => throw const ValidationException(
        'This expense has an unknown status. Please update the app.',
      ),
    ),
    createdAt: createdAt,
    updatedAt: updatedAt,
    submittedAt: submittedAt,
    reviewedAt: reviewedAt,
    adminId: adminId,
    rejectionReason: rejectionReason,
  );

  static ExpenseRecord fromEntity(Expense expense) => ExpenseRecord()
    ..id = expense.id == 0 ? Isar.autoIncrement : expense.id
    ..categoryId = expense.categoryId
    ..name = expense.name
    ..amount = expense.amount
    ..currency = expense.currency
    ..description = expense.description
    ..imagePath = expense.imagePath
    ..date = expense.date
    ..status = expense.status.name
    ..createdAt = expense.createdAt
    ..updatedAt = expense.updatedAt
    ..submittedAt = expense.submittedAt
    ..reviewedAt = expense.reviewedAt
    ..adminId = expense.adminId
    ..rejectionReason = expense.rejectionReason;
}
