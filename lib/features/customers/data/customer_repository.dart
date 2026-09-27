import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/app_database.dart';
import '../domain/customer.dart';

class CustomerRepository {
  CustomerRepository(this.database);
  final AppDatabase database;
  static const _uuid = Uuid();

  Future<List<Customer>> getAll() async {
    await database.ensureCustomersTable();
    final rows = await database
        .customSelect(
          'SELECT id, name, phone, notes FROM customers ORDER BY name COLLATE NOCASE',
        )
        .get();
    return rows
        .map(
          (row) => Customer(
            id: row.read<String>('id'),
            name: row.read<String>('name'),
            phone: row.readNullable<String>('phone'),
            notes: row.readNullable<String>('notes'),
          ),
        )
        .toList(growable: false);
  }

  Future<void> save({String? id, required String name, String? phone}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Nama pelanggan wajib diisi.');
    final now = DateTime.now().toIso8601String();
    if (id == null) {
      await database.customStatement(
        'INSERT OR IGNORE INTO customers (id, name, phone, notes, created_at, updated_at) VALUES (?, ?, ?, NULL, ?, ?)',
        [_uuid.v4(), cleanName, _clean(phone), now, now],
      );
    } else {
      await database.transaction(() async {
        final previous = await database
            .customSelect(
              'SELECT name FROM customers WHERE id = ?',
              variables: [Variable.withString(id)],
            )
            .getSingleOrNull();
        if (previous == null) throw StateError('Pelanggan tidak ditemukan.');
        final previousName = previous.read<String>('name');
        await database.customStatement(
          'UPDATE customers SET name = ?, phone = ?, updated_at = ? WHERE id = ?',
          [cleanName, _clean(phone), now, id],
        );
        if (previousName.toLowerCase() != cleanName.toLowerCase()) {
          await database.customUpdate(
            'UPDATE transactions SET credit_customer_name = ? WHERE credit_customer_name = ? COLLATE NOCASE',
            variables: [
              Variable.withString(cleanName),
              Variable.withString(previousName),
            ],
            updates: {database.transactions},
          );
        }
      });
    }
  }

  Future<String> ensureExists(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('Nama pelanggan wajib diisi.');
    await database.ensureCustomersTable();
    final now = DateTime.now().toIso8601String();
    await database.customStatement(
      'INSERT OR IGNORE INTO customers (id, name, phone, notes, created_at, updated_at) VALUES (?, ?, NULL, NULL, ?, ?)',
      [_uuid.v4(), cleanName, now, now],
    );
    final row = await database
        .customSelect(
          'SELECT name FROM customers WHERE name = ? COLLATE NOCASE',
          variables: [Variable.withString(cleanName)],
        )
        .getSingleOrNull();
    return row?.read<String>('name') ?? cleanName;
  }

  Future<int> transactionCount(Customer customer) async {
    final row = await database
        .customSelect(
          'SELECT COUNT(*) AS total FROM transactions WHERE credit_customer_name = ? COLLATE NOCASE',
          variables: [Variable.withString(customer.name)],
        )
        .getSingle();
    return row.read<int>('total');
  }

  Future<List<QueryRow>> getHistory(Customer customer) => database
      .customSelect(
        'SELECT id, type, name, amount, transaction_date, is_credit, credit_status, credit_paid_amount, credit_due_date FROM transactions WHERE credit_customer_name = ? COLLATE NOCASE ORDER BY transaction_date DESC',
        variables: [Variable.withString(customer.name)],
      )
      .get();

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
