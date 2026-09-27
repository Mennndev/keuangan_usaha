import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../database/database_provider.dart';
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
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: AppPageHeader(title: 'Produk & stok'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        final shown = _brand == null
                            ? items
                            : items
                                  .where((item) => item.brand == _brand)
                                  .toList();
                        return Column(
                          children: [
                            _InventoryOverview(products: shown),
                            if (shown.any((p) => p.stockQuantity <= 5)) ...[
                              const SizedBox(height: 10),
                              Card(
                                color:
                                    (shown.any(
                                              (product) =>
                                                  product.stockQuantity == 0,
                                            )
                                            ? context.appColors.expenseSurface
                                            : context
                                                  .appColors
                                                  .creditPendingSurface)
                                        .withValues(alpha: .78),
                                child: ExpansionTile(
                                  leading: Icon(
                                    Icons.notifications_active_outlined,
                                    color:
                                        shown.any(
                                          (product) =>
                                              product.stockQuantity == 0,
                                        )
                                        ? context.appColors.expense
                                        : context.appColors.creditPending,
                                  ),
                                  title: Text(
                                    'Perlu restok (${shown.where((p) => p.stockQuantity <= 5).length})',
                                  ),
                                  subtitle: const Text(
                                    'Peringatan otomatis saat stok 5 unit atau kurang',
                                  ),
                                  children: [
                                    for (final p in shown.where(
                                      (p) => p.stockQuantity <= 5,
                                    ))
                                      ListTile(
                                        title: Text(
                                          '${p.brand.label} · ${p.name}',
                                        ),
                                        trailing: Text(
                                          p.stockQuantity == 0
                                              ? 'Habis'
                                              : 'Sisa ${p.stockQuantity}',
                                          style: TextStyle(
                                            color: p.stockQuantity == 0
                                                ? context.appColors.expense
                                                : context
                                                      .appColors
                                                      .creditPending,
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
                        items: _brand == null
                            ? items
                            : items
                                  .where((item) => item.product.brand == _brand)
                                  .toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final addButton = FilledButton.icon(
                          onPressed: () => _editProduct(),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah produk'),
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
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
                                      Text(
                                        _brand == null
                                            ? 'Pilih brand untuk menyaring produk'
                                            : 'Brand ${_brand!.label}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (constraints.maxWidth >= 520) addButton,
                              ],
                            ),
                            if (constraints.maxWidth < 520) ...[
                              const SizedBox(height: 12),
                              addButton,
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Semua'),
                                  selected: _brand == null,
                                  onSelected: (_) =>
                                      setState(() => _brand = null),
                                ),
                                for (final brand in ProductBrand.values)
                                  ChoiceChip(
                                    label: Text(brand.label),
                                    selected: _brand == brand,
                                    onSelected: (_) =>
                                        setState(() => _brand = brand),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
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
                            .where((p) => _brand == null || p.brand == _brand)
                            .toList();
                        if (shown.isEmpty) {
                          return EmptyState(
                            icon: Icons.inventory_2_outlined,
                            title: _brand == null
                                ? 'Belum ada produk'
                                : 'Belum ada produk ${_brand!.label}',
                            message:
                                'Tambahkan produk untuk mulai mengelola harga dan stok.',
                            primaryAction: FilledButton.icon(
                              onPressed: () => _editProduct(),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah produk'),
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
                                onRestock: _restock,
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Riwayat stok masuk'),
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
                              final restocks = items.where(
                                (m) => m.reason == 'restock',
                              );
                              if (restocks.isEmpty) {
                                return const ListTile(
                                  title: Text('Belum ada riwayat stok masuk.'),
                                );
                              }
                              return Column(
                                children: restocks
                                    .map(
                                      (movement) => ListTile(
                                        title: Text(
                                          '${movement.productName} · ${movement.brand}',
                                        ),
                                        subtitle: Text(
                                          '${AppDateFormatter.long(movement.movementDate)}${movement.notes == null ? '' : ' · ${movement.notes}'}',
                                        ),
                                        trailing: Text(
                                          '+${movement.quantityChange}',
                                        ),
                                      ),
                                    )
                                    .toList(),
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
        final dao = ref.read(databaseProvider).productDao;
        if (existing == null) {
          await dao.insertProduct(
            id: const Uuid().v4(),
            brand: brand.label,
            name: name.text.trim(),
            sellingPrice: CurrencyFormatter.parse(price.text),
          );
        } else {
          await dao.updateProduct(
            id: existing.id,
            brand: brand.label,
            name: name.text.trim(),
            sellingPrice: CurrencyFormatter.parse(price.text),
          );
        }
        if (mounted) {
          ref.invalidate(productsProvider);
          ref.invalidate(productSalesProvider(_month));
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
            .read(databaseProvider)
            .productDao
            .restock(
              productId: product.id,
              quantity: int.parse(quantity.text),
              date: DateTime.now(),
              notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
            );
        ref.invalidate(productsProvider);
        ref.invalidate(stockMovementsProvider);
        ref.invalidate(productSalesProvider(_month));
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.insights_outlined, color: context.appColors.info),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performa penjualan',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                Text(
                  AppDateFormatter.monthYear(month),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bulan sebelumnya',
            visualDensity: VisualDensity.compact,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            visualDensity: VisualDensity.compact,
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ),
  );
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
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 450
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
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
                    : Theme.of(context).colorScheme.error,
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: color.withValues(alpha: .12),
            foregroundColor: color,
            child: Icon(icon, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _BrandProductSection extends StatelessWidget {
  const _BrandProductSection({
    required this.brand,
    required this.products,
    required this.onEdit,
    required this.onRestock,
  });

  final ProductBrand brand;
  final List<Product> products;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onRestock;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: context.appColors.info,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  brand.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${products.length} produk',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 2 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final product in products)
                    SizedBox(
                      width: width,
                      child: _ProductCard(
                        product: product,
                        onEdit: () => onEdit(product),
                        onRestock: () => onRestock(product),
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
    required this.onRestock,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onRestock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stockEmpty = product.stockQuantity == 0;
    final stockColor = stockEmpty
        ? theme.colorScheme.error
        : context.appColors.income;
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
                CircleAvatar(
                  backgroundColor: context.appColors.infoSurface,
                  foregroundColor: context.appColors.info,
                  child: Text(
                    product.brand.label.characters.first,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
                      const SizedBox(height: 3),
                      Text(
                        product.brand.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    stockEmpty ? 'Habis' : 'Stok ${product.stockQuantity}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: stockColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Harga jual',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.format(product.sellingPrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onRestock,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Tambah stok'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Edit produk',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesHighlights extends StatelessWidget {
  const _SalesHighlights({required this.items});

  final List<ProductSalesSummary> items;

  @override
  Widget build(BuildContext context) {
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
                Icon(
                  Icons.trending_up_rounded,
                  color: context.appColors.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Performa produk',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  'Bulan ini',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Tambahkan produk untuk melihat performa penjualan.')
            else if (top == null)
              Text(
                'Belum ada produk terjual pada periode ini.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              _SalesCallout(
                icon: Icons.emoji_events_outlined,
                label: 'Terlaris',
                product: top,
                color: context.appColors.income,
              ),
            if (slow != null && slow != top) ...[
              const SizedBox(height: 8),
              _SalesCallout(
                icon: Icons.trending_down_rounded,
                label: slow.quantitySold == 0 ? 'Belum terjual' : 'Terendah',
                product: slow,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ],
        ),
      ),
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                '${product.product.name} · ${product.product.brand.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                '${product.quantitySold} terjual · ${CurrencyFormatter.format(product.revenue)} omzet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
