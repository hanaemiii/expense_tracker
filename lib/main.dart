import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/di/dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await AppDependencies.initialize();
  runApp(ExpenseTrackerApp(dependencies: dependencies));
}
