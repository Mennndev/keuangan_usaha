import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database_provider.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../data/settings_repository.dart';
import '../../data/transaction_export_service.dart';
import '../../data/backup_restore_service.dart';
import '../../domain/business_settings.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final businessProfileProvider = StreamProvider<BusinessProfile?>((ref) {
  return ref.watch(settingsRepositoryProvider).watchProfile();
});

final transactionExportServiceProvider = Provider<TransactionExportService>((
  ref,
) {
  return TransactionExportService(
    ref.watch(transactionRepositoryProvider),
    ref.watch(databaseProvider),
  );
});

final backupRestoreServiceProvider = Provider<BackupRestoreService>(
  (ref) => BackupRestoreService(ref.watch(databaseProvider)),
);

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, void>(SettingsController.new);

class SettingsController extends AsyncNotifier<void> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<void> save(BusinessProfile profile) async {
    _guardDoubleSubmit();
    state = const AsyncLoading();
    try {
      await _repository.saveProfile(profile);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAllData() async {
    _guardDoubleSubmit();
    state = const AsyncLoading();
    try {
      await _repository.deleteAllData();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void _guardDoubleSubmit() {
    if (state.isLoading) throw StateError('Permintaan sedang diproses.');
  }
}
