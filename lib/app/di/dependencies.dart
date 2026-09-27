import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/pdf_service.dart';
import '../../core/services/receipt_service.dart';
import '../../data/local/category_local_data_source.dart';
import '../../data/local/expense_local_data_source.dart';
import '../../data/local/profile_local_data_source.dart';
import '../../data/models/category_record.dart';
import '../../data/models/expense_record.dart';
import '../../data/models/profile_record.dart';
import '../../data/repositories/isar_category_repository.dart';
import '../../data/repositories/isar_expense_repository.dart';
import '../../data/repositories/isar_profile_repository.dart';
import '../../domain/usecases/category_actions.dart';
import '../../domain/usecases/expense_actions.dart';
import '../../domain/usecases/profile_actions.dart';

class AppDependencies {
  AppDependencies._({
    required this.categories,
    required this.expenses,
    required this.profiles,
    required this.receipts,
    required this.pdf,
    required Isar isar,
  }) : _isar = isar;

  final CategoryActions categories;
  final ExpenseActions expenses;
  final ProfileActions profiles;
  final ReceiptService receipts;
  final PdfService pdf;
  final Isar _isar;

  static Future<AppDependencies> initialize() async {
    final documents = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [CategoryRecordSchema, ExpenseRecordSchema, ProfileRecordSchema],
      directory: documents.path,
      name: 'expense_tracker',
    );
    return AppDependencies._(
      categories: CategoryActions(
        IsarCategoryRepository(CategoryLocalDataSource(isar)),
      ),
      expenses: ExpenseActions(
        IsarExpenseRepository(ExpenseLocalDataSource(isar)),
      ),
      profiles: ProfileActions(
        IsarProfileRepository(ProfileLocalDataSource(isar)),
      ),
      receipts: ReceiptService(),
      pdf: PdfService(),
      isar: isar,
    );
  }

  Future<void> close() => _isar.close();
}
