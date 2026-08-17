import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/responsive_navigation_scaffold.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/transactions/domain/finance_transaction.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/transactions/presentation/screens/transaction_form_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          ResponsiveNavigationScaffold(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/transactions',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TransactionsScreen()),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) {
                final type = state.uri.queryParameters['type'] == 'expense'
                    ? TransactionType.expense
                    : TransactionType.income;
                return TransactionFormScreen(initialType: type);
              },
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => TransactionDetailScreen(
                transactionId: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => TransactionFormScreen(
                    transactionId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ReportsScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: SafeArea(
      child: EmptyState(
        icon: Icons.route_outlined,
        title: 'Halaman tidak ditemukan',
        message: 'Alamat halaman tidak dikenali oleh aplikasi.',
        primaryAction: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Kembali ke beranda'),
        ),
      ),
    ),
  ),
);
