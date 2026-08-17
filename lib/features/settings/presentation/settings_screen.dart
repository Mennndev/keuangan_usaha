import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_state.dart';
import '../domain/business_settings.dart';
import 'providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _businessController = TextEditingController();
  final _ownerController = TextEditingController();
  AppThemePreference _theme = AppThemePreference.system;
  bool _initialized = false;
  bool _saving = false;
  bool _exporting = false;

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  void _initialize(BusinessProfile? profile) {
    if (_initialized) return;
    _initialized = true;
    _businessController.text = profile?.businessName ?? AppConstants.appName;
    _ownerController.text = profile?.ownerName ?? '';
    _theme = profile?.theme ?? AppThemePreference.system;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .save(
            BusinessProfile(
              businessName: _businessController.text,
              ownerName: _ownerController.text,
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
      final hasData = await ref
          .read(transactionExportServiceProvider)
          .exportAndShare(sharePositionOrigin: _shareOrigin());
      if (!mounted) return;
      if (!hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Belum ada transaksi yang dapat diekspor.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ekspor belum berhasil. Coba lagi.')),
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

  Future<void> _deleteAllData() async {
    final firstConfirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Hapus seluruh data?'),
        content: const Text(
          'Semua transaksi dan pengaturan usaha akan dihapus permanen dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
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

    final phraseController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Konfirmasi terakhir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ketik HAPUS untuk menghapus seluruh data.'),
              const SizedBox(height: 12),
              TextField(
                controller: phraseController,
                autofocus: true,
                onChanged: (_) => setDialogState(() {}),
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
              onPressed: phraseController.text == 'HAPUS'
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Hapus seluruh data'),
            ),
          ],
        ),
      ),
    );
    phraseController.dispose();
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(settingsControllerProvider.notifier).deleteAllData();
      if (!mounted) return;
      _initialized = false;
      _initialize(null);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seluruh data berhasil dihapus.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data belum berhasil dihapus.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(businessProfileProvider);
    return profile.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat pengaturan…'),
          ],
        ),
      ),
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
                child: AppPageHeader(
                  title: 'Pengaturan',
                  subtitle: 'Kelola profil, tampilan, dan data aplikasi',
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
                                  'Profil usaha',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _businessController,
                                  label: 'Nama usaha',
                                  hint: AppConstants.appName,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 14),
                                AppTextField(
                                  controller: _ownerController,
                                  label: 'Nama pemilik (opsional)',
                                  textInputAction: TextInputAction.done,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Tema',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<AppThemePreference>(
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
                                    setState(() => _theme = selection.single);
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
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              ListTile(
                                minTileHeight: 64,
                                leading: const Icon(Icons.ios_share_outlined),
                                title: const Text('Ekspor transaksi ke CSV'),
                                subtitle: const Text(
                                  'Bagikan salinan data transaksi nyata dari database.',
                                ),
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
                              const Divider(height: 1),
                              ListTile(
                                minTileHeight: 64,
                                leading: const Icon(Icons.info_outline),
                                title: const Text('Informasi aplikasi'),
                                subtitle: const Text(
                                  'Versi dan lisensi aplikasi.',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => showAboutDialog(
                                  context: context,
                                  applicationName: AppConstants.appName,
                                  applicationVersion: '1.0.0',
                                  applicationIcon: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 40,
                                  ),
                                  children: const [
                                    Text(
                                      'Aplikasi pencatatan pemasukan dan pengeluaran usaha yang bekerja secara offline.',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: ListTile(
                            minTileHeight: 72,
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
                            subtitle: const Text(
                              'Menghapus semua transaksi dan profil usaha secara permanen.',
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
