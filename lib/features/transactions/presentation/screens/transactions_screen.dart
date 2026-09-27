import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/formatters/date_formatter.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';
import '../../../../core/widgets/transaction_list_item.dart';
import '../../domain/finance_transaction.dart';
import '../../domain/transaction_filter.dart';
import '../providers/transaction_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  TransactionFilter _filter = const TransactionFilter();

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _filter = _filter.copyWith(search: value, limit: AppConstants.pageSize);
      });
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10, 12, 31),
      initialDateRange: _filter.start == null || _filter.end == null
          ? null
          : DateTimeRange(
              start: _filter.start!,
              end: _filter.end!.subtract(const Duration(days: 1)),
            ),
      helpText: 'Pilih rentang transaksi',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
      saveText: 'Terapkan',
    );
    if (result == null || !mounted) return;
    setState(() {
      _filter = _filter.copyWith(
        start: DateTime(
          result.start.year,
          result.start.month,
          result.start.day,
        ),
        end: DateTime(result.end.year, result.end.month, result.end.day + 1),
        limit: AppConstants.pageSize,
      );
    });
  }

  Future<void> _pickSort() async {
    final selected = await showModalBottomSheet<TransactionSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Urutkan transaksi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final sort in TransactionSort.values)
                ListTile(
                  title: Text(sort.label),
                  trailing: sort == _filter.sort
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.of(context).pop(sort),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _filter = _filter.copyWith(sort: selected, limit: AppConstants.pageSize);
    });
  }

  Future<void> _delete(FinanceTransaction transaction) async {
    final deleted = await showConfirmDeleteDialog(
      context,
      transactionName: transaction.name,
      onDelete: () => ref
          .read(transactionControllerProvider.notifier)
          .delete(transaction.id),
    );
    if (!mounted || !deleted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil dihapus.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionsProvider(_filter));
    final hasQuery =
        _filter.search.trim().isNotEmpty ||
        _filter.type != null ||
        _filter.start != null;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Transaksi',
              subtitle: 'Semua aktivitas keuangan usaha',
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push('/customers'),
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Pelanggan'),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.go('/transactions/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Cari nama, kategori, atau keterangan',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TypeChip(
                        label: 'Semua',
                        selected: _filter.type == null,
                        onSelected: () => setState(() {
                          _filter = _filter.copyWith(
                            clearType: true,
                            limit: AppConstants.pageSize,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Pemasukan',
                        selected: _filter.type == TransactionType.income,
                        onSelected: () => setState(() {
                          _filter = _filter.copyWith(
                            type: TransactionType.income,
                            limit: AppConstants.pageSize,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      _TypeChip(
                        label: 'Pengeluaran',
                        selected: _filter.type == TransactionType.expense,
                        onSelected: () => setState(() {
                          _filter = _filter.copyWith(
                            type: TransactionType.expense,
                            limit: AppConstants.pageSize,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                        _filter.start == null
                            ? 'Tanggal'
                            : '${AppDateFormatter.short(_filter.start!)} – ${AppDateFormatter.short(_filter.end!.subtract(const Duration(days: 1)))}',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickSort,
                      icon: const Icon(Icons.sort),
                      label: Text(_filter.sort.label),
                    ),
                    if (_filter.start != null)
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _filter = _filter.copyWith(
                            clearDates: true,
                            limit: AppConstants.pageSize,
                          );
                        }),
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Hapus tanggal'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        transactions.when(
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: AppLoadingState(message: 'Memuat transaksi…'),
          ),
          error: (error, stackTrace) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: 'Periksa penyimpanan perangkat lalu coba kembali.',
              onRetry: () => ref.invalidate(transactionsProvider(_filter)),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: hasQuery
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Transaksi tidak ditemukan',
                        message:
                            'Ubah kata pencarian atau longgarkan filter yang aktif.',
                        primaryAction: OutlinedButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _filter = const TransactionFilter();
                            });
                          },
                          child: const Text('Reset filter'),
                        ),
                      )
                    : EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'Belum ada transaksi',
                        message:
                            'Catat pemasukan atau pengeluaran pertama untuk mulai melihat arus kas usaha.',
                        primaryAction: FilledButton.icon(
                          onPressed: () => context.go('/transactions/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('Catat transaksi pertama'),
                        ),
                      ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount:
                    items.length + (items.length == _filter.limit ? 1 : 0),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return Center(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _filter = _filter.copyWith(
                            limit: _filter.limit + AppConstants.pageSize,
                          );
                        }),
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Muat lebih banyak'),
                      ),
                    );
                  }
                  final transaction = items[index];
                  return TransactionListItem(
                    transaction: transaction,
                    onTap: () => context.go('/transactions/${transaction.id}'),
                    onEdit: () =>
                        context.go('/transactions/${transaction.id}/edit'),
                    onDelete: () => _delete(transaction),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
