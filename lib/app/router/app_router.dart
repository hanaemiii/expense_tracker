import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_role.dart';
import '../../features/admin/pages/admin_expense_detail_page.dart';
import '../../features/admin/pages/admin_expenses_page.dart';
import '../../features/categories/pages/categories_page.dart';
import '../../features/categories/pages/category_detail_page.dart';
import '../../features/expenses/pages/expense_detail_page.dart';
import '../../features/expenses/pages/expense_form_page.dart';
import '../../features/profile/pages/edit_profile_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/role/bloc/role_cubit.dart';
import '../../features/statistics/pages/statistics_page.dart';

String? redirectForRole(AppRole role, String path) {
  if (role == AppRole.admin) {
    if (path == '/profile/edit') return '/admin/profile/edit';
    if (path == '/profile') return '/admin/profile';
    if (!path.startsWith('/admin')) return '/admin/expenses';
  }
  if (role == AppRole.user && path.startsWith('/admin')) {
    return '/categories';
  }
  return null;
}

GoRouter createAppRouter(RoleCubit role) {
  final refresh = _RoleRefresh(role);
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/categories',
    refreshListenable: refresh,
    onException: (context, state, router) => router.go(
      role.state == AppRole.user ? '/categories' : '/admin/expenses',
    ),
    redirect: (context, state) => redirectForRole(role.state, state.uri.path),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _TabShell(navigationShell: navigationShell, admin: false),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _TabShell(navigationShell: navigationShell, admin: true),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/expenses',
                builder: (context, state) => const AdminExpensesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/category/:id',
        builder: (context, state) => CategoryDetailPage(
          categoryId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/expense/create',
        builder: (context, state) => ExpenseFormPage(
          categoryId: int.tryParse(
            state.uri.queryParameters['categoryId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/expense/:id/edit',
        builder: (context, state) => ExpenseFormPage(
          expenseId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/expense/:id',
        builder: (context, state) => ExpenseDetailPage(
          expenseId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/admin/profile/edit',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/admin/expenses/:id',
        builder: (context, state) => AdminExpenseDetailPage(
          expenseId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootKey,
        path: '/admin/expense/:id',
        redirect: (context, state) =>
            '/admin/expenses/${state.pathParameters['id']}',
      ),
    ],
  );
}

class _RoleRefresh extends ChangeNotifier {
  _RoleRefresh(RoleCubit role) {
    _subscription = role.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AppRole> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _TabShell extends StatelessWidget {
  const _TabShell({required this.navigationShell, required this.admin});

  final StatefulNavigationShell navigationShell;
  final bool admin;

  @override
  Widget build(BuildContext context) {
    final destinations = admin
        ? const [
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.insert_chart_outlined_rounded),
              selectedIcon: Icon(Icons.insert_chart_rounded),
              label: 'Statistics',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE6EBFF),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
