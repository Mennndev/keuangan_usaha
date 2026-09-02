import 'package:drift/drift.dart';

@DataClassName('CreditPaymentRecord')
class CreditPayments extends Table {
  TextColumn get id => text()();

TextColumn get transactionId => text().customConstraint(
  'NOT NULL REFERENCES transactions(id) ON DELETE CASCADE',)();

  IntColumn get paymentAmount => integer()();

  DateTimeColumn get paymentDate => dateTime()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
