import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/app/theme/app_theme.dart';
import 'package:keuangan_usaha/core/widgets/finance_chart.dart';
import 'package:keuangan_usaha/features/transactions/domain/finance_summary.dart';

void main() {
  Widget harness(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, child: child)),
      ),
    );
  }

  testWidgets('grafik menampilkan empty state saat tidak ada data', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const FinanceChart(points: [])));

    expect(find.text('Belum ada data untuk grafik'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grafik menangani satu periode tanpa error', (tester) async {
    await tester.pumpWidget(
      harness(
        const FinanceChart(
          points: [
            CashFlowPoint(label: '2026-10', income: 100000, expense: 40000),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
  });

  testWidgets('grafik 12 bulan pada layar sempit tetap stabil', (tester) async {
    final points = [
      for (var month = 1; month <= 12; month++)
        CashFlowPoint(
          label: '2026-${month.toString().padLeft(2, '0')}',
          income: month * 100000,
          expense: month * 50000,
        ),
    ];

    await tester.pumpWidget(harness(FinanceChart(points: points)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
