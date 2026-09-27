import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/categories/bloc/user_data_cubit.dart';
import '../features/role/bloc/role_cubit.dart';
import 'di/dependencies.dart';
import 'router/app_router.dart';

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  late final RoleCubit _role;
  late final UserDataCubit _userData;
  late final GoRouter _router;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _role = RoleCubit();
    _userData = UserDataCubit(widget.dependencies);
    _router = createAppRouter(_role);
  }

  @override
  void dispose() {
    _router.dispose();
    _userData.close();
    _role.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<AppDependencies>.value(
        value: widget.dependencies,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<RoleCubit>.value(value: _role),
            BlocProvider<UserDataCubit>.value(value: _userData),
          ],
          child: MaterialApp.router(
            title: 'Expense Tracker',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: _router,
            scaffoldMessengerKey: _messengerKey,
            builder: (context, child) =>
                BlocListener<UserDataCubit, UserDataState>(
                  listenWhen: (previous, current) =>
                      previous.noticeId != current.noticeId,
                  listener: (context, state) {
                    if (state.notice != null) {
                      final messenger = _messengerKey.currentState;
                      messenger?.hideCurrentSnackBar();
                      messenger?.showSnackBar(
                        SnackBar(
                          content: Text(state.notice!),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: state.noticeIsError
                              ? AppColors.danger
                              : AppColors.ink,
                        ),
                      );
                    }
                  },
                  child: child ?? const SizedBox.shrink(),
                ),
          ),
        ),
      );
}
