# Keuangan Usaha

Aplikasi Flutter offline-first untuk mencatat pemasukan dan pengeluaran usaha kecil tanpa kompleksitas akuntansi. Project dikonfigurasi untuk Android dan iOS. Layout tetap adaptif pada ruang medium dan expanded, tetapi target desktop tidak diklaim karena platform desktop tidak diaktifkan pada scaffold ini.

## Fitur

- Dashboard reaktif untuk total pemasukan, pengeluaran, saldo, grafik, dan transaksi terbaru.
- CRUD transaksi lengkap dengan route detail/edit, validasi, konfirmasi perubahan belum disimpan, dan dialog hapus.
- Search dengan debounce, filter jenis/rentang tanggal, empat urutan, serta lazy limit 30 item.
- Laporan bulanan/tahunan dari query agregasi SQLite tanpa data contoh.
- Profil usaha, tema sistem/terang/gelap, ekspor CSV, dan penghapusan seluruh data dengan konfirmasi berlapis.
- Empty, loading, no-result, error, dan retry state berbahasa Indonesia.
- Navigasi bawah untuk lebar `<600`, NavigationRail untuk `600–1023`, dan sidebar extended untuk `>=1024`.

Database pada instalasi pertama benar-benar kosong. Tidak ada seed, insert otomatis, transaksi hardcoded, atau mock repository di runtime.

## Menjalankan

Gunakan Flutter stable 3.44.6 atau versi stable kompatibel dengan Dart `^3.12.2`.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Pilih perangkat Android atau iOS saat menjalankan. Build iOS memerlukan macOS dan Xcode.

## Pemeriksaan kualitas

```bash
dart format .
flutter analyze
flutter test
```

## Schema database

Schema Drift dimulai dari version 1 dan memiliki migration strategy eksplisit.

`transactions`:

- `id TEXT PRIMARY KEY` — UUID v4.
- `type TEXT` — check constraint `income` atau `expense`.
- `name TEXT`, `amount INTEGER`.
- `category TEXT?`, `notes TEXT?`.
- `transaction_date`, `created_at`, `updated_at` sebagai nilai waktu Drift.

`business_settings`:

- `id TEXT PRIMARY KEY`.
- `business_name TEXT`, `owner_name TEXT?`, `currency_code TEXT`.
- `theme_mode TEXT` — check constraint `system`, `light`, atau `dark`.
- `created_at`, `updated_at`.

Total dan saldo tidak disimpan. Nilainya dihitung dari transaksi, sementara laporan memakai agregasi SQL reaktif.

## Dependency dan alasan

- `flutter_riverpod` — state reaktif dan dependency injection.
- `go_router` — shell navigation dan route parameter detail/edit.
- `drift` + `sqlite3` — database lokal type-safe. SQLite dibundel melalui build hooks `sqlite3 3.x`; `sqlite3_flutter_libs` tidak dipakai karena sudah EOL.
- `path_provider` + `path` — lokasi database dan file CSV.
- `intl` — format rupiah serta tanggal Indonesia.
- `fl_chart` — grafik pemasukan/pengeluaran.
- `uuid` — ID transaksi.
- `csv` + `share_plus` — ekspor data database nyata dan share sheet native.
- `build_runner` + `drift_dev` — code generation database, hanya development.

Font Inter variable dibundel di `assets/fonts` dengan lisensi OFL agar UI tetap konsisten tanpa jaringan.

## Keputusan desain

Desain mengikuti Figma: background `#F5F7FA`, teks `#172033/#667085`, primary `#2563EB`, income `#16A34A`, expense `#DC2626`, kartu radius 16, dan kontrol radius 12. Warna didefinisikan sebagai semantic `ThemeExtension`, bukan literal tersebar.

Prototype Figma memakai koordinat absolut dan ikon teks. Implementasi menggantinya dengan layout Flutter responsif, Material icons, touch target minimal, card yang dapat berkembang, scroll ketika keyboard terbuka, popup action untuk transaksi mobile, dan sidebar untuk ruang expanded. Halaman Pengaturan diturunkan dari design system yang sama karena tidak memiliki frame khusus di file Figma.
