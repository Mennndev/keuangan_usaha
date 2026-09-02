// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (type IN (\'income\', \'expense\'))',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionDateMeta = const VerificationMeta(
    'transactionDate',
  );
  @override
  late final GeneratedColumn<DateTime> transactionDate =
      GeneratedColumn<DateTime>(
        'transaction_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCreditMeta = const VerificationMeta(
    'isCredit',
  );
  @override
  late final GeneratedColumn<bool> isCredit = GeneratedColumn<bool>(
    'is_credit',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_credit" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _creditCustomerNameMeta =
      const VerificationMeta('creditCustomerName');
  @override
  late final GeneratedColumn<String> creditCustomerName =
      GeneratedColumn<String>(
        'credit_customer_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creditDueDateMeta = const VerificationMeta(
    'creditDueDate',
  );
  @override
  late final GeneratedColumn<DateTime> creditDueDate =
      GeneratedColumn<DateTime>(
        'credit_due_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creditPaidAmountMeta = const VerificationMeta(
    'creditPaidAmount',
  );
  @override
  late final GeneratedColumn<int> creditPaidAmount = GeneratedColumn<int>(
    'credit_paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _creditStatusMeta = const VerificationMeta(
    'creditStatus',
  );
  @override
  late final GeneratedColumn<String> creditStatus = GeneratedColumn<String>(
    'credit_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'pending\' CHECK (credit_status IN (\'pending\', \'partial\', \'paid\'))',
    defaultValue: const CustomExpression('\'pending\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    amount,
    category,
    notes,
    transactionDate,
    createdAt,
    updatedAt,
    isCredit,
    creditCustomerName,
    creditDueDate,
    creditPaidAmount,
    creditStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('transaction_date')) {
      context.handle(
        _transactionDateMeta,
        transactionDate.isAcceptableOrUnknown(
          data['transaction_date']!,
          _transactionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_credit')) {
      context.handle(
        _isCreditMeta,
        isCredit.isAcceptableOrUnknown(data['is_credit']!, _isCreditMeta),
      );
    }
    if (data.containsKey('credit_customer_name')) {
      context.handle(
        _creditCustomerNameMeta,
        creditCustomerName.isAcceptableOrUnknown(
          data['credit_customer_name']!,
          _creditCustomerNameMeta,
        ),
      );
    }
    if (data.containsKey('credit_due_date')) {
      context.handle(
        _creditDueDateMeta,
        creditDueDate.isAcceptableOrUnknown(
          data['credit_due_date']!,
          _creditDueDateMeta,
        ),
      );
    }
    if (data.containsKey('credit_paid_amount')) {
      context.handle(
        _creditPaidAmountMeta,
        creditPaidAmount.isAcceptableOrUnknown(
          data['credit_paid_amount']!,
          _creditPaidAmountMeta,
        ),
      );
    }
    if (data.containsKey('credit_status')) {
      context.handle(
        _creditStatusMeta,
        creditStatus.isAcceptableOrUnknown(
          data['credit_status']!,
          _creditStatusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      transactionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transaction_date'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_credit'],
      )!,
      creditCustomerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_customer_name'],
      ),
      creditDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}credit_due_date'],
      ),
      creditPaidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_paid_amount'],
      )!,
      creditStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_status'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRecord extends DataClass
    implements Insertable<TransactionRecord> {
  final String id;
  final String type;
  final String name;
  final int amount;
  final String? category;
  final String? notes;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCredit;
  final String? creditCustomerName;
  final DateTime? creditDueDate;
  final int creditPaidAmount;
  final String creditStatus;
  const TransactionRecord({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    this.category,
    this.notes,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    required this.isCredit,
    this.creditCustomerName,
    this.creditDueDate,
    required this.creditPaidAmount,
    required this.creditStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['transaction_date'] = Variable<DateTime>(transactionDate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_credit'] = Variable<bool>(isCredit);
    if (!nullToAbsent || creditCustomerName != null) {
      map['credit_customer_name'] = Variable<String>(creditCustomerName);
    }
    if (!nullToAbsent || creditDueDate != null) {
      map['credit_due_date'] = Variable<DateTime>(creditDueDate);
    }
    map['credit_paid_amount'] = Variable<int>(creditPaidAmount);
    map['credit_status'] = Variable<String>(creditStatus);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      amount: Value(amount),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      transactionDate: Value(transactionDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isCredit: Value(isCredit),
      creditCustomerName: creditCustomerName == null && nullToAbsent
          ? const Value.absent()
          : Value(creditCustomerName),
      creditDueDate: creditDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(creditDueDate),
      creditPaidAmount: Value(creditPaidAmount),
      creditStatus: Value(creditStatus),
    );
  }

  factory TransactionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRecord(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<int>(json['amount']),
      category: serializer.fromJson<String?>(json['category']),
      notes: serializer.fromJson<String?>(json['notes']),
      transactionDate: serializer.fromJson<DateTime>(json['transactionDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isCredit: serializer.fromJson<bool>(json['isCredit']),
      creditCustomerName: serializer.fromJson<String?>(
        json['creditCustomerName'],
      ),
      creditDueDate: serializer.fromJson<DateTime?>(json['creditDueDate']),
      creditPaidAmount: serializer.fromJson<int>(json['creditPaidAmount']),
      creditStatus: serializer.fromJson<String>(json['creditStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<int>(amount),
      'category': serializer.toJson<String?>(category),
      'notes': serializer.toJson<String?>(notes),
      'transactionDate': serializer.toJson<DateTime>(transactionDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isCredit': serializer.toJson<bool>(isCredit),
      'creditCustomerName': serializer.toJson<String?>(creditCustomerName),
      'creditDueDate': serializer.toJson<DateTime?>(creditDueDate),
      'creditPaidAmount': serializer.toJson<int>(creditPaidAmount),
      'creditStatus': serializer.toJson<String>(creditStatus),
    };
  }

  TransactionRecord copyWith({
    String? id,
    String? type,
    String? name,
    int? amount,
    Value<String?> category = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCredit,
    Value<String?> creditCustomerName = const Value.absent(),
    Value<DateTime?> creditDueDate = const Value.absent(),
    int? creditPaidAmount,
    String? creditStatus,
  }) => TransactionRecord(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    category: category.present ? category.value : this.category,
    notes: notes.present ? notes.value : this.notes,
    transactionDate: transactionDate ?? this.transactionDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isCredit: isCredit ?? this.isCredit,
    creditCustomerName: creditCustomerName.present
        ? creditCustomerName.value
        : this.creditCustomerName,
    creditDueDate: creditDueDate.present
        ? creditDueDate.value
        : this.creditDueDate,
    creditPaidAmount: creditPaidAmount ?? this.creditPaidAmount,
    creditStatus: creditStatus ?? this.creditStatus,
  );
  TransactionRecord copyWithCompanion(TransactionsCompanion data) {
    return TransactionRecord(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      category: data.category.present ? data.category.value : this.category,
      notes: data.notes.present ? data.notes.value : this.notes,
      transactionDate: data.transactionDate.present
          ? data.transactionDate.value
          : this.transactionDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isCredit: data.isCredit.present ? data.isCredit.value : this.isCredit,
      creditCustomerName: data.creditCustomerName.present
          ? data.creditCustomerName.value
          : this.creditCustomerName,
      creditDueDate: data.creditDueDate.present
          ? data.creditDueDate.value
          : this.creditDueDate,
      creditPaidAmount: data.creditPaidAmount.present
          ? data.creditPaidAmount.value
          : this.creditPaidAmount,
      creditStatus: data.creditStatus.present
          ? data.creditStatus.value
          : this.creditStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRecord(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isCredit: $isCredit, ')
          ..write('creditCustomerName: $creditCustomerName, ')
          ..write('creditDueDate: $creditDueDate, ')
          ..write('creditPaidAmount: $creditPaidAmount, ')
          ..write('creditStatus: $creditStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    name,
    amount,
    category,
    notes,
    transactionDate,
    createdAt,
    updatedAt,
    isCredit,
    creditCustomerName,
    creditDueDate,
    creditPaidAmount,
    creditStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRecord &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.category == this.category &&
          other.notes == this.notes &&
          other.transactionDate == this.transactionDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isCredit == this.isCredit &&
          other.creditCustomerName == this.creditCustomerName &&
          other.creditDueDate == this.creditDueDate &&
          other.creditPaidAmount == this.creditPaidAmount &&
          other.creditStatus == this.creditStatus);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRecord> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> name;
  final Value<int> amount;
  final Value<String?> category;
  final Value<String?> notes;
  final Value<DateTime> transactionDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isCredit;
  final Value<String?> creditCustomerName;
  final Value<DateTime?> creditDueDate;
  final Value<int> creditPaidAmount;
  final Value<String> creditStatus;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.category = const Value.absent(),
    this.notes = const Value.absent(),
    this.transactionDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isCredit = const Value.absent(),
    this.creditCustomerName = const Value.absent(),
    this.creditDueDate = const Value.absent(),
    this.creditPaidAmount = const Value.absent(),
    this.creditStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String type,
    required String name,
    required int amount,
    this.category = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime transactionDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isCredit = const Value.absent(),
    this.creditCustomerName = const Value.absent(),
    this.creditDueDate = const Value.absent(),
    this.creditPaidAmount = const Value.absent(),
    this.creditStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       name = Value(name),
       amount = Value(amount),
       transactionDate = Value(transactionDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TransactionRecord> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<int>? amount,
    Expression<String>? category,
    Expression<String>? notes,
    Expression<DateTime>? transactionDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isCredit,
    Expression<String>? creditCustomerName,
    Expression<DateTime>? creditDueDate,
    Expression<int>? creditPaidAmount,
    Expression<String>? creditStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
      if (transactionDate != null) 'transaction_date': transactionDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isCredit != null) 'is_credit': isCredit,
      if (creditCustomerName != null)
        'credit_customer_name': creditCustomerName,
      if (creditDueDate != null) 'credit_due_date': creditDueDate,
      if (creditPaidAmount != null) 'credit_paid_amount': creditPaidAmount,
      if (creditStatus != null) 'credit_status': creditStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? name,
    Value<int>? amount,
    Value<String?>? category,
    Value<String?>? notes,
    Value<DateTime>? transactionDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isCredit,
    Value<String?>? creditCustomerName,
    Value<DateTime?>? creditDueDate,
    Value<int>? creditPaidAmount,
    Value<String>? creditStatus,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCredit: isCredit ?? this.isCredit,
      creditCustomerName: creditCustomerName ?? this.creditCustomerName,
      creditDueDate: creditDueDate ?? this.creditDueDate,
      creditPaidAmount: creditPaidAmount ?? this.creditPaidAmount,
      creditStatus: creditStatus ?? this.creditStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (transactionDate.present) {
      map['transaction_date'] = Variable<DateTime>(transactionDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isCredit.present) {
      map['is_credit'] = Variable<bool>(isCredit.value);
    }
    if (creditCustomerName.present) {
      map['credit_customer_name'] = Variable<String>(creditCustomerName.value);
    }
    if (creditDueDate.present) {
      map['credit_due_date'] = Variable<DateTime>(creditDueDate.value);
    }
    if (creditPaidAmount.present) {
      map['credit_paid_amount'] = Variable<int>(creditPaidAmount.value);
    }
    if (creditStatus.present) {
      map['credit_status'] = Variable<String>(creditStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('category: $category, ')
          ..write('notes: $notes, ')
          ..write('transactionDate: $transactionDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isCredit: $isCredit, ')
          ..write('creditCustomerName: $creditCustomerName, ')
          ..write('creditDueDate: $creditDueDate, ')
          ..write('creditPaidAmount: $creditPaidAmount, ')
          ..write('creditStatus: $creditStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessSettingsTable extends BusinessSettings
    with TableInfo<$BusinessSettingsTable, BusinessSettingRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessNameMeta = const VerificationMeta(
    'businessName',
  );
  @override
  late final GeneratedColumn<String> businessName = GeneratedColumn<String>(
    'business_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IDR'),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (theme_mode IN (\'system\', \'light\', \'dark\'))',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    businessName,
    ownerName,
    currencyCode,
    themeMode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessSettingRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('business_name')) {
      context.handle(
        _businessNameMeta,
        businessName.isAcceptableOrUnknown(
          data['business_name']!,
          _businessNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessNameMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeModeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessSettingRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessSettingRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      businessName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_name'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BusinessSettingsTable createAlias(String alias) {
    return $BusinessSettingsTable(attachedDatabase, alias);
  }
}

class BusinessSettingRecord extends DataClass
    implements Insertable<BusinessSettingRecord> {
  final String id;
  final String businessName;
  final String? ownerName;
  final String currencyCode;
  final String themeMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BusinessSettingRecord({
    required this.id,
    required this.businessName,
    this.ownerName,
    required this.currencyCode,
    required this.themeMode,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['business_name'] = Variable<String>(businessName);
    if (!nullToAbsent || ownerName != null) {
      map['owner_name'] = Variable<String>(ownerName);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['theme_mode'] = Variable<String>(themeMode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BusinessSettingsCompanion toCompanion(bool nullToAbsent) {
    return BusinessSettingsCompanion(
      id: Value(id),
      businessName: Value(businessName),
      ownerName: ownerName == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerName),
      currencyCode: Value(currencyCode),
      themeMode: Value(themeMode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BusinessSettingRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessSettingRecord(
      id: serializer.fromJson<String>(json['id']),
      businessName: serializer.fromJson<String>(json['businessName']),
      ownerName: serializer.fromJson<String?>(json['ownerName']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'businessName': serializer.toJson<String>(businessName),
      'ownerName': serializer.toJson<String?>(ownerName),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'themeMode': serializer.toJson<String>(themeMode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BusinessSettingRecord copyWith({
    String? id,
    String? businessName,
    Value<String?> ownerName = const Value.absent(),
    String? currencyCode,
    String? themeMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BusinessSettingRecord(
    id: id ?? this.id,
    businessName: businessName ?? this.businessName,
    ownerName: ownerName.present ? ownerName.value : this.ownerName,
    currencyCode: currencyCode ?? this.currencyCode,
    themeMode: themeMode ?? this.themeMode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BusinessSettingRecord copyWithCompanion(BusinessSettingsCompanion data) {
    return BusinessSettingRecord(
      id: data.id.present ? data.id.value : this.id,
      businessName: data.businessName.present
          ? data.businessName.value
          : this.businessName,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessSettingRecord(')
          ..write('id: $id, ')
          ..write('businessName: $businessName, ')
          ..write('ownerName: $ownerName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('themeMode: $themeMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    businessName,
    ownerName,
    currencyCode,
    themeMode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessSettingRecord &&
          other.id == this.id &&
          other.businessName == this.businessName &&
          other.ownerName == this.ownerName &&
          other.currencyCode == this.currencyCode &&
          other.themeMode == this.themeMode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BusinessSettingsCompanion extends UpdateCompanion<BusinessSettingRecord> {
  final Value<String> id;
  final Value<String> businessName;
  final Value<String?> ownerName;
  final Value<String> currencyCode;
  final Value<String> themeMode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BusinessSettingsCompanion({
    this.id = const Value.absent(),
    this.businessName = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessSettingsCompanion.insert({
    required String id,
    required String businessName,
    this.ownerName = const Value.absent(),
    this.currencyCode = const Value.absent(),
    required String themeMode,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       businessName = Value(businessName),
       themeMode = Value(themeMode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BusinessSettingRecord> custom({
    Expression<String>? id,
    Expression<String>? businessName,
    Expression<String>? ownerName,
    Expression<String>? currencyCode,
    Expression<String>? themeMode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (businessName != null) 'business_name': businessName,
      if (ownerName != null) 'owner_name': ownerName,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (themeMode != null) 'theme_mode': themeMode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessSettingsCompanion copyWith({
    Value<String>? id,
    Value<String>? businessName,
    Value<String?>? ownerName,
    Value<String>? currencyCode,
    Value<String>? themeMode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BusinessSettingsCompanion(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      currencyCode: currencyCode ?? this.currencyCode,
      themeMode: themeMode ?? this.themeMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (businessName.present) {
      map['business_name'] = Variable<String>(businessName.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessSettingsCompanion(')
          ..write('id: $id, ')
          ..write('businessName: $businessName, ')
          ..write('ownerName: $ownerName, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('themeMode: $themeMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditPaymentsTable extends CreditPayments
    with TableInfo<$CreditPaymentsTable, CreditPaymentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES transactions(id) ON DELETE CASCADE',
  );
  static const VerificationMeta _paymentAmountMeta = const VerificationMeta(
    'paymentAmount',
  );
  @override
  late final GeneratedColumn<int> paymentAmount = GeneratedColumn<int>(
    'payment_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentDateMeta = const VerificationMeta(
    'paymentDate',
  );
  @override
  late final GeneratedColumn<DateTime> paymentDate = GeneratedColumn<DateTime>(
    'payment_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionId,
    paymentAmount,
    paymentDate,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditPaymentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('payment_amount')) {
      context.handle(
        _paymentAmountMeta,
        paymentAmount.isAcceptableOrUnknown(
          data['payment_amount']!,
          _paymentAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentAmountMeta);
    }
    if (data.containsKey('payment_date')) {
      context.handle(
        _paymentDateMeta,
        paymentDate.isAcceptableOrUnknown(
          data['payment_date']!,
          _paymentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditPaymentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditPaymentRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      )!,
      paymentAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_amount'],
      )!,
      paymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}payment_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CreditPaymentsTable createAlias(String alias) {
    return $CreditPaymentsTable(attachedDatabase, alias);
  }
}

class CreditPaymentRecord extends DataClass
    implements Insertable<CreditPaymentRecord> {
  final String id;
  final String transactionId;
  final int paymentAmount;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CreditPaymentRecord({
    required this.id,
    required this.transactionId,
    required this.paymentAmount,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    map['payment_amount'] = Variable<int>(paymentAmount);
    map['payment_date'] = Variable<DateTime>(paymentDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CreditPaymentsCompanion toCompanion(bool nullToAbsent) {
    return CreditPaymentsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      paymentAmount: Value(paymentAmount),
      paymentDate: Value(paymentDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CreditPaymentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditPaymentRecord(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      paymentAmount: serializer.fromJson<int>(json['paymentAmount']),
      paymentDate: serializer.fromJson<DateTime>(json['paymentDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'paymentAmount': serializer.toJson<int>(paymentAmount),
      'paymentDate': serializer.toJson<DateTime>(paymentDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CreditPaymentRecord copyWith({
    String? id,
    String? transactionId,
    int? paymentAmount,
    DateTime? paymentDate,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CreditPaymentRecord(
    id: id ?? this.id,
    transactionId: transactionId ?? this.transactionId,
    paymentAmount: paymentAmount ?? this.paymentAmount,
    paymentDate: paymentDate ?? this.paymentDate,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CreditPaymentRecord copyWithCompanion(CreditPaymentsCompanion data) {
    return CreditPaymentRecord(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      paymentAmount: data.paymentAmount.present
          ? data.paymentAmount.value
          : this.paymentAmount,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditPaymentRecord(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('paymentAmount: $paymentAmount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    transactionId,
    paymentAmount,
    paymentDate,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditPaymentRecord &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.paymentAmount == this.paymentAmount &&
          other.paymentDate == this.paymentDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CreditPaymentsCompanion extends UpdateCompanion<CreditPaymentRecord> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<int> paymentAmount;
  final Value<DateTime> paymentDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CreditPaymentsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.paymentAmount = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditPaymentsCompanion.insert({
    required String id,
    required String transactionId,
    required int paymentAmount,
    required DateTime paymentDate,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       transactionId = Value(transactionId),
       paymentAmount = Value(paymentAmount),
       paymentDate = Value(paymentDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CreditPaymentRecord> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<int>? paymentAmount,
    Expression<DateTime>? paymentDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (paymentAmount != null) 'payment_amount': paymentAmount,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? transactionId,
    Value<int>? paymentAmount,
    Value<DateTime>? paymentDate,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CreditPaymentsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (paymentAmount.present) {
      map['payment_amount'] = Variable<int>(paymentAmount.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(paymentDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('paymentAmount: $paymentAmount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $BusinessSettingsTable businessSettings = $BusinessSettingsTable(
    this,
  );
  late final $CreditPaymentsTable creditPayments = $CreditPaymentsTable(this);
  late final TransactionDao transactionDao = TransactionDao(
    this as AppDatabase,
  );
  late final BusinessSettingsDao businessSettingsDao = BusinessSettingsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    businessSettings,
    creditPayments,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String type,
      required String name,
      required int amount,
      Value<String?> category,
      Value<String?> notes,
      required DateTime transactionDate,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isCredit,
      Value<String?> creditCustomerName,
      Value<DateTime?> creditDueDate,
      Value<int> creditPaidAmount,
      Value<String> creditStatus,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> name,
      Value<int> amount,
      Value<String?> category,
      Value<String?> notes,
      Value<DateTime> transactionDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isCredit,
      Value<String?> creditCustomerName,
      Value<DateTime?> creditDueDate,
      Value<int> creditPaidAmount,
      Value<String> creditStatus,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCredit => $composableBuilder(
    column: $table.isCredit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditCustomerName => $composableBuilder(
    column: $table.creditCustomerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creditDueDate => $composableBuilder(
    column: $table.creditDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditPaidAmount => $composableBuilder(
    column: $table.creditPaidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditStatus => $composableBuilder(
    column: $table.creditStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCredit => $composableBuilder(
    column: $table.isCredit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditCustomerName => $composableBuilder(
    column: $table.creditCustomerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creditDueDate => $composableBuilder(
    column: $table.creditDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditPaidAmount => $composableBuilder(
    column: $table.creditPaidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditStatus => $composableBuilder(
    column: $table.creditStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get transactionDate => $composableBuilder(
    column: $table.transactionDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isCredit =>
      $composableBuilder(column: $table.isCredit, builder: (column) => column);

  GeneratedColumn<String> get creditCustomerName => $composableBuilder(
    column: $table.creditCustomerName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creditDueDate => $composableBuilder(
    column: $table.creditDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditPaidAmount => $composableBuilder(
    column: $table.creditPaidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creditStatus => $composableBuilder(
    column: $table.creditStatus,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRecord,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRecord,
            BaseReferences<
              _$AppDatabase,
              $TransactionsTable,
              TransactionRecord
            >,
          ),
          TransactionRecord,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> transactionDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isCredit = const Value.absent(),
                Value<String?> creditCustomerName = const Value.absent(),
                Value<DateTime?> creditDueDate = const Value.absent(),
                Value<int> creditPaidAmount = const Value.absent(),
                Value<String> creditStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                name: name,
                amount: amount,
                category: category,
                notes: notes,
                transactionDate: transactionDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isCredit: isCredit,
                creditCustomerName: creditCustomerName,
                creditDueDate: creditDueDate,
                creditPaidAmount: creditPaidAmount,
                creditStatus: creditStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String name,
                required int amount,
                Value<String?> category = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime transactionDate,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isCredit = const Value.absent(),
                Value<String?> creditCustomerName = const Value.absent(),
                Value<DateTime?> creditDueDate = const Value.absent(),
                Value<int> creditPaidAmount = const Value.absent(),
                Value<String> creditStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                name: name,
                amount: amount,
                category: category,
                notes: notes,
                transactionDate: transactionDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isCredit: isCredit,
                creditCustomerName: creditCustomerName,
                creditDueDate: creditDueDate,
                creditPaidAmount: creditPaidAmount,
                creditStatus: creditStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRecord,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRecord,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRecord>,
      ),
      TransactionRecord,
      PrefetchHooks Function()
    >;
typedef $$BusinessSettingsTableCreateCompanionBuilder =
    BusinessSettingsCompanion Function({
      required String id,
      required String businessName,
      Value<String?> ownerName,
      Value<String> currencyCode,
      required String themeMode,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$BusinessSettingsTableUpdateCompanionBuilder =
    BusinessSettingsCompanion Function({
      Value<String> id,
      Value<String> businessName,
      Value<String?> ownerName,
      Value<String> currencyCode,
      Value<String> themeMode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BusinessSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTable> {
  $$BusinessSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTable> {
  $$BusinessSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessSettingsTable> {
  $$BusinessSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get businessName => $composableBuilder(
    column: $table.businessName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BusinessSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessSettingsTable,
          BusinessSettingRecord,
          $$BusinessSettingsTableFilterComposer,
          $$BusinessSettingsTableOrderingComposer,
          $$BusinessSettingsTableAnnotationComposer,
          $$BusinessSettingsTableCreateCompanionBuilder,
          $$BusinessSettingsTableUpdateCompanionBuilder,
          (
            BusinessSettingRecord,
            BaseReferences<
              _$AppDatabase,
              $BusinessSettingsTable,
              BusinessSettingRecord
            >,
          ),
          BusinessSettingRecord,
          PrefetchHooks Function()
        > {
  $$BusinessSettingsTableTableManager(
    _$AppDatabase db,
    $BusinessSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> businessName = const Value.absent(),
                Value<String?> ownerName = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessSettingsCompanion(
                id: id,
                businessName: businessName,
                ownerName: ownerName,
                currencyCode: currencyCode,
                themeMode: themeMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String businessName,
                Value<String?> ownerName = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                required String themeMode,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BusinessSettingsCompanion.insert(
                id: id,
                businessName: businessName,
                ownerName: ownerName,
                currencyCode: currencyCode,
                themeMode: themeMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessSettingsTable,
      BusinessSettingRecord,
      $$BusinessSettingsTableFilterComposer,
      $$BusinessSettingsTableOrderingComposer,
      $$BusinessSettingsTableAnnotationComposer,
      $$BusinessSettingsTableCreateCompanionBuilder,
      $$BusinessSettingsTableUpdateCompanionBuilder,
      (
        BusinessSettingRecord,
        BaseReferences<
          _$AppDatabase,
          $BusinessSettingsTable,
          BusinessSettingRecord
        >,
      ),
      BusinessSettingRecord,
      PrefetchHooks Function()
    >;
typedef $$CreditPaymentsTableCreateCompanionBuilder =
    CreditPaymentsCompanion Function({
      required String id,
      required String transactionId,
      required int paymentAmount,
      required DateTime paymentDate,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CreditPaymentsTableUpdateCompanionBuilder =
    CreditPaymentsCompanion Function({
      Value<String> id,
      Value<String> transactionId,
      Value<int> paymentAmount,
      Value<DateTime> paymentDate,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$CreditPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $CreditPaymentsTable> {
  $$CreditPaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentAmount => $composableBuilder(
    column: $table.paymentAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CreditPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditPaymentsTable> {
  $$CreditPaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentAmount => $composableBuilder(
    column: $table.paymentAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreditPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditPaymentsTable> {
  $$CreditPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentAmount => $composableBuilder(
    column: $table.paymentAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CreditPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditPaymentsTable,
          CreditPaymentRecord,
          $$CreditPaymentsTableFilterComposer,
          $$CreditPaymentsTableOrderingComposer,
          $$CreditPaymentsTableAnnotationComposer,
          $$CreditPaymentsTableCreateCompanionBuilder,
          $$CreditPaymentsTableUpdateCompanionBuilder,
          (
            CreditPaymentRecord,
            BaseReferences<
              _$AppDatabase,
              $CreditPaymentsTable,
              CreditPaymentRecord
            >,
          ),
          CreditPaymentRecord,
          PrefetchHooks Function()
        > {
  $$CreditPaymentsTableTableManager(
    _$AppDatabase db,
    $CreditPaymentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> transactionId = const Value.absent(),
                Value<int> paymentAmount = const Value.absent(),
                Value<DateTime> paymentDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditPaymentsCompanion(
                id: id,
                transactionId: transactionId,
                paymentAmount: paymentAmount,
                paymentDate: paymentDate,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String transactionId,
                required int paymentAmount,
                required DateTime paymentDate,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CreditPaymentsCompanion.insert(
                id: id,
                transactionId: transactionId,
                paymentAmount: paymentAmount,
                paymentDate: paymentDate,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CreditPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditPaymentsTable,
      CreditPaymentRecord,
      $$CreditPaymentsTableFilterComposer,
      $$CreditPaymentsTableOrderingComposer,
      $$CreditPaymentsTableAnnotationComposer,
      $$CreditPaymentsTableCreateCompanionBuilder,
      $$CreditPaymentsTableUpdateCompanionBuilder,
      (
        CreditPaymentRecord,
        BaseReferences<
          _$AppDatabase,
          $CreditPaymentsTable,
          CreditPaymentRecord
        >,
      ),
      CreditPaymentRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$BusinessSettingsTableTableManager get businessSettings =>
      $$BusinessSettingsTableTableManager(_db, _db.businessSettings);
  $$CreditPaymentsTableTableManager get creditPayments =>
      $$CreditPaymentsTableTableManager(_db, _db.creditPayments);
}
