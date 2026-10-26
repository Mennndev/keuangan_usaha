# Spec: Edit/Update Stok Produk

## Objective
Pengguna dapat menetapkan jumlah stok akhir sebuah produk langsung dari kartu
produk, tanpa harus menambah stok satu per satu. Stok yang disimpan adalah nilai
absolut (`newStock`), bukan selisih penambahan.

## Assumptions
1. ID produk bertipe `String` (UUID), bukan `int` seperti pada permintaan awal.
   Seluruh skema dan domain produk yang ada memakai `String`.
2. Tabel `inventory_products` dikelola lewat raw SQL di `ProductDao` dan belum
   berupa tabel Drift. Karena itu `customUpdate` dipakai mengikuti pola DAO yang
   sudah ada.
3. Tidak ada provider detail produk terpisah. Detail produk diturunkan dari
   `productsProvider`, sehingga invalidasi provider tersebut sekaligus
   memperbarui kartu produk.
4. Nilai stok tidak boleh negatif. Nilai `0` diperbolehkan (stok habis).

## Commands
- Analyze: `D:\flutter\bin\flutter.bat analyze`
- Test: `D:\flutter\bin\flutter.bat test`

## Acceptance Criteria
- `ProductDao.updateProductStock(productId, newStock)` memperbarui
  `stock_quantity` dan `updated_at`, mengembalikan `false` bila produk tidak ada,
  serta menolak nilai negatif.
- `ProductRepository.updateProductStock` meneruskan panggilan ke DAO.
- `ProductController.updateStock` memvalidasi input, memanggil repository, dan
  meng-invalidasi `productsProvider`, `productSalesProvider`, serta
  `stockMovementsProvider`.
- Kartu produk memiliki aksi "Edit stok" yang membuka dialog berisi input angka
  (`NumberInputFormatter`), nilai awal stok saat ini, dan validasi stok >= 0.
- Unit test DAO dan provider lulus, termasuk kasus produk tidak ditemukan dan
  stok negatif.

## Boundaries
- Always: gunakan DAO, validasi input, jalankan analyze dan test.
- Ask first: perubahan skema tabel atau tipe ID produk.
- Never: menambah dependency baru, mengubah data transaksi/penjualan lama.

## Implementation Plan
1. DAO: tambah `updateProductStock` + unit test.
2. Data & provider: tambah method repository dan action controller + unit test.
3. UI: formatter angka, aksi "Edit stok", dialog, dan widget test.
4. Verifikasi penuh: `flutter analyze` dan seluruh `flutter test`.
