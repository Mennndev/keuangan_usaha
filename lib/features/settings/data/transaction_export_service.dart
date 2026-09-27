import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:excel/excel.dart';
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
    required this.customers,
  });

  final int transactions;
  final int saleItems;
  final int products;
  final int stockMovements;
  final int creditPayments;
  final int customers;

  int get totalRows =>
      transactions +
      saleItems +
      products +
      stockMovements +
      creditPayments +
      customers;
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
        '''SELECT product_name_snapshot, brand_snapshot, quantity_change,
             reason, movement_date, notes, transaction_id
             FROM inventory_stock_movements ORDER BY movement_date, created_at''',
      ).get();
      stage = 'membaca pembayaran kredit';
      final payments = await (_database.select(
        _database.creditPayments,
      )..orderBy([(payment) => OrderingTerm.asc(payment.paymentDate)])).get();
      stage = 'membaca data pelanggan';
      await _database.ensureCustomersTable();
      final customers = await _database
          .customSelect(
            'SELECT name, phone, notes FROM customers ORDER BY name COLLATE NOCASE',
          )
          .get();

      final summary = ExportSummary(
        transactions: transactions.length,
        saleItems: saleRows.length,
        products: products.length,
        stockMovements: movementRows.length,
        creditPayments: payments.length,
        customers: customers.length,
      );
      if (summary.totalRows == 0) return null;

      final creditById = {
        for (final transaction in transactions)
          if (transaction.isCredit) transaction.id: transaction,
      };
      stage = 'menyusun sheet Excel';
      final workbook = Excel.createExcel();
      workbook.rename('Sheet1', 'Transaksi');
      workbook.setDefaultSheet('Transaksi');

      _writeSheet(
        workbook,
        'Transaksi',
        [
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
              _dateTime(transaction.createdAt),
              _dateTime(transaction.updatedAt),
            ],
        ],
      );

      _writeSheet(
        workbook,
        'Detail Penjualan',
        [
          'Nama transaksi',
          'Tanggal transaksi',
          'Nama produk',
          'Brand',
          'Jumlah',
          'Harga satuan (IDR)',
          'Total baris (IDR)',
        ],
        [for (final row in saleRows) _saleExportRow(row, transactionsById)],
      );

      _writeSheet(
        workbook,
        'Produk dan Stok',
        [
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
              _safeText(product.brand),
              _safeText(product.name),
              product.sellingPrice,
              product.stockQuantity,
              _dateTime(product.createdAt),
              _dateTime(product.updatedAt),
            ],
        ],
      );

      _writeSheet(
        workbook,
        'Riwayat Stok',
        [
          'Nama produk',
          'Brand',
          'Perubahan stok',
          'Jenis perubahan',
          'Tanggal',
          'Keterangan',
          'Nama transaksi terkait',
        ],
        [
          for (final row in movementRows)
            [
              _safeText(row.read<String>('product_name_snapshot')),
              _safeText(row.read<String>('brand_snapshot')),
              row.read<int>('quantity_change'),
              _movementLabel(row.read<String>('reason')),
              _storedDate(row.read<String>('movement_date')),
              _safeText(row.readNullable<String>('notes') ?? ''),
              _safeText(
                transactionsById[row.readNullable<String>('transaction_id') ??
                            '']
                        ?.name ??
                    '',
              ),
            ],
        ],
      );

      _writeSheet(
        workbook,
        'Pembayaran Kredit',
        [
          'Nama pelanggan',
          'Nama transaksi',
          'Nominal pembayaran (IDR)',
          'Tanggal pembayaran',
          'Keterangan',
        ],
        [
          for (final payment in payments)
            [
              _safeText(
                creditById[payment.transactionId]?.creditCustomerName ?? '',
              ),
              _safeText(creditById[payment.transactionId]?.name ?? ''),
              payment.paymentAmount,
              _date(payment.paymentDate),
              _safeText(payment.notes ?? ''),
            ],
        ],
      );

      _writeSheet(
        workbook,
        'Pelanggan',
        ['Nama pelanggan', 'Nomor telepon', 'Catatan'],
        [
          for (final customer in customers)
            [
              _safeText(customer.read<String>('name')),
              _safeText(customer.readNullable<String>('phone') ?? ''),
              _safeText(customer.readNullable<String>('notes') ?? ''),
            ],
        ],
      );

      stage = 'menyimpan file Excel';
      final bytes = workbook.save();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Workbook Excel tidak dapat dibuat.');
      }
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final temporary = await getTemporaryDirectory();
      final file = File(
        path.join(temporary.path, 'data-keuangan-usaha-$timestamp.xlsx'),
      );
      await file.writeAsBytes(bytes, flush: true);

      stage = 'membagikan file Excel';
      await SharePlus.instance.share(
        ShareParams(
          title: 'Ekspor data Keuangan Usaha',
          text:
              'Satu file Excel berisi transaksi, detail penjualan, produk dan stok, riwayat stok, pembayaran kredit, serta pelanggan pada sheet terpisah.',
          files: [
            XFile(
              file.path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      return summary;
    } catch (error, stackTrace) {
      if (error is ExportFailure) rethrow;
      Error.throwWithStackTrace(ExportFailure(stage, error), stackTrace);
    }
  }

  void _writeSheet(
    Excel workbook,
    String sheetName,
    List<String> headers,
    List<List<Object?>> rows,
  ) {
    final sheet = workbook[sheetName];
    sheet.appendRow([for (final header in headers) TextCellValue(header)]);
    for (final row in rows) {
      sheet.appendRow([for (final value in row) _cellValue(value)]);
    }
  }

  CellValue _cellValue(Object? value) => switch (value) {
    final int number => IntCellValue(number),
    final double number => DoubleCellValue(number),
    final bool boolean => BoolCellValue(boolean),
    _ => TextCellValue(value?.toString() ?? ''),
  };

  List<Object?> _saleExportRow(
    QueryRow row,
    Map<String, FinanceTransaction> transactionsById,
  ) {
    final transaction = transactionsById[row.read<String>('transaction_id')];
    final quantity = row.read<int>('quantity');
    final unitPrice = row.read<int>('unit_price');
    return [
      _safeText(transaction?.name ?? ''),
      transaction == null ? '' : _date(transaction.transactionDate),
      _safeText(row.read<String>('product_name_snapshot')),
      _safeText(row.read<String>('brand_snapshot')),
      quantity,
      unitPrice,
      quantity * unitPrice,
    ];
  }

  String _date(DateTime value) => AppDateFormatter.long(value);

  String _dateTime(DateTime value) => AppDateFormatter.dateTime(value);

  String _storedDate(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? value : _date(parsed);
  }

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
