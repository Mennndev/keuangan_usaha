import 'package:intl/intl.dart';

class AppDateFormatter {
  const AppDateFormatter._();

  static final DateFormat _long = DateFormat('d MMMM y', 'id_ID');
  static final DateFormat _short = DateFormat('d MMM y', 'id_ID');
  static final DateFormat _dateTime = DateFormat('d MMM y, HH.mm', 'id_ID');
  static final DateFormat _monthYear = DateFormat('MMMM y', 'id_ID');
  static final DateFormat _year = DateFormat('y', 'id_ID');

  static String long(DateTime date) => _long.format(date);

  static String short(DateTime date) => _short.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date);

  static String monthYear(DateTime date) => _monthYear.format(date);

  static String year(DateTime date) => _year.format(date);
}
