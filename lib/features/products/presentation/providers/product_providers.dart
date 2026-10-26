import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/database_provider.dart';
import '../../data/product_repository.dart';
import '../../domain/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(databaseProvider).productDao);
});

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

final productControllerProvider =
    AsyncNotifierProvider<ProductController, void>(ProductController.new);

class ProductController extends AsyncNotifier<void> {
  ProductRepository get _repository => ref.read(productRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<void> createProduct({
    required ProductBrand brand,
    required String name,
    required int sellingPrice,
  }) async {
    _validateProduct(name: name, sellingPrice: sellingPrice);
    await _runMutation(
      () => _repository.createProduct(
        brand: brand.label,
        name: name.trim(),
        sellingPrice: sellingPrice,
      ),
    );
  }

  Future<void> updateProduct({
    required String id,
    required ProductBrand brand,
    required String name,
    required int sellingPrice,
  }) async {
    _validateProduct(name: name, sellingPrice: sellingPrice);
    await _runMutation(
      () => _repository.updateProduct(
        id: id,
        brand: brand.label,
        name: name.trim(),
        sellingPrice: sellingPrice,
      ),
    );
  }

  Future<void> restock({
    required String productId,
    required int quantity,
    required DateTime date,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Jumlah stok harus lebih dari 0.',
      );
    }
    await _runMutation(
      () => _repository.restock(
        productId: productId,
        quantity: quantity,
        date: date,
        notes: notes,
      ),
      invalidateMovements: true,
    );
  }

  Future<void> updateStock(String productId, int newStock) async {
    if (newStock < 0) {
      throw ArgumentError.value(
        newStock,
        'newStock',
        'Stok tidak boleh bernilai negatif.',
      );
    }
    await _runMutation(() async {
      final updated = await _repository.updateProductStock(productId, newStock);
      if (!updated) {
        throw StateError('Produk tidak ditemukan.');
      }
    }, invalidateMovements: true);
  }

  Future<void> delete(String id) async {
    await _runMutation(() async {
      final deleted = await _repository.deleteProduct(id);
      if (!deleted) {
        throw StateError('Produk tidak ditemukan.');
      }
    }, invalidateMovements: true);
  }

  void _validateProduct({required String name, required int sellingPrice}) {
    if (name.trim().isEmpty) {
      throw ArgumentError.value(name, 'name', 'Nama produk wajib diisi.');
    }
    if (sellingPrice <= 0) {
      throw ArgumentError.value(
        sellingPrice,
        'sellingPrice',
        'Harga jual harus lebih dari 0.',
      );
    }
  }

  Future<void> _runMutation(
    Future<void> Function() action, {
    bool invalidateMovements = false,
  }) async {
    if (state.isLoading) {
      throw StateError('Permintaan sedang diproses.');
    }
    state = const AsyncLoading();
    try {
      await action();
      ref.invalidate(productsProvider);
      ref.invalidate(productSalesProvider);
      if (invalidateMovements) {
        ref.invalidate(stockMovementsProvider);
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
