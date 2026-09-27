import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keuangan_usaha/app/theme/app_theme.dart';
import 'package:keuangan_usaha/app/router/app_router.dart';
import 'package:keuangan_usaha/core/widgets/confirm_delete_dialog.dart';
import 'package:keuangan_usaha/core/widgets/responsive_navigation_scaffold.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/database/database_provider.dart';
import 'package:keuangan_usaha/features/dashboard/presentation/dashboard_screen.dart';
import 'package:keuangan_usaha/features/transactions/presentation/screens/transaction_form_screen.dart';
import 'package:keuangan_usaha/features/transactions/presentation/screens/transactions_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Widget appWithDatabase(AppDatabase database, Widget child) {
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    );
  }

  Future<void> pumpFrames(WidgetTester tester, {int count = 8}) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(Duration.zero);
  }

  Future<void> insertFixture(
    AppDatabase database, {
    required String id,
    required String type,
    required String name,
  }) {
    final timestamp = DateTime(2026, 7, 17, 9);
    return database.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        id: id,
        type: type,
        name: name,
        amount: 100000,
        transactionDate: timestamp,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  testWidgets('empty state beranda tampil pada database baru', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(appWithDatabase(database, const DashboardScreen()));
    await pumpFrames(tester);

    expect(find.text('Mulai catat keuangan usaha'), findsOneWidget);
    expect(find.text('Catat transaksi pertama'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('form validation menampilkan error dekat field', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final router = GoRouter(
      initialLocation: '/new',
      routes: [
        GoRoute(
          path: '/new',
          builder: (context, state) =>
              const Scaffold(body: TransactionFormScreen()),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await pumpFrames(tester);
    final saveButton = find.widgetWithText(FilledButton, 'Simpan');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Nama transaksi wajib diisi.'), findsOneWidget);
    expect(find.text('Nominal harus lebih besar dari Rp 0.'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('menambah transaksi menyimpan data nyata', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final router = GoRouter(
      initialLocation: '/new',
      routes: [
        GoRoute(
          path: '/new',
          builder: (context, state) =>
              const Scaffold(body: TransactionFormScreen()),
        ),
        GoRoute(
          path: '/transactions/:id',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Transaksi tersimpan'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await pumpFrames(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Penjualan test');
    await tester.enterText(fields.at(1), '125000');
    final saveButton = find.widgetWithText(FilledButton, 'Simpan');
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pump();
    await tester.tap(saveButton);
    await pumpFrames(tester);

    expect(find.text('Transaksi tersimpan'), findsOneWidget);
    final records = await database.transactionDao.getAllTransactions();
    expect(records, hasLength(1));
    expect(records.single.name, 'Penjualan test');
    expect(records.single.amount, 125000);
    await disposeTree(tester);
  });

  testWidgets('dialog konfirmasi hapus menjalankan aksi sekali', (
    tester,
  ) async {
    var deleteCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showConfirmDeleteDialog(
                  context,
                  transactionName: 'Belanja stok',
                  onDelete: () async {
                    deleteCalls++;
                  },
                ),
                child: const Text('Buka dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka dialog'));
    await pumpFrames(tester);
    expect(find.textContaining('Belanja stok'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await pumpFrames(tester);

    expect(deleteCalls, 1);
    expect(find.text('Hapus transaksi?'), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('filter transaksi hanya menampilkan pemasukan', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await insertFixture(
      database,
      id: 'income',
      type: 'income',
      name: 'Penjualan filter',
    );
    await insertFixture(
      database,
      id: 'expense',
      type: 'expense',
      name: 'Belanja filter',
    );

    await tester.pumpWidget(
      appWithDatabase(database, const TransactionsScreen()),
    );
    await pumpFrames(tester);
    expect(find.text('Penjualan filter'), findsOneWidget);
    expect(find.text('Belanja filter'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Pemasukan'));
    await pumpFrames(tester);

    expect(find.text('Penjualan filter'), findsOneWidget);
    expect(find.text('Belanja filter'), findsNothing);
    await disposeTree(tester);
  });

  testWidgets('layout transaksi sempit menangani nama dan nominal panjang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final timestamp = DateTime(2026, 7, 17, 9);
    await database.transactionDao.insertTransaction(
      TransactionsCompanion.insert(
        id: 'long-content',
        type: 'income',
        name:
            'Penjualan produk dengan nama yang sangat panjang untuk pelanggan utama',
        amount: 999999999999999,
        transactionDate: timestamp,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ResponsiveNavigationScaffold(
            location: '/transactions',
            child: TransactionsScreen(),
          ),
        ),
      ),
    );
    await pumpFrames(tester);

    expect(find.textContaining('Penjualan produk'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeTree(tester);
  });

  testWidgets('perpindahan tab mempertahankan pencarian transaksi', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    addTearDown(appRouter.dispose);
    await insertFixture(
      database,
      id: 'tab-cache',
      type: 'income',
      name: 'Transaksi untuk navigasi',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: appRouter,
        ),
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.byIcon(Icons.swap_vert_rounded));
    await pumpFrames(tester);
    final search = find.byType(TextField).first;
    await tester.enterText(search, 'filter tersimpan');
    await pumpFrames(tester);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await pumpFrames(tester);
    await tester.tap(find.byIcon(Icons.swap_vert_rounded));
    await pumpFrames(tester);

    expect(
      tester.widget<TextField>(search).controller?.text,
      'filter tersimpan',
    );
    await disposeTree(tester);
  });
}
