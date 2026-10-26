import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/formatters/number_input_formatter.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/confirm_delete_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../domain/product.dart';
import 'providers/product_providers.dart';

enum _StockFilter { all, low, out }

extension on _StockFilter {
  String get label => switch (this) {
    _StockFilter.all => 'Semua',
    _StockFilter.low => 'Stok Menipis',
    _StockFilter.out => 'Stok Habis',
  };

  IconData get icon => switch (this) {
    _StockFilter.all => Icons.apps_rounded,
    _StockFilter.low => Icons.warning_amber_rounded,
    _StockFilter.out => Icons.remove_shopping_cart_outlined,
  };
}

enum _ProductMenuAction { edit, delete }

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  static const _lowStockThreshold = 5;

  DateTime _month = DateTime.now();
  ProductBrand? _brand;
  _StockFilter _stockFilter = _StockFilter.all;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesBrandAndQuery(Product product) {
    if (_brand != null && product.brand != _brand) return false;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return product.name.toLowerCase().contains(query) ||
        product.brand.label.toLowerCase().contains(query);
  }

  bool _matches(Product product) {
    if (!_matchesBrandAndQuery(product)) return false;
    return switch (_stockFilter) {
      _StockFilter.all => true,
      _StockFilter.low =>
        product.stockQuantity > 0 &&
            product.stockQuantity <= _lowStockThreshold,
      _StockFilter.out => product.stockQuantity == 0,
    };
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _brand = null;
      _stockFilter = _StockFilter.all;
    });
  }

  String get _filterSummary {
    final parts = <String>[
      if (_brand != null) 'Brand ${_brand!.label}',
      if (_stockFilter != _StockFilter.all) _stockFilter.label,
      if (_query.trim().isNotEmpty) 'Pencarian “${_query.trim()}”',
    ];
    return parts.isEmpty
        ? 'Kelola harga dan stok seluruh produk'
        : parts.join(' · ');
  }

  Future<void> _openBrandFilter() async {
    final selection = await showModalBottomSheet<_BrandSelection>(
      context: context,
      builder: (_) => _BrandFilterSheet(selected: _brand),
    );
    if (selection == null || !mounted) return;
    setState(() => _brand = selection.brand);
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final sales = ref.watch(productSalesProvider(_month));
    final movements = ref.watch(stockMovementsProvider);
    final allItems = products.maybeWhen(
      data: (items) => items,
      orElse: () => const <Product>[],
    );
    final baseItems = allItems
        .where(_matchesBrandAndQuery)
        .toList(growable: false);
    final lowCount = baseItems
        .where(
          (product) =>
              product.stockQuantity > 0 &&
              product.stockQuantity <= _lowStockThreshold,
        )
        .length;
    final outCount = baseItems
        .where((product) => product.stockQuantity == 0)
        .length;
    final now = DateTime.now();
    final canGoNext =
        _month.year < now.year ||
        (_month.year == now.year && _month.month < now.month);
    final compact =
        AppBreakpoints.ofWidth(MediaQuery.sizeOf(context).width) ==
        WindowSizeClass.compact;
    final gutter = compact ? AppSpacing.md : AppSpacing.lg;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.xl,
            gutter,
            AppSpacing.xxl,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppPageHeader(title: 'Produk & stok'),
                    const SizedBox(height: AppSpacing.md),
                    _MonthPickerCard(
                      month: _month,
                      canGoNext: canGoNext,
                      onPrevious: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      ),
                      onNext: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    products.when(
                      loading: () => const SizedBox.shrink(),
                      error: (error, stack) => const SizedBox.shrink(),
                      data: (items) {
                        final shown = items
                            .where(_matches)
                            .toList(growable: false);
                        final lowStock = shown
                            .where(
                              (product) =>
                                  product.stockQuantity <= _lowStockThreshold,
                            )
                            .toList(growable: false);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _InventoryOverview(products: shown),
                            if (lowStock.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              _LowStockCard(
                                products: lowStock,
                                onRestock: _restock,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    sales.when(
                      loading: () => const AppLoadingState(
                        compact: true,
                        message: 'Memuat performa penjualan…',
                      ),
                      error: (error, stack) => ErrorState(
                        compact: true,
                        message:
                            'Ringkasan penjualan produk belum dapat dimuat.',
                        onRetry: () =>
                            ref.invalidate(productSalesProvider(_month)),
                      ),
                      data: (items) => _SalesHighlights(
                        items: items
                            .where((item) => _matches(item.product))
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ProductsToolbar(
                      controller: _searchController,
                      query: _query,
                      summary: _filterSummary,
                      stockFilter: _stockFilter,
                      brandFilterActive: _brand != null,
                      allCount: baseItems.length,
                      lowCount: lowCount,
                      outCount: outCount,
                      onQueryChanged: (value) => setState(() => _query = value),
                      onClearSearch: _clearSearch,
                      onOpenBrandFilter: _openBrandFilter,
                      onStockFilterChanged: (filter) =>
                          setState(() => _stockFilter = filter),
                      onAdd: () => _editProduct(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    products.when(
                      loading: () => const AppLoadingState(
                        message: 'Memuat daftar produk…',
                      ),
                      error: (error, stack) => ErrorState(
                        message: 'Daftar produk belum dapat dimuat.',
                        onRetry: () => ref.invalidate(productsProvider),
                      ),
                      data: (items) {
                        final shown = items
                            .where(_matches)
                            .toList(growable: false);
                        if (shown.isEmpty) {
                          return _buildEmptyState();
                        }
                        final brands = _brand == null
                            ? ProductBrand.values
                            : [_brand!];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final brand in brands)
                              _BrandProductSection(
                                brand: brand,
                                products: shown
                                    .where((product) => product.brand == brand)
                                    .toList(growable: false),
                                onEdit: (product) => _editProduct(product),
                                onEditStock: _editStock,
                                onRestock: _restock,
                                onDelete: _deleteProduct,
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _StockHistoryCard(
                      movements: movements,
                      onRetry: () => ref.invalidate(stockMovementsProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final query = _query.trim();
    final hasQuery = query.isNotEmpty;
    final hasStockFilter = _stockFilter != _StockFilter.all;

    if (hasQuery) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Produk tidak ditemukan',
        message:
            'Tidak ada produk yang cocok dengan “$query”. Coba kata kunci lain atau ubah filter.',
        primaryAction: OutlinedButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Reset filter'),
        ),
      );
    }

    if (hasStockFilter) {
      final outOfStock = _stockFilter == _StockFilter.out;
      return EmptyState(
        icon: outOfStock ? Icons.inventory_2_outlined : Icons.inventory_rounded,
        title: outOfStock ? 'Tidak ada stok habis' : 'Tidak ada stok menipis',
        message: outOfStock
            ? 'Semua produk masih memiliki stok. Tidak ada yang perlu diisi ulang.'
            : 'Semua produk memiliki stok di atas $_lowStockThreshold unit.',
        primaryAction: OutlinedButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Reset filter'),
        ),
      );
    }

    if (_brand != null) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada produk ${_brand!.label}',
        message:
            'Tambahkan produk untuk brand ini agar harga dan stoknya dapat dikelola.',
        primaryAction: FilledButton.icon(
          onPressed: () => _editProduct(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah produk'),
        ),
        secondaryAction: TextButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Tampilkan semua produk'),
        ),
      );
    }

    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'Belum ada produk',
      message:
          'Tambahkan produk pertama Anda untuk mulai mengelola harga dan stok.',
      primaryAction: FilledButton.icon(
        onPressed: () => _editProduct(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah produk'),
      ),
    );
  }

  Future<void> _editProduct([Product? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(
      text: existing == null
          ? ''
          : CurrencyFormatter.digits(existing.sellingPrice),
    );
    var brand = existing?.brand ?? ProductBrand.vanestrix;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Tambah produk' : 'Edit produk'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ProductBrand>(
                    initialValue: brand,
                    decoration: const InputDecoration(labelText: 'Brand'),
                    items: ProductBrand.values
                        .map(
                          (b) =>
                              DropdownMenuItem(value: b, child: Text(b.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => brand = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nama produk',
                      hintText: 'Contoh: Produk A',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nama produk wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [RupiahInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Harga jual',
                      prefixText: 'Rp ',
                      helperText:
                          'Harga yang digunakan saat pencatatan penjualan',
                    ),
                    validator: (v) => CurrencyFormatter.parse(v ?? '') <= 0
                        ? 'Harga harus lebih dari 0'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      try {
        final controller = ref.read(productControllerProvider.notifier);
        final sellingPrice = CurrencyFormatter.parse(price.text);
        final trimmedName = name.text.trim();
        if (existing == null) {
          await controller.createProduct(
            brand: brand,
            name: trimmedName,
            sellingPrice: sellingPrice,
          );
        } else {
          await controller.updateProduct(
            id: existing.id,
            brand: brand,
            name: trimmedName,
            sellingPrice: sellingPrice,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                existing == null
                    ? 'Produk berhasil ditambahkan.'
                    : 'Produk berhasil diperbarui.',
              ),
            ),
          );
        }
      } catch (error, stackTrace) {
        debugPrint('Gagal menyimpan produk: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Produk belum berhasil disimpan. Periksa data lalu coba lagi.',
              ),
            ),
          );
        }
      }
    }
    name.dispose();
    price.dispose();
  }

  Future<void> _deleteProduct(Product product) async {
    final deleted = await showConfirmDeleteDialog(
      context,
      itemName: product.name,
      title: 'Hapus produk?',
      description:
          '“${product.name}” akan dihapus dari daftar produk. Riwayat penjualan dan laporan tetap tersimpan.',
      errorMessage: 'Produk belum berhasil dihapus. Coba lagi.',
      onDelete: () =>
          ref.read(productControllerProvider.notifier).delete(product.id),
      onError: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk ${product.name} gagal dihapus.')),
        );
      },
    );
    if (!mounted || !deleted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Produk ${product.name} berhasil dihapus.')),
    );
  }

  Future<void> _editStock(Product product) async {
    final newStock = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _EditStockDialog(product: product),
    );
    if (newStock == null || !mounted) return;
    try {
      await ref
          .read(productControllerProvider.notifier)
          .updateStock(product.id, newStock);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok ${product.name} diperbarui menjadi $newStock unit.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stok belum berhasil diperbarui: '
            '${error.toString().replaceFirst('Bad state: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _restock(Product product) async {
    final quantity = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Tambah stok · ${product.name}'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appColors.infoSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: context.appColors.info,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Stok saat ini: ${product.stockQuantity} unit',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah stok masuk',
                    hintText: 'Contoh: 10',
                    helperText: 'Jumlah ini akan ditambahkan ke stok saat ini',
                  ),
                  validator: (v) =>
                      int.tryParse(v ?? '') == null || int.parse(v!) <= 0
                      ? 'Masukkan jumlah lebih dari 0'
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan (opsional)',
                    hintText: 'Contoh: Stok dari pemasok',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      try {
        await ref
            .read(productControllerProvider.notifier)
            .restock(
              productId: product.id,
              quantity: int.parse(quantity.text),
              date: DateTime.now(),
              notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
            );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stok belum berhasil ditambahkan. Coba lagi.'),
            ),
          );
        }
      }
    }
    quantity.dispose();
    notes.dispose();
  }
}

