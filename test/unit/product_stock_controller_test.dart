import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/database/app_database.dart';
import 'package:keuangan_usaha/database/database_provider.dart';
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

  Future<void> insertProduct(String id, {int stock = 0}) async {
    await database.productDao.insertProduct(
      id: id,
      brand: 'Vanestrix',
      name: 'Produk $id',
      sellingPrice: 10000,
    );
    if (stock > 0) {
      await database.productDao.updateProductStock(id, stock);
    }
  }

  test('updateStock memperbarui daftar produk secara langsung', () async {
    await insertProduct('p1', stock: 5);
    final month = DateTime.now();
    final subscriptions = [
      container.listen(productsProvider, (_, _) {}),
      container.listen(productSalesProvider(month), (_, _) {}),
      container.listen(stockMovementsProvider, (_, _) {}),
    ];
    addTearDown(() {
      for (final subscription in subscriptions) {
        subscription.close();
      }
    });

    final before = await container.read(productsProvider.future);
    expect(before.single.stockQuantity, 5);

    await container
        .read(productControllerProvider.notifier)
        .updateStock('p1', 30);
    await container.pump();

    final after = await container.read(productsProvider.future);
    expect(after.single.stockQuantity, 30);
    expect(container.read(productControllerProvider), isA<AsyncData<void>>());
  });

  test('updateStock menolak stok negatif', () async {
    await insertProduct('p1');
    final controller = container.read(productControllerProvider.notifier);

    await expectLater(controller.updateStock('p1', -2), throwsArgumentError);
    expect((await database.productDao.findProduct('p1'))?.stockQuantity, 0);
  });

  test('updateStock pada produk yang tidak ada melempar StateError', () async {
    final controller = container.read(productControllerProvider.notifier);

    await expectLater(controller.updateStock('missing', 10), throwsStateError);
    expect(container.read(productControllerProvider), isA<AsyncError<void>>());
  });
}
