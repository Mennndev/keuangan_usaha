import 'package:uuid/uuid.dart';

import '../../../database/daos/product_dao.dart';

class ProductRepository {
  ProductRepository(this._dao);

  final ProductDao _dao;
  static const _uuid = Uuid();

  Future<void> createProduct({
    required String brand,
    required String name,
    required int sellingPrice,
  }) {
    return _dao.insertProduct(
      id: _uuid.v4(),
      brand: brand,
      name: name,
      sellingPrice: sellingPrice,
    );
  }

  Future<void> updateProduct({
    required String id,
    required String brand,
    required String name,
    required int sellingPrice,
  }) {
    return _dao.updateProduct(
      id: id,
      brand: brand,
      name: name,
      sellingPrice: sellingPrice,
    );
  }

  Future<void> restock({
    required String productId,
    required int quantity,
    required DateTime date,
    String? notes,
  }) {
    return _dao.restock(
      productId: productId,
      quantity: quantity,
      date: date,
      notes: notes,
    );
  }

  Future<bool> deleteProduct(String id) => _dao.deleteProduct(id);

  Future<bool> updateProductStock(String productId, int newStock) =>
      _dao.updateProductStock(productId, newStock);
}
