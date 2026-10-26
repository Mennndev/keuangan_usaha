import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
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

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  DateTime _month = DateTime.now();
  ProductBrand? _brand;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Product product) {
    if (_brand != null && product.brand != _brand) return false;
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    return product.name.toLowerCase().contains(query) ||
        product.brand.label.toLowerCase().contains(query);
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
    });
  }

  String get _filterSummary {
    final parts = <String>[
      if (_brand != null) 'Brand ${_brand!.label}',
      if (_query.trim().isNotEmpty) 'Pencarian “${_query.trim()}”',
    ];
    return parts.isEmpty
        ? 'Kelola harga dan stok seluruh produk'
        : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final sales = ref.watch(productSalesProvider(_month));
    final movements = ref.watch(stockMovementsProvider);
    final now = DateTime.now();
    final canGoNext =
        _month.year < now.year ||
        (_month.year == now.year && _month.month < now.month);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppPageHeader(title: 'Produk & stok'),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 12),
                    products.when(
                      loading: () => const SizedBox.shrink(),
                      error: (error, stack) => const SizedBox.shrink(),
                      data: (items) {
                        final shown = items.where(_matches).toList();
                        final lowStock = shown
                            .where((p) => p.stockQuantity <= 5)
                            .toList();
                        final hasEmptyStock = lowStock.any(
                          (p) => p.stockQuantity == 0,
                        );
                        final tone = hasEmptyStock
                            ? context.appColors.expense
                            : context.appColors.creditPending;
                        final surface = hasEmptyStock
                            ? context.appColors.expenseSurface
                            : context.appColors.creditPendingSurface;
                        return Column(
                          children: [
                            _InventoryOverview(products: shown),
                            if (lowStock.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Card(
                                color: surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: tone.withValues(alpha: .3),
                                  ),
                                ),
                                child: ExpansionTile(
                                  shape: const Border(),
                                  collapsedShape: const Border(),
                                  iconColor: tone,
                                  collapsedIconColor: tone,
                                  leading: Icon(
                                    Icons.notifications_active_outlined,
                                    color: tone,
                                  ),
                                  title: Text(
                                    'Perlu restok (${lowStock.length})',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  subtitle: Text(
                                    'Stok 5 unit atau kurang',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color:
                                              context.appColors.textSecondary,
                                        ),
                                  ),
                                  children: [
                                    for (final p in lowStock)
                                      ListTile(
                                        title: Text(
                                          '${p.brand.label} · ${p.name}',
                                        ),
                                        trailing: Text(
                                          p.stockQuantity == 0
                                              ? 'Habis'
                                              : 'Sisa ${p.stockQuantity}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: tone,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        onTap: () => _restock(p),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
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
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final colors = context.appColors;
                        final size = AppBreakpoints.ofWidth(
                          constraints.maxWidth,
                        );
                        final compact = size == WindowSizeClass.compact;
                        final addButton = FilledButton.icon(
                          onPressed: () => _editProduct(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah produk'),
                        );
                        final searchField = TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: 'Cari nama produk atau brand',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Hapus pencarian',
                                    onPressed: _clearSearch,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        );
                        final filters = Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildBrandChip(
                              label: 'Semua',
                              selected: _brand == null,
                              onSelected: () => setState(() => _brand = null),
                            ),
                            for (final brand in ProductBrand.values)
                              _buildBrandChip(
                                label: brand.label,
                                selected: _brand == brand,
                                onSelected: () =>
                                    setState(() => _brand = brand),
                              ),
                          ],
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Daftar produk',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _filterSummary,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!compact) ...[
                                  const SizedBox(width: 16),
                                  addButton,
                                ],
                              ],
                            ),
                            if (compact) ...[
                              const SizedBox(height: 12),
                              addButton,
                            ],
                            const SizedBox(height: 14),
                            if (size == WindowSizeClass.expanded)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: searchField),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 3, child: filters),
                                ],
                              )
                            else ...[
                              searchField,
                              const SizedBox(height: 10),
                              filters,
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    products.when(
                      loading: () => const AppLoadingState(
                        message: 'Memuat daftar produk…',
                      ),
                      error: (error, stack) => ErrorState(
                        message: 'Daftar produk belum dapat dimuat.',
                        onRetry: () => ref.invalidate(productsProvider),
                      ),
                      data: (items) {
                        final shown = items.where(_matches).toList();
                        if (shown.isEmpty) {
                          final hasQuery = _query.trim().isNotEmpty;
                          final hasBrand = _brand != null;
                          return EmptyState(
                            icon: hasQuery
                                ? Icons.search_off_rounded
                                : Icons.inventory_2_outlined,
                            title: hasQuery
                                ? 'Produk tidak ditemukan'
                                : hasBrand
                                ? 'Belum ada produk ${_brand!.label}'
                                : 'Belum ada produk',
                            message: hasQuery
                                ? 'Tidak ada produk yang cocok dengan “${_query.trim()}”. Coba kata kunci lain atau ubah filter brand.'
                                : 'Tambahkan produk untuk mulai mengelola harga dan stok.',
                            primaryAction: hasQuery
                                ? OutlinedButton.icon(
                                    onPressed: _resetFilters,
                                    icon: const Icon(
                                      Icons.filter_alt_off_outlined,
                                    ),
                                    label: const Text('Reset filter'),
                                  )
                                : FilledButton.icon(
                                    onPressed: () => _editProduct(),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tambah produk'),
                                  ),
                            secondaryAction: hasQuery || !hasBrand
                                ? null
                                : TextButton.icon(
                                    onPressed: _resetFilters,
                                    icon: const Icon(
                                      Icons.filter_alt_off_outlined,
                                    ),
                                    label: const Text('Tampilkan semua produk'),
                                  ),
                          );
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
                                    .toList(),
                                onEdit: (product) => _editProduct(product),
                                onEditStock: _editStock,
                                onRestock: _restock,
                                onDelete: _deleteProduct,
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.appColors.infoSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: context.appColors.info,
                          ),
                        ),
                        title: Text(
                          'Riwayat stok masuk',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          'Catatan penambahan stok dari restock',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.appColors.textSecondary,
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
                              onRetry: () =>
                                  ref.invalidate(stockMovementsProvider),
                            ),
                            data: (items) {
                              final restocks = items
                                  .where((m) => m.reason == 'restock')
                                  .toList();
                              if (restocks.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 18,
                                        color: context.appColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Belum ada riwayat stok masuk.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: context
                                                    .appColors
                                                    .textSecondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Column(
                                children: [
                                  for (final (index, movement)
                                      in restocks.indexed) ...[
                                    ListTile(
                                      title: Text(
                                        '${movement.productName} · ${movement.brand}',
                                      ),
                                      subtitle: Text(
                                        '${AppDateFormatter.long(movement.movementDate)}${movement.notes == null ? '' : ' · ${movement.notes}'}',
                                      ),
                                      trailing: Text(
                                        '+${movement.quantityChange}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: context.appColors.income,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    if (index < restocks.length - 1)
                                      Divider(
                                        height: 1,
                                        indent: 16,
                                        endIndent: 16,
                                      ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
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

  Widget _buildBrandChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final colors = context.appColors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: colors.infoSurface,
      backgroundColor: colors.card,
      side: BorderSide(
        color: selected ? colors.info.withValues(alpha: .35) : colors.border,
      ),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? colors.info : colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) => onSelected(),
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
      padding: const EdgeInsets.only(top: 16),
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
                child: Text(brand.label, style: theme.textTheme.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.canvas,
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
    final (
      stockColor,
      stockSurface,
      stockLabel,
    ) = switch (product.stockQuantity) {
      0 => (colors.expense, colors.expenseSurface, 'Habis'),
      <= 5 => (
        colors.creditPending,
        colors.creditPendingSurface,
        'Stok ${product.stockQuantity}',
      ),
      _ => (
        colors.income,
        colors.incomeSurface,
        'Stok ${product.stockQuantity}',
      ),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.infoSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    product.brand.label.characters.first,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.info,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.brand.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: stockSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: stockColor.withValues(alpha: .25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stockLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: stockColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: colors.border.withValues(alpha: .8)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onRestock,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.infoSurface,
                      foregroundColor: colors.info,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    label: const Text(
                      'Tambah stok',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ProductAction(
                  tooltip: 'Edit stok',
                  icon: Icons.inventory_2_outlined,
                  onPressed: onEditStock,
                ),
                const SizedBox(width: 8),
                _ProductAction(
                  tooltip: 'Edit produk',
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                ),
                const SizedBox(width: 8),
                _ProductAction(
                  tooltip: 'Hapus produk',
                  icon: Icons.delete_outline,
                  onPressed: onDelete,
                  color: colors.expense,
                ),
              ],
            ),
          ],
        ),
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

class _ProductAction extends StatelessWidget {
  const _ProductAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      style:
          IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            maximumSize: const Size(44, 44),
            padding: EdgeInsets.zero,
            foregroundColor: color,
          ).copyWith(
            side: WidgetStatePropertyAll(
              BorderSide(color: context.appColors.border),
            ),
          ),
      icon: Icon(icon, size: 19),
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
