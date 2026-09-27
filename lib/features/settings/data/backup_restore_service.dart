import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../database/app_database.dart';

class BackupPreview {
  const BackupPreview({required this.createdAt, required this.tables});

  final DateTime? createdAt;
  final Map<String, List<Map<String, Object?>>> tables;

  int get totalRows => tables.values.fold(0, (sum, rows) => sum + rows.length);
}

class BackupRestoreService {
  BackupRestoreService(this.database);
  final AppDatabase database;
  static const _channel = MethodChannel('keuangan_usaha/backup');
  static const _tables = <String, List<String>>{
    'customers': ['id', 'name', 'phone', 'notes', 'created_at', 'updated_at'],
    'business_settings': [
      'id',
      'business_name',
      'owner_name',
      'currency_code',
      'theme_mode',
      'created_at',
      'updated_at',
    ],
    'inventory_products': [
      'id',
      'brand',
      'name',
      'selling_price',
      'stock_quantity',
      'archived',
      'created_at',
      'updated_at',
    ],
    'transactions': [
      'id',
      'type',
      'name',
      'amount',
      'category',
      'notes',
      'transaction_date',
      'created_at',
      'updated_at',
      'is_credit',
      'credit_customer_name',
      'credit_due_date',
      'credit_paid_amount',
      'credit_status',
    ],
    'inventory_stock_movements': [
      'id',
      'product_id',
      'product_name_snapshot',
      'brand_snapshot',
      'quantity_change',
      'reason',
      'movement_date',
      'notes',
      'transaction_id',
      'created_at',
    ],
    'credit_payments': [
      'id',
      'transaction_id',
      'payment_amount',
      'payment_date',
      'notes',
      'created_at',
      'updated_at',
    ],
    'product_sale_items': [
      'id',
      'transaction_id',
      'product_id',
      'product_name_snapshot',
      'brand_snapshot',
      'quantity',
      'unit_price',
    ],
  };

  Future<void> exportBackup({Rect? origin}) async {
    final file = await _createBackupFile();
    await SharePlus.instance.share(
      ShareParams(
        title: 'Cadangan Keuangan Usaha',
        text:
            'Simpan file JSON ini di tempat aman. File berisi data usaha pribadi.',
        files: [
          XFile.fromData(file.$1, name: file.$2, mimeType: 'application/json'),
        ],
        sharePositionOrigin: origin,
      ),
    );
  }

  Future<bool> saveBackupToDevice() async {
    final file = await _createBackupFile();
    return await _channel.invokeMethod<bool>('saveBackup', {
          'bytes': file.$1,
          'fileName': file.$2,
        }) ??
        false;
  }

  Future<(Uint8List, String)> _createBackupFile() async {
    await database.ensureCustomersTable();
    await database.ensureProductSaleItems();
    final tables = <String, Object?>{};
    for (final table in _tables.keys) {
      final rows = await database.customSelect('SELECT * FROM $table').get();
      tables[table] = rows
          .map((row) => Map<String, Object?>.from(row.data))
          .toList(growable: false);
    }
    final content = <String, Object?>{
      'format': 'keuangan_usaha_backup',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'tables': tables,
    };
    final data = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(content)),
    );
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return (data, 'cadangan-keuangan-usaha-$stamp.json');
  }

  Future<BackupPreview?> pickBackupPreview() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'openBackup',
    );
    if (result == null) return null;
    final raw = result['bytes'];
    if (raw is! Uint8List) {
      throw const FormatException('File cadangan tidak dapat dibaca.');
    }
    final decoded = jsonDecode(utf8.decode(raw));
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'keuangan_usaha_backup' ||
        decoded['version'] != 1 ||
        decoded['tables'] is! Map<String, dynamic>) {
      throw const FormatException('Format file cadangan tidak dikenali.');
    }
    final sourceTables = decoded['tables'] as Map<String, dynamic>;
    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in _tables.entries) {
      if (sourceTables[table.key] is! List) {
        throw FormatException('Data tabel ${table.key} tidak lengkap.');
      }
      final rows = <Map<String, Object?>>[];
      for (final item in sourceTables[table.key] as List) {
        if (item is! Map ||
            table.value.any((column) => !item.containsKey(column))) {
          throw FormatException('Isi tabel ${table.key} tidak valid.');
        }
        rows.add(Map<String, Object?>.from(item));
      }
      tables[table.key] = rows;
    }
    return BackupPreview(
      createdAt: DateTime.tryParse(decoded['createdAt']?.toString() ?? ''),
      tables: tables,
    );
  }

  Future<int> restoreBackup(BackupPreview preview) async {
    await database.ensureCustomersTable();
    await database.ensureProductSaleItems();
    var restored = 0;
    await database.transaction(() async {
      for (final entry in _tables.entries) {
        final columns = entry.value;
        final sql =
            'INSERT OR IGNORE INTO ${entry.key} (${columns.join(',')}) VALUES (${List.filled(columns.length, '?').join(',')})';
        for (final row in preview.tables[entry.key]!) {
          await database.customStatement(sql, [
            for (final column in columns) row[column],
          ]);
          restored++;
        }
      }
    });
    return restored;
  }
}
