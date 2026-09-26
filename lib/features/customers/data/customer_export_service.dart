import 'dart:io';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/formatters/date_formatter.dart';
import '../domain/customer.dart';

class CustomerExportService {
  Future<void> exportAndShare(
    List<Customer> customers, {
    Rect? sharePositionOrigin,
  }) async {
    final rows = <List<Object?>>[
      ['ID pelanggan', 'Nama pelanggan', 'Nomor telepon', 'Catatan'],
      for (final customer in customers)
        [
          customer.id,
          _safeText(customer.name),
          _safeText(customer.phone ?? ''),
          _safeText(customer.notes ?? ''),
        ],
    ];
    final temporary = await getTemporaryDirectory();
    final now = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(path.join(temporary.path, 'daftar-pelanggan-$now.csv'));
    await file.writeAsString(excel.encode(rows), flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Ekspor daftar pelanggan',
        text:
            'Daftar pelanggan diekspor pada ${AppDateFormatter.long(DateTime.now())}.',
        files: [XFile(file.path, mimeType: 'text/csv')],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  String _safeText(String value) {
    if (value.trimLeft().startsWith(RegExp(r'[=+\-@\t\r]'))) return "'$value";
    return value;
  }
}
