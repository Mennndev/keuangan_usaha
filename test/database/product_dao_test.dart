import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/features/products/data/product_repository.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertProduct(String id, {String name = 'Produk'}) {
    return database.productDao.insertProduct(
      id: id,
      brand: 'Vanestrix',
      name: name,
      sellingPrice: 10000,
    );
  }

  test('soft delete mengarsipkan produk dan menyembunyikannya dari daftar', () async {
    await insertProduct('p1', name: 'Produk A');
    await insertProduct('p2', name: 'Produk B');

    expect(await database.productDao.deleteProduct('p1'), isTrue);

    final products = await database.productDao.getProducts();
    expect(products.map((product) => product.id), ['p2']);
    expect(await database.productDao.findProduct('p1'), isNull);

    final row = await database
        .customSelect(
          'SELECT archived FROM inventory_products WHERE id = ?',
          variables: [Variable.withString('p1')],
        )
        .getSingle();
    expect(row.read<int>('archived'), 1);
  });

  test('menghapus produk yang tidak ada mengembalikan false', () async {
    expect(await database.productDao.deleteProduct('missing'), isFalse);
  });

  test('produk yang sudah diarsipkan tidak terhapus dua kali', () async {
    await insertProduct('p1');

    expect(await database.productDao.deleteProduct('p1'), isTrue);
    expect(await database.productDao.deleteProduct('p1'), isFalse);
  });

  test('repository meneruskan penghapusan ke DAO', () async {
    await insertProduct('p1');
    final repository = ProductRepository(database.productDao);

    expect(await repository.deleteProduct('p1'), isTrue);
    expect(await database.productDao.getProducts(), isEmpty);
  });
}
