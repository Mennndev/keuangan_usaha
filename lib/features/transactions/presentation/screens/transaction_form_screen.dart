import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_state.dart';
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
  late DateTime _creditDueDate;
  bool _dirty = false;
  bool _submitting = false;
  bool _popAllowed = false;
  String? _loadedId;

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

  void _populate(FinanceTransaction transaction) {
    if (_loadedId == transaction.id) return;
    _loadedId = transaction.id;
    _type = transaction.type;
    _date = transaction.transactionDate;
    _isCredit = transaction.isCredit;
    _nameController.text = transaction.name;
    _amountController.text = CurrencyFormatter.digits(transaction.amount);
    _dateController.text = AppDateFormatter.long(transaction.transactionDate);
    _categoryController.text = transaction.category ?? '';
    _notesController.text = transaction.notes ?? '';
    if (transaction.isCredit) {
      _creditCustomerController.text = transaction.creditCustomerName ?? '';
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _creditDueDate,
      firstDate: DateTime.now(),
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
      creditCustomerName: _isCredit ? _creditCustomerController.text : null,
      creditDueDate: _isCredit ? _creditDueDate : null,
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi belum berhasil disimpan. Coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactionId != null) {
      final transaction = ref.watch(
        transactionByIdProvider(widget.transactionId!),
      );
      return transaction.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Menyiapkan form transaksi…'),
            ],
          ),
        ),
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
          _populate(value);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
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
                                      _dirty = true;
                                    }),
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              controller: _nameController,
                              label: 'Nama transaksi',
                              hint: 'Contoh: Penjualan toko',
                              validator: TransactionValidators.name,
                              textInputAction: TextInputAction.next,
                              onChanged: _markDirty,
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
                              const SizedBox(height: 20),
                              SwitchListTile(
                                title: const Text('Penjualan Kredit'),
                                subtitle: const Text(
                                  'Pelanggan membayar di bulan berikutnya',
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
                            ],
                            if (_isCredit) ...[
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _creditCustomerController,
                                label: 'Nama Pelanggan',
                                hint: 'Contoh: Toko Sejaya',
                                validator: (value) {
                                  if (_isCredit &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Nama pelanggan harus diisi untuk penjualan kredit';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                                onChanged: _markDirty,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _creditDueDateController,
                                label: 'Tanggal Jatuh Tempo',
                                readOnly: true,
                                onTap:
                                    _submitting ? null : _pickCreditDueDate,
                                suffixIcon: const Icon(
                                  Icons.calendar_today_outlined,
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
