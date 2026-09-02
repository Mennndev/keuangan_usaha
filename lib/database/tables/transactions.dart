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

  // Credit sales fields
  BoolColumn get isCredit => boolean().withDefault(const Constant(false))();

  TextColumn get creditCustomerName => text().nullable()();

  DateTimeColumn get creditDueDate => dateTime().nullable()();

  IntColumn get creditPaidAmount => integer().withDefault(const Constant(0))();

    TextColumn get creditStatus => text().customConstraint(
  "NOT NULL DEFAULT 'pending' CHECK (credit_status IN ('pending', 'partial', 'paid'))",
)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
