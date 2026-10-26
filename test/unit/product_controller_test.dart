import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/database/database_provider.dart';
import 'package:keuangan_usaha/features/products/domain/product.dart';
import 'package:keuangan_usaha/features/products/presentation/providers/product_providers.dart';

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  Future<void> insertProduct(String id, String name) {
    return database.productDao.insertProduct(
      id: id,
      brand: 'Vanestrix',
      name: name,
      sellingPrice: 10000,
    );
  }

  test('hapus produk langsung memperbarui daftar produk', () async {
    await insertProduct('p1', 'Produk A');
    await insertProduct('p2', 'Produk B');
    final subscription = container.listen(productsProvider, (_, _) {});
    addTearDown(subscription.close);

    final before = await container.read(productsProvider.future);
    expect(before.map((product) => product.id), ['p1', 'p2']);

    await container.read(productControllerProvider.notifier).delete('p1');
    await container.pump();

    final after = await container.read(productsProvider.future);
    expect(after.map((product) => product.id), ['p2']);
  });

  test('hapus produk yang tidak ada melempar StateError', () async {
    final controller = container.read(productControllerProvider.notifier);

    await expectLater(controller.delete('missing'), throwsA(isA<StateError>()));

    expect(container.read(productControllerProvider), isA<AsyncError<void>>());
  });

  test('createProduct menambah produk baru dan memangkas spasi nama', () async {
    final subscription = container.listen(productsProvider, (_, _) {});
    addTearDown(subscription.close);

    await container
        .read(productControllerProvider.notifier)
        .createProduct(
          brand: ProductBrand.dioses,
          name: '  Produk Baru  ',
          sellingPrice: 25000,
        );
    await container.pump();

    final products = await container.read(productsProvider.future);
    expect(products, hasLength(1));
    final product = products.single;
    expect(product.name, 'Produk Baru');
    expect(product.brand, ProductBrand.dioses);
    expect(product.sellingPrice, 25000);
    expect(product.stockQuantity, 0);
    expect(container.read(productControllerProvider), isA<AsyncData<void>>());
  });

  test('createProduct menolak nama kosong tanpa menyentuh database', () async {
    final controller = container.read(productControllerProvider.notifier);

    await expectLater(
      controller.createProduct(
        brand: ProductBrand.vanestrix,
        name: '   ',
        sellingPrice: 10000,
      ),
      throwsArgumentError,
    );

    expect(await database.productDao.getProducts(), isEmpty);
  });

  test('createProduct menolak harga jual nol atau negatif', () async {
    final controller = container.read(productControllerProvider.notifier);

    await expectLater(
      controller.createProduct(
        brand: ProductBrand.vanestrix,
        name: 'Produk A',
        sellingPrice: 0,
      ),
      throwsArgumentError,
    );

    expect(await database.productDao.getProducts(), isEmpty);
  });

  test('updateProduct memperbarui data produk di daftar', () async {
    await insertProduct('p1', 'Produk Lama');
    final subscription = container.listen(productsProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(productsProvider.future);

    await container
        .read(productControllerProvider.notifier)
        .updateProduct(
          id: 'p1',
          brand: ProductBrand.zahwa,
          name: 'Produk Baru',
          sellingPrice: 17500,
        );
    await container.pump();

    final products = await container.read(productsProvider.future);
    final product = products.single;
    expect(product.brand, ProductBrand.zahwa);
    expect(product.name, 'Produk Baru');
    expect(product.sellingPrice, 17500);
    expect(container.read(productControllerProvider), isA<AsyncData<void>>());
  });

  test('restock menambah stok dan mencatat riwayat stok', () async {
    await insertProduct('p1', 'Produk A');
    final productSubscription = container.listen(productsProvider, (_, _) {});
    addTearDown(productSubscription.close);
    await container.read(productsProvider.future);

    await container
        .read(productControllerProvider.notifier)
        .restock(
          productId: 'p1',
          quantity: 12,
          date: DateTime(2026, 1, 15),
          notes: 'Kiriman gudang',
        );
    await container.pump();

    final products = await container.read(productsProvider.future);
    expect(products.single.stockQuantity, 12);

    final movementSubscription = container.listen(
      stockMovementsProvider,
      (_, _) {},
    );
    addTearDown(movementSubscription.close);
    final movements = await container.read(stockMovementsProvider.future);
    expect(movements, hasLength(1));
    expect(movements.single.productName, 'Produk A');
    expect(movements.single.quantityChange, 12);
    expect(movements.single.reason, 'restock');
    expect(movements.single.notes, 'Kiriman gudang');
    expect(container.read(productControllerProvider), isA<AsyncData<void>>());
  });

  test('restock menolak jumlah nol atau negatif', () async {
    await insertProduct('p1', 'Produk A');
    final controller = container.read(productControllerProvider.notifier);

    await expectLater(
      controller.restock(
        productId: 'p1',
        quantity: 0,
        date: DateTime(2026, 1, 15),
      ),
      throwsArgumentError,
    );
    await expectLater(
      controller.restock(
        productId: 'p1',
        quantity: -3,
        date: DateTime(2026, 1, 15),
      ),
      throwsArgumentError,
    );

    expect((await database.productDao.findProduct('p1'))?.stockQuantity, 0);
  });
}
