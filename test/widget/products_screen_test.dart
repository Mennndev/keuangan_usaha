import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keuangan_usaha/app/theme/app_theme.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/database/database_provider.dart';
import 'package:keuangan_usaha/features/products/presentation/products_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Widget appWithDatabase(AppDatabase database) {
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
        home: const Scaffold(body: ProductsScreen()),
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

  Future<void> insertProduct(
    AppDatabase database, {
    required String id,
    required String brand,
    required String name,
  }) {
    return database.productDao.insertProduct(
      id: id,
      brand: brand,
      name: name,
      sellingPrice: 10000,
    );
  }

  testWidgets('empty state produk tampil pada database kosong', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(appWithDatabase(database));
    await pumpFrames(tester);

    expect(find.text('Belum ada produk'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tambah produk'), findsWidgets);
    await disposeTree(tester);
  });

  testWidgets('pencarian menyaring produk dan dapat direset', (tester) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await insertProduct(
      database,
      id: 'p1',
      brand: 'Vanestrix',
      name: 'Produk Alpha',
    );
    await insertProduct(
      database,
      id: 'p2',
      brand: 'Dioses',
      name: 'Produk Beta',
    );

    await tester.pumpWidget(appWithDatabase(database));
    await pumpFrames(tester);

    expect(find.text('Produk Alpha'), findsOneWidget);
    expect(find.text('Produk Beta'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Alpha');
    await tester.pump();

    expect(find.text('Produk Alpha'), findsOneWidget);
    expect(find.text('Produk Beta'), findsNothing);
    expect(find.text('Pencarian “Alpha”'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tidak-ada');
    await tester.pump();

    expect(find.text('Produk tidak ditemukan'), findsOneWidget);

    final resetButton = find.widgetWithText(OutlinedButton, 'Reset filter');
    await tester.ensureVisible(resetButton);
    await tester.pump();
    await tester.tap(resetButton);
    await tester.pump();

    expect(find.text('Produk Alpha'), findsOneWidget);
    expect(find.text('Produk Beta'), findsOneWidget);
    expect(find.text('Kelola harga dan stok seluruh produk'), findsOneWidget);
    await disposeTree(tester);
  });

  testWidgets('layout sempit menampilkan produk tanpa overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await insertProduct(
      database,
      id: 'p1',
      brand: 'Vanestrix',
      name: 'Produk dengan nama cukup panjang untuk menguji tata letak',
    );

    await tester.pumpWidget(appWithDatabase(database));
    await pumpFrames(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Daftar produk'), findsOneWidget);
    expect(
      find.text('Produk dengan nama cukup panjang untuk menguji tata letak'),
      findsOneWidget,
    );
    await disposeTree(tester);
  });

  testWidgets('aksi Edit stok menyimpan jumlah stok akhir', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await insertProduct(
      database,
      id: 'p1',
      brand: 'Vanestrix',
      name: 'Produk Alpha',
    );

    await tester.pumpWidget(appWithDatabase(database));
    await pumpFrames(tester);

    final editStock = find.byTooltip('Edit stok');
    await tester.ensureVisible(editStock);
    await tester.tap(editStock);
    await pumpFrames(tester);

    expect(find.text('Edit stok · Produk Alpha'), findsOneWidget);
    expect(find.text('Stok saat ini: 0 unit'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '25');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await pumpFrames(tester, count: 12);

    expect(find.text('Stok 25'), findsOneWidget);
    expect((await database.productDao.findProduct('p1'))?.stockQuantity, 25);
    expect(
      find.text('Stok Produk Alpha diperbarui menjadi 25 unit.'),
      findsOneWidget,
    );
    await disposeTree(tester);
  });

  testWidgets('dialog Edit stok menolak input kosong', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await insertProduct(
      database,
      id: 'p1',
      brand: 'Vanestrix',
      name: 'Produk Alpha',
    );

    await tester.pumpWidget(appWithDatabase(database));
    await pumpFrames(tester);

    final editStock = find.byTooltip('Edit stok');
    await tester.ensureVisible(editStock);
    await tester.tap(editStock);
    await pumpFrames(tester);

    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pump();

    expect(find.text('Stok wajib diisi.'), findsOneWidget);
    expect((await database.productDao.findProduct('p1'))?.stockQuantity, 0);
    await tester.tap(find.widgetWithText(TextButton, 'Batal'));
    await pumpFrames(tester);
    await disposeTree(tester);
  });
}
