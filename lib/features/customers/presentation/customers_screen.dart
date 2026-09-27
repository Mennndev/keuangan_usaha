import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../settings/presentation/providers/settings_providers.dart';
import 'providers/customer_providers.dart';
import '../domain/customer.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editCustomer(BuildContext context, Customer? customer) async {
    final draft = await showDialog<CustomerDraft>(
      context: context,
      builder: (context) => _CustomerEditDialog(customer: customer),
    );
    if (draft != null) {
      try {
        await ref
            .read(customerRepositoryProvider)
            .save(id: customer?.id, name: draft.name, phone: draft.phone);
        ref.invalidate(customersProvider);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pelanggan belum tersimpan: $error')),
          );
        }
      }
    }
  }

  Future<void> _exportAllData() async {
    try {
      final box = context.findRenderObject();
      final origin = box is RenderBox && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      final summary = await ref
          .read(transactionExportServiceProvider)
          .exportAndShare(sharePositionOrigin: origin);
      if (!mounted || summary == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File Excel siap: ${summary.transactions} transaksi, ${summary.customers} pelanggan, ${summary.products} produk.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ekspor data belum berhasil: $error')),
        );
      }
    }
  }

  Future<void> _showHistory(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
  ) async {
    final rows = await ref
        .read(customerRepositoryProvider)
        .getHistory(customer);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: Column(
            children: [
              ListTile(
                title: Text('Riwayat ${customer.name}'),
                subtitle: Text('${rows.length} transaksi'),
              ),
              Expanded(
                child: rows.isEmpty
                    ? const Center(
                        child: Text('Belum ada transaksi untuk pelanggan ini.'),
                      )
                    : ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final row = rows[index];
                          final type = row.read<String>('type');
                          final date = row.read<DateTime>('transaction_date');
                          final isCredit = row.read<bool>('is_credit');
                          final amount = row.read<int>('amount');
                          final paidAmount = row.read<int>(
                            'credit_paid_amount',
                          );
                          final dueDate = row.readNullable<DateTime>(
                            'credit_due_date',
                          );
                          final status = isCredit
                              ? _customerCreditStatus(
                                  row.read<String>('credit_status'),
                                  amount: amount,
                                  paidAmount: paidAmount,
                                  dueDate: dueDate,
                                )
                              : 'Tunai';
                          return ListTile(
                            title: Text(
                              row.read<String>('name'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${AppDateFormatter.long(date)} · $status',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 116,
                                  ),
                                  child: Text(
                                    CurrencyFormatter.formatSigned(
                                      amount,
                                      income: type == 'income',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                            onTap: () => _showTransactionDetail(
                              context,
                              name: row.read<String>('name'),
                              type: type,
                              amount: amount,
                              date: date,
                              isCredit: isCredit,
                              creditStatus: row.read<String>('credit_status'),
                              paidAmount: paidAmount,
                              dueDate: dueDate,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTransactionDetail(
    BuildContext context, {
    required String name,
    required String type,
    required int amount,
    required DateTime date,
    required bool isCredit,
    required String creditStatus,
    required int paidAmount,
    required DateTime? dueDate,
  }) async {
    final remainingAmount = (amount - paidAmount).clamp(0, amount).toInt();
    final status = isCredit
        ? _customerCreditStatus(
            creditStatus,
            amount: amount,
            paidAmount: paidAmount,
            dueDate: dueDate,
          )
        : 'Tunai';
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .75,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Detail transaksi',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(
                    isCredit
                        ? status == 'Lunas'
                              ? Icons.check_circle_outline_rounded
                              : status == 'Terlambat'
                              ? Icons.warning_amber_rounded
                              : Icons.schedule_rounded
                        : Icons.payments_outlined,
                    size: 18,
                  ),
                  label: Text(status),
                  backgroundColor: isCredit && remainingAmount > 0
                      ? colorScheme.tertiaryContainer
                      : colorScheme.secondaryContainer,
                ),
                const Divider(height: 24),
                _CustomerTransactionDetailRow(
                  label: 'Jenis transaksi',
                  value: type == 'income' ? 'Pemasukan' : 'Pengeluaran',
                ),
                _CustomerTransactionDetailRow(
                  label: 'Tanggal',
                  value: AppDateFormatter.long(date),
                ),
                _CustomerTransactionDetailRow(
                  label: 'Total',
                  value: CurrencyFormatter.format(amount),
                ),
                if (isCredit) ...[
                  _CustomerTransactionDetailRow(
                    label: 'Sudah dibayar',
                    value: CurrencyFormatter.format(paidAmount),
                  ),
                  _CustomerTransactionDetailRow(
                    label: 'Sisa pembayaran',
                    value: CurrencyFormatter.format(remainingAmount),
                  ),
                  if (dueDate != null)
                    _CustomerTransactionDetailRow(
                      label: 'Jatuh tempo',
                      value: AppDateFormatter.long(dueDate),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          sliver: SliverToBoxAdapter(
            child: AppPageHeader(
              title: 'Pelanggan',
              leading: context.canPop()
                  ? IconButton(
                      tooltip: 'Kembali ke transaksi',
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                    )
                  : null,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: customers.when(
                  loading: () =>
                      const AppLoadingState(message: 'Memuat pelanggan…'),
                  error: (error, stack) => ErrorState(
                    message: 'Data pelanggan belum dapat dimuat.',
                    onRetry: () => ref.invalidate(customersProvider),
                  ),
                  data: (items) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Cari nama atau nomor telepon',
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Hapus pencarian',
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _query = '';
                                  }),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _exportAllData,
                            icon: const Icon(Icons.ios_share_outlined),
                            label: const Text('Ekspor semua data'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _editCustomer(context, null),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Tambah pelanggan'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        EmptyState(
                          icon: Icons.people_outline,
                          title: 'Belum ada pelanggan',
                          message:
                              'Pelanggan dapat ditambahkan di sini atau langsung saat mencatat transaksi.',
                        )
                      else if (items.where((customer) {
                        final query = _query.trim().toLowerCase();
                        return query.isEmpty ||
                            customer.name.toLowerCase().contains(query) ||
                            (customer.phone?.toLowerCase().contains(query) ??
                                false);
                      }).isEmpty)
                        const EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'Pelanggan tidak ditemukan',
                          message:
                              'Coba kata kunci nama atau nomor telepon lain.',
                        )
                      else
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final customer in items.where((customer) {
                                final query = _query.trim().toLowerCase();
                                return query.isEmpty ||
                                    customer.name.toLowerCase().contains(
                                      query,
                                    ) ||
                                    (customer.phone?.toLowerCase().contains(
                                          query,
                                        ) ??
                                        false);
                              })) ...[
                                ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline),
                                  ),
                                  title: Text(customer.name),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        customer.phone ??
                                            'Nomor telepon belum diisi',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      FutureBuilder<int>(
                                        future: ref
                                            .read(customerRepositoryProvider)
                                            .transactionCount(customer),
                                        builder: (context, snapshot) => Text(
                                          snapshot.connectionState ==
                                                  ConnectionState.done
                                              ? '${snapshot.data ?? 0} transaksi'
                                              : 'Memuat riwayat…',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Edit pelanggan',
                                    onPressed: () =>
                                        _editCustomer(context, customer),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  onTap: () =>
                                      _showHistory(context, ref, customer),
                                ),
                                const Divider(height: 1),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _customerCreditStatus(
  String status, {
  required int amount,
  required int paidAmount,
  required DateTime? dueDate,
}) {
  final remaining = amount - paidAmount;
  if (remaining > 0 && dueDate != null) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (due.isBefore(today)) return 'Terlambat';
  }
  return switch (status) {
    'paid' => 'Lunas',
    'partial' => 'Dibayar sebagian',
    _ => 'Belum lunas',
  };
}

class _CustomerTransactionDetailRow extends StatelessWidget {
  const _CustomerTransactionDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}

class CustomerDraft {
  const CustomerDraft({required this.name, this.phone});
  final String name;
  final String? phone;
}

class _CustomerEditDialog extends StatefulWidget {
  const _CustomerEditDialog({this.customer});
  final Customer? customer;

  @override
  State<_CustomerEditDialog> createState() => _CustomerEditDialogState();
}

class _CustomerEditDialogState extends State<_CustomerEditDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.customer?.name ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.customer?.phone ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.customer == null ? 'Tambah pelanggan' : 'Edit pelanggan',
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Nama pelanggan'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Nomor telepon (opsional)',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _name.text.trim().isEmpty
            ? null
            : () => Navigator.pop(
                context,
                CustomerDraft(
                  name: _name.text.trim(),
                  phone: _phone.text.trim(),
                ),
              ),
        child: const Text('Simpan'),
      ),
    ],
  );
}
