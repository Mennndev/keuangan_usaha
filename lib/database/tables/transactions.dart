import 'package:drift/drift.dart';

@DataClassName('TransactionRecord')
class Transactions extends Table {
  TextColumn get id => text()();

  TextColumn get type => text().customConstraint(
    "NOT NULL CHECK (type IN ('income', 'expense'))",
  )();

  TextColumn get name => text()();

  IntColumn get amount => integer()();

  TextColumn get category => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get transactionDate => dateTime()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
