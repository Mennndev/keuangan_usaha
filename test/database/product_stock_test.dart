import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keuangan_usaha/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> insertProduct(String id) {
    return database.productDao.insertProduct(
      id: id,
      brand: 'Vanestrix',
      name: 'Produk $id',
      sellingPrice: 10000,
    );
  }

  test('updateProductStock menetapkan jumlah stok akhir', () async {
    await insertProduct('p1');
    final before = await database.productDao.findProduct('p1');
    expect(before?.stockQuantity, 0);

    final updated = await database.productDao.updateProductStock('p1', 25);

    expect(updated, isTrue);
    final after = await database.productDao.findProduct('p1');
    expect(after?.stockQuantity, 25);
    expect(after?.updatedAt.isAfter(before!.updatedAt), isTrue);
  });

  test('updateProductStock mengizinkan stok nol', () async {
    await insertProduct('p1');
    await database.productDao.updateProductStock('p1', 10);

    expect(await database.productDao.updateProductStock('p1', 0), isTrue);
    expect((await database.productDao.findProduct('p1'))?.stockQuantity, 0);
  });

  test('updateProductStock menolak stok negatif', () async {
    await insertProduct('p1');

    await expectLater(
      database.productDao.updateProductStock('p1', -1),
      throwsA(isA<ArgumentError>()),
    );
    expect((await database.productDao.findProduct('p1'))?.stockQuantity, 0);
  });

  test(
    'updateProductStock mengembalikan false untuk id yang tidak ada',
    () async {
      expect(
        await database.productDao.updateProductStock('missing', 5),
        isFalse,
      );
    },
  );

  test(
    'updateProductStock tidak mengubah produk yang sudah diarsipkan',
    () async {
      await insertProduct('p1');
      await database.productDao.deleteProduct('p1');

      expect(await database.productDao.updateProductStock('p1', 5), isFalse);
    },
  );
}
