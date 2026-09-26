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
      icon: Icon(Icons.credit_card_outlined),
      selectedIcon: Icon(Icons.credit_card),
      label: 'Kredit',
    ),
    NavigationDestination(
      icon: Icon(Icons.bar_chart_outlined),
      selectedIcon: Icon(Icons.bar_chart_rounded),
      label: 'Laporan',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: 'Produk',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Pengaturan',
    ),
  ];

  int get _selectedIndex {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/credits')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/products')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    const routes = [
      '/',
      '/transactions',
      '/credits',
      '/reports',
      '/products',
      '/settings',
    ];
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
              // Menambahkan behavior ini agar teks label hanya muncul
              // di menu yang sedang aktif. Ini akan mencegah overflow (teks kepanjangan/melebar).
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
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
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 22),
                    child: extended
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BrandMark(),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Keuangan Usaha',
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          )
                        : const Tooltip(
                            message: 'Keuangan Usaha',
                            child: _BrandMark(),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: context.appColors.info,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Icon(
      Icons.account_balance_wallet_rounded,
      color: Colors.white,
      size: 22,
    ),
  );
}
