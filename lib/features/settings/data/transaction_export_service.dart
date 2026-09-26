import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/formatters/date_formatter.dart';
import '../../../database/app_database.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/finance_transaction.dart';

class ExportSummary {
  const ExportSummary({
    required this.transactions,
    required this.saleItems,
    required this.products,
    required this.stockMovements,
    required this.creditPayments,
  });

  final int transactions;
  final int saleItems;
  final int products;
  final int stockMovements;
  final int creditPayments;

  int get totalRows =>
      transactions + saleItems + products + stockMovements + creditPayments;
}

class ExportFailure implements Exception {
  const ExportFailure(this.stage, this.cause);

  final String stage;
  final Object cause;

  String get message => 'Gagal saat $stage. Detail: $cause';

  @override
  String toString() => message;
}

class TransactionExportService {
  TransactionExportService(this._repository, this._database);

  final TransactionRepository _repository;
  final AppDatabase _database;

  Future<ExportSummary?> exportAndShare({Rect? sharePositionOrigin}) async {
    var stage = 'membaca data transaksi';
    try {
      final transactions = await _repository.getAll();
      final transactionsById = {
        for (final transaction in transactions) transaction.id: transaction,
      };
      stage = 'menyiapkan data penjualan';
      await _database.ensureProductSaleItems();
      stage = 'membaca data produk';
      final products = await _database.productDao.getProducts();
      stage = 'membaca detail penjualan';
      final saleRows = await _database.customSelect(
        '''SELECT ps.transaction_id, ps.product_id,
             ps.product_name_snapshot, ps.brand_snapshot, ps.quantity,
             ps.unit_price
             FROM product_sale_items ps
             JOIN transactions t ON t.id = ps.transaction_id
             ORDER BY t.transaction_date, ps.rowid''',
      ).get();
      stage = 'membaca riwayat stok';
      final movementRows = await _database.customSelect(
        '''SELECT id, product_id, product_name_snapshot, brand_snapshot,
             quantity_change, reason, movement_date, notes, transaction_id
             FROM inventory_stock_movements ORDER BY movement_date, created_at''',
      ).get();
      stage = 'membaca pembayaran kredit';
      final payments = await (_database.select(
        _database.creditPayments,
      )..orderBy([(payment) => OrderingTerm.asc(payment.paymentDate)])).get();

      final summary = ExportSummary(
        transactions: transactions.length,
        saleItems: saleRows.length,
        products: products.length,
        stockMovements: movementRows.length,
        creditPayments: payments.length,
      );
      if (summary.totalRows == 0) return null;

      final creditById = {
        for (final transaction in transactions)
          if (transaction.isCredit) transaction.id: transaction,
      };
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final temporary = await getTemporaryDirectory();
      final files = <XFile>[];

      if (transactions.isNotEmpty) {
        stage = 'membuat file transaksi CSV';
        files.add(
          await _writeCsv(
            temporary,
            'transaksi-keuangan-$timestamp.csv',
            [
              'ID transaksi',
              'Jenis',
              'Nama transaksi',
              'Nominal (IDR)',
              'Kategori',
              'Keterangan',
              'Tanggal transaksi',
              'Penjualan kredit',
              'Nama pelanggan',
              'Jatuh tempo',
              'Sudah dibayar (IDR)',
              'Sisa kredit (IDR)',
              'Status kredit',
              'Dibuat',
              'Diperbarui',
            ],
            [
              for (final transaction in transactions)
                [
                  transaction.id,
                  transaction.type.label,
                  _safeText(transaction.name),
                  transaction.amount,
                  _safeText(transaction.category ?? ''),
                  _safeText(transaction.notes ?? ''),
                  _date(transaction.transactionDate),
                  transaction.isCredit ? 'Ya' : 'Tidak',
                  _safeText(transaction.creditCustomerName ?? ''),
                  transaction.creditDueDate == null
                      ? ''
                      : _date(transaction.creditDueDate!),
                  transaction.isCredit ? transaction.creditPaidAmount : '',
                  transaction.isCredit ? transaction.creditRemainingAmount : '',
                  transaction.isCredit ? transaction.creditStatus.label : '',
                  transaction.createdAt.toIso8601String(),
                  transaction.updatedAt.toIso8601String(),
                ],
            ],
          ),
        );
      }

      if (saleRows.isNotEmpty) {
        stage = 'membuat file detail penjualan CSV';
        files.add(
          await _writeCsv(
            temporary,
            'detail-penjualan-$timestamp.csv',
            [
              'ID transaksi',
              'Nama transaksi',
              'Tanggal transaksi',
              'ID produk',
              'Nama produk',
              'Brand',
              'Jumlah',
              'Harga satuan (IDR)',
              'Total baris (IDR)',
            ],
            [for (final row in saleRows) _saleExportRow(row, transactionsById)],
          ),
        );
      }

      if (products.isNotEmpty) {
        stage = 'membuat file produk dan stok CSV';
        files.add(
          await _writeCsv(
            temporary,
            'produk-dan-stok-$timestamp.csv',
            [
              'ID produk',
              'Brand',
              'Nama produk',
              'Harga jual (IDR)',
              'Stok saat ini',
              'Dibuat',
              'Diperbarui',
            ],
            [
              for (final product in products)
                [
                  product.id,
                  _safeText(product.brand),
                  _safeText(product.name),
                  product.sellingPrice,
                  product.stockQuantity,
                  product.createdAt.toIso8601String(),
                  product.updatedAt.toIso8601String(),
                ],
            ],
          ),
        );
      }

      if (movementRows.isNotEmpty) {
        stage = 'membuat file riwayat stok CSV';
        files.add(
          await _writeCsv(
            temporary,
            'riwayat-stok-$timestamp.csv',
            [
              'ID riwayat',
              'ID produk',
              'Nama produk',
              'Brand',
              'Perubahan stok',
              'Jenis perubahan',
              'Tanggal',
              'Keterangan',
              'ID transaksi terkait',
            ],
            [
              for (final row in movementRows)
                [
                  row.read<String>('id'),
                  row.readNullable<String>('product_id') ?? '',
                  _safeText(row.read<String>('product_name_snapshot')),
                  _safeText(row.read<String>('brand_snapshot')),
                  row.read<int>('quantity_change'),
                  _movementLabel(row.read<String>('reason')),
                  row.read<String>('movement_date'),
                  _safeText(row.readNullable<String>('notes') ?? ''),
                  row.readNullable<String>('transaction_id') ?? '',
                ],
            ],
          ),
        );
      }

      if (payments.isNotEmpty) {
        stage = 'membuat file pembayaran kredit CSV';
        files.add(
          await _writeCsv(
            temporary,
            'pembayaran-kredit-$timestamp.csv',
            [
              'ID pembayaran',
              'ID transaksi kredit',
              'Nama pelanggan',
              'Nama transaksi',
              'Nominal pembayaran (IDR)',
              'Tanggal pembayaran',
              'Keterangan',
            ],
            [
              for (final payment in payments)
                [
                  payment.id,
                  payment.transactionId,
                  _safeText(
                    creditById[payment.transactionId]?.creditCustomerName ?? '',
                  ),
                  _safeText(creditById[payment.transactionId]?.name ?? ''),
                  payment.paymentAmount,
                  _date(payment.paymentDate),
                  _safeText(payment.notes ?? ''),
                ],
            ],
          ),
        );
      }

      stage = 'membagikan file ke aplikasi lain';
      await SharePlus.instance.share(
        ShareParams(
          title: 'Ekspor data Keuangan Usaha',
          text:
              'File CSV berisi transaksi, detail penjualan, produk dan stok, riwayat stok, serta pembayaran kredit yang tersedia.',
          files: files,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      return summary;
    } catch (error, stackTrace) {
      if (error is ExportFailure) rethrow;
      Error.throwWithStackTrace(ExportFailure(stage, error), stackTrace);
    }
  }

  Future<XFile> _writeCsv(
    Directory directory,
    String filename,
    List<String> headers,
    List<List<Object?>> data,
  ) async {
    // The Excel codec already includes a UTF-8 BOM and Indonesian-friendly
    // delimiter, so don't prepend a second BOM here.
    final contents = excel.encode([headers, ...data]);
    final file = File(path.join(directory.path, filename));
    await file.writeAsBytes(utf8.encode(contents), flush: true);
    return XFile(file.path, mimeType: 'text/csv');
  }

  List<Object?> _saleExportRow(
    QueryRow row,
    Map<String, FinanceTransaction> transactionsById,
  ) {
    final transactionId = row.read<String>('transaction_id');
    final transaction = transactionsById[transactionId];
    return [
      transactionId,
      _safeText(transaction?.name ?? ''),
      transaction == null ? '' : _date(transaction.transactionDate),
      row.read<String>('product_id'),
      _safeText(row.read<String>('product_name_snapshot')),
      _safeText(row.read<String>('brand_snapshot')),
      row.read<int>('quantity'),
      row.read<int>('unit_price'),
      row.read<int>('quantity') * row.read<int>('unit_price'),
    ];
  }

  String _date(DateTime value) => AppDateFormatter.long(value);

  String _safeText(String value) {
    final trimmed = value.trimLeft();
    if (trimmed.startsWith(RegExp(r'[=+\-@\t\r]'))) return "'$value";
    return value;
  }

  String _movementLabel(String value) => switch (value) {
    'restock' => 'Stok masuk',
    'sale' => 'Penjualan',
    'adjustment' => 'Penyesuaian',
    _ => value,
  };
}