class _ProductsToolbar extends StatelessWidget {
  const _ProductsToolbar({
    required this.controller,
    required this.query,
    required this.summary,
    required this.stockFilter,
    required this.brandFilterActive,
    required this.allCount,
    required this.lowCount,
    required this.outCount,
    required this.onQueryChanged,
    required this.onClearSearch,
    required this.onOpenBrandFilter,
    required this.onStockFilterChanged,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String query;
  final String summary;
  final _StockFilter stockFilter;
  final bool brandFilterActive;
  final int allCount;
  final int lowCount;
  final int outCount;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenBrandFilter;
  final ValueChanged<_StockFilter> onStockFilterChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final addButton = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Tambah produk'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            AppBreakpoints.ofWidth(constraints.maxWidth) ==
            WindowSizeClass.compact;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daftar produk',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  addButton,
                ],
              ],
            ),
            if (compact) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(width: double.infinity, child: addButton),
            ],
            const SizedBox(height: AppSpacing.md),
            _ProductSearchBar(
              controller: controller,
              query: query,
              brandFilterActive: brandFilterActive,
              onChanged: onQueryChanged,
              onClear: onClearSearch,
              onOpenFilter: onOpenBrandFilter,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _StockFilterChip(
                  filter: _StockFilter.all,
                  selected: stockFilter == _StockFilter.all,
                  count: allCount,
                  onSelected: onStockFilterChanged,
                ),
                _StockFilterChip(
                  filter: _StockFilter.low,
                  selected: stockFilter == _StockFilter.low,
                  count: lowCount,
                  onSelected: onStockFilterChanged,
                ),
                _StockFilterChip(
                  filter: _StockFilter.out,
                  selected: stockFilter == _StockFilter.out,
                  count: outCount,
                  onSelected: onStockFilterChanged,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ProductSearchBar extends StatelessWidget {
  const _ProductSearchBar({
    required this.controller,
    required this.query,
    required this.brandFilterActive,
    required this.onChanged,
    required this.onClear,
    required this.onOpenFilter,
  });

  final TextEditingController controller;
  final String query;
  final bool brandFilterActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(14);
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Cari nama produk atau brand',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 22,
          color: colors.textSecondary,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 46,
        ),
        filled: true,
        fillColor: colors.canvas.withValues(alpha: .65),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.info, width: 1.5),
        ),
        suffixIconConstraints: const BoxConstraints(minHeight: 44),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (query.isNotEmpty)
              IconButton(
                tooltip: 'Hapus pencarian',
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
            IconButton(
              tooltip: 'Filter brand',
              onPressed: onOpenFilter,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: brandFilterActive
                    ? colors.infoSurface
                    : Colors.transparent,
                foregroundColor: brandFilterActive
                    ? colors.info
                    : colors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.tune_rounded, size: 20),
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
        ),
      ),
    );
  }
}

