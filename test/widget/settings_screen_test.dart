import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keuangan_usaha/app/theme/app_theme.dart';
import 'package:keuangan_usaha/core/constants/app_constants.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/database/database_provider.dart';
import 'package:keuangan_usaha/features/settings/presentation/settings_screen.dart';

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
        home: const Scaffold(body: SettingsScreen()),
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

  Future<void> setViewport(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  for (final width in <double>[320, 768, 1024, 1440]) {
    testWidgets(
      'pengaturan tampil tanpa overflow pada lebar ${width.toInt()}',
      (tester) async {
        await setViewport(tester, width);
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);

        await tester.pumpWidget(appWithDatabase(database));
        await pumpFrames(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('Pengaturan'), findsOneWidget);
        expect(find.text('Tampilan'), findsOneWidget);
        expect(find.text('Cadangan & pemulihan'), findsOneWidget);
        expect(find.text('Ekspor data'), findsOneWidget);
        expect(find.text('Tentang aplikasi'), findsOneWidget);
        expect(find.text('Zona berbahaya'), findsOneWidget);
        expect(find.text(AppConstants.appVersion), findsOneWidget);

        final preferences = tester.getTopLeft(find.text('Tampilan'));
        final backup = tester.getTopLeft(find.text('Cadangan & pemulihan'));
        if (width >= 1440) {
          expect(backup.dx, greaterThan(preferences.dx));
        } else {
          expect(backup.dy, greaterThan(preferences.dy));
        }

        await disposeTree(tester);
      },
    );
  }

  testWidgets('memilih tema dan menyimpan memperbarui pengaturan usaha', (
    tester,
  ) async {
    await setViewport(tester, 800);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await tester.pumpWidget(appWithDatabase(database));
    await pumpFrames(tester);

    await tester.tap(find.text('Gelap'));
    await tester.pump();

    final saveButton = find.widgetWithText(FilledButton, 'Simpan pengaturan');
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await pumpFrames(tester, count: 12);

    expect(find.text('Pengaturan berhasil disimpan.'), findsOneWidget);
    expect(
      (await database.businessSettingsDao.getSettings())?.themeMode,
      'dark',
    );
    await disposeTree(tester);
  });
}
