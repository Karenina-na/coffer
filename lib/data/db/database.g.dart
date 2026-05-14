// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNoMeta = const VerificationMeta(
    'accountNo',
  );
  @override
  late final GeneratedColumn<String> accountNo = GeneratedColumn<String>(
    'account_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sovereigntyRegionMeta = const VerificationMeta(
    'sovereigntyRegion',
  );
  @override
  late final GeneratedColumn<String> sovereigntyRegion =
      GeneratedColumn<String>(
        'sovereignty_region',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _institutionNameMeta = const VerificationMeta(
    'institutionName',
  );
  @override
  late final GeneratedColumn<String> institutionName = GeneratedColumn<String>(
    'institution_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extInfoMeta = const VerificationMeta(
    'extInfo',
  );
  @override
  late final GeneratedColumn<String> extInfo = GeneratedColumn<String>(
    'ext_info',
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
  static const VerificationMeta _fxSpreadPercentMeta = const VerificationMeta(
    'fxSpreadPercent',
  );
  @override
  late final GeneratedColumn<double> fxSpreadPercent = GeneratedColumn<double>(
    'fx_spread_percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountNo,
    accountType,
    sovereigntyRegion,
    institutionName,
    status,
    openedAt,
    extInfo,
    createdAt,
    updatedAt,
    fxSpreadPercent,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_no')) {
      context.handle(
        _accountNoMeta,
        accountNo.isAcceptableOrUnknown(data['account_no']!, _accountNoMeta),
      );
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('sovereignty_region')) {
      context.handle(
        _sovereigntyRegionMeta,
        sovereigntyRegion.isAcceptableOrUnknown(
          data['sovereignty_region']!,
          _sovereigntyRegionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sovereigntyRegionMeta);
    }
    if (data.containsKey('institution_name')) {
      context.handle(
        _institutionNameMeta,
        institutionName.isAcceptableOrUnknown(
          data['institution_name']!,
          _institutionNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_institutionNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    }
    if (data.containsKey('ext_info')) {
      context.handle(
        _extInfoMeta,
        extInfo.isAcceptableOrUnknown(data['ext_info']!, _extInfoMeta),
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
    if (data.containsKey('fx_spread_percent')) {
      context.handle(
        _fxSpreadPercentMeta,
        fxSpreadPercent.isAcceptableOrUnknown(
          data['fx_spread_percent']!,
          _fxSpreadPercentMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_no'],
      ),
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      sovereigntyRegion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sovereignty_region'],
      )!,
      institutionName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      ),
      extInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ext_info'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      fxSpreadPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fx_spread_percent'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final String id;
  final String? accountNo;
  final String accountType;
  final String sovereigntyRegion;
  final String institutionName;
  final String status;
  final DateTime? openedAt;
  final String? extInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double fxSpreadPercent;
  final bool isDeleted;
  const AccountRow({
    required this.id,
    this.accountNo,
    required this.accountType,
    required this.sovereigntyRegion,
    required this.institutionName,
    required this.status,
    this.openedAt,
    this.extInfo,
    required this.createdAt,
    required this.updatedAt,
    required this.fxSpreadPercent,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || accountNo != null) {
      map['account_no'] = Variable<String>(accountNo);
    }
    map['account_type'] = Variable<String>(accountType);
    map['sovereignty_region'] = Variable<String>(sovereigntyRegion);
    map['institution_name'] = Variable<String>(institutionName);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || openedAt != null) {
      map['opened_at'] = Variable<DateTime>(openedAt);
    }
    if (!nullToAbsent || extInfo != null) {
      map['ext_info'] = Variable<String>(extInfo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['fx_spread_percent'] = Variable<double>(fxSpreadPercent);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      accountNo: accountNo == null && nullToAbsent
          ? const Value.absent()
          : Value(accountNo),
      accountType: Value(accountType),
      sovereigntyRegion: Value(sovereigntyRegion),
      institutionName: Value(institutionName),
      status: Value(status),
      openedAt: openedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(openedAt),
      extInfo: extInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(extInfo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      fxSpreadPercent: Value(fxSpreadPercent),
      isDeleted: Value(isDeleted),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<String>(json['id']),
      accountNo: serializer.fromJson<String?>(json['accountNo']),
      accountType: serializer.fromJson<String>(json['accountType']),
      sovereigntyRegion: serializer.fromJson<String>(json['sovereigntyRegion']),
      institutionName: serializer.fromJson<String>(json['institutionName']),
      status: serializer.fromJson<String>(json['status']),
      openedAt: serializer.fromJson<DateTime?>(json['openedAt']),
      extInfo: serializer.fromJson<String?>(json['extInfo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      fxSpreadPercent: serializer.fromJson<double>(json['fxSpreadPercent']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountNo': serializer.toJson<String?>(accountNo),
      'accountType': serializer.toJson<String>(accountType),
      'sovereigntyRegion': serializer.toJson<String>(sovereigntyRegion),
      'institutionName': serializer.toJson<String>(institutionName),
      'status': serializer.toJson<String>(status),
      'openedAt': serializer.toJson<DateTime?>(openedAt),
      'extInfo': serializer.toJson<String?>(extInfo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'fxSpreadPercent': serializer.toJson<double>(fxSpreadPercent),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  AccountRow copyWith({
    String? id,
    Value<String?> accountNo = const Value.absent(),
    String? accountType,
    String? sovereigntyRegion,
    String? institutionName,
    String? status,
    Value<DateTime?> openedAt = const Value.absent(),
    Value<String?> extInfo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    double? fxSpreadPercent,
    bool? isDeleted,
  }) => AccountRow(
    id: id ?? this.id,
    accountNo: accountNo.present ? accountNo.value : this.accountNo,
    accountType: accountType ?? this.accountType,
    sovereigntyRegion: sovereigntyRegion ?? this.sovereigntyRegion,
    institutionName: institutionName ?? this.institutionName,
    status: status ?? this.status,
    openedAt: openedAt.present ? openedAt.value : this.openedAt,
    extInfo: extInfo.present ? extInfo.value : this.extInfo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    fxSpreadPercent: fxSpreadPercent ?? this.fxSpreadPercent,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      accountNo: data.accountNo.present ? data.accountNo.value : this.accountNo,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      sovereigntyRegion: data.sovereigntyRegion.present
          ? data.sovereigntyRegion.value
          : this.sovereigntyRegion,
      institutionName: data.institutionName.present
          ? data.institutionName.value
          : this.institutionName,
      status: data.status.present ? data.status.value : this.status,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      extInfo: data.extInfo.present ? data.extInfo.value : this.extInfo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      fxSpreadPercent: data.fxSpreadPercent.present
          ? data.fxSpreadPercent.value
          : this.fxSpreadPercent,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('accountNo: $accountNo, ')
          ..write('accountType: $accountType, ')
          ..write('sovereigntyRegion: $sovereigntyRegion, ')
          ..write('institutionName: $institutionName, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('extInfo: $extInfo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fxSpreadPercent: $fxSpreadPercent, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountNo,
    accountType,
    sovereigntyRegion,
    institutionName,
    status,
    openedAt,
    extInfo,
    createdAt,
    updatedAt,
    fxSpreadPercent,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.accountNo == this.accountNo &&
          other.accountType == this.accountType &&
          other.sovereigntyRegion == this.sovereigntyRegion &&
          other.institutionName == this.institutionName &&
          other.status == this.status &&
          other.openedAt == this.openedAt &&
          other.extInfo == this.extInfo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.fxSpreadPercent == this.fxSpreadPercent &&
          other.isDeleted == this.isDeleted);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<String> id;
  final Value<String?> accountNo;
  final Value<String> accountType;
  final Value<String> sovereigntyRegion;
  final Value<String> institutionName;
  final Value<String> status;
  final Value<DateTime?> openedAt;
  final Value<String?> extInfo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<double> fxSpreadPercent;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.accountNo = const Value.absent(),
    this.accountType = const Value.absent(),
    this.sovereigntyRegion = const Value.absent(),
    this.institutionName = const Value.absent(),
    this.status = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.extInfo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.fxSpreadPercent = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    this.accountNo = const Value.absent(),
    required String accountType,
    required String sovereigntyRegion,
    required String institutionName,
    required String status,
    this.openedAt = const Value.absent(),
    this.extInfo = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.fxSpreadPercent = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountType = Value(accountType),
       sovereigntyRegion = Value(sovereigntyRegion),
       institutionName = Value(institutionName),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AccountRow> custom({
    Expression<String>? id,
    Expression<String>? accountNo,
    Expression<String>? accountType,
    Expression<String>? sovereigntyRegion,
    Expression<String>? institutionName,
    Expression<String>? status,
    Expression<DateTime>? openedAt,
    Expression<String>? extInfo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<double>? fxSpreadPercent,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountNo != null) 'account_no': accountNo,
      if (accountType != null) 'account_type': accountType,
      if (sovereigntyRegion != null) 'sovereignty_region': sovereigntyRegion,
      if (institutionName != null) 'institution_name': institutionName,
      if (status != null) 'status': status,
      if (openedAt != null) 'opened_at': openedAt,
      if (extInfo != null) 'ext_info': extInfo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (fxSpreadPercent != null) 'fx_spread_percent': fxSpreadPercent,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String?>? accountNo,
    Value<String>? accountType,
    Value<String>? sovereigntyRegion,
    Value<String>? institutionName,
    Value<String>? status,
    Value<DateTime?>? openedAt,
    Value<String?>? extInfo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<double>? fxSpreadPercent,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      accountNo: accountNo ?? this.accountNo,
      accountType: accountType ?? this.accountType,
      sovereigntyRegion: sovereigntyRegion ?? this.sovereigntyRegion,
      institutionName: institutionName ?? this.institutionName,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      extInfo: extInfo ?? this.extInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fxSpreadPercent: fxSpreadPercent ?? this.fxSpreadPercent,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountNo.present) {
      map['account_no'] = Variable<String>(accountNo.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (sovereigntyRegion.present) {
      map['sovereignty_region'] = Variable<String>(sovereigntyRegion.value);
    }
    if (institutionName.present) {
      map['institution_name'] = Variable<String>(institutionName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (extInfo.present) {
      map['ext_info'] = Variable<String>(extInfo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (fxSpreadPercent.present) {
      map['fx_spread_percent'] = Variable<double>(fxSpreadPercent.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('accountNo: $accountNo, ')
          ..write('accountType: $accountType, ')
          ..write('sovereigntyRegion: $sovereigntyRegion, ')
          ..write('institutionName: $institutionName, ')
          ..write('status: $status, ')
          ..write('openedAt: $openedAt, ')
          ..write('extInfo: $extInfo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fxSpreadPercent: $fxSpreadPercent, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels
    with TableInfo<$ChannelsTable, ChannelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _transferProtocolMeta = const VerificationMeta(
    'transferProtocol',
  );
  @override
  late final GeneratedColumn<String> transferProtocol = GeneratedColumn<String>(
    'transfer_protocol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _feeRateMeta = const VerificationMeta(
    'feeRate',
  );
  @override
  late final GeneratedColumn<String> feeRate = GeneratedColumn<String>(
    'fee_rate',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedFeeMeta = const VerificationMeta(
    'fixedFee',
  );
  @override
  late final GeneratedColumn<String> fixedFee = GeneratedColumn<String>(
    'fixed_fee',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sovereigntyRegionRuleMeta =
      const VerificationMeta('sovereigntyRegionRule');
  @override
  late final GeneratedColumn<String> sovereigntyRegionRule =
      GeneratedColumn<String>(
        'sovereignty_region_rule',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _limitCurrencyMeta = const VerificationMeta(
    'limitCurrency',
  );
  @override
  late final GeneratedColumn<String> limitCurrency = GeneratedColumn<String>(
    'limit_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyLimitMeta = const VerificationMeta(
    'dailyLimit',
  );
  @override
  late final GeneratedColumn<String> dailyLimit = GeneratedColumn<String>(
    'daily_limit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _singleLimitMeta = const VerificationMeta(
    'singleLimit',
  );
  @override
  late final GeneratedColumn<String> singleLimit = GeneratedColumn<String>(
    'single_limit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveFrom =
      GeneratedColumn<DateTime>(
        'effective_from',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _effectiveToMeta = const VerificationMeta(
    'effectiveTo',
  );
  @override
  late final GeneratedColumn<DateTime> effectiveTo = GeneratedColumn<DateTime>(
    'effective_to',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
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
    name,
    transferProtocol,
    isBuiltin,
    feeRate,
    fixedFee,
    sovereigntyRegionRule,
    limitCurrency,
    dailyLimit,
    singleLimit,
    status,
    sortOrder,
    effectiveFrom,
    effectiveTo,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('transfer_protocol')) {
      context.handle(
        _transferProtocolMeta,
        transferProtocol.isAcceptableOrUnknown(
          data['transfer_protocol']!,
          _transferProtocolMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferProtocolMeta);
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
      );
    }
    if (data.containsKey('fee_rate')) {
      context.handle(
        _feeRateMeta,
        feeRate.isAcceptableOrUnknown(data['fee_rate']!, _feeRateMeta),
      );
    }
    if (data.containsKey('fixed_fee')) {
      context.handle(
        _fixedFeeMeta,
        fixedFee.isAcceptableOrUnknown(data['fixed_fee']!, _fixedFeeMeta),
      );
    }
    if (data.containsKey('sovereignty_region_rule')) {
      context.handle(
        _sovereigntyRegionRuleMeta,
        sovereigntyRegionRule.isAcceptableOrUnknown(
          data['sovereignty_region_rule']!,
          _sovereigntyRegionRuleMeta,
        ),
      );
    }
    if (data.containsKey('limit_currency')) {
      context.handle(
        _limitCurrencyMeta,
        limitCurrency.isAcceptableOrUnknown(
          data['limit_currency']!,
          _limitCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('daily_limit')) {
      context.handle(
        _dailyLimitMeta,
        dailyLimit.isAcceptableOrUnknown(data['daily_limit']!, _dailyLimitMeta),
      );
    }
    if (data.containsKey('single_limit')) {
      context.handle(
        _singleLimitMeta,
        singleLimit.isAcceptableOrUnknown(
          data['single_limit']!,
          _singleLimitMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    }
    if (data.containsKey('effective_to')) {
      context.handle(
        _effectiveToMeta,
        effectiveTo.isAcceptableOrUnknown(
          data['effective_to']!,
          _effectiveToMeta,
        ),
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
  ChannelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      transferProtocol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_protocol'],
      )!,
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_builtin'],
      )!,
      feeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fee_rate'],
      ),
      fixedFee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_fee'],
      ),
      sovereigntyRegionRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sovereignty_region_rule'],
      ),
      limitCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}limit_currency'],
      ),
      dailyLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_limit'],
      ),
      singleLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}single_limit'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_from'],
      ),
      effectiveTo: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}effective_to'],
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
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class ChannelRow extends DataClass implements Insertable<ChannelRow> {
  final String id;
  final String name;
  final String transferProtocol;
  final bool isBuiltin;
  final String? feeRate;
  final String? fixedFee;
  final String? sovereigntyRegionRule;
  final String? limitCurrency;
  final String? dailyLimit;
  final String? singleLimit;
  final String status;
  final int sortOrder;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChannelRow({
    required this.id,
    required this.name,
    required this.transferProtocol,
    required this.isBuiltin,
    this.feeRate,
    this.fixedFee,
    this.sovereigntyRegionRule,
    this.limitCurrency,
    this.dailyLimit,
    this.singleLimit,
    required this.status,
    required this.sortOrder,
    this.effectiveFrom,
    this.effectiveTo,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['transfer_protocol'] = Variable<String>(transferProtocol);
    map['is_builtin'] = Variable<bool>(isBuiltin);
    if (!nullToAbsent || feeRate != null) {
      map['fee_rate'] = Variable<String>(feeRate);
    }
    if (!nullToAbsent || fixedFee != null) {
      map['fixed_fee'] = Variable<String>(fixedFee);
    }
    if (!nullToAbsent || sovereigntyRegionRule != null) {
      map['sovereignty_region_rule'] = Variable<String>(sovereigntyRegionRule);
    }
    if (!nullToAbsent || limitCurrency != null) {
      map['limit_currency'] = Variable<String>(limitCurrency);
    }
    if (!nullToAbsent || dailyLimit != null) {
      map['daily_limit'] = Variable<String>(dailyLimit);
    }
    if (!nullToAbsent || singleLimit != null) {
      map['single_limit'] = Variable<String>(singleLimit);
    }
    map['status'] = Variable<String>(status);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || effectiveFrom != null) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom);
    }
    if (!nullToAbsent || effectiveTo != null) {
      map['effective_to'] = Variable<DateTime>(effectiveTo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      name: Value(name),
      transferProtocol: Value(transferProtocol),
      isBuiltin: Value(isBuiltin),
      feeRate: feeRate == null && nullToAbsent
          ? const Value.absent()
          : Value(feeRate),
      fixedFee: fixedFee == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedFee),
      sovereigntyRegionRule: sovereigntyRegionRule == null && nullToAbsent
          ? const Value.absent()
          : Value(sovereigntyRegionRule),
      limitCurrency: limitCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(limitCurrency),
      dailyLimit: dailyLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyLimit),
      singleLimit: singleLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(singleLimit),
      status: Value(status),
      sortOrder: Value(sortOrder),
      effectiveFrom: effectiveFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveFrom),
      effectiveTo: effectiveTo == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveTo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChannelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      transferProtocol: serializer.fromJson<String>(json['transferProtocol']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
      feeRate: serializer.fromJson<String?>(json['feeRate']),
      fixedFee: serializer.fromJson<String?>(json['fixedFee']),
      sovereigntyRegionRule: serializer.fromJson<String?>(
        json['sovereigntyRegionRule'],
      ),
      limitCurrency: serializer.fromJson<String?>(json['limitCurrency']),
      dailyLimit: serializer.fromJson<String?>(json['dailyLimit']),
      singleLimit: serializer.fromJson<String?>(json['singleLimit']),
      status: serializer.fromJson<String>(json['status']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      effectiveFrom: serializer.fromJson<DateTime?>(json['effectiveFrom']),
      effectiveTo: serializer.fromJson<DateTime?>(json['effectiveTo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'transferProtocol': serializer.toJson<String>(transferProtocol),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
      'feeRate': serializer.toJson<String?>(feeRate),
      'fixedFee': serializer.toJson<String?>(fixedFee),
      'sovereigntyRegionRule': serializer.toJson<String?>(
        sovereigntyRegionRule,
      ),
      'limitCurrency': serializer.toJson<String?>(limitCurrency),
      'dailyLimit': serializer.toJson<String?>(dailyLimit),
      'singleLimit': serializer.toJson<String?>(singleLimit),
      'status': serializer.toJson<String>(status),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'effectiveFrom': serializer.toJson<DateTime?>(effectiveFrom),
      'effectiveTo': serializer.toJson<DateTime?>(effectiveTo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChannelRow copyWith({
    String? id,
    String? name,
    String? transferProtocol,
    bool? isBuiltin,
    Value<String?> feeRate = const Value.absent(),
    Value<String?> fixedFee = const Value.absent(),
    Value<String?> sovereigntyRegionRule = const Value.absent(),
    Value<String?> limitCurrency = const Value.absent(),
    Value<String?> dailyLimit = const Value.absent(),
    Value<String?> singleLimit = const Value.absent(),
    String? status,
    int? sortOrder,
    Value<DateTime?> effectiveFrom = const Value.absent(),
    Value<DateTime?> effectiveTo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChannelRow(
    id: id ?? this.id,
    name: name ?? this.name,
    transferProtocol: transferProtocol ?? this.transferProtocol,
    isBuiltin: isBuiltin ?? this.isBuiltin,
    feeRate: feeRate.present ? feeRate.value : this.feeRate,
    fixedFee: fixedFee.present ? fixedFee.value : this.fixedFee,
    sovereigntyRegionRule: sovereigntyRegionRule.present
        ? sovereigntyRegionRule.value
        : this.sovereigntyRegionRule,
    limitCurrency: limitCurrency.present
        ? limitCurrency.value
        : this.limitCurrency,
    dailyLimit: dailyLimit.present ? dailyLimit.value : this.dailyLimit,
    singleLimit: singleLimit.present ? singleLimit.value : this.singleLimit,
    status: status ?? this.status,
    sortOrder: sortOrder ?? this.sortOrder,
    effectiveFrom: effectiveFrom.present
        ? effectiveFrom.value
        : this.effectiveFrom,
    effectiveTo: effectiveTo.present ? effectiveTo.value : this.effectiveTo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChannelRow copyWithCompanion(ChannelsCompanion data) {
    return ChannelRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      transferProtocol: data.transferProtocol.present
          ? data.transferProtocol.value
          : this.transferProtocol,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      feeRate: data.feeRate.present ? data.feeRate.value : this.feeRate,
      fixedFee: data.fixedFee.present ? data.fixedFee.value : this.fixedFee,
      sovereigntyRegionRule: data.sovereigntyRegionRule.present
          ? data.sovereigntyRegionRule.value
          : this.sovereigntyRegionRule,
      limitCurrency: data.limitCurrency.present
          ? data.limitCurrency.value
          : this.limitCurrency,
      dailyLimit: data.dailyLimit.present
          ? data.dailyLimit.value
          : this.dailyLimit,
      singleLimit: data.singleLimit.present
          ? data.singleLimit.value
          : this.singleLimit,
      status: data.status.present ? data.status.value : this.status,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      effectiveTo: data.effectiveTo.present
          ? data.effectiveTo.value
          : this.effectiveTo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('transferProtocol: $transferProtocol, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('feeRate: $feeRate, ')
          ..write('fixedFee: $fixedFee, ')
          ..write('sovereigntyRegionRule: $sovereigntyRegionRule, ')
          ..write('limitCurrency: $limitCurrency, ')
          ..write('dailyLimit: $dailyLimit, ')
          ..write('singleLimit: $singleLimit, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveTo: $effectiveTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    transferProtocol,
    isBuiltin,
    feeRate,
    fixedFee,
    sovereigntyRegionRule,
    limitCurrency,
    dailyLimit,
    singleLimit,
    status,
    sortOrder,
    effectiveFrom,
    effectiveTo,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.transferProtocol == this.transferProtocol &&
          other.isBuiltin == this.isBuiltin &&
          other.feeRate == this.feeRate &&
          other.fixedFee == this.fixedFee &&
          other.sovereigntyRegionRule == this.sovereigntyRegionRule &&
          other.limitCurrency == this.limitCurrency &&
          other.dailyLimit == this.dailyLimit &&
          other.singleLimit == this.singleLimit &&
          other.status == this.status &&
          other.sortOrder == this.sortOrder &&
          other.effectiveFrom == this.effectiveFrom &&
          other.effectiveTo == this.effectiveTo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChannelsCompanion extends UpdateCompanion<ChannelRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> transferProtocol;
  final Value<bool> isBuiltin;
  final Value<String?> feeRate;
  final Value<String?> fixedFee;
  final Value<String?> sovereigntyRegionRule;
  final Value<String?> limitCurrency;
  final Value<String?> dailyLimit;
  final Value<String?> singleLimit;
  final Value<String> status;
  final Value<int> sortOrder;
  final Value<DateTime?> effectiveFrom;
  final Value<DateTime?> effectiveTo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.transferProtocol = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.feeRate = const Value.absent(),
    this.fixedFee = const Value.absent(),
    this.sovereigntyRegionRule = const Value.absent(),
    this.limitCurrency = const Value.absent(),
    this.dailyLimit = const Value.absent(),
    this.singleLimit = const Value.absent(),
    this.status = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.effectiveTo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelsCompanion.insert({
    required String id,
    required String name,
    required String transferProtocol,
    this.isBuiltin = const Value.absent(),
    this.feeRate = const Value.absent(),
    this.fixedFee = const Value.absent(),
    this.sovereigntyRegionRule = const Value.absent(),
    this.limitCurrency = const Value.absent(),
    this.dailyLimit = const Value.absent(),
    this.singleLimit = const Value.absent(),
    required String status,
    this.sortOrder = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.effectiveTo = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       transferProtocol = Value(transferProtocol),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ChannelRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? transferProtocol,
    Expression<bool>? isBuiltin,
    Expression<String>? feeRate,
    Expression<String>? fixedFee,
    Expression<String>? sovereigntyRegionRule,
    Expression<String>? limitCurrency,
    Expression<String>? dailyLimit,
    Expression<String>? singleLimit,
    Expression<String>? status,
    Expression<int>? sortOrder,
    Expression<DateTime>? effectiveFrom,
    Expression<DateTime>? effectiveTo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (transferProtocol != null) 'transfer_protocol': transferProtocol,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (feeRate != null) 'fee_rate': feeRate,
      if (fixedFee != null) 'fixed_fee': fixedFee,
      if (sovereigntyRegionRule != null)
        'sovereignty_region_rule': sovereigntyRegionRule,
      if (limitCurrency != null) 'limit_currency': limitCurrency,
      if (dailyLimit != null) 'daily_limit': dailyLimit,
      if (singleLimit != null) 'single_limit': singleLimit,
      if (status != null) 'status': status,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (effectiveTo != null) 'effective_to': effectiveTo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? transferProtocol,
    Value<bool>? isBuiltin,
    Value<String?>? feeRate,
    Value<String?>? fixedFee,
    Value<String?>? sovereigntyRegionRule,
    Value<String?>? limitCurrency,
    Value<String?>? dailyLimit,
    Value<String?>? singleLimit,
    Value<String>? status,
    Value<int>? sortOrder,
    Value<DateTime?>? effectiveFrom,
    Value<DateTime?>? effectiveTo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      transferProtocol: transferProtocol ?? this.transferProtocol,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      feeRate: feeRate ?? this.feeRate,
      fixedFee: fixedFee ?? this.fixedFee,
      sovereigntyRegionRule:
          sovereigntyRegionRule ?? this.sovereigntyRegionRule,
      limitCurrency: limitCurrency ?? this.limitCurrency,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      singleLimit: singleLimit ?? this.singleLimit,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      effectiveTo: effectiveTo ?? this.effectiveTo,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (transferProtocol.present) {
      map['transfer_protocol'] = Variable<String>(transferProtocol.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    if (feeRate.present) {
      map['fee_rate'] = Variable<String>(feeRate.value);
    }
    if (fixedFee.present) {
      map['fixed_fee'] = Variable<String>(fixedFee.value);
    }
    if (sovereigntyRegionRule.present) {
      map['sovereignty_region_rule'] = Variable<String>(
        sovereigntyRegionRule.value,
      );
    }
    if (limitCurrency.present) {
      map['limit_currency'] = Variable<String>(limitCurrency.value);
    }
    if (dailyLimit.present) {
      map['daily_limit'] = Variable<String>(dailyLimit.value);
    }
    if (singleLimit.present) {
      map['single_limit'] = Variable<String>(singleLimit.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<DateTime>(effectiveFrom.value);
    }
    if (effectiveTo.present) {
      map['effective_to'] = Variable<DateTime>(effectiveTo.value);
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
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('transferProtocol: $transferProtocol, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('feeRate: $feeRate, ')
          ..write('fixedFee: $fixedFee, ')
          ..write('sovereigntyRegionRule: $sovereigntyRegionRule, ')
          ..write('limitCurrency: $limitCurrency, ')
          ..write('dailyLimit: $dailyLimit, ')
          ..write('singleLimit: $singleLimit, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('effectiveTo: $effectiveTo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountChannelsTable extends AccountChannels
    with TableInfo<$AccountChannelsTable, AccountChannelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES channels (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _feeRateOverrideMeta = const VerificationMeta(
    'feeRateOverride',
  );
  @override
  late final GeneratedColumn<String> feeRateOverride = GeneratedColumn<String>(
    'fee_rate_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fixedFeeOverrideMeta = const VerificationMeta(
    'fixedFeeOverride',
  );
  @override
  late final GeneratedColumn<String> fixedFeeOverride = GeneratedColumn<String>(
    'fixed_fee_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feeCurrencyOverrideMeta =
      const VerificationMeta('feeCurrencyOverride');
  @override
  late final GeneratedColumn<String> feeCurrencyOverride =
      GeneratedColumn<String>(
        'fee_currency_override',
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
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    channelId,
    feeRateOverride,
    fixedFeeOverride,
    feeCurrencyOverride,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountChannelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('fee_rate_override')) {
      context.handle(
        _feeRateOverrideMeta,
        feeRateOverride.isAcceptableOrUnknown(
          data['fee_rate_override']!,
          _feeRateOverrideMeta,
        ),
      );
    }
    if (data.containsKey('fixed_fee_override')) {
      context.handle(
        _fixedFeeOverrideMeta,
        fixedFeeOverride.isAcceptableOrUnknown(
          data['fixed_fee_override']!,
          _fixedFeeOverrideMeta,
        ),
      );
    }
    if (data.containsKey('fee_currency_override')) {
      context.handle(
        _feeCurrencyOverrideMeta,
        feeCurrencyOverride.isAcceptableOrUnknown(
          data['fee_currency_override']!,
          _feeCurrencyOverrideMeta,
        ),
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
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, channelId};
  @override
  AccountChannelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountChannelRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      feeRateOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fee_rate_override'],
      ),
      fixedFeeOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_fee_override'],
      ),
      feeCurrencyOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fee_currency_override'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $AccountChannelsTable createAlias(String alias) {
    return $AccountChannelsTable(attachedDatabase, alias);
  }
}

class AccountChannelRow extends DataClass
    implements Insertable<AccountChannelRow> {
  final String accountId;
  final String channelId;
  final String? feeRateOverride;
  final String? fixedFeeOverride;
  final String? feeCurrencyOverride;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const AccountChannelRow({
    required this.accountId,
    required this.channelId,
    this.feeRateOverride,
    this.fixedFeeOverride,
    this.feeCurrencyOverride,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['channel_id'] = Variable<String>(channelId);
    if (!nullToAbsent || feeRateOverride != null) {
      map['fee_rate_override'] = Variable<String>(feeRateOverride);
    }
    if (!nullToAbsent || fixedFeeOverride != null) {
      map['fixed_fee_override'] = Variable<String>(fixedFeeOverride);
    }
    if (!nullToAbsent || feeCurrencyOverride != null) {
      map['fee_currency_override'] = Variable<String>(feeCurrencyOverride);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  AccountChannelsCompanion toCompanion(bool nullToAbsent) {
    return AccountChannelsCompanion(
      accountId: Value(accountId),
      channelId: Value(channelId),
      feeRateOverride: feeRateOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(feeRateOverride),
      fixedFeeOverride: fixedFeeOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(fixedFeeOverride),
      feeCurrencyOverride: feeCurrencyOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(feeCurrencyOverride),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory AccountChannelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountChannelRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      feeRateOverride: serializer.fromJson<String?>(json['feeRateOverride']),
      fixedFeeOverride: serializer.fromJson<String?>(json['fixedFeeOverride']),
      feeCurrencyOverride: serializer.fromJson<String?>(
        json['feeCurrencyOverride'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'channelId': serializer.toJson<String>(channelId),
      'feeRateOverride': serializer.toJson<String?>(feeRateOverride),
      'fixedFeeOverride': serializer.toJson<String?>(fixedFeeOverride),
      'feeCurrencyOverride': serializer.toJson<String?>(feeCurrencyOverride),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  AccountChannelRow copyWith({
    String? accountId,
    String? channelId,
    Value<String?> feeRateOverride = const Value.absent(),
    Value<String?> fixedFeeOverride = const Value.absent(),
    Value<String?> feeCurrencyOverride = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => AccountChannelRow(
    accountId: accountId ?? this.accountId,
    channelId: channelId ?? this.channelId,
    feeRateOverride: feeRateOverride.present
        ? feeRateOverride.value
        : this.feeRateOverride,
    fixedFeeOverride: fixedFeeOverride.present
        ? fixedFeeOverride.value
        : this.fixedFeeOverride,
    feeCurrencyOverride: feeCurrencyOverride.present
        ? feeCurrencyOverride.value
        : this.feeCurrencyOverride,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  AccountChannelRow copyWithCompanion(AccountChannelsCompanion data) {
    return AccountChannelRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      feeRateOverride: data.feeRateOverride.present
          ? data.feeRateOverride.value
          : this.feeRateOverride,
      fixedFeeOverride: data.fixedFeeOverride.present
          ? data.fixedFeeOverride.value
          : this.fixedFeeOverride,
      feeCurrencyOverride: data.feeCurrencyOverride.present
          ? data.feeCurrencyOverride.value
          : this.feeCurrencyOverride,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountChannelRow(')
          ..write('accountId: $accountId, ')
          ..write('channelId: $channelId, ')
          ..write('feeRateOverride: $feeRateOverride, ')
          ..write('fixedFeeOverride: $fixedFeeOverride, ')
          ..write('feeCurrencyOverride: $feeCurrencyOverride, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    channelId,
    feeRateOverride,
    fixedFeeOverride,
    feeCurrencyOverride,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountChannelRow &&
          other.accountId == this.accountId &&
          other.channelId == this.channelId &&
          other.feeRateOverride == this.feeRateOverride &&
          other.fixedFeeOverride == this.fixedFeeOverride &&
          other.feeCurrencyOverride == this.feeCurrencyOverride &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountChannelsCompanion extends UpdateCompanion<AccountChannelRow> {
  final Value<String> accountId;
  final Value<String> channelId;
  final Value<String?> feeRateOverride;
  final Value<String?> fixedFeeOverride;
  final Value<String?> feeCurrencyOverride;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const AccountChannelsCompanion({
    this.accountId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.feeRateOverride = const Value.absent(),
    this.fixedFeeOverride = const Value.absent(),
    this.feeCurrencyOverride = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountChannelsCompanion.insert({
    required String accountId,
    required String channelId,
    this.feeRateOverride = const Value.absent(),
    this.fixedFeeOverride = const Value.absent(),
    this.feeCurrencyOverride = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       channelId = Value(channelId),
       createdAt = Value(createdAt);
  static Insertable<AccountChannelRow> custom({
    Expression<String>? accountId,
    Expression<String>? channelId,
    Expression<String>? feeRateOverride,
    Expression<String>? fixedFeeOverride,
    Expression<String>? feeCurrencyOverride,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (channelId != null) 'channel_id': channelId,
      if (feeRateOverride != null) 'fee_rate_override': feeRateOverride,
      if (fixedFeeOverride != null) 'fixed_fee_override': fixedFeeOverride,
      if (feeCurrencyOverride != null)
        'fee_currency_override': feeCurrencyOverride,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountChannelsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? channelId,
    Value<String?>? feeRateOverride,
    Value<String?>? fixedFeeOverride,
    Value<String?>? feeCurrencyOverride,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return AccountChannelsCompanion(
      accountId: accountId ?? this.accountId,
      channelId: channelId ?? this.channelId,
      feeRateOverride: feeRateOverride ?? this.feeRateOverride,
      fixedFeeOverride: fixedFeeOverride ?? this.fixedFeeOverride,
      feeCurrencyOverride: feeCurrencyOverride ?? this.feeCurrencyOverride,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (feeRateOverride.present) {
      map['fee_rate_override'] = Variable<String>(feeRateOverride.value);
    }
    if (fixedFeeOverride.present) {
      map['fixed_fee_override'] = Variable<String>(fixedFeeOverride.value);
    }
    if (feeCurrencyOverride.present) {
      map['fee_currency_override'] = Variable<String>(
        feeCurrencyOverride.value,
      );
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
    return (StringBuffer('AccountChannelsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('channelId: $channelId, ')
          ..write('feeRateOverride: $feeRateOverride, ')
          ..write('fixedFeeOverride: $fixedFeeOverride, ')
          ..write('feeCurrencyOverride: $feeCurrencyOverride, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, AssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _assetTypeMeta = const VerificationMeta(
    'assetType',
  );
  @override
  late final GeneratedColumn<String> assetType = GeneratedColumn<String>(
    'asset_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetCodeMeta = const VerificationMeta(
    'assetCode',
  );
  @override
  late final GeneratedColumn<String> assetCode = GeneratedColumn<String>(
    'asset_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<String> costPrice = GeneratedColumn<String>(
    'cost_price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<String> currentPrice = GeneratedColumn<String>(
    'current_price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marketValueMeta = const VerificationMeta(
    'marketValue',
  );
  @override
  late final GeneratedColumn<String> marketValue = GeneratedColumn<String>(
    'market_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valuationTimeMeta = const VerificationMeta(
    'valuationTime',
  );
  @override
  late final GeneratedColumn<DateTime> valuationTime =
      GeneratedColumn<DateTime>(
        'valuation_time',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extInfoMeta = const VerificationMeta(
    'extInfo',
  );
  @override
  late final GeneratedColumn<String> extInfo = GeneratedColumn<String>(
    'ext_info',
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
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    assetType,
    assetCode,
    quantity,
    costPrice,
    currentPrice,
    currency,
    marketValue,
    valuationTime,
    status,
    extInfo,
    createdAt,
    updatedAt,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('asset_type')) {
      context.handle(
        _assetTypeMeta,
        assetType.isAcceptableOrUnknown(data['asset_type']!, _assetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_assetTypeMeta);
    }
    if (data.containsKey('asset_code')) {
      context.handle(
        _assetCodeMeta,
        assetCode.isAcceptableOrUnknown(data['asset_code']!, _assetCodeMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('market_value')) {
      context.handle(
        _marketValueMeta,
        marketValue.isAcceptableOrUnknown(
          data['market_value']!,
          _marketValueMeta,
        ),
      );
    }
    if (data.containsKey('valuation_time')) {
      context.handle(
        _valuationTimeMeta,
        valuationTime.isAcceptableOrUnknown(
          data['valuation_time']!,
          _valuationTimeMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('ext_info')) {
      context.handle(
        _extInfoMeta,
        extInfo.isAcceptableOrUnknown(data['ext_info']!, _extInfoMeta),
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
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      assetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_type'],
      )!,
      assetCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_code'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_price'],
      ),
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_price'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      marketValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market_value'],
      ),
      valuationTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}valuation_time'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      extInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ext_info'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class AssetRow extends DataClass implements Insertable<AssetRow> {
  final String id;
  final String accountId;
  final String assetType;
  final String? assetCode;
  final String quantity;
  final String? costPrice;
  final String? currentPrice;
  final String currency;
  final String? marketValue;
  final DateTime? valuationTime;
  final String status;
  final String? extInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  const AssetRow({
    required this.id,
    required this.accountId,
    required this.assetType,
    this.assetCode,
    required this.quantity,
    this.costPrice,
    this.currentPrice,
    required this.currency,
    this.marketValue,
    this.valuationTime,
    required this.status,
    this.extInfo,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['asset_type'] = Variable<String>(assetType);
    if (!nullToAbsent || assetCode != null) {
      map['asset_code'] = Variable<String>(assetCode);
    }
    map['quantity'] = Variable<String>(quantity);
    if (!nullToAbsent || costPrice != null) {
      map['cost_price'] = Variable<String>(costPrice);
    }
    if (!nullToAbsent || currentPrice != null) {
      map['current_price'] = Variable<String>(currentPrice);
    }
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || marketValue != null) {
      map['market_value'] = Variable<String>(marketValue);
    }
    if (!nullToAbsent || valuationTime != null) {
      map['valuation_time'] = Variable<DateTime>(valuationTime);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || extInfo != null) {
      map['ext_info'] = Variable<String>(extInfo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      assetType: Value(assetType),
      assetCode: assetCode == null && nullToAbsent
          ? const Value.absent()
          : Value(assetCode),
      quantity: Value(quantity),
      costPrice: costPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(costPrice),
      currentPrice: currentPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPrice),
      currency: Value(currency),
      marketValue: marketValue == null && nullToAbsent
          ? const Value.absent()
          : Value(marketValue),
      valuationTime: valuationTime == null && nullToAbsent
          ? const Value.absent()
          : Value(valuationTime),
      status: Value(status),
      extInfo: extInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(extInfo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory AssetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      assetType: serializer.fromJson<String>(json['assetType']),
      assetCode: serializer.fromJson<String?>(json['assetCode']),
      quantity: serializer.fromJson<String>(json['quantity']),
      costPrice: serializer.fromJson<String?>(json['costPrice']),
      currentPrice: serializer.fromJson<String?>(json['currentPrice']),
      currency: serializer.fromJson<String>(json['currency']),
      marketValue: serializer.fromJson<String?>(json['marketValue']),
      valuationTime: serializer.fromJson<DateTime?>(json['valuationTime']),
      status: serializer.fromJson<String>(json['status']),
      extInfo: serializer.fromJson<String?>(json['extInfo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'assetType': serializer.toJson<String>(assetType),
      'assetCode': serializer.toJson<String?>(assetCode),
      'quantity': serializer.toJson<String>(quantity),
      'costPrice': serializer.toJson<String?>(costPrice),
      'currentPrice': serializer.toJson<String?>(currentPrice),
      'currency': serializer.toJson<String>(currency),
      'marketValue': serializer.toJson<String?>(marketValue),
      'valuationTime': serializer.toJson<DateTime?>(valuationTime),
      'status': serializer.toJson<String>(status),
      'extInfo': serializer.toJson<String?>(extInfo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  AssetRow copyWith({
    String? id,
    String? accountId,
    String? assetType,
    Value<String?> assetCode = const Value.absent(),
    String? quantity,
    Value<String?> costPrice = const Value.absent(),
    Value<String?> currentPrice = const Value.absent(),
    String? currency,
    Value<String?> marketValue = const Value.absent(),
    Value<DateTime?> valuationTime = const Value.absent(),
    String? status,
    Value<String?> extInfo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) => AssetRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    assetType: assetType ?? this.assetType,
    assetCode: assetCode.present ? assetCode.value : this.assetCode,
    quantity: quantity ?? this.quantity,
    costPrice: costPrice.present ? costPrice.value : this.costPrice,
    currentPrice: currentPrice.present ? currentPrice.value : this.currentPrice,
    currency: currency ?? this.currency,
    marketValue: marketValue.present ? marketValue.value : this.marketValue,
    valuationTime: valuationTime.present
        ? valuationTime.value
        : this.valuationTime,
    status: status ?? this.status,
    extInfo: extInfo.present ? extInfo.value : this.extInfo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  AssetRow copyWithCompanion(AssetsCompanion data) {
    return AssetRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      assetType: data.assetType.present ? data.assetType.value : this.assetType,
      assetCode: data.assetCode.present ? data.assetCode.value : this.assetCode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      currency: data.currency.present ? data.currency.value : this.currency,
      marketValue: data.marketValue.present
          ? data.marketValue.value
          : this.marketValue,
      valuationTime: data.valuationTime.present
          ? data.valuationTime.value
          : this.valuationTime,
      status: data.status.present ? data.status.value : this.status,
      extInfo: data.extInfo.present ? data.extInfo.value : this.extInfo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('assetType: $assetType, ')
          ..write('assetCode: $assetCode, ')
          ..write('quantity: $quantity, ')
          ..write('costPrice: $costPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('currency: $currency, ')
          ..write('marketValue: $marketValue, ')
          ..write('valuationTime: $valuationTime, ')
          ..write('status: $status, ')
          ..write('extInfo: $extInfo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    assetType,
    assetCode,
    quantity,
    costPrice,
    currentPrice,
    currency,
    marketValue,
    valuationTime,
    status,
    extInfo,
    createdAt,
    updatedAt,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.assetType == this.assetType &&
          other.assetCode == this.assetCode &&
          other.quantity == this.quantity &&
          other.costPrice == this.costPrice &&
          other.currentPrice == this.currentPrice &&
          other.currency == this.currency &&
          other.marketValue == this.marketValue &&
          other.valuationTime == this.valuationTime &&
          other.status == this.status &&
          other.extInfo == this.extInfo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class AssetsCompanion extends UpdateCompanion<AssetRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> assetType;
  final Value<String?> assetCode;
  final Value<String> quantity;
  final Value<String?> costPrice;
  final Value<String?> currentPrice;
  final Value<String> currency;
  final Value<String?> marketValue;
  final Value<DateTime?> valuationTime;
  final Value<String> status;
  final Value<String?> extInfo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.assetType = const Value.absent(),
    this.assetCode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.currency = const Value.absent(),
    this.marketValue = const Value.absent(),
    this.valuationTime = const Value.absent(),
    this.status = const Value.absent(),
    this.extInfo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required String accountId,
    required String assetType,
    this.assetCode = const Value.absent(),
    required String quantity,
    this.costPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    required String currency,
    this.marketValue = const Value.absent(),
    this.valuationTime = const Value.absent(),
    required String status,
    this.extInfo = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       assetType = Value(assetType),
       quantity = Value(quantity),
       currency = Value(currency),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AssetRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? assetType,
    Expression<String>? assetCode,
    Expression<String>? quantity,
    Expression<String>? costPrice,
    Expression<String>? currentPrice,
    Expression<String>? currency,
    Expression<String>? marketValue,
    Expression<DateTime>? valuationTime,
    Expression<String>? status,
    Expression<String>? extInfo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (assetType != null) 'asset_type': assetType,
      if (assetCode != null) 'asset_code': assetCode,
      if (quantity != null) 'quantity': quantity,
      if (costPrice != null) 'cost_price': costPrice,
      if (currentPrice != null) 'current_price': currentPrice,
      if (currency != null) 'currency': currency,
      if (marketValue != null) 'market_value': marketValue,
      if (valuationTime != null) 'valuation_time': valuationTime,
      if (status != null) 'status': status,
      if (extInfo != null) 'ext_info': extInfo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? assetType,
    Value<String?>? assetCode,
    Value<String>? quantity,
    Value<String?>? costPrice,
    Value<String?>? currentPrice,
    Value<String>? currency,
    Value<String?>? marketValue,
    Value<DateTime?>? valuationTime,
    Value<String>? status,
    Value<String?>? extInfo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      assetType: assetType ?? this.assetType,
      assetCode: assetCode ?? this.assetCode,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      currency: currency ?? this.currency,
      marketValue: marketValue ?? this.marketValue,
      valuationTime: valuationTime ?? this.valuationTime,
      status: status ?? this.status,
      extInfo: extInfo ?? this.extInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (assetType.present) {
      map['asset_type'] = Variable<String>(assetType.value);
    }
    if (assetCode.present) {
      map['asset_code'] = Variable<String>(assetCode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<String>(costPrice.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<String>(currentPrice.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (marketValue.present) {
      map['market_value'] = Variable<String>(marketValue.value);
    }
    if (valuationTime.present) {
      map['valuation_time'] = Variable<DateTime>(valuationTime.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (extInfo.present) {
      map['ext_info'] = Variable<String>(extInfo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('assetType: $assetType, ')
          ..write('assetCode: $assetCode, ')
          ..write('quantity: $quantity, ')
          ..write('costPrice: $costPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('currency: $currency, ')
          ..write('marketValue: $marketValue, ')
          ..write('valuationTime: $valuationTime, ')
          ..write('status: $status, ')
          ..write('extInfo: $extInfo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetCostHistoryTable extends AssetCostHistory
    with TableInfo<$AssetCostHistoryTable, AssetCostHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetCostHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _costPriceMeta = const VerificationMeta(
    'costPrice',
  );
  @override
  late final GeneratedColumn<String> costPrice = GeneratedColumn<String>(
    'cost_price',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggerTimeMeta = const VerificationMeta(
    'triggerTime',
  );
  @override
  late final GeneratedColumn<DateTime> triggerTime = GeneratedColumn<DateTime>(
    'trigger_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    costPrice,
    quantity,
    currency,
    source,
    reason,
    triggerTime,
    sourceKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_cost_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetCostHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('cost_price')) {
      context.handle(
        _costPriceMeta,
        costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('trigger_time')) {
      context.handle(
        _triggerTimeMeta,
        triggerTime.isAcceptableOrUnknown(
          data['trigger_time']!,
          _triggerTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerTimeMeta);
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetCostHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetCostHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      costPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_price'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      triggerTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trigger_time'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AssetCostHistoryTable createAlias(String alias) {
    return $AssetCostHistoryTable(attachedDatabase, alias);
  }
}

class AssetCostHistoryRow extends DataClass
    implements Insertable<AssetCostHistoryRow> {
  final String id;
  final String assetId;
  final String? costPrice;
  final String quantity;
  final String currency;
  final String source;
  final String? reason;
  final DateTime triggerTime;
  final String? sourceKey;
  final DateTime createdAt;
  const AssetCostHistoryRow({
    required this.id,
    required this.assetId,
    this.costPrice,
    required this.quantity,
    required this.currency,
    required this.source,
    this.reason,
    required this.triggerTime,
    this.sourceKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['asset_id'] = Variable<String>(assetId);
    if (!nullToAbsent || costPrice != null) {
      map['cost_price'] = Variable<String>(costPrice);
    }
    map['quantity'] = Variable<String>(quantity);
    map['currency'] = Variable<String>(currency);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['trigger_time'] = Variable<DateTime>(triggerTime);
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AssetCostHistoryCompanion toCompanion(bool nullToAbsent) {
    return AssetCostHistoryCompanion(
      id: Value(id),
      assetId: Value(assetId),
      costPrice: costPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(costPrice),
      quantity: Value(quantity),
      currency: Value(currency),
      source: Value(source),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      triggerTime: Value(triggerTime),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
      createdAt: Value(createdAt),
    );
  }

  factory AssetCostHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetCostHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      assetId: serializer.fromJson<String>(json['assetId']),
      costPrice: serializer.fromJson<String?>(json['costPrice']),
      quantity: serializer.fromJson<String>(json['quantity']),
      currency: serializer.fromJson<String>(json['currency']),
      source: serializer.fromJson<String>(json['source']),
      reason: serializer.fromJson<String?>(json['reason']),
      triggerTime: serializer.fromJson<DateTime>(json['triggerTime']),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'assetId': serializer.toJson<String>(assetId),
      'costPrice': serializer.toJson<String?>(costPrice),
      'quantity': serializer.toJson<String>(quantity),
      'currency': serializer.toJson<String>(currency),
      'source': serializer.toJson<String>(source),
      'reason': serializer.toJson<String?>(reason),
      'triggerTime': serializer.toJson<DateTime>(triggerTime),
      'sourceKey': serializer.toJson<String?>(sourceKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AssetCostHistoryRow copyWith({
    String? id,
    String? assetId,
    Value<String?> costPrice = const Value.absent(),
    String? quantity,
    String? currency,
    String? source,
    Value<String?> reason = const Value.absent(),
    DateTime? triggerTime,
    Value<String?> sourceKey = const Value.absent(),
    DateTime? createdAt,
  }) => AssetCostHistoryRow(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    costPrice: costPrice.present ? costPrice.value : this.costPrice,
    quantity: quantity ?? this.quantity,
    currency: currency ?? this.currency,
    source: source ?? this.source,
    reason: reason.present ? reason.value : this.reason,
    triggerTime: triggerTime ?? this.triggerTime,
    sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
    createdAt: createdAt ?? this.createdAt,
  );
  AssetCostHistoryRow copyWithCompanion(AssetCostHistoryCompanion data) {
    return AssetCostHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      currency: data.currency.present ? data.currency.value : this.currency,
      source: data.source.present ? data.source.value : this.source,
      reason: data.reason.present ? data.reason.value : this.reason,
      triggerTime: data.triggerTime.present
          ? data.triggerTime.value
          : this.triggerTime,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetCostHistoryRow(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('costPrice: $costPrice, ')
          ..write('quantity: $quantity, ')
          ..write('currency: $currency, ')
          ..write('source: $source, ')
          ..write('reason: $reason, ')
          ..write('triggerTime: $triggerTime, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    costPrice,
    quantity,
    currency,
    source,
    reason,
    triggerTime,
    sourceKey,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetCostHistoryRow &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.costPrice == this.costPrice &&
          other.quantity == this.quantity &&
          other.currency == this.currency &&
          other.source == this.source &&
          other.reason == this.reason &&
          other.triggerTime == this.triggerTime &&
          other.sourceKey == this.sourceKey &&
          other.createdAt == this.createdAt);
}

class AssetCostHistoryCompanion extends UpdateCompanion<AssetCostHistoryRow> {
  final Value<String> id;
  final Value<String> assetId;
  final Value<String?> costPrice;
  final Value<String> quantity;
  final Value<String> currency;
  final Value<String> source;
  final Value<String?> reason;
  final Value<DateTime> triggerTime;
  final Value<String?> sourceKey;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AssetCostHistoryCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.currency = const Value.absent(),
    this.source = const Value.absent(),
    this.reason = const Value.absent(),
    this.triggerTime = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetCostHistoryCompanion.insert({
    required String id,
    required String assetId,
    this.costPrice = const Value.absent(),
    required String quantity,
    required String currency,
    required String source,
    this.reason = const Value.absent(),
    required DateTime triggerTime,
    this.sourceKey = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       assetId = Value(assetId),
       quantity = Value(quantity),
       currency = Value(currency),
       source = Value(source),
       triggerTime = Value(triggerTime),
       createdAt = Value(createdAt);
  static Insertable<AssetCostHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? assetId,
    Expression<String>? costPrice,
    Expression<String>? quantity,
    Expression<String>? currency,
    Expression<String>? source,
    Expression<String>? reason,
    Expression<DateTime>? triggerTime,
    Expression<String>? sourceKey,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (costPrice != null) 'cost_price': costPrice,
      if (quantity != null) 'quantity': quantity,
      if (currency != null) 'currency': currency,
      if (source != null) 'source': source,
      if (reason != null) 'reason': reason,
      if (triggerTime != null) 'trigger_time': triggerTime,
      if (sourceKey != null) 'source_key': sourceKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetCostHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? assetId,
    Value<String?>? costPrice,
    Value<String>? quantity,
    Value<String>? currency,
    Value<String>? source,
    Value<String?>? reason,
    Value<DateTime>? triggerTime,
    Value<String?>? sourceKey,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AssetCostHistoryCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      costPrice: costPrice ?? this.costPrice,
      quantity: quantity ?? this.quantity,
      currency: currency ?? this.currency,
      source: source ?? this.source,
      reason: reason ?? this.reason,
      triggerTime: triggerTime ?? this.triggerTime,
      sourceKey: sourceKey ?? this.sourceKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<String>(costPrice.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (triggerTime.present) {
      map['trigger_time'] = Variable<DateTime>(triggerTime.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetCostHistoryCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('costPrice: $costPrice, ')
          ..write('quantity: $quantity, ')
          ..write('currency: $currency, ')
          ..write('source: $source, ')
          ..write('reason: $reason, ')
          ..write('triggerTime: $triggerTime, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetPriceHistoryTable extends AssetPriceHistory
    with TableInfo<$AssetPriceHistoryTable, AssetPriceHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetPriceHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES assets (id)',
    ),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<String> price = GeneratedColumn<String>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _marketValueMeta = const VerificationMeta(
    'marketValue',
  );
  @override
  late final GeneratedColumn<String> marketValue = GeneratedColumn<String>(
    'market_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _triggerTimeMeta = const VerificationMeta(
    'triggerTime',
  );
  @override
  late final GeneratedColumn<DateTime> triggerTime = GeneratedColumn<DateTime>(
    'trigger_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _rawPayloadMeta = const VerificationMeta(
    'rawPayload',
  );
  @override
  late final GeneratedColumn<String> rawPayload = GeneratedColumn<String>(
    'raw_payload',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    price,
    marketValue,
    currency,
    source,
    batchId,
    triggerTime,
    sourceKey,
    rawPayload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_price_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetPriceHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('market_value')) {
      context.handle(
        _marketValueMeta,
        marketValue.isAcceptableOrUnknown(
          data['market_value']!,
          _marketValueMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('trigger_time')) {
      context.handle(
        _triggerTimeMeta,
        triggerTime.isAcceptableOrUnknown(
          data['trigger_time']!,
          _triggerTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerTimeMeta);
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    }
    if (data.containsKey('raw_payload')) {
      context.handle(
        _rawPayloadMeta,
        rawPayload.isAcceptableOrUnknown(data['raw_payload']!, _rawPayloadMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetPriceHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetPriceHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}price'],
      )!,
      marketValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}market_value'],
      ),
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      triggerTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trigger_time'],
      )!,
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      ),
      rawPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_payload'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AssetPriceHistoryTable createAlias(String alias) {
    return $AssetPriceHistoryTable(attachedDatabase, alias);
  }
}

class AssetPriceHistoryRow extends DataClass
    implements Insertable<AssetPriceHistoryRow> {
  final String id;
  final String assetId;
  final String price;
  final String? marketValue;
  final String currency;
  final String source;
  final String? batchId;
  final DateTime triggerTime;
  final String? sourceKey;
  final String? rawPayload;
  final DateTime createdAt;
  const AssetPriceHistoryRow({
    required this.id,
    required this.assetId,
    required this.price,
    this.marketValue,
    required this.currency,
    required this.source,
    this.batchId,
    required this.triggerTime,
    this.sourceKey,
    this.rawPayload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['asset_id'] = Variable<String>(assetId);
    map['price'] = Variable<String>(price);
    if (!nullToAbsent || marketValue != null) {
      map['market_value'] = Variable<String>(marketValue);
    }
    map['currency'] = Variable<String>(currency);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    map['trigger_time'] = Variable<DateTime>(triggerTime);
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    if (!nullToAbsent || rawPayload != null) {
      map['raw_payload'] = Variable<String>(rawPayload);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AssetPriceHistoryCompanion toCompanion(bool nullToAbsent) {
    return AssetPriceHistoryCompanion(
      id: Value(id),
      assetId: Value(assetId),
      price: Value(price),
      marketValue: marketValue == null && nullToAbsent
          ? const Value.absent()
          : Value(marketValue),
      currency: Value(currency),
      source: Value(source),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      triggerTime: Value(triggerTime),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
      rawPayload: rawPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(rawPayload),
      createdAt: Value(createdAt),
    );
  }

  factory AssetPriceHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetPriceHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      assetId: serializer.fromJson<String>(json['assetId']),
      price: serializer.fromJson<String>(json['price']),
      marketValue: serializer.fromJson<String?>(json['marketValue']),
      currency: serializer.fromJson<String>(json['currency']),
      source: serializer.fromJson<String>(json['source']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      triggerTime: serializer.fromJson<DateTime>(json['triggerTime']),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
      rawPayload: serializer.fromJson<String?>(json['rawPayload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'assetId': serializer.toJson<String>(assetId),
      'price': serializer.toJson<String>(price),
      'marketValue': serializer.toJson<String?>(marketValue),
      'currency': serializer.toJson<String>(currency),
      'source': serializer.toJson<String>(source),
      'batchId': serializer.toJson<String?>(batchId),
      'triggerTime': serializer.toJson<DateTime>(triggerTime),
      'sourceKey': serializer.toJson<String?>(sourceKey),
      'rawPayload': serializer.toJson<String?>(rawPayload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AssetPriceHistoryRow copyWith({
    String? id,
    String? assetId,
    String? price,
    Value<String?> marketValue = const Value.absent(),
    String? currency,
    String? source,
    Value<String?> batchId = const Value.absent(),
    DateTime? triggerTime,
    Value<String?> sourceKey = const Value.absent(),
    Value<String?> rawPayload = const Value.absent(),
    DateTime? createdAt,
  }) => AssetPriceHistoryRow(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    price: price ?? this.price,
    marketValue: marketValue.present ? marketValue.value : this.marketValue,
    currency: currency ?? this.currency,
    source: source ?? this.source,
    batchId: batchId.present ? batchId.value : this.batchId,
    triggerTime: triggerTime ?? this.triggerTime,
    sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
    rawPayload: rawPayload.present ? rawPayload.value : this.rawPayload,
    createdAt: createdAt ?? this.createdAt,
  );
  AssetPriceHistoryRow copyWithCompanion(AssetPriceHistoryCompanion data) {
    return AssetPriceHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      price: data.price.present ? data.price.value : this.price,
      marketValue: data.marketValue.present
          ? data.marketValue.value
          : this.marketValue,
      currency: data.currency.present ? data.currency.value : this.currency,
      source: data.source.present ? data.source.value : this.source,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      triggerTime: data.triggerTime.present
          ? data.triggerTime.value
          : this.triggerTime,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      rawPayload: data.rawPayload.present
          ? data.rawPayload.value
          : this.rawPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetPriceHistoryRow(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('price: $price, ')
          ..write('marketValue: $marketValue, ')
          ..write('currency: $currency, ')
          ..write('source: $source, ')
          ..write('batchId: $batchId, ')
          ..write('triggerTime: $triggerTime, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('rawPayload: $rawPayload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    price,
    marketValue,
    currency,
    source,
    batchId,
    triggerTime,
    sourceKey,
    rawPayload,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetPriceHistoryRow &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.price == this.price &&
          other.marketValue == this.marketValue &&
          other.currency == this.currency &&
          other.source == this.source &&
          other.batchId == this.batchId &&
          other.triggerTime == this.triggerTime &&
          other.sourceKey == this.sourceKey &&
          other.rawPayload == this.rawPayload &&
          other.createdAt == this.createdAt);
}

class AssetPriceHistoryCompanion extends UpdateCompanion<AssetPriceHistoryRow> {
  final Value<String> id;
  final Value<String> assetId;
  final Value<String> price;
  final Value<String?> marketValue;
  final Value<String> currency;
  final Value<String> source;
  final Value<String?> batchId;
  final Value<DateTime> triggerTime;
  final Value<String?> sourceKey;
  final Value<String?> rawPayload;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AssetPriceHistoryCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.price = const Value.absent(),
    this.marketValue = const Value.absent(),
    this.currency = const Value.absent(),
    this.source = const Value.absent(),
    this.batchId = const Value.absent(),
    this.triggerTime = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.rawPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetPriceHistoryCompanion.insert({
    required String id,
    required String assetId,
    required String price,
    this.marketValue = const Value.absent(),
    required String currency,
    required String source,
    this.batchId = const Value.absent(),
    required DateTime triggerTime,
    this.sourceKey = const Value.absent(),
    this.rawPayload = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       assetId = Value(assetId),
       price = Value(price),
       currency = Value(currency),
       source = Value(source),
       triggerTime = Value(triggerTime),
       createdAt = Value(createdAt);
  static Insertable<AssetPriceHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? assetId,
    Expression<String>? price,
    Expression<String>? marketValue,
    Expression<String>? currency,
    Expression<String>? source,
    Expression<String>? batchId,
    Expression<DateTime>? triggerTime,
    Expression<String>? sourceKey,
    Expression<String>? rawPayload,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (price != null) 'price': price,
      if (marketValue != null) 'market_value': marketValue,
      if (currency != null) 'currency': currency,
      if (source != null) 'source': source,
      if (batchId != null) 'batch_id': batchId,
      if (triggerTime != null) 'trigger_time': triggerTime,
      if (sourceKey != null) 'source_key': sourceKey,
      if (rawPayload != null) 'raw_payload': rawPayload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetPriceHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? assetId,
    Value<String>? price,
    Value<String?>? marketValue,
    Value<String>? currency,
    Value<String>? source,
    Value<String?>? batchId,
    Value<DateTime>? triggerTime,
    Value<String?>? sourceKey,
    Value<String?>? rawPayload,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AssetPriceHistoryCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      price: price ?? this.price,
      marketValue: marketValue ?? this.marketValue,
      currency: currency ?? this.currency,
      source: source ?? this.source,
      batchId: batchId ?? this.batchId,
      triggerTime: triggerTime ?? this.triggerTime,
      sourceKey: sourceKey ?? this.sourceKey,
      rawPayload: rawPayload ?? this.rawPayload,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (price.present) {
      map['price'] = Variable<String>(price.value);
    }
    if (marketValue.present) {
      map['market_value'] = Variable<String>(marketValue.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (triggerTime.present) {
      map['trigger_time'] = Variable<DateTime>(triggerTime.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (rawPayload.present) {
      map['raw_payload'] = Variable<String>(rawPayload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetPriceHistoryCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('price: $price, ')
          ..write('marketValue: $marketValue, ')
          ..write('currency: $currency, ')
          ..write('source: $source, ')
          ..write('batchId: $batchId, ')
          ..write('triggerTime: $triggerTime, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('rawPayload: $rawPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _cardOrganizationMeta = const VerificationMeta(
    'cardOrganization',
  );
  @override
  late final GeneratedColumn<String> cardOrganization = GeneratedColumn<String>(
    'card_organization',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardNoMaskedMeta = const VerificationMeta(
    'cardNoMasked',
  );
  @override
  late final GeneratedColumn<String> cardNoMasked = GeneratedColumn<String>(
    'card_no_masked',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardNoCiphertextMeta = const VerificationMeta(
    'cardNoCiphertext',
  );
  @override
  late final GeneratedColumn<String> cardNoCiphertext = GeneratedColumn<String>(
    'card_no_ciphertext',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardTypeMeta = const VerificationMeta(
    'cardType',
  );
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
    'card_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expireMonthMeta = const VerificationMeta(
    'expireMonth',
  );
  @override
  late final GeneratedColumn<int> expireMonth = GeneratedColumn<int>(
    'expire_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expireYearMeta = const VerificationMeta(
    'expireYear',
  );
  @override
  late final GeneratedColumn<int> expireYear = GeneratedColumn<int>(
    'expire_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cvvCiphertextMeta = const VerificationMeta(
    'cvvCiphertext',
  );
  @override
  late final GeneratedColumn<String> cvvCiphertext = GeneratedColumn<String>(
    'cvv_ciphertext',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _issuerNameMeta = const VerificationMeta(
    'issuerName',
  );
  @override
  late final GeneratedColumn<String> issuerName = GeneratedColumn<String>(
    'issuer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supportsAllCurrenciesMeta =
      const VerificationMeta('supportsAllCurrencies');
  @override
  late final GeneratedColumn<bool> supportsAllCurrencies =
      GeneratedColumn<bool>(
        'supports_all_currencies',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("supports_all_currencies" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _supportedCurrenciesMeta =
      const VerificationMeta('supportedCurrencies');
  @override
  late final GeneratedColumn<String> supportedCurrencies =
      GeneratedColumn<String>(
        'supported_currencies',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<String> creditLimit = GeneratedColumn<String>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _availableCreditMeta = const VerificationMeta(
    'availableCredit',
  );
  @override
  late final GeneratedColumn<String> availableCredit = GeneratedColumn<String>(
    'available_credit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billingCycleDayMeta = const VerificationMeta(
    'billingCycleDay',
  );
  @override
  late final GeneratedColumn<int> billingCycleDay = GeneratedColumn<int>(
    'billing_cycle_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentDueDayMeta = const VerificationMeta(
    'paymentDueDay',
  );
  @override
  late final GeneratedColumn<int> paymentDueDay = GeneratedColumn<int>(
    'payment_due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billingAddressMeta = const VerificationMeta(
    'billingAddress',
  );
  @override
  late final GeneratedColumn<String> billingAddress = GeneratedColumn<String>(
    'billing_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isVirtualMeta = const VerificationMeta(
    'isVirtual',
  );
  @override
  late final GeneratedColumn<bool> isVirtual = GeneratedColumn<bool>(
    'is_virtual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_virtual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
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
    accountId,
    cardOrganization,
    cardNoMasked,
    cardNoCiphertext,
    cardType,
    expireMonth,
    expireYear,
    cvvCiphertext,
    issuerName,
    currency,
    supportsAllCurrencies,
    supportedCurrencies,
    creditLimit,
    availableCredit,
    billingCycleDay,
    paymentDueDay,
    billingAddress,
    isVirtual,
    status,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('card_organization')) {
      context.handle(
        _cardOrganizationMeta,
        cardOrganization.isAcceptableOrUnknown(
          data['card_organization']!,
          _cardOrganizationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cardOrganizationMeta);
    }
    if (data.containsKey('card_no_masked')) {
      context.handle(
        _cardNoMaskedMeta,
        cardNoMasked.isAcceptableOrUnknown(
          data['card_no_masked']!,
          _cardNoMaskedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cardNoMaskedMeta);
    }
    if (data.containsKey('card_no_ciphertext')) {
      context.handle(
        _cardNoCiphertextMeta,
        cardNoCiphertext.isAcceptableOrUnknown(
          data['card_no_ciphertext']!,
          _cardNoCiphertextMeta,
        ),
      );
    }
    if (data.containsKey('card_type')) {
      context.handle(
        _cardTypeMeta,
        cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_cardTypeMeta);
    }
    if (data.containsKey('expire_month')) {
      context.handle(
        _expireMonthMeta,
        expireMonth.isAcceptableOrUnknown(
          data['expire_month']!,
          _expireMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expireMonthMeta);
    }
    if (data.containsKey('expire_year')) {
      context.handle(
        _expireYearMeta,
        expireYear.isAcceptableOrUnknown(data['expire_year']!, _expireYearMeta),
      );
    } else if (isInserting) {
      context.missing(_expireYearMeta);
    }
    if (data.containsKey('cvv_ciphertext')) {
      context.handle(
        _cvvCiphertextMeta,
        cvvCiphertext.isAcceptableOrUnknown(
          data['cvv_ciphertext']!,
          _cvvCiphertextMeta,
        ),
      );
    }
    if (data.containsKey('issuer_name')) {
      context.handle(
        _issuerNameMeta,
        issuerName.isAcceptableOrUnknown(data['issuer_name']!, _issuerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_issuerNameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('supports_all_currencies')) {
      context.handle(
        _supportsAllCurrenciesMeta,
        supportsAllCurrencies.isAcceptableOrUnknown(
          data['supports_all_currencies']!,
          _supportsAllCurrenciesMeta,
        ),
      );
    }
    if (data.containsKey('supported_currencies')) {
      context.handle(
        _supportedCurrenciesMeta,
        supportedCurrencies.isAcceptableOrUnknown(
          data['supported_currencies']!,
          _supportedCurrenciesMeta,
        ),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('available_credit')) {
      context.handle(
        _availableCreditMeta,
        availableCredit.isAcceptableOrUnknown(
          data['available_credit']!,
          _availableCreditMeta,
        ),
      );
    }
    if (data.containsKey('billing_cycle_day')) {
      context.handle(
        _billingCycleDayMeta,
        billingCycleDay.isAcceptableOrUnknown(
          data['billing_cycle_day']!,
          _billingCycleDayMeta,
        ),
      );
    }
    if (data.containsKey('payment_due_day')) {
      context.handle(
        _paymentDueDayMeta,
        paymentDueDay.isAcceptableOrUnknown(
          data['payment_due_day']!,
          _paymentDueDayMeta,
        ),
      );
    }
    if (data.containsKey('billing_address')) {
      context.handle(
        _billingAddressMeta,
        billingAddress.isAcceptableOrUnknown(
          data['billing_address']!,
          _billingAddressMeta,
        ),
      );
    }
    if (data.containsKey('is_virtual')) {
      context.handle(
        _isVirtualMeta,
        isVirtual.isAcceptableOrUnknown(data['is_virtual']!, _isVirtualMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
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
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      cardOrganization: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_organization'],
      )!,
      cardNoMasked: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_no_masked'],
      )!,
      cardNoCiphertext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_no_ciphertext'],
      ),
      cardType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_type'],
      )!,
      expireMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expire_month'],
      )!,
      expireYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expire_year'],
      )!,
      cvvCiphertext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cvv_ciphertext'],
      ),
      issuerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}issuer_name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      ),
      supportsAllCurrencies: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}supports_all_currencies'],
      )!,
      supportedCurrencies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supported_currencies'],
      ),
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit_limit'],
      ),
      availableCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}available_credit'],
      ),
      billingCycleDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}billing_cycle_day'],
      ),
      paymentDueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}payment_due_day'],
      ),
      billingAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}billing_address'],
      ),
      isVirtual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_virtual'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
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
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final String id;
  final String accountId;
  final String cardOrganization;
  final String cardNoMasked;
  final String? cardNoCiphertext;
  final String cardType;
  final int expireMonth;
  final int expireYear;
  final String? cvvCiphertext;
  final String issuerName;
  final String? currency;
  final bool supportsAllCurrencies;

  /// CSV of ISO-4217 uppercase codes, e.g. "USD,EUR,HKD". `null` or empty
  /// means "仅主币种"。Not used when `supports_all_currencies = 1`.
  final String? supportedCurrencies;
  final String? creditLimit;
  final String? availableCredit;
  final int? billingCycleDay;
  final int? paymentDueDay;
  final String? billingAddress;
  final bool isVirtual;
  final String status;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CardRow({
    required this.id,
    required this.accountId,
    required this.cardOrganization,
    required this.cardNoMasked,
    this.cardNoCiphertext,
    required this.cardType,
    required this.expireMonth,
    required this.expireYear,
    this.cvvCiphertext,
    required this.issuerName,
    this.currency,
    required this.supportsAllCurrencies,
    this.supportedCurrencies,
    this.creditLimit,
    this.availableCredit,
    this.billingCycleDay,
    this.paymentDueDay,
    this.billingAddress,
    required this.isVirtual,
    required this.status,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['card_organization'] = Variable<String>(cardOrganization);
    map['card_no_masked'] = Variable<String>(cardNoMasked);
    if (!nullToAbsent || cardNoCiphertext != null) {
      map['card_no_ciphertext'] = Variable<String>(cardNoCiphertext);
    }
    map['card_type'] = Variable<String>(cardType);
    map['expire_month'] = Variable<int>(expireMonth);
    map['expire_year'] = Variable<int>(expireYear);
    if (!nullToAbsent || cvvCiphertext != null) {
      map['cvv_ciphertext'] = Variable<String>(cvvCiphertext);
    }
    map['issuer_name'] = Variable<String>(issuerName);
    if (!nullToAbsent || currency != null) {
      map['currency'] = Variable<String>(currency);
    }
    map['supports_all_currencies'] = Variable<bool>(supportsAllCurrencies);
    if (!nullToAbsent || supportedCurrencies != null) {
      map['supported_currencies'] = Variable<String>(supportedCurrencies);
    }
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<String>(creditLimit);
    }
    if (!nullToAbsent || availableCredit != null) {
      map['available_credit'] = Variable<String>(availableCredit);
    }
    if (!nullToAbsent || billingCycleDay != null) {
      map['billing_cycle_day'] = Variable<int>(billingCycleDay);
    }
    if (!nullToAbsent || paymentDueDay != null) {
      map['payment_due_day'] = Variable<int>(paymentDueDay);
    }
    if (!nullToAbsent || billingAddress != null) {
      map['billing_address'] = Variable<String>(billingAddress);
    }
    map['is_virtual'] = Variable<bool>(isVirtual);
    map['status'] = Variable<String>(status);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      cardOrganization: Value(cardOrganization),
      cardNoMasked: Value(cardNoMasked),
      cardNoCiphertext: cardNoCiphertext == null && nullToAbsent
          ? const Value.absent()
          : Value(cardNoCiphertext),
      cardType: Value(cardType),
      expireMonth: Value(expireMonth),
      expireYear: Value(expireYear),
      cvvCiphertext: cvvCiphertext == null && nullToAbsent
          ? const Value.absent()
          : Value(cvvCiphertext),
      issuerName: Value(issuerName),
      currency: currency == null && nullToAbsent
          ? const Value.absent()
          : Value(currency),
      supportsAllCurrencies: Value(supportsAllCurrencies),
      supportedCurrencies: supportedCurrencies == null && nullToAbsent
          ? const Value.absent()
          : Value(supportedCurrencies),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      availableCredit: availableCredit == null && nullToAbsent
          ? const Value.absent()
          : Value(availableCredit),
      billingCycleDay: billingCycleDay == null && nullToAbsent
          ? const Value.absent()
          : Value(billingCycleDay),
      paymentDueDay: paymentDueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentDueDay),
      billingAddress: billingAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(billingAddress),
      isVirtual: Value(isVirtual),
      status: Value(status),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      cardOrganization: serializer.fromJson<String>(json['cardOrganization']),
      cardNoMasked: serializer.fromJson<String>(json['cardNoMasked']),
      cardNoCiphertext: serializer.fromJson<String?>(json['cardNoCiphertext']),
      cardType: serializer.fromJson<String>(json['cardType']),
      expireMonth: serializer.fromJson<int>(json['expireMonth']),
      expireYear: serializer.fromJson<int>(json['expireYear']),
      cvvCiphertext: serializer.fromJson<String?>(json['cvvCiphertext']),
      issuerName: serializer.fromJson<String>(json['issuerName']),
      currency: serializer.fromJson<String?>(json['currency']),
      supportsAllCurrencies: serializer.fromJson<bool>(
        json['supportsAllCurrencies'],
      ),
      supportedCurrencies: serializer.fromJson<String?>(
        json['supportedCurrencies'],
      ),
      creditLimit: serializer.fromJson<String?>(json['creditLimit']),
      availableCredit: serializer.fromJson<String?>(json['availableCredit']),
      billingCycleDay: serializer.fromJson<int?>(json['billingCycleDay']),
      paymentDueDay: serializer.fromJson<int?>(json['paymentDueDay']),
      billingAddress: serializer.fromJson<String?>(json['billingAddress']),
      isVirtual: serializer.fromJson<bool>(json['isVirtual']),
      status: serializer.fromJson<String>(json['status']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'cardOrganization': serializer.toJson<String>(cardOrganization),
      'cardNoMasked': serializer.toJson<String>(cardNoMasked),
      'cardNoCiphertext': serializer.toJson<String?>(cardNoCiphertext),
      'cardType': serializer.toJson<String>(cardType),
      'expireMonth': serializer.toJson<int>(expireMonth),
      'expireYear': serializer.toJson<int>(expireYear),
      'cvvCiphertext': serializer.toJson<String?>(cvvCiphertext),
      'issuerName': serializer.toJson<String>(issuerName),
      'currency': serializer.toJson<String?>(currency),
      'supportsAllCurrencies': serializer.toJson<bool>(supportsAllCurrencies),
      'supportedCurrencies': serializer.toJson<String?>(supportedCurrencies),
      'creditLimit': serializer.toJson<String?>(creditLimit),
      'availableCredit': serializer.toJson<String?>(availableCredit),
      'billingCycleDay': serializer.toJson<int?>(billingCycleDay),
      'paymentDueDay': serializer.toJson<int?>(paymentDueDay),
      'billingAddress': serializer.toJson<String?>(billingAddress),
      'isVirtual': serializer.toJson<bool>(isVirtual),
      'status': serializer.toJson<String>(status),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CardRow copyWith({
    String? id,
    String? accountId,
    String? cardOrganization,
    String? cardNoMasked,
    Value<String?> cardNoCiphertext = const Value.absent(),
    String? cardType,
    int? expireMonth,
    int? expireYear,
    Value<String?> cvvCiphertext = const Value.absent(),
    String? issuerName,
    Value<String?> currency = const Value.absent(),
    bool? supportsAllCurrencies,
    Value<String?> supportedCurrencies = const Value.absent(),
    Value<String?> creditLimit = const Value.absent(),
    Value<String?> availableCredit = const Value.absent(),
    Value<int?> billingCycleDay = const Value.absent(),
    Value<int?> paymentDueDay = const Value.absent(),
    Value<String?> billingAddress = const Value.absent(),
    bool? isVirtual,
    String? status,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => CardRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    cardOrganization: cardOrganization ?? this.cardOrganization,
    cardNoMasked: cardNoMasked ?? this.cardNoMasked,
    cardNoCiphertext: cardNoCiphertext.present
        ? cardNoCiphertext.value
        : this.cardNoCiphertext,
    cardType: cardType ?? this.cardType,
    expireMonth: expireMonth ?? this.expireMonth,
    expireYear: expireYear ?? this.expireYear,
    cvvCiphertext: cvvCiphertext.present
        ? cvvCiphertext.value
        : this.cvvCiphertext,
    issuerName: issuerName ?? this.issuerName,
    currency: currency.present ? currency.value : this.currency,
    supportsAllCurrencies: supportsAllCurrencies ?? this.supportsAllCurrencies,
    supportedCurrencies: supportedCurrencies.present
        ? supportedCurrencies.value
        : this.supportedCurrencies,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    availableCredit: availableCredit.present
        ? availableCredit.value
        : this.availableCredit,
    billingCycleDay: billingCycleDay.present
        ? billingCycleDay.value
        : this.billingCycleDay,
    paymentDueDay: paymentDueDay.present
        ? paymentDueDay.value
        : this.paymentDueDay,
    billingAddress: billingAddress.present
        ? billingAddress.value
        : this.billingAddress,
    isVirtual: isVirtual ?? this.isVirtual,
    status: status ?? this.status,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      cardOrganization: data.cardOrganization.present
          ? data.cardOrganization.value
          : this.cardOrganization,
      cardNoMasked: data.cardNoMasked.present
          ? data.cardNoMasked.value
          : this.cardNoMasked,
      cardNoCiphertext: data.cardNoCiphertext.present
          ? data.cardNoCiphertext.value
          : this.cardNoCiphertext,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      expireMonth: data.expireMonth.present
          ? data.expireMonth.value
          : this.expireMonth,
      expireYear: data.expireYear.present
          ? data.expireYear.value
          : this.expireYear,
      cvvCiphertext: data.cvvCiphertext.present
          ? data.cvvCiphertext.value
          : this.cvvCiphertext,
      issuerName: data.issuerName.present
          ? data.issuerName.value
          : this.issuerName,
      currency: data.currency.present ? data.currency.value : this.currency,
      supportsAllCurrencies: data.supportsAllCurrencies.present
          ? data.supportsAllCurrencies.value
          : this.supportsAllCurrencies,
      supportedCurrencies: data.supportedCurrencies.present
          ? data.supportedCurrencies.value
          : this.supportedCurrencies,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      availableCredit: data.availableCredit.present
          ? data.availableCredit.value
          : this.availableCredit,
      billingCycleDay: data.billingCycleDay.present
          ? data.billingCycleDay.value
          : this.billingCycleDay,
      paymentDueDay: data.paymentDueDay.present
          ? data.paymentDueDay.value
          : this.paymentDueDay,
      billingAddress: data.billingAddress.present
          ? data.billingAddress.value
          : this.billingAddress,
      isVirtual: data.isVirtual.present ? data.isVirtual.value : this.isVirtual,
      status: data.status.present ? data.status.value : this.status,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('cardOrganization: $cardOrganization, ')
          ..write('cardNoMasked: $cardNoMasked, ')
          ..write('cardNoCiphertext: $cardNoCiphertext, ')
          ..write('cardType: $cardType, ')
          ..write('expireMonth: $expireMonth, ')
          ..write('expireYear: $expireYear, ')
          ..write('cvvCiphertext: $cvvCiphertext, ')
          ..write('issuerName: $issuerName, ')
          ..write('currency: $currency, ')
          ..write('supportsAllCurrencies: $supportsAllCurrencies, ')
          ..write('supportedCurrencies: $supportedCurrencies, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('availableCredit: $availableCredit, ')
          ..write('billingCycleDay: $billingCycleDay, ')
          ..write('paymentDueDay: $paymentDueDay, ')
          ..write('billingAddress: $billingAddress, ')
          ..write('isVirtual: $isVirtual, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    accountId,
    cardOrganization,
    cardNoMasked,
    cardNoCiphertext,
    cardType,
    expireMonth,
    expireYear,
    cvvCiphertext,
    issuerName,
    currency,
    supportsAllCurrencies,
    supportedCurrencies,
    creditLimit,
    availableCredit,
    billingCycleDay,
    paymentDueDay,
    billingAddress,
    isVirtual,
    status,
    sortOrder,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.cardOrganization == this.cardOrganization &&
          other.cardNoMasked == this.cardNoMasked &&
          other.cardNoCiphertext == this.cardNoCiphertext &&
          other.cardType == this.cardType &&
          other.expireMonth == this.expireMonth &&
          other.expireYear == this.expireYear &&
          other.cvvCiphertext == this.cvvCiphertext &&
          other.issuerName == this.issuerName &&
          other.currency == this.currency &&
          other.supportsAllCurrencies == this.supportsAllCurrencies &&
          other.supportedCurrencies == this.supportedCurrencies &&
          other.creditLimit == this.creditLimit &&
          other.availableCredit == this.availableCredit &&
          other.billingCycleDay == this.billingCycleDay &&
          other.paymentDueDay == this.paymentDueDay &&
          other.billingAddress == this.billingAddress &&
          other.isVirtual == this.isVirtual &&
          other.status == this.status &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> cardOrganization;
  final Value<String> cardNoMasked;
  final Value<String?> cardNoCiphertext;
  final Value<String> cardType;
  final Value<int> expireMonth;
  final Value<int> expireYear;
  final Value<String?> cvvCiphertext;
  final Value<String> issuerName;
  final Value<String?> currency;
  final Value<bool> supportsAllCurrencies;
  final Value<String?> supportedCurrencies;
  final Value<String?> creditLimit;
  final Value<String?> availableCredit;
  final Value<int?> billingCycleDay;
  final Value<int?> paymentDueDay;
  final Value<String?> billingAddress;
  final Value<bool> isVirtual;
  final Value<String> status;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.cardOrganization = const Value.absent(),
    this.cardNoMasked = const Value.absent(),
    this.cardNoCiphertext = const Value.absent(),
    this.cardType = const Value.absent(),
    this.expireMonth = const Value.absent(),
    this.expireYear = const Value.absent(),
    this.cvvCiphertext = const Value.absent(),
    this.issuerName = const Value.absent(),
    this.currency = const Value.absent(),
    this.supportsAllCurrencies = const Value.absent(),
    this.supportedCurrencies = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.availableCredit = const Value.absent(),
    this.billingCycleDay = const Value.absent(),
    this.paymentDueDay = const Value.absent(),
    this.billingAddress = const Value.absent(),
    this.isVirtual = const Value.absent(),
    this.status = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String accountId,
    required String cardOrganization,
    required String cardNoMasked,
    this.cardNoCiphertext = const Value.absent(),
    required String cardType,
    required int expireMonth,
    required int expireYear,
    this.cvvCiphertext = const Value.absent(),
    required String issuerName,
    this.currency = const Value.absent(),
    this.supportsAllCurrencies = const Value.absent(),
    this.supportedCurrencies = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.availableCredit = const Value.absent(),
    this.billingCycleDay = const Value.absent(),
    this.paymentDueDay = const Value.absent(),
    this.billingAddress = const Value.absent(),
    this.isVirtual = const Value.absent(),
    required String status,
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       cardOrganization = Value(cardOrganization),
       cardNoMasked = Value(cardNoMasked),
       cardType = Value(cardType),
       expireMonth = Value(expireMonth),
       expireYear = Value(expireYear),
       issuerName = Value(issuerName),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CardRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? cardOrganization,
    Expression<String>? cardNoMasked,
    Expression<String>? cardNoCiphertext,
    Expression<String>? cardType,
    Expression<int>? expireMonth,
    Expression<int>? expireYear,
    Expression<String>? cvvCiphertext,
    Expression<String>? issuerName,
    Expression<String>? currency,
    Expression<bool>? supportsAllCurrencies,
    Expression<String>? supportedCurrencies,
    Expression<String>? creditLimit,
    Expression<String>? availableCredit,
    Expression<int>? billingCycleDay,
    Expression<int>? paymentDueDay,
    Expression<String>? billingAddress,
    Expression<bool>? isVirtual,
    Expression<String>? status,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (cardOrganization != null) 'card_organization': cardOrganization,
      if (cardNoMasked != null) 'card_no_masked': cardNoMasked,
      if (cardNoCiphertext != null) 'card_no_ciphertext': cardNoCiphertext,
      if (cardType != null) 'card_type': cardType,
      if (expireMonth != null) 'expire_month': expireMonth,
      if (expireYear != null) 'expire_year': expireYear,
      if (cvvCiphertext != null) 'cvv_ciphertext': cvvCiphertext,
      if (issuerName != null) 'issuer_name': issuerName,
      if (currency != null) 'currency': currency,
      if (supportsAllCurrencies != null)
        'supports_all_currencies': supportsAllCurrencies,
      if (supportedCurrencies != null)
        'supported_currencies': supportedCurrencies,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (availableCredit != null) 'available_credit': availableCredit,
      if (billingCycleDay != null) 'billing_cycle_day': billingCycleDay,
      if (paymentDueDay != null) 'payment_due_day': paymentDueDay,
      if (billingAddress != null) 'billing_address': billingAddress,
      if (isVirtual != null) 'is_virtual': isVirtual,
      if (status != null) 'status': status,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String>? cardOrganization,
    Value<String>? cardNoMasked,
    Value<String?>? cardNoCiphertext,
    Value<String>? cardType,
    Value<int>? expireMonth,
    Value<int>? expireYear,
    Value<String?>? cvvCiphertext,
    Value<String>? issuerName,
    Value<String?>? currency,
    Value<bool>? supportsAllCurrencies,
    Value<String?>? supportedCurrencies,
    Value<String?>? creditLimit,
    Value<String?>? availableCredit,
    Value<int?>? billingCycleDay,
    Value<int?>? paymentDueDay,
    Value<String?>? billingAddress,
    Value<bool>? isVirtual,
    Value<String>? status,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      cardOrganization: cardOrganization ?? this.cardOrganization,
      cardNoMasked: cardNoMasked ?? this.cardNoMasked,
      cardNoCiphertext: cardNoCiphertext ?? this.cardNoCiphertext,
      cardType: cardType ?? this.cardType,
      expireMonth: expireMonth ?? this.expireMonth,
      expireYear: expireYear ?? this.expireYear,
      cvvCiphertext: cvvCiphertext ?? this.cvvCiphertext,
      issuerName: issuerName ?? this.issuerName,
      currency: currency ?? this.currency,
      supportsAllCurrencies:
          supportsAllCurrencies ?? this.supportsAllCurrencies,
      supportedCurrencies: supportedCurrencies ?? this.supportedCurrencies,
      creditLimit: creditLimit ?? this.creditLimit,
      availableCredit: availableCredit ?? this.availableCredit,
      billingCycleDay: billingCycleDay ?? this.billingCycleDay,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
      billingAddress: billingAddress ?? this.billingAddress,
      isVirtual: isVirtual ?? this.isVirtual,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (cardOrganization.present) {
      map['card_organization'] = Variable<String>(cardOrganization.value);
    }
    if (cardNoMasked.present) {
      map['card_no_masked'] = Variable<String>(cardNoMasked.value);
    }
    if (cardNoCiphertext.present) {
      map['card_no_ciphertext'] = Variable<String>(cardNoCiphertext.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (expireMonth.present) {
      map['expire_month'] = Variable<int>(expireMonth.value);
    }
    if (expireYear.present) {
      map['expire_year'] = Variable<int>(expireYear.value);
    }
    if (cvvCiphertext.present) {
      map['cvv_ciphertext'] = Variable<String>(cvvCiphertext.value);
    }
    if (issuerName.present) {
      map['issuer_name'] = Variable<String>(issuerName.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (supportsAllCurrencies.present) {
      map['supports_all_currencies'] = Variable<bool>(
        supportsAllCurrencies.value,
      );
    }
    if (supportedCurrencies.present) {
      map['supported_currencies'] = Variable<String>(supportedCurrencies.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<String>(creditLimit.value);
    }
    if (availableCredit.present) {
      map['available_credit'] = Variable<String>(availableCredit.value);
    }
    if (billingCycleDay.present) {
      map['billing_cycle_day'] = Variable<int>(billingCycleDay.value);
    }
    if (paymentDueDay.present) {
      map['payment_due_day'] = Variable<int>(paymentDueDay.value);
    }
    if (billingAddress.present) {
      map['billing_address'] = Variable<String>(billingAddress.value);
    }
    if (isVirtual.present) {
      map['is_virtual'] = Variable<bool>(isVirtual.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('cardOrganization: $cardOrganization, ')
          ..write('cardNoMasked: $cardNoMasked, ')
          ..write('cardNoCiphertext: $cardNoCiphertext, ')
          ..write('cardType: $cardType, ')
          ..write('expireMonth: $expireMonth, ')
          ..write('expireYear: $expireYear, ')
          ..write('cvvCiphertext: $cvvCiphertext, ')
          ..write('issuerName: $issuerName, ')
          ..write('currency: $currency, ')
          ..write('supportsAllCurrencies: $supportsAllCurrencies, ')
          ..write('supportedCurrencies: $supportedCurrencies, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('availableCredit: $availableCredit, ')
          ..write('billingCycleDay: $billingCycleDay, ')
          ..write('paymentDueDay: $paymentDueDay, ')
          ..write('billingAddress: $billingAddress, ')
          ..write('isVirtual: $isVirtual, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictEntriesTable extends DictEntries
    with TableInfo<$DictEntriesTable, DictEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _nameEnMeta = const VerificationMeta('nameEn');
  @override
  late final GeneratedColumn<String> nameEn = GeneratedColumn<String>(
    'name_en',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  static const VerificationMeta _isBuiltinMeta = const VerificationMeta(
    'isBuiltin',
  );
  @override
  late final GeneratedColumn<bool> isBuiltin = GeneratedColumn<bool>(
    'is_builtin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_builtin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  static const VerificationMeta _flagEmojiMeta = const VerificationMeta(
    'flagEmoji',
  );
  @override
  late final GeneratedColumn<String> flagEmoji = GeneratedColumn<String>(
    'flag_emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _continentMeta = const VerificationMeta(
    'continent',
  );
  @override
  late final GeneratedColumn<String> continent = GeneratedColumn<String>(
    'continent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mapLonMeta = const VerificationMeta('mapLon');
  @override
  late final GeneratedColumn<double> mapLon = GeneratedColumn<double>(
    'map_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mapLatMeta = const VerificationMeta('mapLat');
  @override
  late final GeneratedColumn<double> mapLat = GeneratedColumn<double>(
    'map_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anchorLonMeta = const VerificationMeta(
    'anchorLon',
  );
  @override
  late final GeneratedColumn<double> anchorLon = GeneratedColumn<double>(
    'anchor_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anchorLatMeta = const VerificationMeta(
    'anchorLat',
  );
  @override
  late final GeneratedColumn<double> anchorLat = GeneratedColumn<double>(
    'anchor_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentRegionMeta = const VerificationMeta(
    'parentRegion',
  );
  @override
  late final GeneratedColumn<String> parentRegion = GeneratedColumn<String>(
    'parent_region',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    code,
    name,
    nameEn,
    sortOrder,
    isBuiltin,
    createdAt,
    updatedAt,
    flagEmoji,
    continent,
    colorHex,
    mapLon,
    mapLat,
    anchorLon,
    anchorLat,
    parentRegion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dict_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_en')) {
      context.handle(
        _nameEnMeta,
        nameEn.isAcceptableOrUnknown(data['name_en']!, _nameEnMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_builtin')) {
      context.handle(
        _isBuiltinMeta,
        isBuiltin.isAcceptableOrUnknown(data['is_builtin']!, _isBuiltinMeta),
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
    if (data.containsKey('flag_emoji')) {
      context.handle(
        _flagEmojiMeta,
        flagEmoji.isAcceptableOrUnknown(data['flag_emoji']!, _flagEmojiMeta),
      );
    }
    if (data.containsKey('continent')) {
      context.handle(
        _continentMeta,
        continent.isAcceptableOrUnknown(data['continent']!, _continentMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('map_lon')) {
      context.handle(
        _mapLonMeta,
        mapLon.isAcceptableOrUnknown(data['map_lon']!, _mapLonMeta),
      );
    }
    if (data.containsKey('map_lat')) {
      context.handle(
        _mapLatMeta,
        mapLat.isAcceptableOrUnknown(data['map_lat']!, _mapLatMeta),
      );
    }
    if (data.containsKey('anchor_lon')) {
      context.handle(
        _anchorLonMeta,
        anchorLon.isAcceptableOrUnknown(data['anchor_lon']!, _anchorLonMeta),
      );
    }
    if (data.containsKey('anchor_lat')) {
      context.handle(
        _anchorLatMeta,
        anchorLat.isAcceptableOrUnknown(data['anchor_lat']!, _anchorLatMeta),
      );
    }
    if (data.containsKey('parent_region')) {
      context.handle(
        _parentRegionMeta,
        parentRegion.isAcceptableOrUnknown(
          data['parent_region']!,
          _parentRegionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_en'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isBuiltin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_builtin'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      flagEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flag_emoji'],
      ),
      continent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}continent'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      mapLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}map_lon'],
      ),
      mapLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}map_lat'],
      ),
      anchorLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}anchor_lon'],
      ),
      anchorLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}anchor_lat'],
      ),
      parentRegion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_region'],
      ),
    );
  }

  @override
  $DictEntriesTable createAlias(String alias) {
    return $DictEntriesTable(attachedDatabase, alias);
  }
}

class DictEntryRow extends DataClass implements Insertable<DictEntryRow> {
  final int id;
  final String type;
  final String code;
  final String name;
  final String? nameEn;
  final int sortOrder;
  final bool isBuiltin;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Emoji 国旗，如 `'🇨🇳'`。
  final String? flagEmoji;

  /// 大洲分组标签，如 `'亚太'` / `'欧洲'` / `'美洲'` / `'中东'`。
  final String? continent;

  /// 强调色十六进制字符串，如 `'0xFFEF4444'`（与 `Color(0xFFEF4444)` 对应）。
  final String? colorHex;

  /// 地理经度（-180 ~ 180），表示国家/地区的真实地理参考位置。
  final double? mapLon;

  /// 地理纬度（-90 ~ 90），表示国家/地区的真实地理参考位置。
  final double? mapLat;

  /// 地图锚点经度（-180 ~ 180），默认用于金融中心点展示。
  final double? anchorLon;

  /// 地图锚点纬度（-90 ~ 90），默认用于金融中心点展示。
  final double? anchorLat;

  /// 所属上级区域 code（如 `DE` 的 `parent_region = 'EU'`）。
  /// 为 `null` 表示顶级区域。UI 展示为「区域 | 国家」层级格式。
  final String? parentRegion;
  const DictEntryRow({
    required this.id,
    required this.type,
    required this.code,
    required this.name,
    this.nameEn,
    required this.sortOrder,
    required this.isBuiltin,
    required this.createdAt,
    required this.updatedAt,
    this.flagEmoji,
    this.continent,
    this.colorHex,
    this.mapLon,
    this.mapLat,
    this.anchorLon,
    this.anchorLat,
    this.parentRegion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || nameEn != null) {
      map['name_en'] = Variable<String>(nameEn);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_builtin'] = Variable<bool>(isBuiltin);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || flagEmoji != null) {
      map['flag_emoji'] = Variable<String>(flagEmoji);
    }
    if (!nullToAbsent || continent != null) {
      map['continent'] = Variable<String>(continent);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || mapLon != null) {
      map['map_lon'] = Variable<double>(mapLon);
    }
    if (!nullToAbsent || mapLat != null) {
      map['map_lat'] = Variable<double>(mapLat);
    }
    if (!nullToAbsent || anchorLon != null) {
      map['anchor_lon'] = Variable<double>(anchorLon);
    }
    if (!nullToAbsent || anchorLat != null) {
      map['anchor_lat'] = Variable<double>(anchorLat);
    }
    if (!nullToAbsent || parentRegion != null) {
      map['parent_region'] = Variable<String>(parentRegion);
    }
    return map;
  }

  DictEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictEntriesCompanion(
      id: Value(id),
      type: Value(type),
      code: Value(code),
      name: Value(name),
      nameEn: nameEn == null && nullToAbsent
          ? const Value.absent()
          : Value(nameEn),
      sortOrder: Value(sortOrder),
      isBuiltin: Value(isBuiltin),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      flagEmoji: flagEmoji == null && nullToAbsent
          ? const Value.absent()
          : Value(flagEmoji),
      continent: continent == null && nullToAbsent
          ? const Value.absent()
          : Value(continent),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      mapLon: mapLon == null && nullToAbsent
          ? const Value.absent()
          : Value(mapLon),
      mapLat: mapLat == null && nullToAbsent
          ? const Value.absent()
          : Value(mapLat),
      anchorLon: anchorLon == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorLon),
      anchorLat: anchorLat == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorLat),
      parentRegion: parentRegion == null && nullToAbsent
          ? const Value.absent()
          : Value(parentRegion),
    );
  }

  factory DictEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictEntryRow(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      nameEn: serializer.fromJson<String?>(json['nameEn']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isBuiltin: serializer.fromJson<bool>(json['isBuiltin']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      flagEmoji: serializer.fromJson<String?>(json['flagEmoji']),
      continent: serializer.fromJson<String?>(json['continent']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      mapLon: serializer.fromJson<double?>(json['mapLon']),
      mapLat: serializer.fromJson<double?>(json['mapLat']),
      anchorLon: serializer.fromJson<double?>(json['anchorLon']),
      anchorLat: serializer.fromJson<double?>(json['anchorLat']),
      parentRegion: serializer.fromJson<String?>(json['parentRegion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'nameEn': serializer.toJson<String?>(nameEn),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isBuiltin': serializer.toJson<bool>(isBuiltin),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'flagEmoji': serializer.toJson<String?>(flagEmoji),
      'continent': serializer.toJson<String?>(continent),
      'colorHex': serializer.toJson<String?>(colorHex),
      'mapLon': serializer.toJson<double?>(mapLon),
      'mapLat': serializer.toJson<double?>(mapLat),
      'anchorLon': serializer.toJson<double?>(anchorLon),
      'anchorLat': serializer.toJson<double?>(anchorLat),
      'parentRegion': serializer.toJson<String?>(parentRegion),
    };
  }

  DictEntryRow copyWith({
    int? id,
    String? type,
    String? code,
    String? name,
    Value<String?> nameEn = const Value.absent(),
    int? sortOrder,
    bool? isBuiltin,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> flagEmoji = const Value.absent(),
    Value<String?> continent = const Value.absent(),
    Value<String?> colorHex = const Value.absent(),
    Value<double?> mapLon = const Value.absent(),
    Value<double?> mapLat = const Value.absent(),
    Value<double?> anchorLon = const Value.absent(),
    Value<double?> anchorLat = const Value.absent(),
    Value<String?> parentRegion = const Value.absent(),
  }) => DictEntryRow(
    id: id ?? this.id,
    type: type ?? this.type,
    code: code ?? this.code,
    name: name ?? this.name,
    nameEn: nameEn.present ? nameEn.value : this.nameEn,
    sortOrder: sortOrder ?? this.sortOrder,
    isBuiltin: isBuiltin ?? this.isBuiltin,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    flagEmoji: flagEmoji.present ? flagEmoji.value : this.flagEmoji,
    continent: continent.present ? continent.value : this.continent,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    mapLon: mapLon.present ? mapLon.value : this.mapLon,
    mapLat: mapLat.present ? mapLat.value : this.mapLat,
    anchorLon: anchorLon.present ? anchorLon.value : this.anchorLon,
    anchorLat: anchorLat.present ? anchorLat.value : this.anchorLat,
    parentRegion: parentRegion.present ? parentRegion.value : this.parentRegion,
  );
  DictEntryRow copyWithCompanion(DictEntriesCompanion data) {
    return DictEntryRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      nameEn: data.nameEn.present ? data.nameEn.value : this.nameEn,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isBuiltin: data.isBuiltin.present ? data.isBuiltin.value : this.isBuiltin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      flagEmoji: data.flagEmoji.present ? data.flagEmoji.value : this.flagEmoji,
      continent: data.continent.present ? data.continent.value : this.continent,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      mapLon: data.mapLon.present ? data.mapLon.value : this.mapLon,
      mapLat: data.mapLat.present ? data.mapLat.value : this.mapLat,
      anchorLon: data.anchorLon.present ? data.anchorLon.value : this.anchorLon,
      anchorLat: data.anchorLat.present ? data.anchorLat.value : this.anchorLat,
      parentRegion: data.parentRegion.present
          ? data.parentRegion.value
          : this.parentRegion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictEntryRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('nameEn: $nameEn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('flagEmoji: $flagEmoji, ')
          ..write('continent: $continent, ')
          ..write('colorHex: $colorHex, ')
          ..write('mapLon: $mapLon, ')
          ..write('mapLat: $mapLat, ')
          ..write('anchorLon: $anchorLon, ')
          ..write('anchorLat: $anchorLat, ')
          ..write('parentRegion: $parentRegion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    code,
    name,
    nameEn,
    sortOrder,
    isBuiltin,
    createdAt,
    updatedAt,
    flagEmoji,
    continent,
    colorHex,
    mapLon,
    mapLat,
    anchorLon,
    anchorLat,
    parentRegion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictEntryRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.code == this.code &&
          other.name == this.name &&
          other.nameEn == this.nameEn &&
          other.sortOrder == this.sortOrder &&
          other.isBuiltin == this.isBuiltin &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.flagEmoji == this.flagEmoji &&
          other.continent == this.continent &&
          other.colorHex == this.colorHex &&
          other.mapLon == this.mapLon &&
          other.mapLat == this.mapLat &&
          other.anchorLon == this.anchorLon &&
          other.anchorLat == this.anchorLat &&
          other.parentRegion == this.parentRegion);
}

class DictEntriesCompanion extends UpdateCompanion<DictEntryRow> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> code;
  final Value<String> name;
  final Value<String?> nameEn;
  final Value<int> sortOrder;
  final Value<bool> isBuiltin;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> flagEmoji;
  final Value<String?> continent;
  final Value<String?> colorHex;
  final Value<double?> mapLon;
  final Value<double?> mapLat;
  final Value<double?> anchorLon;
  final Value<double?> anchorLat;
  final Value<String?> parentRegion;
  const DictEntriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.nameEn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.flagEmoji = const Value.absent(),
    this.continent = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.mapLon = const Value.absent(),
    this.mapLat = const Value.absent(),
    this.anchorLon = const Value.absent(),
    this.anchorLat = const Value.absent(),
    this.parentRegion = const Value.absent(),
  });
  DictEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required String code,
    required String name,
    this.nameEn = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isBuiltin = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.flagEmoji = const Value.absent(),
    this.continent = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.mapLon = const Value.absent(),
    this.mapLat = const Value.absent(),
    this.anchorLon = const Value.absent(),
    this.anchorLat = const Value.absent(),
    this.parentRegion = const Value.absent(),
  }) : type = Value(type),
       code = Value(code),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DictEntryRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? nameEn,
    Expression<int>? sortOrder,
    Expression<bool>? isBuiltin,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? flagEmoji,
    Expression<String>? continent,
    Expression<String>? colorHex,
    Expression<double>? mapLon,
    Expression<double>? mapLat,
    Expression<double>? anchorLon,
    Expression<double>? anchorLat,
    Expression<String>? parentRegion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (nameEn != null) 'name_en': nameEn,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isBuiltin != null) 'is_builtin': isBuiltin,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (flagEmoji != null) 'flag_emoji': flagEmoji,
      if (continent != null) 'continent': continent,
      if (colorHex != null) 'color_hex': colorHex,
      if (mapLon != null) 'map_lon': mapLon,
      if (mapLat != null) 'map_lat': mapLat,
      if (anchorLon != null) 'anchor_lon': anchorLon,
      if (anchorLat != null) 'anchor_lat': anchorLat,
      if (parentRegion != null) 'parent_region': parentRegion,
    });
  }

  DictEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? code,
    Value<String>? name,
    Value<String?>? nameEn,
    Value<int>? sortOrder,
    Value<bool>? isBuiltin,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? flagEmoji,
    Value<String?>? continent,
    Value<String?>? colorHex,
    Value<double?>? mapLon,
    Value<double?>? mapLat,
    Value<double?>? anchorLon,
    Value<double?>? anchorLat,
    Value<String?>? parentRegion,
  }) {
    return DictEntriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      code: code ?? this.code,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      sortOrder: sortOrder ?? this.sortOrder,
      isBuiltin: isBuiltin ?? this.isBuiltin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      continent: continent ?? this.continent,
      colorHex: colorHex ?? this.colorHex,
      mapLon: mapLon ?? this.mapLon,
      mapLat: mapLat ?? this.mapLat,
      anchorLon: anchorLon ?? this.anchorLon,
      anchorLat: anchorLat ?? this.anchorLat,
      parentRegion: parentRegion ?? this.parentRegion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameEn.present) {
      map['name_en'] = Variable<String>(nameEn.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isBuiltin.present) {
      map['is_builtin'] = Variable<bool>(isBuiltin.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (flagEmoji.present) {
      map['flag_emoji'] = Variable<String>(flagEmoji.value);
    }
    if (continent.present) {
      map['continent'] = Variable<String>(continent.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (mapLon.present) {
      map['map_lon'] = Variable<double>(mapLon.value);
    }
    if (mapLat.present) {
      map['map_lat'] = Variable<double>(mapLat.value);
    }
    if (anchorLon.present) {
      map['anchor_lon'] = Variable<double>(anchorLon.value);
    }
    if (anchorLat.present) {
      map['anchor_lat'] = Variable<double>(anchorLat.value);
    }
    if (parentRegion.present) {
      map['parent_region'] = Variable<String>(parentRegion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictEntriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('nameEn: $nameEn, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isBuiltin: $isBuiltin, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('flagEmoji: $flagEmoji, ')
          ..write('continent: $continent, ')
          ..write('colorHex: $colorHex, ')
          ..write('mapLon: $mapLon, ')
          ..write('mapLat: $mapLat, ')
          ..write('anchorLon: $anchorLon, ')
          ..write('anchorLat: $anchorLat, ')
          ..write('parentRegion: $parentRegion')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRatesTable extends ExchangeRates
    with TableInfo<$ExchangeRatesTable, ExchangeRateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pairKeyMeta = const VerificationMeta(
    'pairKey',
  );
  @override
  late final GeneratedColumn<String> pairKey = GeneratedColumn<String>(
    'pair_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quoteCurrencyMeta = const VerificationMeta(
    'quoteCurrency',
  );
  @override
  late final GeneratedColumn<String> quoteCurrency = GeneratedColumn<String>(
    'quote_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<String> rate = GeneratedColumn<String>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _asOfTimeMeta = const VerificationMeta(
    'asOfTime',
  );
  @override
  late final GeneratedColumn<DateTime> asOfTime = GeneratedColumn<DateTime>(
    'as_of_time',
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snapshotTypeMeta = const VerificationMeta(
    'snapshotType',
  );
  @override
  late final GeneratedColumn<String> snapshotType = GeneratedColumn<String>(
    'snapshot_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawPayloadMeta = const VerificationMeta(
    'rawPayload',
  );
  @override
  late final GeneratedColumn<String> rawPayload = GeneratedColumn<String>(
    'raw_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pairKey,
    baseCurrency,
    quoteCurrency,
    rate,
    asOfTime,
    updatedAt,
    source,
    snapshotType,
    rawPayload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExchangeRateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('pair_key')) {
      context.handle(
        _pairKeyMeta,
        pairKey.isAcceptableOrUnknown(data['pair_key']!, _pairKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pairKeyMeta);
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyMeta);
    }
    if (data.containsKey('quote_currency')) {
      context.handle(
        _quoteCurrencyMeta,
        quoteCurrency.isAcceptableOrUnknown(
          data['quote_currency']!,
          _quoteCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quoteCurrencyMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('as_of_time')) {
      context.handle(
        _asOfTimeMeta,
        asOfTime.isAcceptableOrUnknown(data['as_of_time']!, _asOfTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_asOfTimeMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('snapshot_type')) {
      context.handle(
        _snapshotTypeMeta,
        snapshotType.isAcceptableOrUnknown(
          data['snapshot_type']!,
          _snapshotTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotTypeMeta);
    }
    if (data.containsKey('raw_payload')) {
      context.handle(
        _rawPayloadMeta,
        rawPayload.isAcceptableOrUnknown(data['raw_payload']!, _rawPayloadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExchangeRateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pairKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pair_key'],
      )!,
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
      quoteCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_currency'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate'],
      )!,
      asOfTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}as_of_time'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      snapshotType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot_type'],
      )!,
      rawPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_payload'],
      ),
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRateRow extends DataClass implements Insertable<ExchangeRateRow> {
  final String id;
  final String pairKey;
  final String baseCurrency;
  final String quoteCurrency;
  final String rate;
  final DateTime asOfTime;
  final DateTime updatedAt;
  final String source;
  final String snapshotType;
  final String? rawPayload;
  const ExchangeRateRow({
    required this.id,
    required this.pairKey,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.rate,
    required this.asOfTime,
    required this.updatedAt,
    required this.source,
    required this.snapshotType,
    this.rawPayload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['pair_key'] = Variable<String>(pairKey);
    map['base_currency'] = Variable<String>(baseCurrency);
    map['quote_currency'] = Variable<String>(quoteCurrency);
    map['rate'] = Variable<String>(rate);
    map['as_of_time'] = Variable<DateTime>(asOfTime);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['source'] = Variable<String>(source);
    map['snapshot_type'] = Variable<String>(snapshotType);
    if (!nullToAbsent || rawPayload != null) {
      map['raw_payload'] = Variable<String>(rawPayload);
    }
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      id: Value(id),
      pairKey: Value(pairKey),
      baseCurrency: Value(baseCurrency),
      quoteCurrency: Value(quoteCurrency),
      rate: Value(rate),
      asOfTime: Value(asOfTime),
      updatedAt: Value(updatedAt),
      source: Value(source),
      snapshotType: Value(snapshotType),
      rawPayload: rawPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(rawPayload),
    );
  }

  factory ExchangeRateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRateRow(
      id: serializer.fromJson<String>(json['id']),
      pairKey: serializer.fromJson<String>(json['pairKey']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      quoteCurrency: serializer.fromJson<String>(json['quoteCurrency']),
      rate: serializer.fromJson<String>(json['rate']),
      asOfTime: serializer.fromJson<DateTime>(json['asOfTime']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      source: serializer.fromJson<String>(json['source']),
      snapshotType: serializer.fromJson<String>(json['snapshotType']),
      rawPayload: serializer.fromJson<String?>(json['rawPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pairKey': serializer.toJson<String>(pairKey),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'quoteCurrency': serializer.toJson<String>(quoteCurrency),
      'rate': serializer.toJson<String>(rate),
      'asOfTime': serializer.toJson<DateTime>(asOfTime),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'source': serializer.toJson<String>(source),
      'snapshotType': serializer.toJson<String>(snapshotType),
      'rawPayload': serializer.toJson<String?>(rawPayload),
    };
  }

  ExchangeRateRow copyWith({
    String? id,
    String? pairKey,
    String? baseCurrency,
    String? quoteCurrency,
    String? rate,
    DateTime? asOfTime,
    DateTime? updatedAt,
    String? source,
    String? snapshotType,
    Value<String?> rawPayload = const Value.absent(),
  }) => ExchangeRateRow(
    id: id ?? this.id,
    pairKey: pairKey ?? this.pairKey,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    quoteCurrency: quoteCurrency ?? this.quoteCurrency,
    rate: rate ?? this.rate,
    asOfTime: asOfTime ?? this.asOfTime,
    updatedAt: updatedAt ?? this.updatedAt,
    source: source ?? this.source,
    snapshotType: snapshotType ?? this.snapshotType,
    rawPayload: rawPayload.present ? rawPayload.value : this.rawPayload,
  );
  ExchangeRateRow copyWithCompanion(ExchangeRatesCompanion data) {
    return ExchangeRateRow(
      id: data.id.present ? data.id.value : this.id,
      pairKey: data.pairKey.present ? data.pairKey.value : this.pairKey,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      quoteCurrency: data.quoteCurrency.present
          ? data.quoteCurrency.value
          : this.quoteCurrency,
      rate: data.rate.present ? data.rate.value : this.rate,
      asOfTime: data.asOfTime.present ? data.asOfTime.value : this.asOfTime,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      source: data.source.present ? data.source.value : this.source,
      snapshotType: data.snapshotType.present
          ? data.snapshotType.value
          : this.snapshotType,
      rawPayload: data.rawPayload.present
          ? data.rawPayload.value
          : this.rawPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRateRow(')
          ..write('id: $id, ')
          ..write('pairKey: $pairKey, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('quoteCurrency: $quoteCurrency, ')
          ..write('rate: $rate, ')
          ..write('asOfTime: $asOfTime, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source, ')
          ..write('snapshotType: $snapshotType, ')
          ..write('rawPayload: $rawPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pairKey,
    baseCurrency,
    quoteCurrency,
    rate,
    asOfTime,
    updatedAt,
    source,
    snapshotType,
    rawPayload,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRateRow &&
          other.id == this.id &&
          other.pairKey == this.pairKey &&
          other.baseCurrency == this.baseCurrency &&
          other.quoteCurrency == this.quoteCurrency &&
          other.rate == this.rate &&
          other.asOfTime == this.asOfTime &&
          other.updatedAt == this.updatedAt &&
          other.source == this.source &&
          other.snapshotType == this.snapshotType &&
          other.rawPayload == this.rawPayload);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRateRow> {
  final Value<String> id;
  final Value<String> pairKey;
  final Value<String> baseCurrency;
  final Value<String> quoteCurrency;
  final Value<String> rate;
  final Value<DateTime> asOfTime;
  final Value<DateTime> updatedAt;
  final Value<String> source;
  final Value<String> snapshotType;
  final Value<String?> rawPayload;
  final Value<int> rowid;
  const ExchangeRatesCompanion({
    this.id = const Value.absent(),
    this.pairKey = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.quoteCurrency = const Value.absent(),
    this.rate = const Value.absent(),
    this.asOfTime = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.snapshotType = const Value.absent(),
    this.rawPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    required String id,
    required String pairKey,
    required String baseCurrency,
    required String quoteCurrency,
    required String rate,
    required DateTime asOfTime,
    required DateTime updatedAt,
    required String source,
    required String snapshotType,
    this.rawPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pairKey = Value(pairKey),
       baseCurrency = Value(baseCurrency),
       quoteCurrency = Value(quoteCurrency),
       rate = Value(rate),
       asOfTime = Value(asOfTime),
       updatedAt = Value(updatedAt),
       source = Value(source),
       snapshotType = Value(snapshotType);
  static Insertable<ExchangeRateRow> custom({
    Expression<String>? id,
    Expression<String>? pairKey,
    Expression<String>? baseCurrency,
    Expression<String>? quoteCurrency,
    Expression<String>? rate,
    Expression<DateTime>? asOfTime,
    Expression<DateTime>? updatedAt,
    Expression<String>? source,
    Expression<String>? snapshotType,
    Expression<String>? rawPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pairKey != null) 'pair_key': pairKey,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (quoteCurrency != null) 'quote_currency': quoteCurrency,
      if (rate != null) 'rate': rate,
      if (asOfTime != null) 'as_of_time': asOfTime,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (source != null) 'source': source,
      if (snapshotType != null) 'snapshot_type': snapshotType,
      if (rawPayload != null) 'raw_payload': rawPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeRatesCompanion copyWith({
    Value<String>? id,
    Value<String>? pairKey,
    Value<String>? baseCurrency,
    Value<String>? quoteCurrency,
    Value<String>? rate,
    Value<DateTime>? asOfTime,
    Value<DateTime>? updatedAt,
    Value<String>? source,
    Value<String>? snapshotType,
    Value<String?>? rawPayload,
    Value<int>? rowid,
  }) {
    return ExchangeRatesCompanion(
      id: id ?? this.id,
      pairKey: pairKey ?? this.pairKey,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      quoteCurrency: quoteCurrency ?? this.quoteCurrency,
      rate: rate ?? this.rate,
      asOfTime: asOfTime ?? this.asOfTime,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      snapshotType: snapshotType ?? this.snapshotType,
      rawPayload: rawPayload ?? this.rawPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pairKey.present) {
      map['pair_key'] = Variable<String>(pairKey.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (quoteCurrency.present) {
      map['quote_currency'] = Variable<String>(quoteCurrency.value);
    }
    if (rate.present) {
      map['rate'] = Variable<String>(rate.value);
    }
    if (asOfTime.present) {
      map['as_of_time'] = Variable<DateTime>(asOfTime.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (snapshotType.present) {
      map['snapshot_type'] = Variable<String>(snapshotType.value);
    }
    if (rawPayload.present) {
      map['raw_payload'] = Variable<String>(rawPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesCompanion(')
          ..write('id: $id, ')
          ..write('pairKey: $pairKey, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('quoteCurrency: $quoteCurrency, ')
          ..write('rate: $rate, ')
          ..write('asOfTime: $asOfTime, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('source: $source, ')
          ..write('snapshotType: $snapshotType, ')
          ..write('rawPayload: $rawPayload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relatedModelMeta = const VerificationMeta(
    'relatedModel',
  );
  @override
  late final GeneratedColumn<String> relatedModel = GeneratedColumn<String>(
    'related_model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relatedIdMeta = const VerificationMeta(
    'relatedId',
  );
  @override
  late final GeneratedColumn<String> relatedId = GeneratedColumn<String>(
    'related_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refsMeta = const VerificationMeta('refs');
  @override
  late final GeneratedColumn<String> refs = GeneratedColumn<String>(
    'refs',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _triggerTimeMeta = const VerificationMeta(
    'triggerTime',
  );
  @override
  late final GeneratedColumn<DateTime> triggerTime = GeneratedColumn<DateTime>(
    'trigger_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handlingStatusMeta = const VerificationMeta(
    'handlingStatus',
  );
  @override
  late final GeneratedColumn<String> handlingStatus = GeneratedColumn<String>(
    'handling_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _handlerMeta = const VerificationMeta(
    'handler',
  );
  @override
  late final GeneratedColumn<String> handler = GeneratedColumn<String>(
    'handler',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _handlingNoteMeta = const VerificationMeta(
    'handlingNote',
  );
  @override
  late final GeneratedColumn<String> handlingNote = GeneratedColumn<String>(
    'handling_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ackRequirementMeta = const VerificationMeta(
    'ackRequirement',
  );
  @override
  late final GeneratedColumn<String> ackRequirement = GeneratedColumn<String>(
    'ack_requirement',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('NOT_APPLICABLE'),
  );
  static const VerificationMeta _ackStatusMeta = const VerificationMeta(
    'ackStatus',
  );
  @override
  late final GeneratedColumn<String> ackStatus = GeneratedColumn<String>(
    'ack_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _ackAtMeta = const VerificationMeta('ackAt');
  @override
  late final GeneratedColumn<DateTime> ackAt = GeneratedColumn<DateTime>(
    'ack_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ackNoteMeta = const VerificationMeta(
    'ackNote',
  );
  @override
  late final GeneratedColumn<String> ackNote = GeneratedColumn<String>(
    'ack_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    eventType,
    relatedModel,
    relatedId,
    refs,
    batchId,
    sourceKey,
    triggerTime,
    dueAt,
    priority,
    status,
    handlingStatus,
    handler,
    handlingNote,
    ackRequirement,
    ackStatus,
    ackAt,
    ackNote,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('related_model')) {
      context.handle(
        _relatedModelMeta,
        relatedModel.isAcceptableOrUnknown(
          data['related_model']!,
          _relatedModelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relatedModelMeta);
    }
    if (data.containsKey('related_id')) {
      context.handle(
        _relatedIdMeta,
        relatedId.isAcceptableOrUnknown(data['related_id']!, _relatedIdMeta),
      );
    } else if (isInserting) {
      context.missing(_relatedIdMeta);
    }
    if (data.containsKey('refs')) {
      context.handle(
        _refsMeta,
        refs.isAcceptableOrUnknown(data['refs']!, _refsMeta),
      );
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    }
    if (data.containsKey('trigger_time')) {
      context.handle(
        _triggerTimeMeta,
        triggerTime.isAcceptableOrUnknown(
          data['trigger_time']!,
          _triggerTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_triggerTimeMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('handling_status')) {
      context.handle(
        _handlingStatusMeta,
        handlingStatus.isAcceptableOrUnknown(
          data['handling_status']!,
          _handlingStatusMeta,
        ),
      );
    }
    if (data.containsKey('handler')) {
      context.handle(
        _handlerMeta,
        handler.isAcceptableOrUnknown(data['handler']!, _handlerMeta),
      );
    }
    if (data.containsKey('handling_note')) {
      context.handle(
        _handlingNoteMeta,
        handlingNote.isAcceptableOrUnknown(
          data['handling_note']!,
          _handlingNoteMeta,
        ),
      );
    }
    if (data.containsKey('ack_requirement')) {
      context.handle(
        _ackRequirementMeta,
        ackRequirement.isAcceptableOrUnknown(
          data['ack_requirement']!,
          _ackRequirementMeta,
        ),
      );
    }
    if (data.containsKey('ack_status')) {
      context.handle(
        _ackStatusMeta,
        ackStatus.isAcceptableOrUnknown(data['ack_status']!, _ackStatusMeta),
      );
    }
    if (data.containsKey('ack_at')) {
      context.handle(
        _ackAtMeta,
        ackAt.isAcceptableOrUnknown(data['ack_at']!, _ackAtMeta),
      );
    }
    if (data.containsKey('ack_note')) {
      context.handle(
        _ackNoteMeta,
        ackNote.isAcceptableOrUnknown(data['ack_note']!, _ackNoteMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
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
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      relatedModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_model'],
      )!,
      relatedId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_id'],
      )!,
      refs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refs'],
      ),
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      ),
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      ),
      triggerTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trigger_time'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      handlingStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handling_status'],
      ),
      handler: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handler'],
      ),
      handlingNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handling_note'],
      ),
      ackRequirement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ack_requirement'],
      )!,
      ackStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ack_status'],
      )!,
      ackAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ack_at'],
      ),
      ackNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ack_note'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
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
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final String id;
  final String eventType;
  final String relatedModel;
  final String relatedId;
  final String? refs;
  final String? batchId;
  final String? sourceKey;
  final DateTime triggerTime;
  final DateTime? dueAt;
  final String? priority;
  final String status;
  final String? handlingStatus;
  final String? handler;
  final String? handlingNote;
  final String ackRequirement;
  final String ackStatus;
  final DateTime? ackAt;
  final String? ackNote;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EventRow({
    required this.id,
    required this.eventType,
    required this.relatedModel,
    required this.relatedId,
    this.refs,
    this.batchId,
    this.sourceKey,
    required this.triggerTime,
    this.dueAt,
    this.priority,
    required this.status,
    this.handlingStatus,
    this.handler,
    this.handlingNote,
    required this.ackRequirement,
    required this.ackStatus,
    this.ackAt,
    this.ackNote,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_type'] = Variable<String>(eventType);
    map['related_model'] = Variable<String>(relatedModel);
    map['related_id'] = Variable<String>(relatedId);
    if (!nullToAbsent || refs != null) {
      map['refs'] = Variable<String>(refs);
    }
    if (!nullToAbsent || batchId != null) {
      map['batch_id'] = Variable<String>(batchId);
    }
    if (!nullToAbsent || sourceKey != null) {
      map['source_key'] = Variable<String>(sourceKey);
    }
    map['trigger_time'] = Variable<DateTime>(triggerTime);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<String>(priority);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || handlingStatus != null) {
      map['handling_status'] = Variable<String>(handlingStatus);
    }
    if (!nullToAbsent || handler != null) {
      map['handler'] = Variable<String>(handler);
    }
    if (!nullToAbsent || handlingNote != null) {
      map['handling_note'] = Variable<String>(handlingNote);
    }
    map['ack_requirement'] = Variable<String>(ackRequirement);
    map['ack_status'] = Variable<String>(ackStatus);
    if (!nullToAbsent || ackAt != null) {
      map['ack_at'] = Variable<DateTime>(ackAt);
    }
    if (!nullToAbsent || ackNote != null) {
      map['ack_note'] = Variable<String>(ackNote);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      eventType: Value(eventType),
      relatedModel: Value(relatedModel),
      relatedId: Value(relatedId),
      refs: refs == null && nullToAbsent ? const Value.absent() : Value(refs),
      batchId: batchId == null && nullToAbsent
          ? const Value.absent()
          : Value(batchId),
      sourceKey: sourceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceKey),
      triggerTime: Value(triggerTime),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      status: Value(status),
      handlingStatus: handlingStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(handlingStatus),
      handler: handler == null && nullToAbsent
          ? const Value.absent()
          : Value(handler),
      handlingNote: handlingNote == null && nullToAbsent
          ? const Value.absent()
          : Value(handlingNote),
      ackRequirement: Value(ackRequirement),
      ackStatus: Value(ackStatus),
      ackAt: ackAt == null && nullToAbsent
          ? const Value.absent()
          : Value(ackAt),
      ackNote: ackNote == null && nullToAbsent
          ? const Value.absent()
          : Value(ackNote),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<String>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      relatedModel: serializer.fromJson<String>(json['relatedModel']),
      relatedId: serializer.fromJson<String>(json['relatedId']),
      refs: serializer.fromJson<String?>(json['refs']),
      batchId: serializer.fromJson<String?>(json['batchId']),
      sourceKey: serializer.fromJson<String?>(json['sourceKey']),
      triggerTime: serializer.fromJson<DateTime>(json['triggerTime']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      priority: serializer.fromJson<String?>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      handlingStatus: serializer.fromJson<String?>(json['handlingStatus']),
      handler: serializer.fromJson<String?>(json['handler']),
      handlingNote: serializer.fromJson<String?>(json['handlingNote']),
      ackRequirement: serializer.fromJson<String>(json['ackRequirement']),
      ackStatus: serializer.fromJson<String>(json['ackStatus']),
      ackAt: serializer.fromJson<DateTime?>(json['ackAt']),
      ackNote: serializer.fromJson<String?>(json['ackNote']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'eventType': serializer.toJson<String>(eventType),
      'relatedModel': serializer.toJson<String>(relatedModel),
      'relatedId': serializer.toJson<String>(relatedId),
      'refs': serializer.toJson<String?>(refs),
      'batchId': serializer.toJson<String?>(batchId),
      'sourceKey': serializer.toJson<String?>(sourceKey),
      'triggerTime': serializer.toJson<DateTime>(triggerTime),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'priority': serializer.toJson<String?>(priority),
      'status': serializer.toJson<String>(status),
      'handlingStatus': serializer.toJson<String?>(handlingStatus),
      'handler': serializer.toJson<String?>(handler),
      'handlingNote': serializer.toJson<String?>(handlingNote),
      'ackRequirement': serializer.toJson<String>(ackRequirement),
      'ackStatus': serializer.toJson<String>(ackStatus),
      'ackAt': serializer.toJson<DateTime?>(ackAt),
      'ackNote': serializer.toJson<String?>(ackNote),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EventRow copyWith({
    String? id,
    String? eventType,
    String? relatedModel,
    String? relatedId,
    Value<String?> refs = const Value.absent(),
    Value<String?> batchId = const Value.absent(),
    Value<String?> sourceKey = const Value.absent(),
    DateTime? triggerTime,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<String?> priority = const Value.absent(),
    String? status,
    Value<String?> handlingStatus = const Value.absent(),
    Value<String?> handler = const Value.absent(),
    Value<String?> handlingNote = const Value.absent(),
    String? ackRequirement,
    String? ackStatus,
    Value<DateTime?> ackAt = const Value.absent(),
    Value<String?> ackNote = const Value.absent(),
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EventRow(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    relatedModel: relatedModel ?? this.relatedModel,
    relatedId: relatedId ?? this.relatedId,
    refs: refs.present ? refs.value : this.refs,
    batchId: batchId.present ? batchId.value : this.batchId,
    sourceKey: sourceKey.present ? sourceKey.value : this.sourceKey,
    triggerTime: triggerTime ?? this.triggerTime,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    priority: priority.present ? priority.value : this.priority,
    status: status ?? this.status,
    handlingStatus: handlingStatus.present
        ? handlingStatus.value
        : this.handlingStatus,
    handler: handler.present ? handler.value : this.handler,
    handlingNote: handlingNote.present ? handlingNote.value : this.handlingNote,
    ackRequirement: ackRequirement ?? this.ackRequirement,
    ackStatus: ackStatus ?? this.ackStatus,
    ackAt: ackAt.present ? ackAt.value : this.ackAt,
    ackNote: ackNote.present ? ackNote.value : this.ackNote,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EventRow copyWithCompanion(EventsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      relatedModel: data.relatedModel.present
          ? data.relatedModel.value
          : this.relatedModel,
      relatedId: data.relatedId.present ? data.relatedId.value : this.relatedId,
      refs: data.refs.present ? data.refs.value : this.refs,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      triggerTime: data.triggerTime.present
          ? data.triggerTime.value
          : this.triggerTime,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      handlingStatus: data.handlingStatus.present
          ? data.handlingStatus.value
          : this.handlingStatus,
      handler: data.handler.present ? data.handler.value : this.handler,
      handlingNote: data.handlingNote.present
          ? data.handlingNote.value
          : this.handlingNote,
      ackRequirement: data.ackRequirement.present
          ? data.ackRequirement.value
          : this.ackRequirement,
      ackStatus: data.ackStatus.present ? data.ackStatus.value : this.ackStatus,
      ackAt: data.ackAt.present ? data.ackAt.value : this.ackAt,
      ackNote: data.ackNote.present ? data.ackNote.value : this.ackNote,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('relatedModel: $relatedModel, ')
          ..write('relatedId: $relatedId, ')
          ..write('refs: $refs, ')
          ..write('batchId: $batchId, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('triggerTime: $triggerTime, ')
          ..write('dueAt: $dueAt, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('handlingStatus: $handlingStatus, ')
          ..write('handler: $handler, ')
          ..write('handlingNote: $handlingNote, ')
          ..write('ackRequirement: $ackRequirement, ')
          ..write('ackStatus: $ackStatus, ')
          ..write('ackAt: $ackAt, ')
          ..write('ackNote: $ackNote, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    eventType,
    relatedModel,
    relatedId,
    refs,
    batchId,
    sourceKey,
    triggerTime,
    dueAt,
    priority,
    status,
    handlingStatus,
    handler,
    handlingNote,
    ackRequirement,
    ackStatus,
    ackAt,
    ackNote,
    isDeleted,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.relatedModel == this.relatedModel &&
          other.relatedId == this.relatedId &&
          other.refs == this.refs &&
          other.batchId == this.batchId &&
          other.sourceKey == this.sourceKey &&
          other.triggerTime == this.triggerTime &&
          other.dueAt == this.dueAt &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.handlingStatus == this.handlingStatus &&
          other.handler == this.handler &&
          other.handlingNote == this.handlingNote &&
          other.ackRequirement == this.ackRequirement &&
          other.ackStatus == this.ackStatus &&
          other.ackAt == this.ackAt &&
          other.ackNote == this.ackNote &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EventsCompanion extends UpdateCompanion<EventRow> {
  final Value<String> id;
  final Value<String> eventType;
  final Value<String> relatedModel;
  final Value<String> relatedId;
  final Value<String?> refs;
  final Value<String?> batchId;
  final Value<String?> sourceKey;
  final Value<DateTime> triggerTime;
  final Value<DateTime?> dueAt;
  final Value<String?> priority;
  final Value<String> status;
  final Value<String?> handlingStatus;
  final Value<String?> handler;
  final Value<String?> handlingNote;
  final Value<String> ackRequirement;
  final Value<String> ackStatus;
  final Value<DateTime?> ackAt;
  final Value<String?> ackNote;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.relatedModel = const Value.absent(),
    this.relatedId = const Value.absent(),
    this.refs = const Value.absent(),
    this.batchId = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.triggerTime = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.handlingStatus = const Value.absent(),
    this.handler = const Value.absent(),
    this.handlingNote = const Value.absent(),
    this.ackRequirement = const Value.absent(),
    this.ackStatus = const Value.absent(),
    this.ackAt = const Value.absent(),
    this.ackNote = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String eventType,
    required String relatedModel,
    required String relatedId,
    this.refs = const Value.absent(),
    this.batchId = const Value.absent(),
    this.sourceKey = const Value.absent(),
    required DateTime triggerTime,
    this.dueAt = const Value.absent(),
    this.priority = const Value.absent(),
    required String status,
    this.handlingStatus = const Value.absent(),
    this.handler = const Value.absent(),
    this.handlingNote = const Value.absent(),
    this.ackRequirement = const Value.absent(),
    this.ackStatus = const Value.absent(),
    this.ackAt = const Value.absent(),
    this.ackNote = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventType = Value(eventType),
       relatedModel = Value(relatedModel),
       relatedId = Value(relatedId),
       triggerTime = Value(triggerTime),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EventRow> custom({
    Expression<String>? id,
    Expression<String>? eventType,
    Expression<String>? relatedModel,
    Expression<String>? relatedId,
    Expression<String>? refs,
    Expression<String>? batchId,
    Expression<String>? sourceKey,
    Expression<DateTime>? triggerTime,
    Expression<DateTime>? dueAt,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<String>? handlingStatus,
    Expression<String>? handler,
    Expression<String>? handlingNote,
    Expression<String>? ackRequirement,
    Expression<String>? ackStatus,
    Expression<DateTime>? ackAt,
    Expression<String>? ackNote,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (relatedModel != null) 'related_model': relatedModel,
      if (relatedId != null) 'related_id': relatedId,
      if (refs != null) 'refs': refs,
      if (batchId != null) 'batch_id': batchId,
      if (sourceKey != null) 'source_key': sourceKey,
      if (triggerTime != null) 'trigger_time': triggerTime,
      if (dueAt != null) 'due_at': dueAt,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (handlingStatus != null) 'handling_status': handlingStatus,
      if (handler != null) 'handler': handler,
      if (handlingNote != null) 'handling_note': handlingNote,
      if (ackRequirement != null) 'ack_requirement': ackRequirement,
      if (ackStatus != null) 'ack_status': ackStatus,
      if (ackAt != null) 'ack_at': ackAt,
      if (ackNote != null) 'ack_note': ackNote,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventType,
    Value<String>? relatedModel,
    Value<String>? relatedId,
    Value<String?>? refs,
    Value<String?>? batchId,
    Value<String?>? sourceKey,
    Value<DateTime>? triggerTime,
    Value<DateTime?>? dueAt,
    Value<String?>? priority,
    Value<String>? status,
    Value<String?>? handlingStatus,
    Value<String?>? handler,
    Value<String?>? handlingNote,
    Value<String>? ackRequirement,
    Value<String>? ackStatus,
    Value<DateTime?>? ackAt,
    Value<String?>? ackNote,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      relatedModel: relatedModel ?? this.relatedModel,
      relatedId: relatedId ?? this.relatedId,
      refs: refs ?? this.refs,
      batchId: batchId ?? this.batchId,
      sourceKey: sourceKey ?? this.sourceKey,
      triggerTime: triggerTime ?? this.triggerTime,
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      handlingStatus: handlingStatus ?? this.handlingStatus,
      handler: handler ?? this.handler,
      handlingNote: handlingNote ?? this.handlingNote,
      ackRequirement: ackRequirement ?? this.ackRequirement,
      ackStatus: ackStatus ?? this.ackStatus,
      ackAt: ackAt ?? this.ackAt,
      ackNote: ackNote ?? this.ackNote,
      isDeleted: isDeleted ?? this.isDeleted,
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
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (relatedModel.present) {
      map['related_model'] = Variable<String>(relatedModel.value);
    }
    if (relatedId.present) {
      map['related_id'] = Variable<String>(relatedId.value);
    }
    if (refs.present) {
      map['refs'] = Variable<String>(refs.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (triggerTime.present) {
      map['trigger_time'] = Variable<DateTime>(triggerTime.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (handlingStatus.present) {
      map['handling_status'] = Variable<String>(handlingStatus.value);
    }
    if (handler.present) {
      map['handler'] = Variable<String>(handler.value);
    }
    if (handlingNote.present) {
      map['handling_note'] = Variable<String>(handlingNote.value);
    }
    if (ackRequirement.present) {
      map['ack_requirement'] = Variable<String>(ackRequirement.value);
    }
    if (ackStatus.present) {
      map['ack_status'] = Variable<String>(ackStatus.value);
    }
    if (ackAt.present) {
      map['ack_at'] = Variable<DateTime>(ackAt.value);
    }
    if (ackNote.present) {
      map['ack_note'] = Variable<String>(ackNote.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
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
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('relatedModel: $relatedModel, ')
          ..write('relatedId: $relatedId, ')
          ..write('refs: $refs, ')
          ..write('batchId: $batchId, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('triggerTime: $triggerTime, ')
          ..write('dueAt: $dueAt, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('handlingStatus: $handlingStatus, ')
          ..write('handler: $handler, ')
          ..write('handlingNote: $handlingNote, ')
          ..write('ackRequirement: $ackRequirement, ')
          ..write('ackStatus: $ackStatus, ')
          ..write('ackAt: $ackAt, ')
          ..write('ackNote: $ackNote, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RegionGroupOrdersTable extends RegionGroupOrders
    with TableInfo<$RegionGroupOrdersTable, RegionGroupOrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegionGroupOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sceneMeta = const VerificationMeta('scene');
  @override
  late final GeneratedColumn<String> scene = GeneratedColumn<String>(
    'scene',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _regionCodeMeta = const VerificationMeta(
    'regionCode',
  );
  @override
  late final GeneratedColumn<String> regionCode = GeneratedColumn<String>(
    'region_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  @override
  List<GeneratedColumn> get $columns => [scene, regionCode, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'region_group_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<RegionGroupOrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scene')) {
      context.handle(
        _sceneMeta,
        scene.isAcceptableOrUnknown(data['scene']!, _sceneMeta),
      );
    } else if (isInserting) {
      context.missing(_sceneMeta);
    }
    if (data.containsKey('region_code')) {
      context.handle(
        _regionCodeMeta,
        regionCode.isAcceptableOrUnknown(data['region_code']!, _regionCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_regionCodeMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scene, regionCode};
  @override
  RegionGroupOrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegionGroupOrderRow(
      scene: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scene'],
      )!,
      regionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_code'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $RegionGroupOrdersTable createAlias(String alias) {
    return $RegionGroupOrdersTable(attachedDatabase, alias);
  }
}

class RegionGroupOrderRow extends DataClass
    implements Insertable<RegionGroupOrderRow> {
  final String scene;
  final String regionCode;
  final int sortOrder;
  const RegionGroupOrderRow({
    required this.scene,
    required this.regionCode,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scene'] = Variable<String>(scene);
    map['region_code'] = Variable<String>(regionCode);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  RegionGroupOrdersCompanion toCompanion(bool nullToAbsent) {
    return RegionGroupOrdersCompanion(
      scene: Value(scene),
      regionCode: Value(regionCode),
      sortOrder: Value(sortOrder),
    );
  }

  factory RegionGroupOrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegionGroupOrderRow(
      scene: serializer.fromJson<String>(json['scene']),
      regionCode: serializer.fromJson<String>(json['regionCode']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scene': serializer.toJson<String>(scene),
      'regionCode': serializer.toJson<String>(regionCode),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  RegionGroupOrderRow copyWith({
    String? scene,
    String? regionCode,
    int? sortOrder,
  }) => RegionGroupOrderRow(
    scene: scene ?? this.scene,
    regionCode: regionCode ?? this.regionCode,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  RegionGroupOrderRow copyWithCompanion(RegionGroupOrdersCompanion data) {
    return RegionGroupOrderRow(
      scene: data.scene.present ? data.scene.value : this.scene,
      regionCode: data.regionCode.present
          ? data.regionCode.value
          : this.regionCode,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegionGroupOrderRow(')
          ..write('scene: $scene, ')
          ..write('regionCode: $regionCode, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scene, regionCode, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegionGroupOrderRow &&
          other.scene == this.scene &&
          other.regionCode == this.regionCode &&
          other.sortOrder == this.sortOrder);
}

class RegionGroupOrdersCompanion extends UpdateCompanion<RegionGroupOrderRow> {
  final Value<String> scene;
  final Value<String> regionCode;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const RegionGroupOrdersCompanion({
    this.scene = const Value.absent(),
    this.regionCode = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegionGroupOrdersCompanion.insert({
    required String scene,
    required String regionCode,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scene = Value(scene),
       regionCode = Value(regionCode);
  static Insertable<RegionGroupOrderRow> custom({
    Expression<String>? scene,
    Expression<String>? regionCode,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scene != null) 'scene': scene,
      if (regionCode != null) 'region_code': regionCode,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegionGroupOrdersCompanion copyWith({
    Value<String>? scene,
    Value<String>? regionCode,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return RegionGroupOrdersCompanion(
      scene: scene ?? this.scene,
      regionCode: regionCode ?? this.regionCode,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scene.present) {
      map['scene'] = Variable<String>(scene.value);
    }
    if (regionCode.present) {
      map['region_code'] = Variable<String>(regionCode.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegionGroupOrdersCompanion(')
          ..write('scene: $scene, ')
          ..write('regionCode: $regionCode, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryEntriesTable extends SearchHistoryEntries
    with TableInfo<$SearchHistoryEntriesTable, SearchHistoryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uniqueKeyMeta = const VerificationMeta(
    'uniqueKey',
  );
  @override
  late final GeneratedColumn<String> uniqueKey = GeneratedColumn<String>(
    'unique_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _featureMeta = const VerificationMeta(
    'feature',
  );
  @override
  late final GeneratedColumn<String> feature = GeneratedColumn<String>(
    'feature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sublabelMeta = const VerificationMeta(
    'sublabel',
  );
  @override
  late final GeneratedColumn<String> sublabel = GeneratedColumn<String>(
    'sublabel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitedAtMeta = const VerificationMeta(
    'visitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
    'visited_at',
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
    kind,
    uniqueKey,
    query,
    feature,
    targetId,
    label,
    sublabel,
    visitedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('unique_key')) {
      context.handle(
        _uniqueKeyMeta,
        uniqueKey.isAcceptableOrUnknown(data['unique_key']!, _uniqueKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_uniqueKeyMeta);
    }
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    }
    if (data.containsKey('feature')) {
      context.handle(
        _featureMeta,
        feature.isAcceptableOrUnknown(data['feature']!, _featureMeta),
      );
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('sublabel')) {
      context.handle(
        _sublabelMeta,
        sublabel.isAcceptableOrUnknown(data['sublabel']!, _sublabelMeta),
      );
    }
    if (data.containsKey('visited_at')) {
      context.handle(
        _visitedAtMeta,
        visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_visitedAtMeta);
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
  SearchHistoryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      uniqueKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unique_key'],
      )!,
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      ),
      feature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feature'],
      ),
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      sublabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sublabel'],
      ),
      visitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SearchHistoryEntriesTable createAlias(String alias) {
    return $SearchHistoryEntriesTable(attachedDatabase, alias);
  }
}

class SearchHistoryEntryRow extends DataClass
    implements Insertable<SearchHistoryEntryRow> {
  final int id;
  final String kind;
  final String uniqueKey;
  final String? query;
  final String? feature;
  final String? targetId;
  final String? label;
  final String? sublabel;
  final DateTime visitedAt;
  final DateTime updatedAt;
  const SearchHistoryEntryRow({
    required this.id,
    required this.kind,
    required this.uniqueKey,
    this.query,
    this.feature,
    this.targetId,
    this.label,
    this.sublabel,
    required this.visitedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['unique_key'] = Variable<String>(uniqueKey);
    if (!nullToAbsent || query != null) {
      map['query'] = Variable<String>(query);
    }
    if (!nullToAbsent || feature != null) {
      map['feature'] = Variable<String>(feature);
    }
    if (!nullToAbsent || targetId != null) {
      map['target_id'] = Variable<String>(targetId);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    if (!nullToAbsent || sublabel != null) {
      map['sublabel'] = Variable<String>(sublabel);
    }
    map['visited_at'] = Variable<DateTime>(visitedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SearchHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      uniqueKey: Value(uniqueKey),
      query: query == null && nullToAbsent
          ? const Value.absent()
          : Value(query),
      feature: feature == null && nullToAbsent
          ? const Value.absent()
          : Value(feature),
      targetId: targetId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetId),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      sublabel: sublabel == null && nullToAbsent
          ? const Value.absent()
          : Value(sublabel),
      visitedAt: Value(visitedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SearchHistoryEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryEntryRow(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      uniqueKey: serializer.fromJson<String>(json['uniqueKey']),
      query: serializer.fromJson<String?>(json['query']),
      feature: serializer.fromJson<String?>(json['feature']),
      targetId: serializer.fromJson<String?>(json['targetId']),
      label: serializer.fromJson<String?>(json['label']),
      sublabel: serializer.fromJson<String?>(json['sublabel']),
      visitedAt: serializer.fromJson<DateTime>(json['visitedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'uniqueKey': serializer.toJson<String>(uniqueKey),
      'query': serializer.toJson<String?>(query),
      'feature': serializer.toJson<String?>(feature),
      'targetId': serializer.toJson<String?>(targetId),
      'label': serializer.toJson<String?>(label),
      'sublabel': serializer.toJson<String?>(sublabel),
      'visitedAt': serializer.toJson<DateTime>(visitedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SearchHistoryEntryRow copyWith({
    int? id,
    String? kind,
    String? uniqueKey,
    Value<String?> query = const Value.absent(),
    Value<String?> feature = const Value.absent(),
    Value<String?> targetId = const Value.absent(),
    Value<String?> label = const Value.absent(),
    Value<String?> sublabel = const Value.absent(),
    DateTime? visitedAt,
    DateTime? updatedAt,
  }) => SearchHistoryEntryRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    uniqueKey: uniqueKey ?? this.uniqueKey,
    query: query.present ? query.value : this.query,
    feature: feature.present ? feature.value : this.feature,
    targetId: targetId.present ? targetId.value : this.targetId,
    label: label.present ? label.value : this.label,
    sublabel: sublabel.present ? sublabel.value : this.sublabel,
    visitedAt: visitedAt ?? this.visitedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SearchHistoryEntryRow copyWithCompanion(SearchHistoryEntriesCompanion data) {
    return SearchHistoryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      uniqueKey: data.uniqueKey.present ? data.uniqueKey.value : this.uniqueKey,
      query: data.query.present ? data.query.value : this.query,
      feature: data.feature.present ? data.feature.value : this.feature,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      label: data.label.present ? data.label.value : this.label,
      sublabel: data.sublabel.present ? data.sublabel.value : this.sublabel,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryEntryRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('uniqueKey: $uniqueKey, ')
          ..write('query: $query, ')
          ..write('feature: $feature, ')
          ..write('targetId: $targetId, ')
          ..write('label: $label, ')
          ..write('sublabel: $sublabel, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    uniqueKey,
    query,
    feature,
    targetId,
    label,
    sublabel,
    visitedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryEntryRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.uniqueKey == this.uniqueKey &&
          other.query == this.query &&
          other.feature == this.feature &&
          other.targetId == this.targetId &&
          other.label == this.label &&
          other.sublabel == this.sublabel &&
          other.visitedAt == this.visitedAt &&
          other.updatedAt == this.updatedAt);
}

class SearchHistoryEntriesCompanion
    extends UpdateCompanion<SearchHistoryEntryRow> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> uniqueKey;
  final Value<String?> query;
  final Value<String?> feature;
  final Value<String?> targetId;
  final Value<String?> label;
  final Value<String?> sublabel;
  final Value<DateTime> visitedAt;
  final Value<DateTime> updatedAt;
  const SearchHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.uniqueKey = const Value.absent(),
    this.query = const Value.absent(),
    this.feature = const Value.absent(),
    this.targetId = const Value.absent(),
    this.label = const Value.absent(),
    this.sublabel = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SearchHistoryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String uniqueKey,
    this.query = const Value.absent(),
    this.feature = const Value.absent(),
    this.targetId = const Value.absent(),
    this.label = const Value.absent(),
    this.sublabel = const Value.absent(),
    required DateTime visitedAt,
    required DateTime updatedAt,
  }) : kind = Value(kind),
       uniqueKey = Value(uniqueKey),
       visitedAt = Value(visitedAt),
       updatedAt = Value(updatedAt);
  static Insertable<SearchHistoryEntryRow> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? uniqueKey,
    Expression<String>? query,
    Expression<String>? feature,
    Expression<String>? targetId,
    Expression<String>? label,
    Expression<String>? sublabel,
    Expression<DateTime>? visitedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (uniqueKey != null) 'unique_key': uniqueKey,
      if (query != null) 'query': query,
      if (feature != null) 'feature': feature,
      if (targetId != null) 'target_id': targetId,
      if (label != null) 'label': label,
      if (sublabel != null) 'sublabel': sublabel,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SearchHistoryEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? uniqueKey,
    Value<String?>? query,
    Value<String?>? feature,
    Value<String?>? targetId,
    Value<String?>? label,
    Value<String?>? sublabel,
    Value<DateTime>? visitedAt,
    Value<DateTime>? updatedAt,
  }) {
    return SearchHistoryEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      query: query ?? this.query,
      feature: feature ?? this.feature,
      targetId: targetId ?? this.targetId,
      label: label ?? this.label,
      sublabel: sublabel ?? this.sublabel,
      visitedAt: visitedAt ?? this.visitedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (uniqueKey.present) {
      map['unique_key'] = Variable<String>(uniqueKey.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (feature.present) {
      map['feature'] = Variable<String>(feature.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (sublabel.present) {
      map['sublabel'] = Variable<String>(sublabel.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('uniqueKey: $uniqueKey, ')
          ..write('query: $query, ')
          ..write('feature: $feature, ')
          ..write('targetId: $targetId, ')
          ..write('label: $label, ')
          ..write('sublabel: $sublabel, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WatchedPairsTable extends WatchedPairs
    with TableInfo<$WatchedPairsTable, WatchedPairRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchedPairsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pairKeyMeta = const VerificationMeta(
    'pairKey',
  );
  @override
  late final GeneratedColumn<String> pairKey = GeneratedColumn<String>(
    'pair_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quoteCurrencyMeta = const VerificationMeta(
    'quoteCurrency',
  );
  @override
  late final GeneratedColumn<String> quoteCurrency = GeneratedColumn<String>(
    'quote_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _thresholdHighMeta = const VerificationMeta(
    'thresholdHigh',
  );
  @override
  late final GeneratedColumn<String> thresholdHigh = GeneratedColumn<String>(
    'threshold_high',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thresholdLowMeta = const VerificationMeta(
    'thresholdLow',
  );
  @override
  late final GeneratedColumn<String> thresholdLow = GeneratedColumn<String>(
    'threshold_low',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alertChangePctMeta = const VerificationMeta(
    'alertChangePct',
  );
  @override
  late final GeneratedColumn<String> alertChangePct = GeneratedColumn<String>(
    'alert_change_pct',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  @override
  List<GeneratedColumn> get $columns => [
    pairKey,
    baseCurrency,
    quoteCurrency,
    createdAt,
    thresholdHigh,
    thresholdLow,
    alertChangePct,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watched_pairs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchedPairRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('pair_key')) {
      context.handle(
        _pairKeyMeta,
        pairKey.isAcceptableOrUnknown(data['pair_key']!, _pairKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_pairKeyMeta);
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyMeta);
    }
    if (data.containsKey('quote_currency')) {
      context.handle(
        _quoteCurrencyMeta,
        quoteCurrency.isAcceptableOrUnknown(
          data['quote_currency']!,
          _quoteCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quoteCurrencyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('threshold_high')) {
      context.handle(
        _thresholdHighMeta,
        thresholdHigh.isAcceptableOrUnknown(
          data['threshold_high']!,
          _thresholdHighMeta,
        ),
      );
    }
    if (data.containsKey('threshold_low')) {
      context.handle(
        _thresholdLowMeta,
        thresholdLow.isAcceptableOrUnknown(
          data['threshold_low']!,
          _thresholdLowMeta,
        ),
      );
    }
    if (data.containsKey('alert_change_pct')) {
      context.handle(
        _alertChangePctMeta,
        alertChangePct.isAcceptableOrUnknown(
          data['alert_change_pct']!,
          _alertChangePctMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pairKey};
  @override
  WatchedPairRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchedPairRow(
      pairKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pair_key'],
      )!,
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
      quoteCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote_currency'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      thresholdHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}threshold_high'],
      ),
      thresholdLow: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}threshold_low'],
      ),
      alertChangePct: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_change_pct'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $WatchedPairsTable createAlias(String alias) {
    return $WatchedPairsTable(attachedDatabase, alias);
  }
}

class WatchedPairRow extends DataClass implements Insertable<WatchedPairRow> {
  final String pairKey;
  final String baseCurrency;
  final String quoteCurrency;
  final DateTime createdAt;
  final String? thresholdHigh;
  final String? thresholdLow;
  final String? alertChangePct;
  final int sortOrder;
  const WatchedPairRow({
    required this.pairKey,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.createdAt,
    this.thresholdHigh,
    this.thresholdLow,
    this.alertChangePct,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['pair_key'] = Variable<String>(pairKey);
    map['base_currency'] = Variable<String>(baseCurrency);
    map['quote_currency'] = Variable<String>(quoteCurrency);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || thresholdHigh != null) {
      map['threshold_high'] = Variable<String>(thresholdHigh);
    }
    if (!nullToAbsent || thresholdLow != null) {
      map['threshold_low'] = Variable<String>(thresholdLow);
    }
    if (!nullToAbsent || alertChangePct != null) {
      map['alert_change_pct'] = Variable<String>(alertChangePct);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  WatchedPairsCompanion toCompanion(bool nullToAbsent) {
    return WatchedPairsCompanion(
      pairKey: Value(pairKey),
      baseCurrency: Value(baseCurrency),
      quoteCurrency: Value(quoteCurrency),
      createdAt: Value(createdAt),
      thresholdHigh: thresholdHigh == null && nullToAbsent
          ? const Value.absent()
          : Value(thresholdHigh),
      thresholdLow: thresholdLow == null && nullToAbsent
          ? const Value.absent()
          : Value(thresholdLow),
      alertChangePct: alertChangePct == null && nullToAbsent
          ? const Value.absent()
          : Value(alertChangePct),
      sortOrder: Value(sortOrder),
    );
  }

  factory WatchedPairRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchedPairRow(
      pairKey: serializer.fromJson<String>(json['pairKey']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      quoteCurrency: serializer.fromJson<String>(json['quoteCurrency']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      thresholdHigh: serializer.fromJson<String?>(json['thresholdHigh']),
      thresholdLow: serializer.fromJson<String?>(json['thresholdLow']),
      alertChangePct: serializer.fromJson<String?>(json['alertChangePct']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pairKey': serializer.toJson<String>(pairKey),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'quoteCurrency': serializer.toJson<String>(quoteCurrency),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'thresholdHigh': serializer.toJson<String?>(thresholdHigh),
      'thresholdLow': serializer.toJson<String?>(thresholdLow),
      'alertChangePct': serializer.toJson<String?>(alertChangePct),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  WatchedPairRow copyWith({
    String? pairKey,
    String? baseCurrency,
    String? quoteCurrency,
    DateTime? createdAt,
    Value<String?> thresholdHigh = const Value.absent(),
    Value<String?> thresholdLow = const Value.absent(),
    Value<String?> alertChangePct = const Value.absent(),
    int? sortOrder,
  }) => WatchedPairRow(
    pairKey: pairKey ?? this.pairKey,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    quoteCurrency: quoteCurrency ?? this.quoteCurrency,
    createdAt: createdAt ?? this.createdAt,
    thresholdHigh: thresholdHigh.present
        ? thresholdHigh.value
        : this.thresholdHigh,
    thresholdLow: thresholdLow.present ? thresholdLow.value : this.thresholdLow,
    alertChangePct: alertChangePct.present
        ? alertChangePct.value
        : this.alertChangePct,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  WatchedPairRow copyWithCompanion(WatchedPairsCompanion data) {
    return WatchedPairRow(
      pairKey: data.pairKey.present ? data.pairKey.value : this.pairKey,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      quoteCurrency: data.quoteCurrency.present
          ? data.quoteCurrency.value
          : this.quoteCurrency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      thresholdHigh: data.thresholdHigh.present
          ? data.thresholdHigh.value
          : this.thresholdHigh,
      thresholdLow: data.thresholdLow.present
          ? data.thresholdLow.value
          : this.thresholdLow,
      alertChangePct: data.alertChangePct.present
          ? data.alertChangePct.value
          : this.alertChangePct,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchedPairRow(')
          ..write('pairKey: $pairKey, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('quoteCurrency: $quoteCurrency, ')
          ..write('createdAt: $createdAt, ')
          ..write('thresholdHigh: $thresholdHigh, ')
          ..write('thresholdLow: $thresholdLow, ')
          ..write('alertChangePct: $alertChangePct, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pairKey,
    baseCurrency,
    quoteCurrency,
    createdAt,
    thresholdHigh,
    thresholdLow,
    alertChangePct,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchedPairRow &&
          other.pairKey == this.pairKey &&
          other.baseCurrency == this.baseCurrency &&
          other.quoteCurrency == this.quoteCurrency &&
          other.createdAt == this.createdAt &&
          other.thresholdHigh == this.thresholdHigh &&
          other.thresholdLow == this.thresholdLow &&
          other.alertChangePct == this.alertChangePct &&
          other.sortOrder == this.sortOrder);
}

class WatchedPairsCompanion extends UpdateCompanion<WatchedPairRow> {
  final Value<String> pairKey;
  final Value<String> baseCurrency;
  final Value<String> quoteCurrency;
  final Value<DateTime> createdAt;
  final Value<String?> thresholdHigh;
  final Value<String?> thresholdLow;
  final Value<String?> alertChangePct;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const WatchedPairsCompanion({
    this.pairKey = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.quoteCurrency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.thresholdHigh = const Value.absent(),
    this.thresholdLow = const Value.absent(),
    this.alertChangePct = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchedPairsCompanion.insert({
    required String pairKey,
    required String baseCurrency,
    required String quoteCurrency,
    required DateTime createdAt,
    this.thresholdHigh = const Value.absent(),
    this.thresholdLow = const Value.absent(),
    this.alertChangePct = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pairKey = Value(pairKey),
       baseCurrency = Value(baseCurrency),
       quoteCurrency = Value(quoteCurrency),
       createdAt = Value(createdAt);
  static Insertable<WatchedPairRow> custom({
    Expression<String>? pairKey,
    Expression<String>? baseCurrency,
    Expression<String>? quoteCurrency,
    Expression<DateTime>? createdAt,
    Expression<String>? thresholdHigh,
    Expression<String>? thresholdLow,
    Expression<String>? alertChangePct,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pairKey != null) 'pair_key': pairKey,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (quoteCurrency != null) 'quote_currency': quoteCurrency,
      if (createdAt != null) 'created_at': createdAt,
      if (thresholdHigh != null) 'threshold_high': thresholdHigh,
      if (thresholdLow != null) 'threshold_low': thresholdLow,
      if (alertChangePct != null) 'alert_change_pct': alertChangePct,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchedPairsCompanion copyWith({
    Value<String>? pairKey,
    Value<String>? baseCurrency,
    Value<String>? quoteCurrency,
    Value<DateTime>? createdAt,
    Value<String?>? thresholdHigh,
    Value<String?>? thresholdLow,
    Value<String?>? alertChangePct,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return WatchedPairsCompanion(
      pairKey: pairKey ?? this.pairKey,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      quoteCurrency: quoteCurrency ?? this.quoteCurrency,
      createdAt: createdAt ?? this.createdAt,
      thresholdHigh: thresholdHigh ?? this.thresholdHigh,
      thresholdLow: thresholdLow ?? this.thresholdLow,
      alertChangePct: alertChangePct ?? this.alertChangePct,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pairKey.present) {
      map['pair_key'] = Variable<String>(pairKey.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (quoteCurrency.present) {
      map['quote_currency'] = Variable<String>(quoteCurrency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (thresholdHigh.present) {
      map['threshold_high'] = Variable<String>(thresholdHigh.value);
    }
    if (thresholdLow.present) {
      map['threshold_low'] = Variable<String>(thresholdLow.value);
    }
    if (alertChangePct.present) {
      map['alert_change_pct'] = Variable<String>(alertChangePct.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchedPairsCompanion(')
          ..write('pairKey: $pairKey, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('quoteCurrency: $quoteCurrency, ')
          ..write('createdAt: $createdAt, ')
          ..write('thresholdHigh: $thresholdHigh, ')
          ..write('thresholdLow: $thresholdLow, ')
          ..write('alertChangePct: $alertChangePct, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $AccountChannelsTable accountChannels = $AccountChannelsTable(
    this,
  );
  late final $AssetsTable assets = $AssetsTable(this);
  late final $AssetCostHistoryTable assetCostHistory = $AssetCostHistoryTable(
    this,
  );
  late final $AssetPriceHistoryTable assetPriceHistory =
      $AssetPriceHistoryTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $DictEntriesTable dictEntries = $DictEntriesTable(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $RegionGroupOrdersTable regionGroupOrders =
      $RegionGroupOrdersTable(this);
  late final $SearchHistoryEntriesTable searchHistoryEntries =
      $SearchHistoryEntriesTable(this);
  late final $WatchedPairsTable watchedPairs = $WatchedPairsTable(this);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final AccountChannelDao accountChannelDao = AccountChannelDao(
    this as AppDatabase,
  );
  late final AssetDao assetDao = AssetDao(this as AppDatabase);
  late final AssetCostHistoryDao assetCostHistoryDao = AssetCostHistoryDao(
    this as AppDatabase,
  );
  late final AssetPriceHistoryDao assetPriceHistoryDao = AssetPriceHistoryDao(
    this as AppDatabase,
  );
  late final CardDao cardDao = CardDao(this as AppDatabase);
  late final ChannelDao channelDao = ChannelDao(this as AppDatabase);
  late final DictEntryDao dictEntryDao = DictEntryDao(this as AppDatabase);
  late final EventDao eventDao = EventDao(this as AppDatabase);
  late final ExchangeRateDao exchangeRateDao = ExchangeRateDao(
    this as AppDatabase,
  );
  late final SearchHistoryDao searchHistoryDao = SearchHistoryDao(
    this as AppDatabase,
  );
  late final WatchedPairDao watchedPairDao = WatchedPairDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    channels,
    accountChannels,
    assets,
    assetCostHistory,
    assetPriceHistory,
    cards,
    dictEntries,
    exchangeRates,
    events,
    regionGroupOrders,
    searchHistoryEntries,
    watchedPairs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('account_channels', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'channels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('account_channels', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      Value<String?> accountNo,
      required String accountType,
      required String sovereigntyRegion,
      required String institutionName,
      required String status,
      Value<DateTime?> openedAt,
      Value<String?> extInfo,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<double> fxSpreadPercent,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String?> accountNo,
      Value<String> accountType,
      Value<String> sovereigntyRegion,
      Value<String> institutionName,
      Value<String> status,
      Value<DateTime?> openedAt,
      Value<String?> extInfo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<double> fxSpreadPercent,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountRow> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountChannelsTable, List<AccountChannelRow>>
  _accountChannelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accountChannels,
    aliasName: $_aliasNameGenerator(
      db.accounts.id,
      db.accountChannels.accountId,
    ),
  );

  $$AccountChannelsTableProcessedTableManager get accountChannelsRefs {
    final manager = $$AccountChannelsTableTableManager(
      $_db,
      $_db.accountChannels,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountChannelsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssetsTable, List<AssetRow>> _assetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assets,
    aliasName: $_aliasNameGenerator(db.accounts.id, db.assets.accountId),
  );

  $$AssetsTableProcessedTableManager get assetsRefs {
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CardsTable, List<CardRow>> _cardsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: $_aliasNameGenerator(db.accounts.id, db.cards.accountId),
  );

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get accountNo => $composableBuilder(
    column: $table.accountNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sovereigntyRegion => $composableBuilder(
    column: $table.sovereigntyRegion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institutionName => $composableBuilder(
    column: $table.institutionName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extInfo => $composableBuilder(
    column: $table.extInfo,
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

  ColumnFilters<double> get fxSpreadPercent => $composableBuilder(
    column: $table.fxSpreadPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountChannelsRefs(
    Expression<bool> Function($$AccountChannelsTableFilterComposer f) f,
  ) {
    final $$AccountChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountChannels,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountChannelsTableFilterComposer(
            $db: $db,
            $table: $db.accountChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetsRefs(
    Expression<bool> Function($$AssetsTableFilterComposer f) f,
  ) {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cardsRefs(
    Expression<bool> Function($$CardsTableFilterComposer f) f,
  ) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get accountNo => $composableBuilder(
    column: $table.accountNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sovereigntyRegion => $composableBuilder(
    column: $table.sovereigntyRegion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institutionName => $composableBuilder(
    column: $table.institutionName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extInfo => $composableBuilder(
    column: $table.extInfo,
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

  ColumnOrderings<double> get fxSpreadPercent => $composableBuilder(
    column: $table.fxSpreadPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountNo =>
      $composableBuilder(column: $table.accountNo, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sovereigntyRegion => $composableBuilder(
    column: $table.sovereigntyRegion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get institutionName => $composableBuilder(
    column: $table.institutionName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<String> get extInfo =>
      $composableBuilder(column: $table.extInfo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<double> get fxSpreadPercent => $composableBuilder(
    column: $table.fxSpreadPercent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> accountChannelsRefs<T extends Object>(
    Expression<T> Function($$AccountChannelsTableAnnotationComposer a) f,
  ) {
    final $$AccountChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountChannels,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.accountChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetsRefs<T extends Object>(
    Expression<T> Function($$AssetsTableAnnotationComposer a) f,
  ) {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($$CardsTableAnnotationComposer a) f,
  ) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountRow,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (AccountRow, $$AccountsTableReferences),
          AccountRow,
          PrefetchHooks Function({
            bool accountChannelsRefs,
            bool assetsRefs,
            bool cardsRefs,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> accountNo = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<String> sovereigntyRegion = const Value.absent(),
                Value<String> institutionName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> openedAt = const Value.absent(),
                Value<String?> extInfo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<double> fxSpreadPercent = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                accountNo: accountNo,
                accountType: accountType,
                sovereigntyRegion: sovereigntyRegion,
                institutionName: institutionName,
                status: status,
                openedAt: openedAt,
                extInfo: extInfo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                fxSpreadPercent: fxSpreadPercent,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> accountNo = const Value.absent(),
                required String accountType,
                required String sovereigntyRegion,
                required String institutionName,
                required String status,
                Value<DateTime?> openedAt = const Value.absent(),
                Value<String?> extInfo = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<double> fxSpreadPercent = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                accountNo: accountNo,
                accountType: accountType,
                sovereigntyRegion: sovereigntyRegion,
                institutionName: institutionName,
                status: status,
                openedAt: openedAt,
                extInfo: extInfo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                fxSpreadPercent: fxSpreadPercent,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountChannelsRefs = false,
                assetsRefs = false,
                cardsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (accountChannelsRefs) db.accountChannels,
                    if (assetsRefs) db.assets,
                    if (cardsRefs) db.cards,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountChannelsRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $AccountsTable,
                          AccountChannelRow
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._accountChannelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).accountChannelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetsRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $AccountsTable,
                          AssetRow
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._assetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardsRefs)
                        await $_getPrefetchedData<
                          AccountRow,
                          $AccountsTable,
                          CardRow
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._cardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).cardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountRow,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountRow, $$AccountsTableReferences),
      AccountRow,
      PrefetchHooks Function({
        bool accountChannelsRefs,
        bool assetsRefs,
        bool cardsRefs,
      })
    >;
typedef $$ChannelsTableCreateCompanionBuilder =
    ChannelsCompanion Function({
      required String id,
      required String name,
      required String transferProtocol,
      Value<bool> isBuiltin,
      Value<String?> feeRate,
      Value<String?> fixedFee,
      Value<String?> sovereigntyRegionRule,
      Value<String?> limitCurrency,
      Value<String?> dailyLimit,
      Value<String?> singleLimit,
      required String status,
      Value<int> sortOrder,
      Value<DateTime?> effectiveFrom,
      Value<DateTime?> effectiveTo,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChannelsTableUpdateCompanionBuilder =
    ChannelsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> transferProtocol,
      Value<bool> isBuiltin,
      Value<String?> feeRate,
      Value<String?> fixedFee,
      Value<String?> sovereigntyRegionRule,
      Value<String?> limitCurrency,
      Value<String?> dailyLimit,
      Value<String?> singleLimit,
      Value<String> status,
      Value<int> sortOrder,
      Value<DateTime?> effectiveFrom,
      Value<DateTime?> effectiveTo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ChannelsTableReferences
    extends BaseReferences<_$AppDatabase, $ChannelsTable, ChannelRow> {
  $$ChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountChannelsTable, List<AccountChannelRow>>
  _accountChannelsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accountChannels,
    aliasName: $_aliasNameGenerator(
      db.channels.id,
      db.accountChannels.channelId,
    ),
  );

  $$AccountChannelsTableProcessedTableManager get accountChannelsRefs {
    final manager = $$AccountChannelsTableTableManager(
      $_db,
      $_db.accountChannels,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _accountChannelsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferProtocol => $composableBuilder(
    column: $table.transferProtocol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feeRate => $composableBuilder(
    column: $table.feeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedFee => $composableBuilder(
    column: $table.fixedFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sovereigntyRegionRule => $composableBuilder(
    column: $table.sovereigntyRegionRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get limitCurrency => $composableBuilder(
    column: $table.limitCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyLimit => $composableBuilder(
    column: $table.dailyLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get singleLimit => $composableBuilder(
    column: $table.singleLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
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

  Expression<bool> accountChannelsRefs(
    Expression<bool> Function($$AccountChannelsTableFilterComposer f) f,
  ) {
    final $$AccountChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountChannels,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountChannelsTableFilterComposer(
            $db: $db,
            $table: $db.accountChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferProtocol => $composableBuilder(
    column: $table.transferProtocol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feeRate => $composableBuilder(
    column: $table.feeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedFee => $composableBuilder(
    column: $table.fixedFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sovereigntyRegionRule => $composableBuilder(
    column: $table.sovereigntyRegionRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get limitCurrency => $composableBuilder(
    column: $table.limitCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyLimit => $composableBuilder(
    column: $table.dailyLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get singleLimit => $composableBuilder(
    column: $table.singleLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
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

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get transferProtocol => $composableBuilder(
    column: $table.transferProtocol,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<String> get feeRate =>
      $composableBuilder(column: $table.feeRate, builder: (column) => column);

  GeneratedColumn<String> get fixedFee =>
      $composableBuilder(column: $table.fixedFee, builder: (column) => column);

  GeneratedColumn<String> get sovereigntyRegionRule => $composableBuilder(
    column: $table.sovereigntyRegionRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get limitCurrency => $composableBuilder(
    column: $table.limitCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dailyLimit => $composableBuilder(
    column: $table.dailyLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get singleLimit => $composableBuilder(
    column: $table.singleLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get effectiveTo => $composableBuilder(
    column: $table.effectiveTo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> accountChannelsRefs<T extends Object>(
    Expression<T> Function($$AccountChannelsTableAnnotationComposer a) f,
  ) {
    final $$AccountChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accountChannels,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.accountChannels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          ChannelRow,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (ChannelRow, $$ChannelsTableReferences),
          ChannelRow,
          PrefetchHooks Function({bool accountChannelsRefs})
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> transferProtocol = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                Value<String?> feeRate = const Value.absent(),
                Value<String?> fixedFee = const Value.absent(),
                Value<String?> sovereigntyRegionRule = const Value.absent(),
                Value<String?> limitCurrency = const Value.absent(),
                Value<String?> dailyLimit = const Value.absent(),
                Value<String?> singleLimit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> effectiveFrom = const Value.absent(),
                Value<DateTime?> effectiveTo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                name: name,
                transferProtocol: transferProtocol,
                isBuiltin: isBuiltin,
                feeRate: feeRate,
                fixedFee: fixedFee,
                sovereigntyRegionRule: sovereigntyRegionRule,
                limitCurrency: limitCurrency,
                dailyLimit: dailyLimit,
                singleLimit: singleLimit,
                status: status,
                sortOrder: sortOrder,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String transferProtocol,
                Value<bool> isBuiltin = const Value.absent(),
                Value<String?> feeRate = const Value.absent(),
                Value<String?> fixedFee = const Value.absent(),
                Value<String?> sovereigntyRegionRule = const Value.absent(),
                Value<String?> limitCurrency = const Value.absent(),
                Value<String?> dailyLimit = const Value.absent(),
                Value<String?> singleLimit = const Value.absent(),
                required String status,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> effectiveFrom = const Value.absent(),
                Value<DateTime?> effectiveTo = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                name: name,
                transferProtocol: transferProtocol,
                isBuiltin: isBuiltin,
                feeRate: feeRate,
                fixedFee: fixedFee,
                sovereigntyRegionRule: sovereigntyRegionRule,
                limitCurrency: limitCurrency,
                dailyLimit: dailyLimit,
                singleLimit: singleLimit,
                status: status,
                sortOrder: sortOrder,
                effectiveFrom: effectiveFrom,
                effectiveTo: effectiveTo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountChannelsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (accountChannelsRefs) db.accountChannels,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountChannelsRefs)
                    await $_getPrefetchedData<
                      ChannelRow,
                      $ChannelsTable,
                      AccountChannelRow
                    >(
                      currentTable: table,
                      referencedTable: $$ChannelsTableReferences
                          ._accountChannelsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ChannelsTableReferences(
                        db,
                        table,
                        p0,
                      ).accountChannelsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.channelId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      ChannelRow,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (ChannelRow, $$ChannelsTableReferences),
      ChannelRow,
      PrefetchHooks Function({bool accountChannelsRefs})
    >;
typedef $$AccountChannelsTableCreateCompanionBuilder =
    AccountChannelsCompanion Function({
      required String accountId,
      required String channelId,
      Value<String?> feeRateOverride,
      Value<String?> fixedFeeOverride,
      Value<String?> feeCurrencyOverride,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$AccountChannelsTableUpdateCompanionBuilder =
    AccountChannelsCompanion Function({
      Value<String> accountId,
      Value<String> channelId,
      Value<String?> feeRateOverride,
      Value<String?> fixedFeeOverride,
      Value<String?> feeCurrencyOverride,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

final class $$AccountChannelsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AccountChannelsTable,
          AccountChannelRow
        > {
  $$AccountChannelsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.accountChannels.accountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChannelsTable _channelIdTable(_$AppDatabase db) =>
      db.channels.createAlias(
        $_aliasNameGenerator(db.accountChannels.channelId, db.channels.id),
      );

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<String>('channel_id')!;

    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AccountChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountChannelsTable> {
  $$AccountChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get feeRateOverride => $composableBuilder(
    column: $table.feeRateOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedFeeOverride => $composableBuilder(
    column: $table.fixedFeeOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feeCurrencyOverride => $composableBuilder(
    column: $table.feeCurrencyOverride,
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

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountChannelsTable> {
  $$AccountChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get feeRateOverride => $composableBuilder(
    column: $table.feeRateOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedFeeOverride => $composableBuilder(
    column: $table.fixedFeeOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feeCurrencyOverride => $composableBuilder(
    column: $table.feeCurrencyOverride,
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

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountChannelsTable> {
  $$AccountChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get feeRateOverride => $composableBuilder(
    column: $table.feeRateOverride,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fixedFeeOverride => $composableBuilder(
    column: $table.fixedFeeOverride,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feeCurrencyOverride => $composableBuilder(
    column: $table.feeCurrencyOverride,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountChannelsTable,
          AccountChannelRow,
          $$AccountChannelsTableFilterComposer,
          $$AccountChannelsTableOrderingComposer,
          $$AccountChannelsTableAnnotationComposer,
          $$AccountChannelsTableCreateCompanionBuilder,
          $$AccountChannelsTableUpdateCompanionBuilder,
          (AccountChannelRow, $$AccountChannelsTableReferences),
          AccountChannelRow,
          PrefetchHooks Function({bool accountId, bool channelId})
        > {
  $$AccountChannelsTableTableManager(
    _$AppDatabase db,
    $AccountChannelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String?> feeRateOverride = const Value.absent(),
                Value<String?> fixedFeeOverride = const Value.absent(),
                Value<String?> feeCurrencyOverride = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountChannelsCompanion(
                accountId: accountId,
                channelId: channelId,
                feeRateOverride: feeRateOverride,
                fixedFeeOverride: fixedFeeOverride,
                feeCurrencyOverride: feeCurrencyOverride,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String channelId,
                Value<String?> feeRateOverride = const Value.absent(),
                Value<String?> fixedFeeOverride = const Value.absent(),
                Value<String?> feeCurrencyOverride = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountChannelsCompanion.insert(
                accountId: accountId,
                channelId: channelId,
                feeRateOverride: feeRateOverride,
                fixedFeeOverride: fixedFeeOverride,
                feeCurrencyOverride: feeCurrencyOverride,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false, channelId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$AccountChannelsTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$AccountChannelsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable:
                                    $$AccountChannelsTableReferences
                                        ._channelIdTable(db),
                                referencedColumn:
                                    $$AccountChannelsTableReferences
                                        ._channelIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AccountChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountChannelsTable,
      AccountChannelRow,
      $$AccountChannelsTableFilterComposer,
      $$AccountChannelsTableOrderingComposer,
      $$AccountChannelsTableAnnotationComposer,
      $$AccountChannelsTableCreateCompanionBuilder,
      $$AccountChannelsTableUpdateCompanionBuilder,
      (AccountChannelRow, $$AccountChannelsTableReferences),
      AccountChannelRow,
      PrefetchHooks Function({bool accountId, bool channelId})
    >;
typedef $$AssetsTableCreateCompanionBuilder =
    AssetsCompanion Function({
      required String id,
      required String accountId,
      required String assetType,
      Value<String?> assetCode,
      required String quantity,
      Value<String?> costPrice,
      Value<String?> currentPrice,
      required String currency,
      Value<String?> marketValue,
      Value<DateTime?> valuationTime,
      required String status,
      Value<String?> extInfo,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$AssetsTableUpdateCompanionBuilder =
    AssetsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> assetType,
      Value<String?> assetCode,
      Value<String> quantity,
      Value<String?> costPrice,
      Value<String?> currentPrice,
      Value<String> currency,
      Value<String?> marketValue,
      Value<DateTime?> valuationTime,
      Value<String> status,
      Value<String?> extInfo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$AssetsTableReferences
    extends BaseReferences<_$AppDatabase, $AssetsTable, AssetRow> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) => db.accounts
      .createAlias($_aliasNameGenerator(db.assets.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AssetCostHistoryTable, List<AssetCostHistoryRow>>
  _assetCostHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetCostHistory,
    aliasName: $_aliasNameGenerator(db.assets.id, db.assetCostHistory.assetId),
  );

  $$AssetCostHistoryTableProcessedTableManager get assetCostHistoryRefs {
    final manager = $$AssetCostHistoryTableTableManager(
      $_db,
      $_db.assetCostHistory,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _assetCostHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AssetPriceHistoryTable,
    List<AssetPriceHistoryRow>
  >
  _assetPriceHistoryRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.assetPriceHistory,
        aliasName: $_aliasNameGenerator(
          db.assets.id,
          db.assetPriceHistory.assetId,
        ),
      );

  $$AssetPriceHistoryTableProcessedTableManager get assetPriceHistoryRefs {
    final manager = $$AssetPriceHistoryTableTableManager(
      $_db,
      $_db.assetPriceHistory,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _assetPriceHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetsTableFilterComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
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

  ColumnFilters<String> get assetType => $composableBuilder(
    column: $table.assetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetCode => $composableBuilder(
    column: $table.assetCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marketValue => $composableBuilder(
    column: $table.marketValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get valuationTime => $composableBuilder(
    column: $table.valuationTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extInfo => $composableBuilder(
    column: $table.extInfo,
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

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> assetCostHistoryRefs(
    Expression<bool> Function($$AssetCostHistoryTableFilterComposer f) f,
  ) {
    final $$AssetCostHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetCostHistory,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCostHistoryTableFilterComposer(
            $db: $db,
            $table: $db.assetCostHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetPriceHistoryRefs(
    Expression<bool> Function($$AssetPriceHistoryTableFilterComposer f) f,
  ) {
    final $$AssetPriceHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetPriceHistory,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetPriceHistoryTableFilterComposer(
            $db: $db,
            $table: $db.assetPriceHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
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

  ColumnOrderings<String> get assetType => $composableBuilder(
    column: $table.assetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetCode => $composableBuilder(
    column: $table.assetCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marketValue => $composableBuilder(
    column: $table.marketValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get valuationTime => $composableBuilder(
    column: $table.valuationTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extInfo => $composableBuilder(
    column: $table.extInfo,
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

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get assetType =>
      $composableBuilder(column: $table.assetType, builder: (column) => column);

  GeneratedColumn<String> get assetCode =>
      $composableBuilder(column: $table.assetCode, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<String> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get marketValue => $composableBuilder(
    column: $table.marketValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get valuationTime => $composableBuilder(
    column: $table.valuationTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get extInfo =>
      $composableBuilder(column: $table.extInfo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> assetCostHistoryRefs<T extends Object>(
    Expression<T> Function($$AssetCostHistoryTableAnnotationComposer a) f,
  ) {
    final $$AssetCostHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetCostHistory,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCostHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.assetCostHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetPriceHistoryRefs<T extends Object>(
    Expression<T> Function($$AssetPriceHistoryTableAnnotationComposer a) f,
  ) {
    final $$AssetPriceHistoryTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.assetPriceHistory,
          getReferencedColumn: (t) => t.assetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AssetPriceHistoryTableAnnotationComposer(
                $db: $db,
                $table: $db.assetPriceHistory,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetsTable,
          AssetRow,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (AssetRow, $$AssetsTableReferences),
          AssetRow,
          PrefetchHooks Function({
            bool accountId,
            bool assetCostHistoryRefs,
            bool assetPriceHistoryRefs,
          })
        > {
  $$AssetsTableTableManager(_$AppDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> assetType = const Value.absent(),
                Value<String?> assetCode = const Value.absent(),
                Value<String> quantity = const Value.absent(),
                Value<String?> costPrice = const Value.absent(),
                Value<String?> currentPrice = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> marketValue = const Value.absent(),
                Value<DateTime?> valuationTime = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> extInfo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                accountId: accountId,
                assetType: assetType,
                assetCode: assetCode,
                quantity: quantity,
                costPrice: costPrice,
                currentPrice: currentPrice,
                currency: currency,
                marketValue: marketValue,
                valuationTime: valuationTime,
                status: status,
                extInfo: extInfo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String assetType,
                Value<String?> assetCode = const Value.absent(),
                required String quantity,
                Value<String?> costPrice = const Value.absent(),
                Value<String?> currentPrice = const Value.absent(),
                required String currency,
                Value<String?> marketValue = const Value.absent(),
                Value<DateTime?> valuationTime = const Value.absent(),
                required String status,
                Value<String?> extInfo = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                accountId: accountId,
                assetType: assetType,
                assetCode: assetCode,
                quantity: quantity,
                costPrice: costPrice,
                currentPrice: currentPrice,
                currency: currency,
                marketValue: marketValue,
                valuationTime: valuationTime,
                status: status,
                extInfo: extInfo,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AssetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountId = false,
                assetCostHistoryRefs = false,
                assetPriceHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assetCostHistoryRefs) db.assetCostHistory,
                    if (assetPriceHistoryRefs) db.assetPriceHistory,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable: $$AssetsTableReferences
                                        ._accountIdTable(db),
                                    referencedColumn: $$AssetsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assetCostHistoryRefs)
                        await $_getPrefetchedData<
                          AssetRow,
                          $AssetsTable,
                          AssetCostHistoryRow
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._assetCostHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetCostHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetPriceHistoryRefs)
                        await $_getPrefetchedData<
                          AssetRow,
                          $AssetsTable,
                          AssetPriceHistoryRow
                        >(
                          currentTable: table,
                          referencedTable: $$AssetsTableReferences
                              ._assetPriceHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AssetsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetPriceHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assetId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetsTable,
      AssetRow,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (AssetRow, $$AssetsTableReferences),
      AssetRow,
      PrefetchHooks Function({
        bool accountId,
        bool assetCostHistoryRefs,
        bool assetPriceHistoryRefs,
      })
    >;
typedef $$AssetCostHistoryTableCreateCompanionBuilder =
    AssetCostHistoryCompanion Function({
      required String id,
      required String assetId,
      Value<String?> costPrice,
      required String quantity,
      required String currency,
      required String source,
      Value<String?> reason,
      required DateTime triggerTime,
      Value<String?> sourceKey,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AssetCostHistoryTableUpdateCompanionBuilder =
    AssetCostHistoryCompanion Function({
      Value<String> id,
      Value<String> assetId,
      Value<String?> costPrice,
      Value<String> quantity,
      Value<String> currency,
      Value<String> source,
      Value<String?> reason,
      Value<DateTime> triggerTime,
      Value<String?> sourceKey,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AssetCostHistoryTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AssetCostHistoryTable,
          AssetCostHistoryRow
        > {
  $$AssetCostHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.assetCostHistory.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetCostHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $AssetCostHistoryTable> {
  $$AssetCostHistoryTableFilterComposer({
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

  ColumnFilters<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetCostHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetCostHistoryTable> {
  $$AssetCostHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get costPrice => $composableBuilder(
    column: $table.costPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetCostHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetCostHistoryTable> {
  $$AssetCostHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetCostHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetCostHistoryTable,
          AssetCostHistoryRow,
          $$AssetCostHistoryTableFilterComposer,
          $$AssetCostHistoryTableOrderingComposer,
          $$AssetCostHistoryTableAnnotationComposer,
          $$AssetCostHistoryTableCreateCompanionBuilder,
          $$AssetCostHistoryTableUpdateCompanionBuilder,
          (AssetCostHistoryRow, $$AssetCostHistoryTableReferences),
          AssetCostHistoryRow,
          PrefetchHooks Function({bool assetId})
        > {
  $$AssetCostHistoryTableTableManager(
    _$AppDatabase db,
    $AssetCostHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetCostHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetCostHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetCostHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String?> costPrice = const Value.absent(),
                Value<String> quantity = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<DateTime> triggerTime = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetCostHistoryCompanion(
                id: id,
                assetId: assetId,
                costPrice: costPrice,
                quantity: quantity,
                currency: currency,
                source: source,
                reason: reason,
                triggerTime: triggerTime,
                sourceKey: sourceKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String assetId,
                Value<String?> costPrice = const Value.absent(),
                required String quantity,
                required String currency,
                required String source,
                Value<String?> reason = const Value.absent(),
                required DateTime triggerTime,
                Value<String?> sourceKey = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AssetCostHistoryCompanion.insert(
                id: id,
                assetId: assetId,
                costPrice: costPrice,
                quantity: quantity,
                currency: currency,
                source: source,
                reason: reason,
                triggerTime: triggerTime,
                sourceKey: sourceKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetCostHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable:
                                    $$AssetCostHistoryTableReferences
                                        ._assetIdTable(db),
                                referencedColumn:
                                    $$AssetCostHistoryTableReferences
                                        ._assetIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssetCostHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetCostHistoryTable,
      AssetCostHistoryRow,
      $$AssetCostHistoryTableFilterComposer,
      $$AssetCostHistoryTableOrderingComposer,
      $$AssetCostHistoryTableAnnotationComposer,
      $$AssetCostHistoryTableCreateCompanionBuilder,
      $$AssetCostHistoryTableUpdateCompanionBuilder,
      (AssetCostHistoryRow, $$AssetCostHistoryTableReferences),
      AssetCostHistoryRow,
      PrefetchHooks Function({bool assetId})
    >;
typedef $$AssetPriceHistoryTableCreateCompanionBuilder =
    AssetPriceHistoryCompanion Function({
      required String id,
      required String assetId,
      required String price,
      Value<String?> marketValue,
      required String currency,
      required String source,
      Value<String?> batchId,
      required DateTime triggerTime,
      Value<String?> sourceKey,
      Value<String?> rawPayload,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AssetPriceHistoryTableUpdateCompanionBuilder =
    AssetPriceHistoryCompanion Function({
      Value<String> id,
      Value<String> assetId,
      Value<String> price,
      Value<String?> marketValue,
      Value<String> currency,
      Value<String> source,
      Value<String?> batchId,
      Value<DateTime> triggerTime,
      Value<String?> sourceKey,
      Value<String?> rawPayload,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AssetPriceHistoryTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AssetPriceHistoryTable,
          AssetPriceHistoryRow
        > {
  $$AssetPriceHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AssetsTable _assetIdTable(_$AppDatabase db) => db.assets.createAlias(
    $_aliasNameGenerator(db.assetPriceHistory.assetId, db.assets.id),
  );

  $$AssetsTableProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetPriceHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $AssetPriceHistoryTable> {
  $$AssetPriceHistoryTableFilterComposer({
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

  ColumnFilters<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get marketValue => $composableBuilder(
    column: $table.marketValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetsTableFilterComposer get assetId {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetPriceHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetPriceHistoryTable> {
  $$AssetPriceHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get marketValue => $composableBuilder(
    column: $table.marketValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetsTableOrderingComposer get assetId {
    final $$AssetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetPriceHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetPriceHistoryTable> {
  $$AssetPriceHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get marketValue => $composableBuilder(
    column: $table.marketValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AssetsTableAnnotationComposer get assetId {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetPriceHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetPriceHistoryTable,
          AssetPriceHistoryRow,
          $$AssetPriceHistoryTableFilterComposer,
          $$AssetPriceHistoryTableOrderingComposer,
          $$AssetPriceHistoryTableAnnotationComposer,
          $$AssetPriceHistoryTableCreateCompanionBuilder,
          $$AssetPriceHistoryTableUpdateCompanionBuilder,
          (AssetPriceHistoryRow, $$AssetPriceHistoryTableReferences),
          AssetPriceHistoryRow,
          PrefetchHooks Function({bool assetId})
        > {
  $$AssetPriceHistoryTableTableManager(
    _$AppDatabase db,
    $AssetPriceHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetPriceHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetPriceHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetPriceHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String> price = const Value.absent(),
                Value<String?> marketValue = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<DateTime> triggerTime = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<String?> rawPayload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetPriceHistoryCompanion(
                id: id,
                assetId: assetId,
                price: price,
                marketValue: marketValue,
                currency: currency,
                source: source,
                batchId: batchId,
                triggerTime: triggerTime,
                sourceKey: sourceKey,
                rawPayload: rawPayload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String assetId,
                required String price,
                Value<String?> marketValue = const Value.absent(),
                required String currency,
                required String source,
                Value<String?> batchId = const Value.absent(),
                required DateTime triggerTime,
                Value<String?> sourceKey = const Value.absent(),
                Value<String?> rawPayload = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AssetPriceHistoryCompanion.insert(
                id: id,
                assetId: assetId,
                price: price,
                marketValue: marketValue,
                currency: currency,
                source: source,
                batchId: batchId,
                triggerTime: triggerTime,
                sourceKey: sourceKey,
                rawPayload: rawPayload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetPriceHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (assetId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.assetId,
                                referencedTable:
                                    $$AssetPriceHistoryTableReferences
                                        ._assetIdTable(db),
                                referencedColumn:
                                    $$AssetPriceHistoryTableReferences
                                        ._assetIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssetPriceHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetPriceHistoryTable,
      AssetPriceHistoryRow,
      $$AssetPriceHistoryTableFilterComposer,
      $$AssetPriceHistoryTableOrderingComposer,
      $$AssetPriceHistoryTableAnnotationComposer,
      $$AssetPriceHistoryTableCreateCompanionBuilder,
      $$AssetPriceHistoryTableUpdateCompanionBuilder,
      (AssetPriceHistoryRow, $$AssetPriceHistoryTableReferences),
      AssetPriceHistoryRow,
      PrefetchHooks Function({bool assetId})
    >;
typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      required String id,
      required String accountId,
      required String cardOrganization,
      required String cardNoMasked,
      Value<String?> cardNoCiphertext,
      required String cardType,
      required int expireMonth,
      required int expireYear,
      Value<String?> cvvCiphertext,
      required String issuerName,
      Value<String?> currency,
      Value<bool> supportsAllCurrencies,
      Value<String?> supportedCurrencies,
      Value<String?> creditLimit,
      Value<String?> availableCredit,
      Value<int?> billingCycleDay,
      Value<int?> paymentDueDay,
      Value<String?> billingAddress,
      Value<bool> isVirtual,
      required String status,
      Value<int> sortOrder,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String> cardOrganization,
      Value<String> cardNoMasked,
      Value<String?> cardNoCiphertext,
      Value<String> cardType,
      Value<int> expireMonth,
      Value<int> expireYear,
      Value<String?> cvvCiphertext,
      Value<String> issuerName,
      Value<String?> currency,
      Value<bool> supportsAllCurrencies,
      Value<String?> supportedCurrencies,
      Value<String?> creditLimit,
      Value<String?> availableCredit,
      Value<int?> billingCycleDay,
      Value<int?> paymentDueDay,
      Value<String?> billingAddress,
      Value<bool> isVirtual,
      Value<String> status,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$CardsTableReferences
    extends BaseReferences<_$AppDatabase, $CardsTable, CardRow> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) => db.accounts
      .createAlias($_aliasNameGenerator(db.cards.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
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

  ColumnFilters<String> get cardOrganization => $composableBuilder(
    column: $table.cardOrganization,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardNoMasked => $composableBuilder(
    column: $table.cardNoMasked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardNoCiphertext => $composableBuilder(
    column: $table.cardNoCiphertext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expireMonth => $composableBuilder(
    column: $table.expireMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expireYear => $composableBuilder(
    column: $table.expireYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cvvCiphertext => $composableBuilder(
    column: $table.cvvCiphertext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get issuerName => $composableBuilder(
    column: $table.issuerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get supportsAllCurrencies => $composableBuilder(
    column: $table.supportsAllCurrencies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supportedCurrencies => $composableBuilder(
    column: $table.supportedCurrencies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availableCredit => $composableBuilder(
    column: $table.availableCredit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billingCycleDay => $composableBuilder(
    column: $table.billingCycleDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billingAddress => $composableBuilder(
    column: $table.billingAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isVirtual => $composableBuilder(
    column: $table.isVirtual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
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

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
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

  ColumnOrderings<String> get cardOrganization => $composableBuilder(
    column: $table.cardOrganization,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardNoMasked => $composableBuilder(
    column: $table.cardNoMasked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardNoCiphertext => $composableBuilder(
    column: $table.cardNoCiphertext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardType => $composableBuilder(
    column: $table.cardType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expireMonth => $composableBuilder(
    column: $table.expireMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expireYear => $composableBuilder(
    column: $table.expireYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cvvCiphertext => $composableBuilder(
    column: $table.cvvCiphertext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get issuerName => $composableBuilder(
    column: $table.issuerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get supportsAllCurrencies => $composableBuilder(
    column: $table.supportsAllCurrencies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supportedCurrencies => $composableBuilder(
    column: $table.supportedCurrencies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availableCredit => $composableBuilder(
    column: $table.availableCredit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billingCycleDay => $composableBuilder(
    column: $table.billingCycleDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billingAddress => $composableBuilder(
    column: $table.billingAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isVirtual => $composableBuilder(
    column: $table.isVirtual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
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

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardOrganization => $composableBuilder(
    column: $table.cardOrganization,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardNoMasked => $composableBuilder(
    column: $table.cardNoMasked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardNoCiphertext => $composableBuilder(
    column: $table.cardNoCiphertext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<int> get expireMonth => $composableBuilder(
    column: $table.expireMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expireYear => $composableBuilder(
    column: $table.expireYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cvvCiphertext => $composableBuilder(
    column: $table.cvvCiphertext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get issuerName => $composableBuilder(
    column: $table.issuerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get supportsAllCurrencies => $composableBuilder(
    column: $table.supportsAllCurrencies,
    builder: (column) => column,
  );

  GeneratedColumn<String> get supportedCurrencies => $composableBuilder(
    column: $table.supportedCurrencies,
    builder: (column) => column,
  );

  GeneratedColumn<String> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availableCredit => $composableBuilder(
    column: $table.availableCredit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billingCycleDay => $composableBuilder(
    column: $table.billingCycleDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paymentDueDay => $composableBuilder(
    column: $table.paymentDueDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get billingAddress => $composableBuilder(
    column: $table.billingAddress,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isVirtual =>
      $composableBuilder(column: $table.isVirtual, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CardsTable,
          CardRow,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (CardRow, $$CardsTableReferences),
          CardRow,
          PrefetchHooks Function({bool accountId})
        > {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> cardOrganization = const Value.absent(),
                Value<String> cardNoMasked = const Value.absent(),
                Value<String?> cardNoCiphertext = const Value.absent(),
                Value<String> cardType = const Value.absent(),
                Value<int> expireMonth = const Value.absent(),
                Value<int> expireYear = const Value.absent(),
                Value<String?> cvvCiphertext = const Value.absent(),
                Value<String> issuerName = const Value.absent(),
                Value<String?> currency = const Value.absent(),
                Value<bool> supportsAllCurrencies = const Value.absent(),
                Value<String?> supportedCurrencies = const Value.absent(),
                Value<String?> creditLimit = const Value.absent(),
                Value<String?> availableCredit = const Value.absent(),
                Value<int?> billingCycleDay = const Value.absent(),
                Value<int?> paymentDueDay = const Value.absent(),
                Value<String?> billingAddress = const Value.absent(),
                Value<bool> isVirtual = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                accountId: accountId,
                cardOrganization: cardOrganization,
                cardNoMasked: cardNoMasked,
                cardNoCiphertext: cardNoCiphertext,
                cardType: cardType,
                expireMonth: expireMonth,
                expireYear: expireYear,
                cvvCiphertext: cvvCiphertext,
                issuerName: issuerName,
                currency: currency,
                supportsAllCurrencies: supportsAllCurrencies,
                supportedCurrencies: supportedCurrencies,
                creditLimit: creditLimit,
                availableCredit: availableCredit,
                billingCycleDay: billingCycleDay,
                paymentDueDay: paymentDueDay,
                billingAddress: billingAddress,
                isVirtual: isVirtual,
                status: status,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required String cardOrganization,
                required String cardNoMasked,
                Value<String?> cardNoCiphertext = const Value.absent(),
                required String cardType,
                required int expireMonth,
                required int expireYear,
                Value<String?> cvvCiphertext = const Value.absent(),
                required String issuerName,
                Value<String?> currency = const Value.absent(),
                Value<bool> supportsAllCurrencies = const Value.absent(),
                Value<String?> supportedCurrencies = const Value.absent(),
                Value<String?> creditLimit = const Value.absent(),
                Value<String?> availableCredit = const Value.absent(),
                Value<int?> billingCycleDay = const Value.absent(),
                Value<int?> paymentDueDay = const Value.absent(),
                Value<String?> billingAddress = const Value.absent(),
                Value<bool> isVirtual = const Value.absent(),
                required String status,
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                accountId: accountId,
                cardOrganization: cardOrganization,
                cardNoMasked: cardNoMasked,
                cardNoCiphertext: cardNoCiphertext,
                cardType: cardType,
                expireMonth: expireMonth,
                expireYear: expireYear,
                cvvCiphertext: cvvCiphertext,
                issuerName: issuerName,
                currency: currency,
                supportsAllCurrencies: supportsAllCurrencies,
                supportedCurrencies: supportedCurrencies,
                creditLimit: creditLimit,
                availableCredit: availableCredit,
                billingCycleDay: billingCycleDay,
                paymentDueDay: paymentDueDay,
                billingAddress: billingAddress,
                isVirtual: isVirtual,
                status: status,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$CardsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$CardsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CardsTable,
      CardRow,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (CardRow, $$CardsTableReferences),
      CardRow,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$DictEntriesTableCreateCompanionBuilder =
    DictEntriesCompanion Function({
      Value<int> id,
      required String type,
      required String code,
      required String name,
      Value<String?> nameEn,
      Value<int> sortOrder,
      Value<bool> isBuiltin,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> flagEmoji,
      Value<String?> continent,
      Value<String?> colorHex,
      Value<double?> mapLon,
      Value<double?> mapLat,
      Value<double?> anchorLon,
      Value<double?> anchorLat,
      Value<String?> parentRegion,
    });
typedef $$DictEntriesTableUpdateCompanionBuilder =
    DictEntriesCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> code,
      Value<String> name,
      Value<String?> nameEn,
      Value<int> sortOrder,
      Value<bool> isBuiltin,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> flagEmoji,
      Value<String?> continent,
      Value<String?> colorHex,
      Value<double?> mapLon,
      Value<double?> mapLat,
      Value<double?> anchorLon,
      Value<double?> anchorLat,
      Value<String?> parentRegion,
    });

class $$DictEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictEntriesTable> {
  $$DictEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
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

  ColumnFilters<String> get flagEmoji => $composableBuilder(
    column: $table.flagEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get continent => $composableBuilder(
    column: $table.continent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mapLon => $composableBuilder(
    column: $table.mapLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mapLat => $composableBuilder(
    column: $table.mapLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get anchorLon => $composableBuilder(
    column: $table.anchorLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get anchorLat => $composableBuilder(
    column: $table.anchorLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentRegion => $composableBuilder(
    column: $table.parentRegion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictEntriesTable> {
  $$DictEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameEn => $composableBuilder(
    column: $table.nameEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltin => $composableBuilder(
    column: $table.isBuiltin,
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

  ColumnOrderings<String> get flagEmoji => $composableBuilder(
    column: $table.flagEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get continent => $composableBuilder(
    column: $table.continent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mapLon => $composableBuilder(
    column: $table.mapLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mapLat => $composableBuilder(
    column: $table.mapLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get anchorLon => $composableBuilder(
    column: $table.anchorLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get anchorLat => $composableBuilder(
    column: $table.anchorLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentRegion => $composableBuilder(
    column: $table.parentRegion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictEntriesTable> {
  $$DictEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameEn =>
      $composableBuilder(column: $table.nameEn, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isBuiltin =>
      $composableBuilder(column: $table.isBuiltin, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get flagEmoji =>
      $composableBuilder(column: $table.flagEmoji, builder: (column) => column);

  GeneratedColumn<String> get continent =>
      $composableBuilder(column: $table.continent, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<double> get mapLon =>
      $composableBuilder(column: $table.mapLon, builder: (column) => column);

  GeneratedColumn<double> get mapLat =>
      $composableBuilder(column: $table.mapLat, builder: (column) => column);

  GeneratedColumn<double> get anchorLon =>
      $composableBuilder(column: $table.anchorLon, builder: (column) => column);

  GeneratedColumn<double> get anchorLat =>
      $composableBuilder(column: $table.anchorLat, builder: (column) => column);

  GeneratedColumn<String> get parentRegion => $composableBuilder(
    column: $table.parentRegion,
    builder: (column) => column,
  );
}

class $$DictEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictEntriesTable,
          DictEntryRow,
          $$DictEntriesTableFilterComposer,
          $$DictEntriesTableOrderingComposer,
          $$DictEntriesTableAnnotationComposer,
          $$DictEntriesTableCreateCompanionBuilder,
          $$DictEntriesTableUpdateCompanionBuilder,
          (
            DictEntryRow,
            BaseReferences<_$AppDatabase, $DictEntriesTable, DictEntryRow>,
          ),
          DictEntryRow,
          PrefetchHooks Function()
        > {
  $$DictEntriesTableTableManager(_$AppDatabase db, $DictEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> nameEn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> flagEmoji = const Value.absent(),
                Value<String?> continent = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<double?> mapLon = const Value.absent(),
                Value<double?> mapLat = const Value.absent(),
                Value<double?> anchorLon = const Value.absent(),
                Value<double?> anchorLat = const Value.absent(),
                Value<String?> parentRegion = const Value.absent(),
              }) => DictEntriesCompanion(
                id: id,
                type: type,
                code: code,
                name: name,
                nameEn: nameEn,
                sortOrder: sortOrder,
                isBuiltin: isBuiltin,
                createdAt: createdAt,
                updatedAt: updatedAt,
                flagEmoji: flagEmoji,
                continent: continent,
                colorHex: colorHex,
                mapLon: mapLon,
                mapLat: mapLat,
                anchorLon: anchorLon,
                anchorLat: anchorLat,
                parentRegion: parentRegion,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required String code,
                required String name,
                Value<String?> nameEn = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isBuiltin = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> flagEmoji = const Value.absent(),
                Value<String?> continent = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<double?> mapLon = const Value.absent(),
                Value<double?> mapLat = const Value.absent(),
                Value<double?> anchorLon = const Value.absent(),
                Value<double?> anchorLat = const Value.absent(),
                Value<String?> parentRegion = const Value.absent(),
              }) => DictEntriesCompanion.insert(
                id: id,
                type: type,
                code: code,
                name: name,
                nameEn: nameEn,
                sortOrder: sortOrder,
                isBuiltin: isBuiltin,
                createdAt: createdAt,
                updatedAt: updatedAt,
                flagEmoji: flagEmoji,
                continent: continent,
                colorHex: colorHex,
                mapLon: mapLon,
                mapLat: mapLat,
                anchorLon: anchorLon,
                anchorLat: anchorLat,
                parentRegion: parentRegion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictEntriesTable,
      DictEntryRow,
      $$DictEntriesTableFilterComposer,
      $$DictEntriesTableOrderingComposer,
      $$DictEntriesTableAnnotationComposer,
      $$DictEntriesTableCreateCompanionBuilder,
      $$DictEntriesTableUpdateCompanionBuilder,
      (
        DictEntryRow,
        BaseReferences<_$AppDatabase, $DictEntriesTable, DictEntryRow>,
      ),
      DictEntryRow,
      PrefetchHooks Function()
    >;
typedef $$ExchangeRatesTableCreateCompanionBuilder =
    ExchangeRatesCompanion Function({
      required String id,
      required String pairKey,
      required String baseCurrency,
      required String quoteCurrency,
      required String rate,
      required DateTime asOfTime,
      required DateTime updatedAt,
      required String source,
      required String snapshotType,
      Value<String?> rawPayload,
      Value<int> rowid,
    });
typedef $$ExchangeRatesTableUpdateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<String> id,
      Value<String> pairKey,
      Value<String> baseCurrency,
      Value<String> quoteCurrency,
      Value<String> rate,
      Value<DateTime> asOfTime,
      Value<DateTime> updatedAt,
      Value<String> source,
      Value<String> snapshotType,
      Value<String?> rawPayload,
      Value<int> rowid,
    });

class $$ExchangeRatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer({
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

  ColumnFilters<String> get pairKey => $composableBuilder(
    column: $table.pairKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quoteCurrency => $composableBuilder(
    column: $table.quoteCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get asOfTime => $composableBuilder(
    column: $table.asOfTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshotType => $composableBuilder(
    column: $table.snapshotType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExchangeRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer({
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

  ColumnOrderings<String> get pairKey => $composableBuilder(
    column: $table.pairKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoteCurrency => $composableBuilder(
    column: $table.quoteCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get asOfTime => $composableBuilder(
    column: $table.asOfTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshotType => $composableBuilder(
    column: $table.snapshotType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExchangeRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pairKey =>
      $composableBuilder(column: $table.pairKey, builder: (column) => column);

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quoteCurrency => $composableBuilder(
    column: $table.quoteCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<DateTime> get asOfTime =>
      $composableBuilder(column: $table.asOfTime, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get snapshotType => $composableBuilder(
    column: $table.snapshotType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawPayload => $composableBuilder(
    column: $table.rawPayload,
    builder: (column) => column,
  );
}

class $$ExchangeRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExchangeRatesTable,
          ExchangeRateRow,
          $$ExchangeRatesTableFilterComposer,
          $$ExchangeRatesTableOrderingComposer,
          $$ExchangeRatesTableAnnotationComposer,
          $$ExchangeRatesTableCreateCompanionBuilder,
          $$ExchangeRatesTableUpdateCompanionBuilder,
          (
            ExchangeRateRow,
            BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRateRow>,
          ),
          ExchangeRateRow,
          PrefetchHooks Function()
        > {
  $$ExchangeRatesTableTableManager(_$AppDatabase db, $ExchangeRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pairKey = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> quoteCurrency = const Value.absent(),
                Value<String> rate = const Value.absent(),
                Value<DateTime> asOfTime = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> snapshotType = const Value.absent(),
                Value<String?> rawPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion(
                id: id,
                pairKey: pairKey,
                baseCurrency: baseCurrency,
                quoteCurrency: quoteCurrency,
                rate: rate,
                asOfTime: asOfTime,
                updatedAt: updatedAt,
                source: source,
                snapshotType: snapshotType,
                rawPayload: rawPayload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pairKey,
                required String baseCurrency,
                required String quoteCurrency,
                required String rate,
                required DateTime asOfTime,
                required DateTime updatedAt,
                required String source,
                required String snapshotType,
                Value<String?> rawPayload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion.insert(
                id: id,
                pairKey: pairKey,
                baseCurrency: baseCurrency,
                quoteCurrency: quoteCurrency,
                rate: rate,
                asOfTime: asOfTime,
                updatedAt: updatedAt,
                source: source,
                snapshotType: snapshotType,
                rawPayload: rawPayload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExchangeRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExchangeRatesTable,
      ExchangeRateRow,
      $$ExchangeRatesTableFilterComposer,
      $$ExchangeRatesTableOrderingComposer,
      $$ExchangeRatesTableAnnotationComposer,
      $$ExchangeRatesTableCreateCompanionBuilder,
      $$ExchangeRatesTableUpdateCompanionBuilder,
      (
        ExchangeRateRow,
        BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRateRow>,
      ),
      ExchangeRateRow,
      PrefetchHooks Function()
    >;
typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      required String id,
      required String eventType,
      required String relatedModel,
      required String relatedId,
      Value<String?> refs,
      Value<String?> batchId,
      Value<String?> sourceKey,
      required DateTime triggerTime,
      Value<DateTime?> dueAt,
      Value<String?> priority,
      required String status,
      Value<String?> handlingStatus,
      Value<String?> handler,
      Value<String?> handlingNote,
      Value<String> ackRequirement,
      Value<String> ackStatus,
      Value<DateTime?> ackAt,
      Value<String?> ackNote,
      Value<bool> isDeleted,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<String> id,
      Value<String> eventType,
      Value<String> relatedModel,
      Value<String> relatedId,
      Value<String?> refs,
      Value<String?> batchId,
      Value<String?> sourceKey,
      Value<DateTime> triggerTime,
      Value<DateTime?> dueAt,
      Value<String?> priority,
      Value<String> status,
      Value<String?> handlingStatus,
      Value<String?> handler,
      Value<String?> handlingNote,
      Value<String> ackRequirement,
      Value<String> ackStatus,
      Value<DateTime?> ackAt,
      Value<String?> ackNote,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
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

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedModel => $composableBuilder(
    column: $table.relatedModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedId => $composableBuilder(
    column: $table.relatedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refs => $composableBuilder(
    column: $table.refs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handlingStatus => $composableBuilder(
    column: $table.handlingStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handler => $composableBuilder(
    column: $table.handler,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handlingNote => $composableBuilder(
    column: $table.handlingNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ackRequirement => $composableBuilder(
    column: $table.ackRequirement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ackStatus => $composableBuilder(
    column: $table.ackStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ackAt => $composableBuilder(
    column: $table.ackAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ackNote => $composableBuilder(
    column: $table.ackNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
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

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
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

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedModel => $composableBuilder(
    column: $table.relatedModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedId => $composableBuilder(
    column: $table.relatedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refs => $composableBuilder(
    column: $table.refs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handlingStatus => $composableBuilder(
    column: $table.handlingStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handler => $composableBuilder(
    column: $table.handler,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handlingNote => $composableBuilder(
    column: $table.handlingNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ackRequirement => $composableBuilder(
    column: $table.ackRequirement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ackStatus => $composableBuilder(
    column: $table.ackStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ackAt => $composableBuilder(
    column: $table.ackAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ackNote => $composableBuilder(
    column: $table.ackNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
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

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get relatedModel => $composableBuilder(
    column: $table.relatedModel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedId =>
      $composableBuilder(column: $table.relatedId, builder: (column) => column);

  GeneratedColumn<String> get refs =>
      $composableBuilder(column: $table.refs, builder: (column) => column);

  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<DateTime> get triggerTime => $composableBuilder(
    column: $table.triggerTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get handlingStatus => $composableBuilder(
    column: $table.handlingStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get handler =>
      $composableBuilder(column: $table.handler, builder: (column) => column);

  GeneratedColumn<String> get handlingNote => $composableBuilder(
    column: $table.handlingNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ackRequirement => $composableBuilder(
    column: $table.ackRequirement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ackStatus =>
      $composableBuilder(column: $table.ackStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get ackAt =>
      $composableBuilder(column: $table.ackAt, builder: (column) => column);

  GeneratedColumn<String> get ackNote =>
      $composableBuilder(column: $table.ackNote, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          EventRow,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (EventRow, BaseReferences<_$AppDatabase, $EventsTable, EventRow>),
          EventRow,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> relatedModel = const Value.absent(),
                Value<String> relatedId = const Value.absent(),
                Value<String?> refs = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                Value<DateTime> triggerTime = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<String?> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> handlingStatus = const Value.absent(),
                Value<String?> handler = const Value.absent(),
                Value<String?> handlingNote = const Value.absent(),
                Value<String> ackRequirement = const Value.absent(),
                Value<String> ackStatus = const Value.absent(),
                Value<DateTime?> ackAt = const Value.absent(),
                Value<String?> ackNote = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                eventType: eventType,
                relatedModel: relatedModel,
                relatedId: relatedId,
                refs: refs,
                batchId: batchId,
                sourceKey: sourceKey,
                triggerTime: triggerTime,
                dueAt: dueAt,
                priority: priority,
                status: status,
                handlingStatus: handlingStatus,
                handler: handler,
                handlingNote: handlingNote,
                ackRequirement: ackRequirement,
                ackStatus: ackStatus,
                ackAt: ackAt,
                ackNote: ackNote,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventType,
                required String relatedModel,
                required String relatedId,
                Value<String?> refs = const Value.absent(),
                Value<String?> batchId = const Value.absent(),
                Value<String?> sourceKey = const Value.absent(),
                required DateTime triggerTime,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<String?> priority = const Value.absent(),
                required String status,
                Value<String?> handlingStatus = const Value.absent(),
                Value<String?> handler = const Value.absent(),
                Value<String?> handlingNote = const Value.absent(),
                Value<String> ackRequirement = const Value.absent(),
                Value<String> ackStatus = const Value.absent(),
                Value<DateTime?> ackAt = const Value.absent(),
                Value<String?> ackNote = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                eventType: eventType,
                relatedModel: relatedModel,
                relatedId: relatedId,
                refs: refs,
                batchId: batchId,
                sourceKey: sourceKey,
                triggerTime: triggerTime,
                dueAt: dueAt,
                priority: priority,
                status: status,
                handlingStatus: handlingStatus,
                handler: handler,
                handlingNote: handlingNote,
                ackRequirement: ackRequirement,
                ackStatus: ackStatus,
                ackAt: ackAt,
                ackNote: ackNote,
                isDeleted: isDeleted,
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

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      EventRow,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$AppDatabase, $EventsTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;
typedef $$RegionGroupOrdersTableCreateCompanionBuilder =
    RegionGroupOrdersCompanion Function({
      required String scene,
      required String regionCode,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$RegionGroupOrdersTableUpdateCompanionBuilder =
    RegionGroupOrdersCompanion Function({
      Value<String> scene,
      Value<String> regionCode,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$RegionGroupOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $RegionGroupOrdersTable> {
  $$RegionGroupOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scene => $composableBuilder(
    column: $table.scene,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RegionGroupOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $RegionGroupOrdersTable> {
  $$RegionGroupOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scene => $composableBuilder(
    column: $table.scene,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RegionGroupOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RegionGroupOrdersTable> {
  $$RegionGroupOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scene =>
      $composableBuilder(column: $table.scene, builder: (column) => column);

  GeneratedColumn<String> get regionCode => $composableBuilder(
    column: $table.regionCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$RegionGroupOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RegionGroupOrdersTable,
          RegionGroupOrderRow,
          $$RegionGroupOrdersTableFilterComposer,
          $$RegionGroupOrdersTableOrderingComposer,
          $$RegionGroupOrdersTableAnnotationComposer,
          $$RegionGroupOrdersTableCreateCompanionBuilder,
          $$RegionGroupOrdersTableUpdateCompanionBuilder,
          (
            RegionGroupOrderRow,
            BaseReferences<
              _$AppDatabase,
              $RegionGroupOrdersTable,
              RegionGroupOrderRow
            >,
          ),
          RegionGroupOrderRow,
          PrefetchHooks Function()
        > {
  $$RegionGroupOrdersTableTableManager(
    _$AppDatabase db,
    $RegionGroupOrdersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegionGroupOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegionGroupOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegionGroupOrdersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scene = const Value.absent(),
                Value<String> regionCode = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegionGroupOrdersCompanion(
                scene: scene,
                regionCode: regionCode,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scene,
                required String regionCode,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegionGroupOrdersCompanion.insert(
                scene: scene,
                regionCode: regionCode,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RegionGroupOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RegionGroupOrdersTable,
      RegionGroupOrderRow,
      $$RegionGroupOrdersTableFilterComposer,
      $$RegionGroupOrdersTableOrderingComposer,
      $$RegionGroupOrdersTableAnnotationComposer,
      $$RegionGroupOrdersTableCreateCompanionBuilder,
      $$RegionGroupOrdersTableUpdateCompanionBuilder,
      (
        RegionGroupOrderRow,
        BaseReferences<
          _$AppDatabase,
          $RegionGroupOrdersTable,
          RegionGroupOrderRow
        >,
      ),
      RegionGroupOrderRow,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryEntriesTableCreateCompanionBuilder =
    SearchHistoryEntriesCompanion Function({
      Value<int> id,
      required String kind,
      required String uniqueKey,
      Value<String?> query,
      Value<String?> feature,
      Value<String?> targetId,
      Value<String?> label,
      Value<String?> sublabel,
      required DateTime visitedAt,
      required DateTime updatedAt,
    });
typedef $$SearchHistoryEntriesTableUpdateCompanionBuilder =
    SearchHistoryEntriesCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<String> uniqueKey,
      Value<String?> query,
      Value<String?> feature,
      Value<String?> targetId,
      Value<String?> label,
      Value<String?> sublabel,
      Value<DateTime> visitedAt,
      Value<DateTime> updatedAt,
    });

class $$SearchHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SearchHistoryEntriesTable> {
  $$SearchHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uniqueKey => $composableBuilder(
    column: $table.uniqueKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feature => $composableBuilder(
    column: $table.feature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sublabel => $composableBuilder(
    column: $table.sublabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchHistoryEntriesTable> {
  $$SearchHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uniqueKey => $composableBuilder(
    column: $table.uniqueKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feature => $composableBuilder(
    column: $table.feature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sublabel => $composableBuilder(
    column: $table.sublabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchHistoryEntriesTable> {
  $$SearchHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get uniqueKey =>
      $composableBuilder(column: $table.uniqueKey, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get feature =>
      $composableBuilder(column: $table.feature, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get sublabel =>
      $composableBuilder(column: $table.sublabel, builder: (column) => column);

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SearchHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchHistoryEntriesTable,
          SearchHistoryEntryRow,
          $$SearchHistoryEntriesTableFilterComposer,
          $$SearchHistoryEntriesTableOrderingComposer,
          $$SearchHistoryEntriesTableAnnotationComposer,
          $$SearchHistoryEntriesTableCreateCompanionBuilder,
          $$SearchHistoryEntriesTableUpdateCompanionBuilder,
          (
            SearchHistoryEntryRow,
            BaseReferences<
              _$AppDatabase,
              $SearchHistoryEntriesTable,
              SearchHistoryEntryRow
            >,
          ),
          SearchHistoryEntryRow,
          PrefetchHooks Function()
        > {
  $$SearchHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $SearchHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SearchHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> uniqueKey = const Value.absent(),
                Value<String?> query = const Value.absent(),
                Value<String?> feature = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> sublabel = const Value.absent(),
                Value<DateTime> visitedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SearchHistoryEntriesCompanion(
                id: id,
                kind: kind,
                uniqueKey: uniqueKey,
                query: query,
                feature: feature,
                targetId: targetId,
                label: label,
                sublabel: sublabel,
                visitedAt: visitedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String uniqueKey,
                Value<String?> query = const Value.absent(),
                Value<String?> feature = const Value.absent(),
                Value<String?> targetId = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String?> sublabel = const Value.absent(),
                required DateTime visitedAt,
                required DateTime updatedAt,
              }) => SearchHistoryEntriesCompanion.insert(
                id: id,
                kind: kind,
                uniqueKey: uniqueKey,
                query: query,
                feature: feature,
                targetId: targetId,
                label: label,
                sublabel: sublabel,
                visitedAt: visitedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchHistoryEntriesTable,
      SearchHistoryEntryRow,
      $$SearchHistoryEntriesTableFilterComposer,
      $$SearchHistoryEntriesTableOrderingComposer,
      $$SearchHistoryEntriesTableAnnotationComposer,
      $$SearchHistoryEntriesTableCreateCompanionBuilder,
      $$SearchHistoryEntriesTableUpdateCompanionBuilder,
      (
        SearchHistoryEntryRow,
        BaseReferences<
          _$AppDatabase,
          $SearchHistoryEntriesTable,
          SearchHistoryEntryRow
        >,
      ),
      SearchHistoryEntryRow,
      PrefetchHooks Function()
    >;
typedef $$WatchedPairsTableCreateCompanionBuilder =
    WatchedPairsCompanion Function({
      required String pairKey,
      required String baseCurrency,
      required String quoteCurrency,
      required DateTime createdAt,
      Value<String?> thresholdHigh,
      Value<String?> thresholdLow,
      Value<String?> alertChangePct,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$WatchedPairsTableUpdateCompanionBuilder =
    WatchedPairsCompanion Function({
      Value<String> pairKey,
      Value<String> baseCurrency,
      Value<String> quoteCurrency,
      Value<DateTime> createdAt,
      Value<String?> thresholdHigh,
      Value<String?> thresholdLow,
      Value<String?> alertChangePct,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$WatchedPairsTableFilterComposer
    extends Composer<_$AppDatabase, $WatchedPairsTable> {
  $$WatchedPairsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pairKey => $composableBuilder(
    column: $table.pairKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quoteCurrency => $composableBuilder(
    column: $table.quoteCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thresholdHigh => $composableBuilder(
    column: $table.thresholdHigh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thresholdLow => $composableBuilder(
    column: $table.thresholdLow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alertChangePct => $composableBuilder(
    column: $table.alertChangePct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchedPairsTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchedPairsTable> {
  $$WatchedPairsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pairKey => $composableBuilder(
    column: $table.pairKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quoteCurrency => $composableBuilder(
    column: $table.quoteCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thresholdHigh => $composableBuilder(
    column: $table.thresholdHigh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thresholdLow => $composableBuilder(
    column: $table.thresholdLow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alertChangePct => $composableBuilder(
    column: $table.alertChangePct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchedPairsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchedPairsTable> {
  $$WatchedPairsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pairKey =>
      $composableBuilder(column: $table.pairKey, builder: (column) => column);

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quoteCurrency => $composableBuilder(
    column: $table.quoteCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get thresholdHigh => $composableBuilder(
    column: $table.thresholdHigh,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thresholdLow => $composableBuilder(
    column: $table.thresholdLow,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alertChangePct => $composableBuilder(
    column: $table.alertChangePct,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$WatchedPairsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchedPairsTable,
          WatchedPairRow,
          $$WatchedPairsTableFilterComposer,
          $$WatchedPairsTableOrderingComposer,
          $$WatchedPairsTableAnnotationComposer,
          $$WatchedPairsTableCreateCompanionBuilder,
          $$WatchedPairsTableUpdateCompanionBuilder,
          (
            WatchedPairRow,
            BaseReferences<_$AppDatabase, $WatchedPairsTable, WatchedPairRow>,
          ),
          WatchedPairRow,
          PrefetchHooks Function()
        > {
  $$WatchedPairsTableTableManager(_$AppDatabase db, $WatchedPairsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchedPairsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchedPairsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchedPairsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pairKey = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> quoteCurrency = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> thresholdHigh = const Value.absent(),
                Value<String?> thresholdLow = const Value.absent(),
                Value<String?> alertChangePct = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchedPairsCompanion(
                pairKey: pairKey,
                baseCurrency: baseCurrency,
                quoteCurrency: quoteCurrency,
                createdAt: createdAt,
                thresholdHigh: thresholdHigh,
                thresholdLow: thresholdLow,
                alertChangePct: alertChangePct,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pairKey,
                required String baseCurrency,
                required String quoteCurrency,
                required DateTime createdAt,
                Value<String?> thresholdHigh = const Value.absent(),
                Value<String?> thresholdLow = const Value.absent(),
                Value<String?> alertChangePct = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchedPairsCompanion.insert(
                pairKey: pairKey,
                baseCurrency: baseCurrency,
                quoteCurrency: quoteCurrency,
                createdAt: createdAt,
                thresholdHigh: thresholdHigh,
                thresholdLow: thresholdLow,
                alertChangePct: alertChangePct,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchedPairsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchedPairsTable,
      WatchedPairRow,
      $$WatchedPairsTableFilterComposer,
      $$WatchedPairsTableOrderingComposer,
      $$WatchedPairsTableAnnotationComposer,
      $$WatchedPairsTableCreateCompanionBuilder,
      $$WatchedPairsTableUpdateCompanionBuilder,
      (
        WatchedPairRow,
        BaseReferences<_$AppDatabase, $WatchedPairsTable, WatchedPairRow>,
      ),
      WatchedPairRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$AccountChannelsTableTableManager get accountChannels =>
      $$AccountChannelsTableTableManager(_db, _db.accountChannels);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$AssetCostHistoryTableTableManager get assetCostHistory =>
      $$AssetCostHistoryTableTableManager(_db, _db.assetCostHistory);
  $$AssetPriceHistoryTableTableManager get assetPriceHistory =>
      $$AssetPriceHistoryTableTableManager(_db, _db.assetPriceHistory);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$DictEntriesTableTableManager get dictEntries =>
      $$DictEntriesTableTableManager(_db, _db.dictEntries);
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$RegionGroupOrdersTableTableManager get regionGroupOrders =>
      $$RegionGroupOrdersTableTableManager(_db, _db.regionGroupOrders);
  $$SearchHistoryEntriesTableTableManager get searchHistoryEntries =>
      $$SearchHistoryEntriesTableTableManager(_db, _db.searchHistoryEntries);
  $$WatchedPairsTableTableManager get watchedPairs =>
      $$WatchedPairsTableTableManager(_db, _db.watchedPairs);
}
