# AGENTS.md - Standar Proyek Keuangan Usaha

Proyek ini adalah aplikasi manajemen keuangan usaha berbasis **Flutter (Dart)** dengan arsitektur **Feature-First Clean Architecture**, **Riverpod** untuk state management, dan **Drift (SQLite)** untuk basis data lokal[cite: 6].

---

## 1. Aturan Eksekusi & Pemanggilan Skill

Sebelum mengeksekusi instruksi koding, wajib mengevaluasi niat pengguna dan memanggil *skill* yang sesuai terlebih dahulu via `skill()` tool:

- **Fitur Baru / Perubahan UI** -> `spec-driven-development`, `frontend-ui-engineering`, `incremental-implementation`
- **Analisis / Perencanaan Arsitektur** -> `planning-and-task-breakdown`
- **Bug Fix / Crash Log** -> `debugging-and-error-recovery`
- **Refactoring / Optimalisasi Kode** -> `code-simplification`
- **Review Kode** -> `code-review-and-quality`
- **Penulisan Test** -> `test-driven-development`

---

## 2. Standar Arsitektur & Struktur Berkas

Setiap fitur di dalam direktori `lib/features/<feature>/` wajib mengikuti pemisahan layer berikut[cite: 6]:

- **`domain/`**: Berisi entitas model data (seperti `customer.dart`, `product.dart`, `finance_transaction.dart`), kriteria filter, dan kelas validasi[cite: 6].
- **`data/`**: Berisi implementasi repository (`transaction_repository.dart`) dan layanan eksternal (backup, restore, ekspor transaksi)[cite: 6].
- **`presentation/`**: Berisi UI screen (`*_screen.dart`), widget spesifik fitur, dan Riverpod providers (`presentation/providers/`)[cite: 6].

Direktori pendukung[cite: 6]:
- **`lib/core/`**: Widget umum (`currency_text.dart`, `app_text_field.dart`), formatter (`currency_formatter.dart`, `date_formatter.dart`), breakpoints responsif, dan konstanta[cite: 6].
- **`lib/database/`**: Definisi tabel Drift (`lib/database/tables/`), DAOs (`lib/database/daos/`), dan berkas tergenerasi `app_database.g.dart`[cite: 6].

---

## 3. Aturan Koding & Konvensi Teknis

### Flutter & Dart
- Gunakan konstruktor `const` pada widget statis untuk menjaga efisiensi render.
- Gunakan tipe data eksplisit dan hindari tipe `dynamic`.
- Manfaatkan komponen responsif yang tersedia di `lib/core/responsive/` serta `responsive_navigation_scaffold.dart`[cite: 6].

### Basis Data (Drift / SQLite)
- Dilarang menggunakan raw SQL query; gunakan Drift DAOs (`TransactionDao`, `ProductDao`, `BusinessSettingsDao`)[cite: 6].
- Setiap penambahan atau pembaruan pada tabel (`transactions.dart`, `credit_payments.dart`, dll.) harus memperhitungkan generasi berkas `app_database.g.dart`[cite: 6].

### State Management (Riverpod)
- Kelola *state* UI secara terpisah di layer `presentation/providers/`[cite: 6].
- Dilarang memanggil repository atau query basis data secara langsung dari dalam file widget UI (`build()` method).

---

## 4. Keamanan & Pengujian

- **Validasi Input:** Selalu jalankan validasi input menggunakan validator domain (`transaction_validators.dart`) sebelum melakukan transaksi kas atau pembayaran kredit[cite: 6].
- **Pengujian:** Setiap perubahan logika perhitungan keuangan (ringkasan kas, piutang, ekspor) wajib melewati pengujian di `test/unit/` dan `test/database/`[cite: 6].