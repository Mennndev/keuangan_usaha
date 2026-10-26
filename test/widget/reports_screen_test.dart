import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keuangan_usaha/app/theme/app_theme.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/database/database_provider.dart';
import 'package:keuangan_usaha/features/reports/presentation/reports_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<void> seedTransactions(AppDatabase database) async {
    final now = DateTime.now();
    await database.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        id: 'report-income',
        type: 'income',
        name:
            'Penjualan produk dengan nama yang sangat panjang untuk pelanggan utama',
        amount: 987654321,
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        id: 'report-expense',
        type: 'expense',
        name: 'Pembelian stok bulanan',
        amount: 456789012,
        transactionDate: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> pumpReports(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await seedTransactions(database);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: ReportsScreen()),
        ),
      ),
    );
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(Duration.zero);
  }

  for (final size in const [
    Size(320, 900),
    Size(768, 1000),
    Size(1024, 1000),
    Size(1440, 1000),
  ]) {
    testWidgets('laporan tanpa overflow pada lebar ${size.width.toInt()}px', (
      tester,
    ) async {
      await pumpReports(tester, size);

      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Periode laporan'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeTree(tester);
    });
  }
}
