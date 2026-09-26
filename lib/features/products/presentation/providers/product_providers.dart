import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database_provider.dart';
import '../../domain/product.dart';

final productsProvider = StreamProvider.autoDispose<List<Product>>((ref) {
  final dao = ref.watch(databaseProvider).productDao;
  return dao.watchProducts().map(
    (records) => records
        .map(
          (record) => Product(
            id: record.id,
            brand: ProductBrandX.fromDatabase(record.brand),
            name: record.name,
            sellingPrice: record.sellingPrice,
            stockQuantity: record.stockQuantity,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
          ),
        )
        .toList(growable: false),
  );
});

final stockMovementsProvider = StreamProvider.autoDispose<List<StockMovement>>((
  ref,
) {
  final dao = ref.watch(databaseProvider).productDao;
  return dao.watchMovements().map(
    (records) => records
        .map(
          (record) => StockMovement(
            productName: record.read<String>('product_name_snapshot'),
            brand: record.read<String>('brand_snapshot'),
            quantityChange: record.read<int>('quantity_change'),
            reason: record.read<String>('reason'),
            movementDate: DateTime.parse(record.read<String>('movement_date')),
            notes: record.readNullable<String>('notes'),
          ),
        )
        .toList(growable: false),
  );
});

final productSalesProvider = StreamProvider.autoDispose
    .family<List<ProductSalesSummary>, DateTime>((ref, anchor) {
      final dao = ref.watch(databaseProvider).productDao;
      final start = DateTime(anchor.year, anchor.month);
      final end = DateTime(anchor.year, anchor.month + 1);
      return dao
          .watchSalesSummary(start: start, end: end)
          .map(
            (rows) => rows
                .map((row) {
                  final product = Product(
                    id: row.read<String>('id'),
                    brand: ProductBrandX.fromDatabase(
                      row.read<String>('brand'),
                    ),
                    name: row.read<String>('name'),
                    sellingPrice: row.read<int>('selling_price'),
                    stockQuantity: row.read<int>('stock_quantity'),
                    createdAt: DateTime.parse(row.read<String>('created_at')),
                    updatedAt: DateTime.parse(row.read<String>('updated_at')),
                  );
                  return ProductSalesSummary(
                    product: product,
                    quantitySold: row.read<int>('quantity_sold'),
                    revenue: row.read<int>('revenue'),
                  );
                })
                .toList(growable: false),
          );
    });
