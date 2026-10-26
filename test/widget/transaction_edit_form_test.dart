import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:keuangan_usaha/app/theme/app_theme.dart';
import 'package:keuangan_usaha/core/formatters/date_formatter.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/database/database_provider.dart';
import 'package:keuangan_usaha/features/transactions/domain/finance_transaction.dart';
import 'package:keuangan_usaha/features/transactions/presentation/screens/transaction_form_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('form edit terisi dari objek transaksi yang diberikan', (
    tester,
  ) async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final date = DateTime(2026, 6, 15);
    final transaction = FinanceTransaction(
      id: 't1',
      type: TransactionType.expense,
      name: 'Belanja lama',
      amount: 75000,
      category: 'Operasional',
      notes: 'Catatan lama',
      transactionDate: date,
      createdAt: date,
      updatedAt: date,
    );

    await tester.pumpWidget(
      ProviderScope(
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
          home: Scaffold(body: TransactionFormScreen(transaction: transaction)),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Edit transaksi'), findsOneWidget);
    expect(find.text('Belanja lama'), findsOneWidget);
    expect(find.text('Operasional'), findsOneWidget);
    expect(find.text('Catatan lama'), findsOneWidget);
    expect(find.text(AppDateFormatter.long(date)), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(Duration.zero);
  });
}