class _StockFilterChip extends StatelessWidget {
  const _StockFilterChip({
    required this.filter,
    required this.selected,
    required this.count,
    required this.onSelected,
  });

  final _StockFilter filter;
  final bool selected;
  final int count;
  final ValueChanged<_StockFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final accent = switch (filter) {
      _StockFilter.all => colors.info,
      _StockFilter.low => colors.creditPending,
      _StockFilter.out => colors.expense,
    };
    final surface = switch (filter) {
      _StockFilter.all => colors.infoSurface,
      _StockFilter.low => colors.creditPendingSurface,
      _StockFilter.out => colors.expenseSurface,
    };
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(filter),
      backgroundColor: colors.card,
      selectedColor: surface,
      side: BorderSide(
        color: selected ? accent.withValues(alpha: .35) : colors.border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelPadding: EdgeInsets.zero,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filter.icon,
            size: 15,
            color: selected ? accent : colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            filter.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? accent : colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: .14) : colors.canvas,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? accent : colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSelection {
  const _BrandSelection(this.brand);

  final ProductBrand? brand;
}

class _BrandFilterSheet extends StatelessWidget {
  const _BrandFilterSheet({required this.selected});

  final ProductBrand? selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final options = <ProductBrand?>[null, ...ProductBrand.values];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter brand',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tampilkan produk berdasarkan brand tertentu.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final option in options) ...[
              _BrandOption(
                brand: option,
                selected: option == selected,
                onTap: () => Navigator.of(context).pop(_BrandSelection(option)),
              ),
              if (option != options.last) const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrandOption extends StatelessWidget {
  const _BrandOption({
    required this.brand,
    required this.selected,
    required this.onTap,
  });

  final ProductBrand? brand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? colors.infoSurface
          : colors.canvas.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colors.info.withValues(alpha: .35)
                  : colors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                brand == null ? Icons.apps_rounded : Icons.sell_outlined,
                size: 19,
                color: selected ? colors.info : colors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  brand?.label ?? 'Semua brand',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? colors.info : colors.textPrimary,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, size: 19, color: colors.info),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthPickerCard extends StatelessWidget {
  const _MonthPickerCard({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.infoSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.insights_rounded, size: 20, color: colors.info),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performa penjualan',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppDateFormatter.monthYear(month),
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: 'Bulan sebelumnya',
              visualDensity: VisualDensity.compact,
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            const SizedBox(width: 6),
            IconButton.outlined(
              tooltip: 'Bulan berikutnya',
              visualDensity: VisualDensity.compact,
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryOverview extends StatelessWidget {
  const _InventoryOverview({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final unitCount = products.fold<int>(
      0,
      (sum, item) => sum + item.stockQuantity,
    );
    final outOfStock = products.where((item) => item.stockQuantity == 0).length;
    final lowStock = products
        .where((item) => item.stockQuantity > 0 && item.stockQuantity <= 5)
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (AppBreakpoints.ofWidth(constraints.maxWidth)) {
          WindowSizeClass.compact => 1,
          WindowSizeClass.medium => 2,
          WindowSizeClass.expanded => 4,
        };
        const gap = 12.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _InventoryMetric(
                label: 'Jenis produk',
                value: '${products.length}',
                icon: Icons.inventory_2_outlined,
                color: context.appColors.info,
              ),
            ),
            SizedBox(
              width: width,
              child: _InventoryMetric(
                label: 'Total unit stok',
                value: '$unitCount',
                icon: Icons.stacked_bar_chart_rounded,
                color: context.appColors.income,
              ),
            ),
            SizedBox(
              width: width,
              child: _InventoryMetric(
                label: 'Stok menipis (≤5)',
                value: '$lowStock',
                icon: Icons.notifications_active_outlined,
                color: lowStock == 0
                    ? context.appColors.income
                    : context.appColors.creditPending,
              ),
            ),
            SizedBox(
              width: width,
              child: _InventoryMetric(
                label: 'Stok habis',
                value: '$outOfStock',
                icon: Icons.warning_amber_rounded,
                color: outOfStock == 0
                    ? context.appColors.income
                    : context.appColors.expense,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InventoryMetric extends StatelessWidget {
  const _InventoryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label: $value',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.products, required this.onRestock});

  final List<Product> products;
  final ValueChanged<Product> onRestock;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final hasEmpty = products.any((product) => product.stockQuantity == 0);
    final tone = hasEmpty ? colors.expense : colors.creditPending;
    final surface = hasEmpty
        ? colors.expenseSurface
        : colors.creditPendingSurface;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: .28)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: tone,
          collapsedIconColor: tone,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.notifications_active_outlined,
              size: 19,
              color: tone,
            ),
          ),
          title: Text(
            'Perlu restok (${products.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            'Stok 5 unit atau kurang',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          children: [
            for (final product in products)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onRestock(product),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.brand.label} · ${product.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _StockQuantityChip(stock: product.stockQuantity),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: tone,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BrandProductSection extends StatelessWidget {
  const _BrandProductSection({
    required this.brand,
    required this.products,
    required this.onEdit,
    required this.onEditStock,
    required this.onRestock,
    required this.onDelete,
  });

  final ProductBrand brand;
  final List<Product> products;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onEditStock;
  final ValueChanged<Product> onRestock;
  final ValueChanged<Product> onDelete;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.info,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  brand.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  '${products.length} produk',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = switch (AppBreakpoints.ofWidth(
                constraints.maxWidth,
              )) {
                WindowSizeClass.compact => 1,
                WindowSizeClass.medium => 2,
                WindowSizeClass.expanded => 3,
              };
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final product in products)
                    SizedBox(
                      width: width,
                      child: _ProductCard(
                        product: product,
                        onEdit: () => onEdit(product),
                        onEditStock: () => onEditStock(product),
                        onRestock: () => onRestock(product),
                        onDelete: () => onDelete(product),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onEditStock,
    required this.onRestock,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onEditStock;
  final VoidCallback onRestock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .045),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.infoSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  product.brand.label.characters.first,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.info,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  product.brand.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _StockStatusBadge(stock: product.stockQuantity),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 42,
            child: Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga jual',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormatter.format(product.sellingPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: colors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _StockQuantityChip(stock: product.stockQuantity),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: colors.border.withValues(alpha: .8)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onRestock,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.infoSurface,
                    foregroundColor: colors.info,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text(
                    'Tambah stok',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _ProductIconAction(
                tooltip: 'Edit stok',
                icon: Icons.inventory_2_outlined,
                onPressed: onEditStock,
              ),
              const SizedBox(width: 6),
              _ProductMenuButton(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _StockStatusBadge extends StatelessWidget {
  const _StockStatusBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final (color, surface, label, icon) = switch (stock) {
      0 => (
        colors.expense,
        colors.expenseSurface,
        'Habis',
        Icons.remove_shopping_cart_outlined,
      ),
      <= 5 => (
        colors.creditPending,
        colors.creditPendingSurface,
        'Menipis',
        Icons.warning_amber_rounded,
      ),
      _ => (
        colors.income,
        colors.incomeSurface,
        'Tersedia',
        Icons.check_circle_outline_rounded,
      ),
    };
    return Semantics(
      label: 'Status stok: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockQuantityChip extends StatelessWidget {
  const _StockQuantityChip({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.canvas.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 15,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 5),
          Text(
            'Stok $stock',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductIconAction extends StatelessWidget {
  const _ProductIconAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: colors.canvas.withValues(alpha: .7),
        foregroundColor: colors.textSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(11),
          side: BorderSide(color: colors.border),
        ),
      ),
      icon: Icon(icon, size: 19),
    );
  }
}

class _ProductMenuButton extends StatelessWidget {
  const _ProductMenuButton({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopupMenuButton<_ProductMenuAction>(
      tooltip: 'Menu produk',
      onSelected: (action) => switch (action) {
        _ProductMenuAction.edit => onEdit(),
        _ProductMenuAction.delete => onDelete(),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ProductMenuAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Edit produk'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _ProductMenuAction.delete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: colors.expense,
              ),
              const SizedBox(width: 10),
              Text('Hapus produk', style: TextStyle(color: colors.expense)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.canvas.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}

class _StockHistoryCard extends StatelessWidget {
  const _StockHistoryCard({required this.movements, required this.onRetry});

  final AsyncValue<List<StockMovement>> movements;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.infoSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.history_rounded, size: 20, color: colors.info),
        ),
        title: Text('Riwayat stok masuk', style: theme.textTheme.titleSmall),
        subtitle: Text(
          'Catatan penambahan stok dari restock',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          movements.when(
            loading: () => const AppLoadingState(
              compact: true,
              message: 'Memuat riwayat stok…',
            ),
            error: (error, stack) => ErrorState(
              compact: true,
              message: 'Riwayat stok belum dapat dimuat.',
              onRetry: onRetry,
            ),
            data: (items) {
              final restocks = items
                  .where((movement) => movement.reason == 'restock')
                  .toList(growable: false);
              if (restocks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Belum ada riwayat stok masuk.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final (index, movement) in restocks.indexed) ...[
                    ListTile(
                      title: Text(
                        '${movement.productName} · ${movement.brand}',
                      ),
                      subtitle: Text(
                        '${AppDateFormatter.long(movement.movementDate)}${movement.notes == null ? '' : ' · ${movement.notes}'}',
                      ),
                      trailing: Text(
                        '+${movement.quantityChange}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.income,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (index < restocks.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EditStockDialog extends StatefulWidget {
  const _EditStockDialog({required this.product});

  final Product product;

  @override
  State<_EditStockDialog> createState() => _EditStockDialogState();
}

class _EditStockDialogState extends State<_EditStockDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _stockController = TextEditingController(
      text: '${widget.product.stockQuantity}',
    );
  }

  @override
  void dispose() {
    _stockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.of(context).pop(int.parse(_stockController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit stok · ${widget.product.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appColors.infoSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: context.appColors.info,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Stok saat ini: ${widget.product.stockQuantity} unit',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _stockController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: const [NumberInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Stok baru',
                  hintText: 'Contoh: 25',
                  suffixText: 'unit',
                  helperText:
                      'Masukkan jumlah stok akhir, bukan penambahan stok.',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Stok wajib diisi.';
                  final parsed = int.tryParse(text);
                  if (parsed == null) return 'Stok harus berupa angka.';
                  if (parsed < 0) return 'Stok tidak boleh negatif.';
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}

class _SalesHighlights extends StatelessWidget {
  const _SalesHighlights({required this.items});

  final List<ProductSalesSummary> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final sold = items.where((item) => item.quantitySold > 0).toList();
    final top = sold.isEmpty ? null : sold.first;
    final slow = items.isEmpty ? null : items.last;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.infoSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: colors.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Performa produk',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.canvas,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'Periode ini',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const _SalesEmpty(
                message: 'Tambahkan produk untuk melihat performa penjualan.',
              )
            else if (top == null)
              const _SalesEmpty(
                message: 'Belum ada produk terjual pada periode ini.',
              )
            else
              _SalesCallout(
                icon: Icons.emoji_events_outlined,
                label: 'Terlaris',
                product: top,
                color: colors.income,
              ),
            if (slow != null && slow != top) ...[
              const SizedBox(height: 8),
              _SalesCallout(
                icon: Icons.trending_down_rounded,
                label: slow.quantitySold == 0 ? 'Belum terjual' : 'Terendah',
                product: slow,
                color: colors.creditPending,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SalesEmpty extends StatelessWidget {
  const _SalesEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(Icons.insights_outlined, size: 18, color: colors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SalesCallout extends StatelessWidget {
  const _SalesCallout({
    required this.icon,
    required this.label,
    required this.product,
    required this.color,
  });

  final IconData icon;
  final String label;
  final ProductSalesSummary product;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${product.product.name} · ${product.product.brand.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 1),
                Text(
                  '${product.quantitySold} terjual · ${CurrencyFormatter.format(product.revenue)} omzet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
