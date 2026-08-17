import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../responsive/breakpoints.dart';

class ResponsiveNavigationScaffold extends StatelessWidget {
  const ResponsiveNavigationScaffold({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Beranda',
    ),
    NavigationDestination(
      icon: Icon(Icons.swap_vert_rounded),
      selectedIcon: Icon(Icons.swap_vert_circle_rounded),
      label: 'Transaksi',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart_rounded),
      label: 'Laporan',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Pengaturan',
    ),
  ];

  int get _selectedIndex {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    const routes = ['/', '/transactions', '/reports', '/settings'];
    if (index != _selectedIndex) context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppBreakpoints.ofWidth(constraints.maxWidth);
        if (sizeClass == WindowSizeClass.compact) {
          return Scaffold(
            body: SafeArea(bottom: false, child: child),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => _navigate(context, index),
              destinations: _destinations,
            ),
          );
        }
        final extended = sizeClass == WindowSizeClass.expanded;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  extended: extended,
                  minExtendedWidth: 232,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => _navigate(context, index),
                  backgroundColor: context.appColors.card,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: extended
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_wallet_rounded),
                              SizedBox(width: 12),
                              Text(
                                'Keuangan Usaha',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          )
                        : const Tooltip(
                            message: 'Keuangan Usaha',
                            child: Icon(Icons.account_balance_wallet_rounded),
                          ),
                  ),
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: Text(destination.label),
                      ),
                  ],
                ),
                VerticalDivider(width: 1, color: context.appColors.border),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }
}
