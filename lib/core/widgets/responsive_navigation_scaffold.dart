import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../responsive/breakpoints.dart';

class ResponsiveNavigationScaffold extends StatelessWidget {
  const ResponsiveNavigationScaffold({
    required this.location,
    this.child,
    this.navigationShell,
    super.key,
  }) : assert(child != null || navigationShell != null);

  final String location;
  final Widget? child;
  final StatefulNavigationShell? navigationShell;

  Widget get _content => navigationShell ?? child!;

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

  static const _compactDestinations = [
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
      icon: Icon(Icons.more_horiz_rounded),
      selectedIcon: Icon(Icons.more_horiz_rounded),
      label: 'Lainnya',
    ),
  ];

  int get _selectedIndex {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/credits')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/products')) return 4;
    if (location.startsWith('/settings')) return 5;
    if (location.startsWith('/customers')) return 1;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    final returnToTransactionList =
        index == 1 && location.startsWith('/customers');
    if (index != _selectedIndex || returnToTransactionList) {
      FocusManager.instance.primaryFocus?.unfocus();
      final shell = navigationShell;
      if (shell != null) {
        shell.goBranch(index, initialLocation: returnToTransactionList);
      } else {
        const routes = [
          '/',
          '/transactions',
          '/credits',
          '/reports',
          '/products',
          '/settings',
        ];
        context.go(routes[index]);
      }
    }
  }

  void _showMore(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Produk'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _navigate(context, 4);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _navigate(context, 5);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppBreakpoints.ofWidth(constraints.maxWidth);
        if (sizeClass == WindowSizeClass.compact) {
          final narrow = constraints.maxWidth < 420;
          final selectedIndex = narrow && _selectedIndex >= 4
              ? 4
              : _selectedIndex;
          return Scaffold(
            body: SafeArea(bottom: false, child: _content),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                if (narrow && index == 4) {
                  _showMore(context);
                } else {
                  _navigate(context, index);
                }
              },
              destinations: narrow ? _compactDestinations : _destinations,
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
                Expanded(child: _content),
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
