import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../customers/presentation/providers/customer_providers.dart';
import '../../products/presentation/providers/product_providers.dart';
import '../../transactions/presentation/providers/transaction_providers.dart';
import '../data/transaction_export_service.dart';
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
    final compact = AppBreakpoints.of(context) == WindowSizeClass.compact;
    final gutter = compact ? AppSpacing.md : AppSpacing.lg;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.xl,
            gutter,
            AppSpacing.sm,
          ),
          sliver: const SliverToBoxAdapter(
            child: AppPageHeader(title: 'Pengaturan'),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.xs,
            gutter,
            AppSpacing.xxl + MediaQuery.viewInsetsOf(context).bottom,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: profile.when(
                  loading: () => const SizedBox(
                    height: 260,
                    child: AppLoadingState(message: 'Memuat pengaturan…'),
                  ),
                  error: (error, stackTrace) => ErrorState(
                    message: 'Pengaturan belum dapat dibuka.',
                    onRetry: () => ref.invalidate(businessProfileProvider),
                  ),
                  data: (value) {
                    _initialize(value);
                    return _SettingsContent(
                      theme: _theme,
                      saving: _saving,
                      exporting: _exporting,
                      backupBusy: _backupBusy,
                      onThemeChanged: (theme) => setState(() => _theme = theme),
                      onSave: _save,
                      onCreateBackup: _createBackup,
                      onShareBackup: _shareBackup,
                      onRestoreBackup: _restoreBackup,
                      onExport: _export,
                      onDeleteAll: _deleteAllData,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.theme,
    required this.saving,
    required this.exporting,
    required this.backupBusy,
    required this.onThemeChanged,
    required this.onSave,
    required this.onCreateBackup,
    required this.onShareBackup,
    required this.onRestoreBackup,
    required this.onExport,
    required this.onDeleteAll,
  });

  final AppThemePreference theme;
  final bool saving;
  final bool exporting;
  final bool backupBusy;
  final ValueChanged<AppThemePreference> onThemeChanged;
  final VoidCallback onSave;
  final VoidCallback onCreateBackup;
  final VoidCallback onShareBackup;
  final VoidCallback onRestoreBackup;
  final VoidCallback onExport;
  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded =
            AppBreakpoints.ofWidth(constraints.maxWidth) ==
            WindowSizeClass.expanded;
        final preferences = _PreferencesCard(
          theme: theme,
          saving: saving,
          onThemeChanged: onThemeChanged,
          onSave: onSave,
        );
        final backup = _BackupCard(
          busy: backupBusy,
          onCreateBackup: onCreateBackup,
          onShareBackup: onShareBackup,
          onRestoreBackup: onRestoreBackup,
        );
        final export = _ExportCard(exporting: exporting, onExport: onExport);
        const about = _AboutCard();
        final danger = _DangerZoneCard(onDeleteAll: onDeleteAll);
        const gap = SizedBox(height: AppSpacing.md);

        if (!expanded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              preferences,
              gap,
              backup,
              gap,
              export,
              gap,
              about,
              gap,
              danger,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [preferences, gap, about],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [backup, gap, export, gap, danger],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    this.tone,
    this.surface,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final Color? tone;
  final Color? surface;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = tone ?? colors.info;
    final accentSurface = surface ?? colors.infoSurface;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                    color: accentSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.theme,
    required this.saving,
    required this.onThemeChanged,
    required this.onSave,
  });

  final AppThemePreference theme;
  final bool saving;
  final ValueChanged<AppThemePreference> onThemeChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeData = Theme.of(context);
    return _SettingsCard(
      icon: Icons.palette_outlined,
      title: 'Tampilan',
      description: 'Pilih tema yang paling nyaman untuk mata Anda.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 420 ? 1 : 3;
              const gap = AppSpacing.xs;
              final width =
                  (constraints.maxWidth - (columns - 1) * gap) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final option in AppThemePreference.values)
                    SizedBox(
                      width: width,
                      child: _ThemeOption(
                        option: option,
                        selected: option == theme,
                        onSelected: () => onThemeChanged(option),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final hint = Text(
                'Perubahan tema diterapkan setelah disimpan.',
                style: themeData.textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              );
              final button = FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Menyimpan…' : 'Simpan pengaturan'),
              );
              if (constraints.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hint,
                    const SizedBox(height: AppSpacing.sm),
                    button,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: hint),
                  const SizedBox(width: AppSpacing.md),
                  button,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final AppThemePreference option;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema ${option.label}',
      child: Material(
        color: selected ? colors.infoSurface : colors.canvas,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onSelected,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? colors.info.withValues(alpha: .45)
                    : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 20,
                  color: selected ? colors.info : colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? colors.info : colors.textPrimary,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colors.info,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.busy,
    required this.onCreateBackup,
    required this.onShareBackup,
    required this.onRestoreBackup,
  });

  final bool busy;
  final VoidCallback onCreateBackup;
  final VoidCallback onShareBackup;
  final VoidCallback onRestoreBackup;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _SettingsCard(
      icon: Icons.cloud_sync_outlined,
      title: 'Cadangan & pemulihan',
      description:
          'Simpan salinan database, bagikan, atau pulihkan data dari file cadangan.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (busy) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(minHeight: 3),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          _SettingsActionTile(
            icon: Icons.save_alt_rounded,
            title: 'Simpan cadangan ke folder HP',
            description: 'Menyimpan salinan database ke penyimpanan perangkat.',
            onTap: busy ? null : onCreateBackup,
          ),
          _SettingsDivider(color: colors.border),
          _SettingsActionTile(
            icon: Icons.ios_share_rounded,
            title: 'Bagikan file cadangan',
            description: 'Kirim file cadangan melalui aplikasi lain.',
            onTap: busy ? null : onShareBackup,
          ),
          _SettingsDivider(color: colors.border),
          _SettingsActionTile(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Pulihkan dari cadangan',
            description:
                'Menggabungkan data dari file cadangan tanpa menghapus data saat ini.',
            onTap: busy ? null : onRestoreBackup,
          ),
        ],
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({required this.exporting, required this.onExport});

  final bool exporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.table_view_outlined,
      title: 'Ekspor data',
      description: 'Bagikan seluruh data usaha dalam satu file Excel.',
      child: _SettingsActionTile(
        icon: Icons.file_download_outlined,
        title: 'Ekspor semua data ke Excel',
        description:
            'Berisi transaksi, produk, stok, pembayaran kredit, dan pelanggan.',
        onTap: exporting ? null : onExport,
        trailing: exporting
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _SettingsCard(
      icon: Icons.info_outline_rounded,
      title: 'Tentang aplikasi',
      description: 'Informasi versi dan cara penyimpanan data.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InfoRow(label: 'Aplikasi', value: AppConstants.appName),
          _SettingsDivider(color: colors.border, indent: 0),
          const _InfoRow(label: 'Versi', value: AppConstants.appVersion),
          _SettingsDivider(color: colors.border, indent: 0),
          const _InfoRow(
            label: 'Mata uang',
            value: '${AppConstants.currencyCode} · Rupiah',
          ),
          _SettingsDivider(color: colors.border, indent: 0),
          const _InfoRow(label: 'Penyimpanan', value: 'Offline di perangkat'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.infoSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.info.withValues(alpha: .18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 18, color: colors.info),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Semua data tersimpan di perangkat ini dan tidak dikirim ke server.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
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

class _DangerZoneCard extends StatelessWidget {
  const _DangerZoneCard({required this.onDeleteAll});

  final VoidCallback onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _SettingsCard(
      icon: Icons.warning_amber_rounded,
      title: 'Zona berbahaya',
      description: 'Tindakan di bawah ini tidak dapat dibatalkan.',
      tone: colors.expense,
      surface: colors.expenseSurface,
      child: _SettingsActionTile(
        icon: Icons.delete_forever_outlined,
        title: 'Hapus seluruh data',
        description:
            'Menghapus semua transaksi, produk, pelanggan, riwayat stok, dan pengaturan usaha.',
        onTap: onDeleteAll,
        tone: colors.expense,
        surface: colors.expenseSurface,
        titleColor: colors.expense,
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.tone,
    this.surface,
    this.titleColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Color? tone;
  final Color? surface;
  final Color? titleColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final enabled = onTap != null;
    final accent = tone ?? colors.info;
    final accentSurface = surface ?? colors.infoSurface;
    return ListTile(
      enabled: enabled,
      onTap: onTap,
      minTileHeight: 72,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? accentSurface : colors.canvas,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? accent : colors.textSecondary,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: enabled
              ? (titleColor ?? colors.textPrimary)
              : colors.textSecondary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: enabled ? colors.textSecondary : colors.border,
          ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.color, this.indent = 56});

  final Color color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: indent, color: color);
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
