import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/currency_formatter.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import 'providers/customer_providers.dart';
import '../domain/customer.dart';
import '../data/customer_export_service.dart';

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
        if (context.mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pelanggan belum tersimpan: $error')),
          );
      }
    }
  }

  Future<void> _exportCustomers(List<Customer> customers) async {
    try {
      final box = context.findRenderObject();
      final origin = box is RenderBox && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await CustomerExportService().exportAndShare(
        customers,
        sharePositionOrigin: origin,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ekspor pelanggan belum berhasil: $error')),
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
                          return ListTile(
                            title: Text(row.read<String>('name')),
                            subtitle: Text(
                              '${AppDateFormatter.long(date)}${row.read<bool>('is_credit') ? ' · Kredit' : ''}',
                            ),
                            trailing: Text(
                              '${type == 'income' ? '+' : '-'}${CurrencyFormatter.format(row.read<int>('amount'))}',
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
              subtitle: 'Daftar pelanggan dan riwayat transaksi mereka',
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
                            onPressed: items.isEmpty
                                ? null
                                : () => _exportCustomers(items),
                            icon: const Icon(Icons.ios_share_outlined),
                            label: const Text('Ekspor pelanggan'),
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
