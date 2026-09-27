import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../data/transaction_export_service.dart';
import '../../products/presentation/providers/product_providers.dart';
import '../../customers/presentation/providers/customer_providers.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../domain/business_settings.dart';
import 'providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  AppThemePreference _theme = AppThemePreference.system;
  bool _initialized = false;
  bool _saving = false;
  bool _exporting = false;
  bool _backupBusy = false;

  void _initialize(BusinessProfile? profile) {
    if (_initialized) return;
    _initialized = true;
    _theme = profile?.theme ?? AppThemePreference.system;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final profile = ref.read(businessProfileProvider).value;
      await ref
          .read(settingsControllerProvider.notifier)
          .save(
            BusinessProfile(
              businessName: profile?.businessName ?? AppConstants.appName,
              ownerName: profile?.ownerName ?? '',
              theme: _theme,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan berhasil disimpan.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan belum berhasil disimpan.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _export() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final summary = await ref
          .read(transactionExportServiceProvider)
          .exportAndShare(sharePositionOrigin: _shareOrigin());
      if (!mounted) return;
      if (summary == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada data yang dapat diekspor.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File Excel siap: ${summary.transactions} transaksi, ${summary.saleItems} detail penjualan, ${summary.products} produk, ${summary.stockMovements} riwayat stok, ${summary.creditPayments} pembayaran kredit, ${summary.customers} pelanggan.',
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Gagal mengekspor data Excel: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ExportFailure ? error.message : 'Ekspor gagal: $error',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Rect? _shareOrigin() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _createBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final saved = await ref
          .read(backupRestoreServiceProvider)
          .saveBackupToDevice();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'Cadangan berhasil disimpan ke folder yang dipilih.'
                  : 'Penyimpanan cadangan dibatalkan.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cadangan belum berhasil dibuat: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _shareBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      await ref
          .read(backupRestoreServiceProvider)
          .exportBackup(origin: _shareOrigin());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File cadangan siap dibagikan.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cadangan belum berhasil dibuat: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _restoreBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final service = ref.read(backupRestoreServiceProvider);
      final preview = await service.pickBackupPreview();
      if (preview == null || !mounted) return;
      final confirmed = await _showDialogAndWaitForClose<bool>(
        builder: (context) => AlertDialog(
          title: const Text('Periksa cadangan'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal cadangan: ${preview.createdAt == null ? 'tidak tercatat' : AppDateFormatter.long(preview.createdAt!)}',
                  ),
                  const SizedBox(height: 12),
                  Text('${preview.totalRows} entri data di dalam file.'),
                  const SizedBox(height: 8),
                  for (final item in [
                    ('transactions', 'Transaksi'),
                    ('customers', 'Pelanggan'),
                    ('inventory_products', 'Produk'),
                    ('inventory_stock_movements', 'Riwayat stok'),
                    ('product_sale_items', 'Detail penjualan produk'),
                    ('credit_payments', 'Pembayaran kredit'),
                    ('business_settings', 'Pengaturan usaha'),
                  ])
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.$2),
                      trailing: Text('${preview.tables[item.$1]?.length ?? 0}'),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pemulihan menggabungkan data. Entri dengan ID yang sudah ada dilewati; data di perangkat tidak dihapus atau ditimpa.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Gabungkan data'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final count = await service.restoreBackup(preview);
      if (count == 0) return;
      ref.invalidate(customersProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(latestTransactionsProvider);
      ref.invalidate(creditsProvider);
      ref.invalidate(financeTotalsProvider);
      ref.invalidate(allTimeFinanceTotalsProvider);
      ref.invalidate(businessProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$count entri cadangan diproses. Entri yang sudah ada dilewati.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pemulihan belum berhasil: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _backupBusy = false);
    }
  }

  Future<void> _deleteAllData() async {
    final firstConfirmation = await _showDialogAndWaitForClose<bool>(
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Hapus seluruh data?'),
        content: const Text(
          'Semua transaksi, pelanggan, produk, riwayat stok, dan pengaturan usaha akan dihapus permanen dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (firstConfirmation != true || !mounted) return;

    final confirmed = await _showDialogAndWaitForClose<bool>(
      barrierDismissible: false,
      builder: (context) => const _DeleteConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(settingsControllerProvider.notifier).deleteAllData();
      if (!mounted) return;
      ref.invalidate(customersProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(latestTransactionsProvider);
      ref.invalidate(creditsProvider);
      ref.invalidate(financeTotalsProvider);
      ref.invalidate(allTimeFinanceTotalsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seluruh data berhasil dihapus.')),
      );
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data belum berhasil dihapus.')),
      );
    }
  }

  Future<T?> _showDialogAndWaitForClose<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    );
    final result = await navigator.push<T>(route);
    // Navigator.push completes on pop; wait until the reverse animation has
    // detached the dialog subtree before changing app data or navigation.
    await route.completed;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(businessProfileProvider);
    return profile.when(
      loading: () => const AppLoadingState(message: 'Memuat pengaturan…'),
      error: (error, stackTrace) => ErrorState(
        message: 'Pengaturan belum dapat dibuka.',
        onRetry: () => ref.invalidate(businessProfileProvider),
      ),
      data: (value) {
        _initialize(value);
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: AppPageHeader(title: 'Pengaturan'),
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
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Tampilan',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 14),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 400) {
                                      return DropdownButtonFormField<
                                        AppThemePreference
                                      >(
                                        initialValue: _theme,
                                        decoration: const InputDecoration(
                                          labelText: 'Pilih tema',
                                        ),
                                        items: [
                                          for (final theme
                                              in AppThemePreference.values)
                                            DropdownMenuItem(
                                              value: theme,
                                              child: Row(
                                                children: [
                                                  Icon(theme.icon, size: 20),
                                                  const SizedBox(width: 10),
                                                  Text(theme.label),
                                                ],
                                              ),
                                            ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _theme = value);
                                          }
                                        },
                                      );
                                    }
                                    return SegmentedButton<AppThemePreference>(
                                      showSelectedIcon: false,
                                      segments: [
                                        for (final theme
                                            in AppThemePreference.values)
                                          ButtonSegment(
                                            value: theme,
                                            icon: Icon(theme.icon),
                                            label: Text(theme.label),
                                          ),
                                      ],
                                      selected: {_theme},
                                      onSelectionChanged: (selection) {
                                        setState(
                                          () => _theme = selection.single,
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: _saving ? null : _save,
                                    icon: _saving
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.save_outlined),
                                    label: Text(
                                      _saving
                                          ? 'Menyimpan…'
                                          : 'Simpan pengaturan',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.save_alt_outlined),
                                title: const Text(
                                  'Simpan cadangan ke folder HP',
                                ),
                                trailing: _backupBusy
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: _backupBusy ? null : _createBackup,
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.share_outlined),
                                title: const Text('Bagikan file cadangan'),
                                trailing: _backupBusy
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: _backupBusy ? null : _shareBackup,
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.settings_backup_restore_outlined,
                                ),
                                title: const Text('Pulihkan dari cadangan'),
                                trailing: _backupBusy
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: _backupBusy ? null : _restoreBackup,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              ListTile(
                                minTileHeight: 64,
                                leading: const Icon(Icons.ios_share_outlined),
                                title: const Text('Ekspor semua data ke Excel'),
                                trailing: _exporting
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.chevron_right),
                                onTap: _exporting ? null : _export,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: ListTile(
                            minTileHeight: 64,
                            leading: Icon(
                              Icons.delete_forever_outlined,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Hapus seluruh data',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: _deleteAllData,
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
      },
    );
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  const _DeleteConfirmationDialog();

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _phraseController = TextEditingController();

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Konfirmasi terakhir'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ketik HAPUS untuk menghapus seluruh data.'),
        const SizedBox(height: 12),
        TextField(
          controller: _phraseController,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Ketik HAPUS'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: _phraseController.text == 'HAPUS'
            ? () => Navigator.of(context).pop(true)
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('Hapus seluruh data'),
      ),
    ],
  );
}
