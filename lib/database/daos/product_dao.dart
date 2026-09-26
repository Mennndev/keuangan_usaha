import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';

class ProductRow {
  const ProductRow({
    required this.id,
    required this.brand,
    required this.name,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String brand;
  final String name;
  final int sellingPrice;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProductRow.fromRow(QueryRow row) => ProductRow(
    id: row.read<String>('id'),
    brand: row.read<String>('brand'),
    name: row.read<String>('name'),
    sellingPrice: row.read<int>('selling_price'),
    stockQuantity: row.read<int>('stock_quantity'),
    createdAt: DateTime.parse(row.read<String>('created_at')),
    updatedAt: DateTime.parse(row.read<String>('updated_at')),
  );
}

class ProductSaleSnapshot {
  const ProductSaleSnapshot({
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.brand,
    required this.quantity,
    required this.unitPrice,
  });
  final String saleId;
  final String productId;
  final String productName;
  final String brand;
  final int quantity;
  final int unitPrice;
}

class ProductDao {
  ProductDao(this.database);
  final AppDatabase database;
  static const _uuid = Uuid();

  Stream<List<ProductRow>> watchProducts() => database
      .customSelect(
        'SELECT * FROM inventory_products WHERE archived = 0 ORDER BY brand, name COLLATE NOCASE',
        readsFrom: {database.transactions},
      )
      .watch()
      .map((rows) => rows.map(ProductRow.fromRow).toList(growable: false));

  Future<List<ProductRow>> getProducts() async =>
      (await database
              .customSelect(
                'SELECT * FROM inventory_products WHERE archived = 0 ORDER BY brand, name COLLATE NOCASE',
              )
              .get())
          .map(ProductRow.fromRow)
          .toList(growable: false);

  Future<ProductRow?> findProduct(String id) async {
    final row = await database
        .customSelect(
          'SELECT * FROM inventory_products WHERE id = ? AND archived = 0',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    return row == null ? null : ProductRow.fromRow(row);
  }

  Future<void> insertProduct({
    required String id,
    required String brand,
    required String name,
    required int sellingPrice,
  }) async {
    await database.customStatement(
      'INSERT INTO inventory_products (id, brand, name, selling_price, stock_quantity, archived, created_at, updated_at) VALUES (?, ?, ?, ?, 0, 0, ?, ?)',
      [
        id,
        brand,
        name,
        sellingPrice,
        DateTime.now().toIso8601String(),
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<void> updateProduct({
    required String id,
    required String brand,
    required String name,
    required int sellingPrice,
  }) async {
    await database.customStatement(
      'UPDATE inventory_products SET brand = ?, name = ?, selling_price = ?, updated_at = ? WHERE id = ?',
      [brand, name, sellingPrice, DateTime.now().toIso8601String(), id],
    );
  }

  Future<void> restock({
    required String productId,
    required int quantity,
    required DateTime date,
    String? notes,
  }) async {
    if (quantity <= 0) throw ArgumentError.value(quantity, 'quantity');
    await database.transaction(() async {
      final product = await findProduct(productId);
      if (product == null) throw StateError('Produk tidak ditemukan.');
      await database.customStatement(
        'UPDATE inventory_products SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
        [quantity, DateTime.now().toIso8601String(), productId],
      );
      await _movement(
        product: product,
        quantityChange: quantity,
        reason: 'restock',
        date: date,
        notes: notes,
      );
    });
  }

  Future<ProductSaleSnapshot> recordSale({
    required String productId,
    required int quantity,
    required DateTime date,
    required String transactionId,
    int? snapshotUnitPrice,
  }) async {
    if (quantity <= 0) throw ArgumentError.value(quantity, 'quantity');
    await database.ensureProductSaleItems();
    final product = await findProduct(productId);
    if (product == null) throw StateError('Produk tidak ditemukan.');
    if (product.stockQuantity < quantity)
      throw StateError('Stok ${product.name} tidak mencukupi.');
    await database.customStatement(
      'UPDATE inventory_products SET stock_quantity = stock_quantity - ?, updated_at = ? WHERE id = ?',
      [quantity, DateTime.now().toIso8601String(), productId],
    );
    await _movement(
      product: product,
      quantityChange: -quantity,
      reason: 'sale',
      date: date,
      transactionId: transactionId,
    );
    final saleId = _uuid.v4();
    await database.customStatement(
      'INSERT INTO product_sale_items (id, transaction_id, product_id, product_name_snapshot, brand_snapshot, quantity, unit_price) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        saleId,
        transactionId,
        product.id,
        product.name,
        product.brand,
        quantity,
        snapshotUnitPrice ?? product.sellingPrice,
      ],
    );
    return ProductSaleSnapshot(
      saleId: saleId,
      productId: product.id,
      productName: product.name,
      brand: product.brand,
      quantity: quantity,
      unitPrice: snapshotUnitPrice ?? product.sellingPrice,
    );
  }

  Future<List<ProductSaleSnapshot>> salesForTransaction(
    String transactionId,
  ) async {
    await database.ensureProductSaleItems();
    final rows = await database
        .customSelect(
          'SELECT * FROM product_sale_items WHERE transaction_id = ? ORDER BY rowid',
          variables: [Variable.withString(transactionId)],
        )
        .get();
    return rows
        .map(
          (row) => ProductSaleSnapshot(
            saleId: row.read<String>('id'),
            productId: row.read<String>('product_id'),
            productName: row.read<String>('product_name_snapshot'),
            brand: row.read<String>('brand_snapshot'),
            quantity: row.read<int>('quantity'),
            unitPrice: row.read<int>('unit_price'),
          ),
        )
        .toList(growable: false);
  }

  Future<void> restoreSale(
    ProductSaleSnapshot sale, {
    required String transactionId,
    required DateTime date,
  }) async {
    final product = await findProduct(sale.productId);
    if (product != null) {
      await database.customStatement(
        'UPDATE inventory_products SET stock_quantity = stock_quantity + ?, updated_at = ? WHERE id = ?',
        [sale.quantity, DateTime.now().toIso8601String(), sale.productId],
      );
    }
    await database.customStatement(
      'DELETE FROM product_sale_items WHERE id = ?',
      [sale.saleId],
    );
    await database.customStatement(
      'INSERT INTO inventory_stock_movements (id, product_id, product_name_snapshot, brand_snapshot, quantity_change, reason, movement_date, notes, transaction_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        _uuid.v4(),
        sale.productId,
        sale.productName,
        sale.brand,
        sale.quantity,
        'adjustment',
        date.toIso8601String(),
        'Pembatalan penjualan yang diedit',
        transactionId,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Stream<List<QueryRow>> watchMovements() => database
      .customSelect(
        'SELECT * FROM inventory_stock_movements ORDER BY movement_date DESC, created_at DESC',
        readsFrom: {database.transactions},
      )
      .watch();

  Stream<List<QueryRow>> watchSalesSummary({
    required DateTime start,
    required DateTime end,
  }) => database
      .customSelect(
        '''
    SELECT p.*, COALESCE(SUM(CASE WHEN t.id IS NOT NULL THEN ps.quantity ELSE 0 END), 0) AS quantity_sold,
      COALESCE(SUM(CASE WHEN t.id IS NOT NULL THEN ps.quantity * ps.unit_price ELSE 0 END), 0) AS revenue
    FROM inventory_products p LEFT JOIN product_sale_items ps ON ps.product_id = p.id
      LEFT JOIN transactions t ON t.id = ps.transaction_id AND t.transaction_date >= ? AND t.transaction_date < ?
    WHERE p.archived = 0 GROUP BY p.id ORDER BY quantity_sold DESC, p.name COLLATE NOCASE ASC
  ''',
        variables: [Variable.withDateTime(start), Variable.withDateTime(end)],
        readsFrom: {database.transactions},
      )
      .watch();

  Future<void> _movement({
    required ProductRow product,
    required int quantityChange,
    required String reason,
    required DateTime date,
    String? notes,
    String? transactionId,
  }) async {
    await database.customStatement(
      'INSERT INTO inventory_stock_movements (id, product_id, product_name_snapshot, brand_snapshot, quantity_change, reason, movement_date, notes, transaction_id, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        _uuid.v4(),
        product.id,
        product.name,
        product.brand,
        quantityChange,
        reason,
        date.toIso8601String(),
        notes,
        transactionId,
        DateTime.now().toIso8601String(),
      ],
    );
  }
}
