import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../customers/presentation/providers/customer_providers.dart';

import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../products/domain/product.dart';
import '../../../../database/daos/product_dao.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../domain/finance_transaction.dart';
import '../../domain/transaction_validators.dart';
import '../providers/transaction_providers.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    this.transactionId,
    this.initialType = TransactionType.income,
    super.key,
  });

  final String? transactionId;
  final TransactionType initialType;

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();
  final _creditCustomerController = TextEditingController();
  final _creditDueDateController = TextEditingController();

  late TransactionType _type;
  late DateTime _date;
  bool _isCredit = false;
  final Map<String, int> _selectedProducts = {};
  final Map<String, int> _originalProductQuantities = {};
  final Map<String, int> _originalProductUnitPrices = {};
  String? _productToAdd;
  late DateTime _creditDueDate;
  bool _dirty = false;
  bool _submitting = false;
  bool _transactionNameEdited = false;
  bool _popAllowed = false;
  String? _loadedId;
  String? _loadedSaleId;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _date = DateTime.now();
    _creditDueDate = DateTime.now().add(const Duration(days: 30));
    _dateController.text = AppDateFormatter.long(_date);
    _creditDueDateController.text = AppDateFormatter.long(_creditDueDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    _creditCustomerController.dispose();
    _creditDueDateController.dispose();
    super.dispose();
  }

  void _populate(
    FinanceTransaction transaction,
    List<ProductSaleSnapshot> sales,
  ) {
    if (_loadedId == transaction.id && _loadedSaleId == transaction.id) return;
    _loadedId = transaction.id;
    _loadedSaleId = transaction.id;
    _type = transaction.type;
    _date = transaction.transactionDate;
    _isCredit = transaction.isCredit;
    _selectedProducts
      ..clear()
      ..addEntries(
        sales.map((sale) => MapEntry(sale.productId, sale.quantity)),
      );
    _originalProductQuantities
      ..clear()
      ..addEntries(
        sales.map((sale) => MapEntry(sale.productId, sale.quantity)),
      );
    _originalProductUnitPrices
      ..clear()
      ..addEntries(
        sales.map((sale) => MapEntry(sale.productId, sale.unitPrice)),
      );
    _productToAdd = null;
    _transactionNameEdited = true;
    _nameController.text = transaction.name;
    _amountController.text = CurrencyFormatter.digits(transaction.amount);
    _dateController.text = AppDateFormatter.long(transaction.transactionDate);
    _categoryController.text = transaction.category ?? '';
    _notesController.text = transaction.notes ?? '';
    if (transaction.type == TransactionType.income) {
      _creditCustomerController.text = transaction.creditCustomerName ?? '';
    }
    if (transaction.isCredit) {
      _creditDueDate = transaction.creditDueDate ?? DateTime.now();
      _creditDueDateController.text = AppDateFormatter.long(_creditDueDate);
    }
    _dirty = false;
  }

  void _markDirty([String? _]) {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
      helpText: 'Pilih tanggal transaksi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _date = picked;
      _dateController.text = AppDateFormatter.long(picked);
      _dirty = true;
    });
  }

  Future<void> _pickCreditDueDate() async {
    // Bug fix: `firstDate` used to always be `DateTime.now()`. When editing a
    // credit transaction whose due date is already in the past (overdue),
    // `initialDate` (the old, past due date) would fall *before* `firstDate`,
    // which makes `showDatePicker` throw an assertion error and crash the
    // screen. We now let `firstDate` go as far back as the current due date
    // so the picker always opens safely, whether the transaction is new,
    // upcoming, or overdue.
    final today = DateTime.now();
    final firstSelectableDate = _creditDueDate.isBefore(today)
        ? _creditDueDate
        : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _creditDueDate,
      firstDate: firstSelectableDate,
      lastDate: DateTime(DateTime.now().year + 10, 12, 31),
      helpText: 'Pilih tanggal jatuh tempo pembayaran',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _creditDueDate = picked;
      _creditDueDateController.text = AppDateFormatter.long(picked);
      _dirty = true;
    });
  }

  Future<void> _chooseCustomer() async {
    final customers = await ref.read(customersProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Pilih pelanggan')),
            if (customers.isEmpty)
              const ListTile(title: Text('Belum ada pelanggan tersimpan.')),
            for (final customer in customers)
              ListTile(
                title: Text(customer.name),
                subtitle: customer.phone == null ? null : Text(customer.phone!),
                onTap: () => Navigator.pop(context, customer.name),
              ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1),
              title: const Text('Tambah pelanggan baru'),
              onTap: () => Navigator.pop(context, '__new__'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == '__new__') {
      final name = TextEditingController();
      final phone = TextEditingController();
      final save = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tambah pelanggan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nama pelanggan'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor telepon (opsional',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
      if (save == true && name.text.trim().isNotEmpty) {
        try {
          await ref
              .read(customerRepositoryProvider)
              .save(name: name.text, phone: phone.text);
          // Bug fix: this `mounted` check was missing. If the user leaves the
          // screen while `save()` is still awaiting, calling `_markDirty()`
          // (which calls `setState`) afterwards would throw
          // "setState() called after dispose()".
          if (!mounted) return;
          ref.invalidate(customersProvider);
          _creditCustomerController.text = name.text.trim();
          _markDirty();
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pelanggan belum tersimpan: $error')),
            );
          }
        }
      }
      name.dispose();
      phone.dispose();
    } else {
      setState(() {
        _creditCustomerController.text = selected;
        _dirty = true;
      });
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty || _submitting) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Buang perubahan?'),
            content: const Text(
              'Perubahan pada form belum disimpan dan akan hilang.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tetap di sini'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Buang perubahan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _leave() async {
    final shouldLeave = await _confirmDiscard();
    if (!mounted || !shouldLeave) return;
    setState(() => _popAllowed = true);
    context.pop();
  }

  Future<void> _submit() async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final input = TransactionInput(
      type: _type,
      name: _nameController.text,
      amount: CurrencyFormatter.parse(_amountController.text),
      transactionDate: _date,
      category: _categoryController.text,
      notes: _notesController.text,
      isCredit: _isCredit,
      creditCustomerName:
          _type != TransactionType.income ||
              _creditCustomerController.text.trim().isEmpty
          ? null
          : _creditCustomerController.text.trim(),
      creditDueDate: _isCredit ? _creditDueDate : null,
      products: _type == TransactionType.income
          ? _selectedProducts.entries
                .map(
                  (entry) => TransactionProductInput(
                    productId: entry.key,
                    quantity: entry.value,
                  ),
                )
                .toList(growable: false)
          : const [],
    );
    try {
      final controller = ref.read(transactionControllerProvider.notifier);
      late final String id;
      if (widget.transactionId == null) {
        id = await controller.create(input);
      } else {
        id = widget.transactionId!;
        await controller.edit(id, input);
      }
      if (!mounted) return;
      setState(() {
        _dirty = false;
        _popAllowed = true;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Perubahan transaksi disimpan.'
                : 'Transaksi berhasil dicatat.',
          ),
        ),
      );
      context.go('/transactions/$id');
    } catch (error) {
      debugPrint('Gagal menyimpan transaksi: $error');
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError || error is ArgumentError
                ? error.toString().replaceFirst('Bad state: ', '')
                : 'Transaksi gagal disimpan: $error',
          ),
        ),
      );
    }
  }

  Widget _buildProductPicker(List<Product> products) {
    if (products.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.go('/products'),
          icon: const Icon(Icons.inventory_2_outlined),
          label: const Text('Kelola produk dan stok'),
        ),
      );
    }

    final available = products
        .where(
          (product) =>
              product.stockQuantity > 0 &&
              !_selectedProducts.containsKey(product.id),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (available.isNotEmpty)
          DropdownButtonFormField<String?>(
            key: ValueKey(
              '${_productToAdd ?? 'empty'}-${_selectedProducts.length}',
            ),
            // Bug fix: `value` is deprecated since Flutter v3.33 in favor of
            // `initialValue`.
            initialValue: _productToAdd,
            decoration: const InputDecoration(
              labelText: 'Tambah produk',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Pilih produk'),
              ),
              ...available.map(
                (product) => DropdownMenuItem<String?>(
                  value: product.id,
                  child: Text(
                    '${product.brand.label} · ${product.name} · stok ${product.stockQuantity}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: _submitting
                ? null
                : (id) {
                    if (id == null) return;
                    final product = _findProduct(products, id);
                    if (product == null) return;
                    setState(() {
                      _selectedProducts[id] = 1;
                      _productToAdd = null;
                      if (!_transactionNameEdited) {
                        _nameController.text = _selectedProducts.length == 1
                            ? 'Penjualan ${product.name}'
                            : 'Penjualan ${_selectedProducts.length} produk';
                      }
                      final brands = _selectedProducts.keys
                          .map((productId) => _findProduct(products, productId))
                          .whereType<Product>()
                          .map((selected) => selected.brand.label)
                          .toSet();
                      _categoryController.text = brands.length == 1
                          ? brands.first
                          : 'Penjualan produk';
                      _updateSaleAmount(products);
                      _dirty = true;
                    });
                  },
          )
        else
          Text(
            _selectedProducts.isEmpty
                ? 'Tidak ada produk dengan stok tersedia.'
                : 'Semua produk yang tersedia sudah ditambahkan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (_selectedProducts.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final entry in _selectedProducts.entries.toList())
            _buildSelectedProductLine(products, entry.key, entry.value),
        ],
      ],
    );
  }

  Widget _buildSelectedProductLine(
    List<Product> products,
    String productId,
    int quantity,
  ) {
    final product = _findProduct(products, productId);
    if (product == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Produk pada transaksi lama tidak tersedia.'),
        trailing: IconButton(
          tooltip: 'Hapus produk',
          onPressed: _submitting
              ? null
              : () => setState(() {
                  _selectedProducts.remove(productId);
                  _dirty = true;
                  _updateSaleAmount(products);
                }),
          icon: const Icon(Icons.close),
        ),
      );
    }

    final availableStock =
        product.stockQuantity + (_originalProductQuantities[productId] ?? 0);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${product.brand.label} · ${CurrencyFormatter.format(product.sellingPrice)} per item',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus produk',
                onPressed: _submitting
                    ? null
                    : () => setState(() {
                        _selectedProducts.remove(productId);
                        _dirty = true;
                        _updateSaleAmount(products);
                      }),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          TextFormField(
            key: ValueKey('$_loadedId-$productId'),
            initialValue: '$quantity',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Jumlah terjual',
              helperText: 'Tersedia: $availableStock',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final selectedQuantity = int.tryParse(value ?? '');
              if (selectedQuantity == null || selectedQuantity <= 0) {
                return 'Jumlah harus lebih dari 0';
              }
              if (selectedQuantity > availableStock) {
                return 'Stok produk tidak mencukupi';
              }
              return null;
            },
            onChanged: (value) {
              final selectedQuantity = int.tryParse(value);
              if (selectedQuantity == null || selectedQuantity <= 0) return;
              setState(() {
                _selectedProducts[productId] = selectedQuantity;
                _updateSaleAmount(products);
                _dirty = true;
              });
            },
          ),
        ],
      ),
    );
  }

  void _updateSaleAmount(List<Product> products) {
    if (_selectedProducts.isEmpty) {
      _amountController.clear();
      return;
    }
    var total = 0;
    for (final entry in _selectedProducts.entries) {
      final product = _findProduct(products, entry.key);
      if (product != null) {
        final originalQuantity = _originalProductQuantities[entry.key];
        final originalPrice = _originalProductUnitPrices[entry.key];
        final unitPrice =
            originalQuantity == entry.value && originalPrice != null
            ? originalPrice
            : product.sellingPrice;
        total += unitPrice * entry.value;
      }
    }
    _amountController.text = CurrencyFormatter.digits(total);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactionId != null) {
      final transaction = ref.watch(
        transactionByIdProvider(widget.transactionId!),
      );
      return transaction.when(
        loading: () =>
            const AppLoadingState(message: 'Menyiapkan form transaksi…'),
        error: (error, stackTrace) => ErrorState(
          message: 'Detail transaksi belum dapat dibuka.',
          onRetry: () =>
              ref.invalidate(transactionByIdProvider(widget.transactionId!)),
        ),
        data: (value) {
          if (value == null) {
            return const ErrorState(
              message: 'Transaksi ini tidak ditemukan atau sudah dihapus.',
            );
          }
          final sales = ref.watch(productSaleProvider(value.id));
          return sales.when(
            loading: () => const AppLoadingState(
              message: 'Memuat rincian produk transaksi…',
            ),
            error: (error, stack) => ErrorState(
              compact: true,
              message: 'Informasi produk transaksi belum dapat dimuat.',
              onRetry: () => ref.invalidate(productSaleProvider(value.id)),
            ),
            data: (saleValues) {
              _populate(value, saleValues);
              return _buildForm(context);
            },
          );
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    return PopScope(
      canPop: _popAllowed || !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await _confirmDiscard();
        if (!mounted || !shouldLeave) return;
        setState(() => _popAllowed = true);
        if (!context.mounted) return;
        context.pop();
      },
      child: Form(
        key: _formKey,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: AppPageHeader(
                  title: widget.isEditing
                      ? 'Edit transaksi'
                      : 'Tambah transaksi',
                  subtitle: widget.isEditing
                      ? 'Perbarui data transaksi usaha'
                      : 'Catat pemasukan atau pengeluaran',
                  leading: IconButton(
                    tooltip: 'Kembali',
                    onPressed: _submitting ? null : _leave,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                28 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Jenis transaksi',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<TransactionType>(
                              segments: const [
                                ButtonSegment(
                                  value: TransactionType.income,
                                  icon: Icon(Icons.south_west_rounded),
                                  label: Text('Pemasukan'),
                                ),
                                ButtonSegment(
                                  value: TransactionType.expense,
                                  icon: Icon(Icons.north_east_rounded),
                                  label: Text('Pengeluaran'),
                                ),
                              ],
                              selected: {_type},
                              onSelectionChanged: _submitting
                                  ? null
                                  : (selection) => setState(() {
                                      _type = selection.single;
                                      if (_type == TransactionType.expense) {
                                        _selectedProducts.clear();
                                        _isCredit = false;
                                      }
                                      _dirty = true;
                                    }),
                            ),
                            if (_type == TransactionType.income) ...[
                              const SizedBox(height: 16),
                              productsAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (error, stack) => ErrorState(
                                  compact: true,
                                  message: 'Daftar produk tidak dapat dimuat.',
                                  onRetry: () =>
                                      ref.invalidate(productsProvider),
                                ),
                                data: (products) =>
                                    _buildProductPicker(products),
                              ),
                            ],
                            const SizedBox(height: 20),
                            AppTextField(
                              controller: _nameController,
                              label: 'Nama transaksi',
                              hint: 'Contoh: Penjualan toko',
                              validator: TransactionValidators.name,
                              textInputAction: TextInputAction.next,
                              onChanged: (value) {
                                _transactionNameEdited = true;
                                _markDirty(value);
                              },
                              autofocus: !widget.isEditing,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _amountController,
                              label: 'Nominal',
                              hint: '0',
                              prefixText: 'Rp ',
                              keyboardType: TextInputType.number,
                              inputFormatters: [RupiahInputFormatter()],
                              validator: TransactionValidators.amount,
                              readOnly: _selectedProducts.isNotEmpty,
                              textInputAction: TextInputAction.next,
                              onChanged: _markDirty,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _dateController,
                              label: 'Tanggal',
                              readOnly: true,
                              onTap: _submitting ? null : _pickDate,
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _categoryController,
                              label: 'Kategori (opsional)',
                              hint: 'Contoh: Penjualan, stok, operasional',
                              textInputAction: TextInputAction.next,
                              onChanged: _markDirty,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _notesController,
                              label: 'Keterangan (opsional)',
                              hint: 'Tambahkan catatan singkat',
                              maxLines: 4,
                              keyboardType: TextInputType.multiline,
                              textInputAction: TextInputAction.newline,
                              onChanged: _markDirty,
                            ),
                            if (_type == TransactionType.income) ...[
                              const SizedBox(height: 24),
                              _FormSectionHeading(
                                icon: Icons.person_outline_rounded,
                                title: 'Pelanggan',
                                subtitle: 'Opsional untuk pembayaran langsung',
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                controller: _creditCustomerController,
                                label: _isCredit
                                    ? 'Nama Pelanggan'
                                    : 'Nama Pelanggan (opsional)',
                                hint: 'Pilih pelanggan atau ketik nama',
                                validator: (value) {
                                  if (_isCredit &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Pelanggan wajib diisi untuk penjualan kredit';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                                onChanged: _markDirty,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _submitting
                                        ? null
                                        : _chooseCustomer,
                                    icon: const Icon(
                                      Icons.person_search_outlined,
                                    ),
                                    label: const Text(
                                      'Pilih / tambah pelanggan',
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => context.push('/customers'),
                                    icon: const Icon(Icons.people_outline),
                                    label: const Text('Kelola pelanggan'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  8,
                                  14,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text('Penjualan kredit'),
                                      subtitle: const Text(
                                        'Catat jika pelanggan membayar nanti',
                                      ),
                                      value: _isCredit,
                                      onChanged: _submitting
                                          ? null
                                          : (value) => setState(() {
                                              _isCredit = value;
                                              _dirty = true;
                                            }),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      curve: Curves.easeInOutCubic,
                                      alignment: Alignment.topCenter,
                                      child: _isCredit
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                const Divider(height: 20),
                                                Text(
                                                  'Rincian pembayaran kredit',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.labelLarge,
                                                ),
                                                const SizedBox(height: 10),
                                                AppTextField(
                                                  controller:
                                                      _creditDueDateController,
                                                  label: 'Tanggal jatuh tempo',
                                                  readOnly: true,
                                                  onTap: _submitting
                                                      ? null
                                                      : _pickCreditDueDate,
                                                  suffixIcon: const Icon(
                                                    Icons
                                                        .calendar_today_outlined,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 420;
                                final cancel = OutlinedButton(
                                  onPressed: _submitting ? null : _leave,
                                  child: const Text('Batal'),
                                );
                                final save = FilledButton.icon(
                                  onPressed: _submitting ? null : _submit,
                                  icon: _submitting
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    _submitting ? 'Menyimpan…' : 'Simpan',
                                  ),
                                );
                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      save,
                                      const SizedBox(height: 10),
                                      cancel,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: cancel),
                                    const SizedBox(width: 12),
                                    Expanded(child: save),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSectionHeading extends StatelessWidget {
  const _FormSectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

Product? _findProduct(List<Product> products, String id) {
  for (final product in products) {
    if (product.id == id) return product;
  }
  return null;
}