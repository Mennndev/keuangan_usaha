import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/finance_transaction.dart';

class TransactionExportService {
  TransactionExportService(this._repository);

  final TransactionRepository _repository;

  Future<bool> exportAndShare({Rect? sharePositionOrigin}) async {
    final transactions = await _repository.getAll();
    if (transactions.isEmpty) return false;
    final rows = <List<Object?>>[
      [
        'ID',
        'Jenis',
        'Nama',
        'Nominal (IDR)',
        'Kategori',
        'Keterangan',
        'Tanggal',
        'Dibuat',
        'Diperbarui',
      ],
      for (final transaction in transactions)
        [
          transaction.id,
          transaction.type.label,
          transaction.name,
          transaction.amount,
          transaction.category ?? '',
          transaction.notes ?? '',
          AppDateFormatter.long(transaction.transactionDate),
          transaction.createdAt.toIso8601String(),
          transaction.updatedAt.toIso8601String(),
        ],
    ];
    final contents = excel.encode(rows);
    final temporary = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(
      path.join(temporary.path, 'transaksi-keuangan-$timestamp.csv'),
    );
    await file.writeAsBytes(utf8.encode('\ufeff$contents'), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Ekspor transaksi Keuangan Usaha',
        text: 'Data transaksi dari aplikasi Keuangan Usaha.',
        files: [XFile(file.path, mimeType: 'text/csv')],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return true;
  }
}
