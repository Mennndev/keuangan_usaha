# Fitur Penjualan Kredit - Dokumentasi

## Deskripsi Fitur

Fitur penjualan kredit memungkinkan pengguna untuk mencatat transaksi penjualan yang dibayar secara kredit (cicilan). Pelanggan dapat membayar penuh di kemudian hari dengan sistem tracking pembayaran yang terstruktur.

## Fitur-Fitur Utama

### 1. Tambah Penjualan Kredit
- User dapat menandai transaksi pemasukan sebagai **penjualan kredit**
- Field yang perlu diisi:
  - **Nama Pelanggan**: Identitas pembeli yang membeli secara kredit
  - **Tanggal Jatuh Tempo**: Kapan pelanggan harus melunasi kredit (default: 30 hari ke depan)
  - **Nominal**: Total nilai penjualan kredit
  - Field standar lainnya: nama transaksi, kategori, keterangan

### 2. Daftar Penjualan Kredit
- Screen untuk melihat semua transaksi penjualan kredit
- Filter berdasarkan status pembayaran:
  - **Belum Dibayar** (Pending): Kredit yang belum ada pembayaran sama sekali
  - **Sebagian Dibayar** (Partial): Kredit yang sudah ada pembayaran tapi belum lunas
  - **Lunas** (Paid): Kredit yang sudah dilunasi penuh

### 3. Catat Pembayaran Kredit
- Dialog untuk mencatat pembayaran cicilan kredit
- User dapat membayar sebagian atau penuh
- Sistem otomatis update status pembayaran:
  - Sisa = 0 → Status "Lunas"
  - Sisa > 0 dan pembayaran > 0 → Status "Sebagian Dibayar"
  - Sisa = total → Status "Belum Dibayar"

### 4. Detail Transaksi Kredit
- Menampilkan informasi kredit lengkap:
  - Nama pelanggan
  - Status pembayaran
  - Tanggal jatuh tempo
  - Total kredit
  - Jumlah yang sudah dibayar
  - Sisa cicilan

## Data Model

### Transactions Table (Diperluas)
```dart
- isCredit (bool): Apakah transaksi adalah penjualan kredit
- creditCustomerName (String?): Nama pelanggan pembeli kredit
- creditDueDate (DateTime?): Tanggal jatuh tempo pembayaran
- creditPaidAmount (int): Total nominal yang sudah dibayar
- creditStatus (String): Status pembayaran (pending, partial, paid)
```

### CreditPayments Table (Baru)
```dart
- id (String): ID unik pembayaran
- transactionId (String): Referensi ke Transactions
- paymentAmount (int): Nominal pembayaran
- paymentDate (DateTime): Tanggal pembayaran
- notes (String?): Catatan pembayaran
- createdAt (DateTime): Waktu pencatatan
- updatedAt (DateTime): Waktu update terakhir
```

## Flow Penggunaan

### Skenario 1: Mencatat Penjualan Kredit Baru
1. Buka Form Tambah Transaksi
2. Pilih jenis: **Pemasukan**
3. Isikan data transaksi standar (nama, nominal, tanggal, dll)
4. Aktifkan toggle **"Penjualan Kredit"**
5. Isikan nama pelanggan
6. Pilih tanggal jatuh tempo pembayaran
7. Simpan transaksi

### Skenario 2: Mencatat Pembayaran Kredit
1. Buka Screen "Penjualan Kredit"
2. Pilih transaksi kredit yang ingin dibayar
3. Klik tombol **"Bayar"**
4. Masukkan nominal pembayaran
5. (Opsional) Tambahkan catatan
6. Simpan pembayaran
7. Status otomatis update berdasarkan sisa pembayaran

### Skenario 3: Melihat Transaksi Kredit
1. Buka Detail Transaksi Kredit
2. Scroll ke bagian "Informasi Kredit"
3. Lihat detail lengkap: status, jatuh tempo, total, dibayar, sisa

## Validasi

### Saat Membuat Penjualan Kredit
- ✅ Nama pelanggan harus diisi jika kredit diaktifkan
- ✅ Tanggal jatuh tempo tidak boleh mundur dari hari ini
- ✅ Nominal kredit harus > 0

### Saat Mencatat Pembayaran
- ✅ Nominal pembayaran harus > 0
- ✅ Nominal pembayaran tidak boleh melebihi sisa cicilan
- ✅ Hanya transaksi kredit yang bisa diisi pembayaran

## Integrasi dengan Fitur Lain

### Dashboard
- Dapat menampilkan ringkasan total kredit yang belum lunas
- Menampilkan kredit jatuh tempo hari ini/besok sebagai alert

### Reports
- Total penjualan kredit per periode
- Total pembayaran kredit per periode
- Analisis kredit berdasarkan status

### Settings
- Opsi default durasi kredit (misal: 30 hari)
- Opsi notifikasi jatuh tempo kredit

## Database Migration

**Schema Version**: 2

Perubahan:
- Tambah 5 field baru ke tabel `Transactions`
- Buat tabel baru `CreditPayments`
- Foreign key relationship dari `CreditPayments.transactionId` ke `Transactions.id`

## Testing Checklist

- [ ] Membuat transaksi penjualan kredit baru
- [ ] Validasi nama pelanggan wajib diisi
- [ ] Validasi tanggal jatuh tempo tidak boleh mundur
- [ ] Melihat daftar kredit dengan filter semua status
- [ ] Mencatat pembayaran kredit (sebagian)
- [ ] Mencatat pembayaran kredit (penuh)
- [ ] Status otomatis update sesuai sisa pembayaran
- [ ] Melihat detail transaksi kredit
- [ ] Edit transaksi kredit
- [ ] Hapus transaksi kredit
- [ ] Validasi pembayaran tidak boleh > sisa
- [ ] Undo pembayaran (jika ada fitur undo di masa depan)

## Future Enhancements

1. **Riwayat Pembayaran**: Lihat semua riwayat pembayaran untuk satu kredit
2. **Notifikasi Jatuh Tempo**: Reminder otomatis saat kredit mau jatuh tempo
3. **Laporan Kredit**: Laporan detail kredit yang belum lunas, overdue, dll
4. **Discount Kredit**: Fitur diskon khusus untuk pembayaran tepat waktu
5. **Multi-currency**: Support untuk mata uang selain Rupiah
6. **Invoice/Receipt**: Cetak dokumen bukti kredit dan pembayaran
7. **Customer Management**: Manajemen data pelanggan terpisah
8. **Sistem Denda**: Denda otomatis untuk kredit yang overdue
