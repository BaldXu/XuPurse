// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
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
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialBalanceMeta = const VerificationMeta(
    'initialBalance',
  );
  @override
  late final GeneratedColumn<int> initialBalance = GeneratedColumn<int>(
    'initial_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<int> currentBalance = GeneratedColumn<int>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: const Constant('CNY'),
  );
  static const VerificationMeta _includeInAssetsMeta = const VerificationMeta(
    'includeInAssets',
  );
  @override
  late final GeneratedColumn<bool> includeInAssets = GeneratedColumn<bool>(
    'include_in_assets',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_assets" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<int> creditLimit = GeneratedColumn<int>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cardCodeMeta = const VerificationMeta(
    'cardCode',
  );
  @override
  late final GeneratedColumn<String> cardCode = GeneratedColumn<String>(
    'card_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statementDateMeta = const VerificationMeta(
    'statementDate',
  );
  @override
  late final GeneratedColumn<int> statementDate = GeneratedColumn<int>(
    'statement_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repaymentDateMeta = const VerificationMeta(
    'repaymentDate',
  );
  @override
  late final GeneratedColumn<int> repaymentDate = GeneratedColumn<int>(
    'repayment_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remarkMeta = const VerificationMeta('remark');
  @override
  late final GeneratedColumn<String> remark = GeneratedColumn<String>(
    'remark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _yimuAssetIdMeta = const VerificationMeta(
    'yimuAssetId',
  );
  @override
  late final GeneratedColumn<int> yimuAssetId = GeneratedColumn<int>(
    'yimu_asset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _zhouhuAccountIdMeta = const VerificationMeta(
    'zhouhuAccountId',
  );
  @override
  late final GeneratedColumn<int> zhouhuAccountId = GeneratedColumn<int>(
    'zhouhu_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qianjiAssetIdMeta = const VerificationMeta(
    'qianjiAssetId',
  );
  @override
  late final GeneratedColumn<int> qianjiAssetId = GeneratedColumn<int>(
    'qianji_asset_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    type,
    icon,
    color,
    initialBalance,
    currentBalance,
    currency,
    includeInAssets,
    creditLimit,
    cardCode,
    statementDate,
    repaymentDate,
    remark,
    enabled,
    yimuAssetId,
    zhouhuAccountId,
    qianjiAssetId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('initial_balance')) {
      context.handle(
        _initialBalanceMeta,
        initialBalance.isAcceptableOrUnknown(
          data['initial_balance']!,
          _initialBalanceMeta,
        ),
      );
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('include_in_assets')) {
      context.handle(
        _includeInAssetsMeta,
        includeInAssets.isAcceptableOrUnknown(
          data['include_in_assets']!,
          _includeInAssetsMeta,
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
    if (data.containsKey('card_code')) {
      context.handle(
        _cardCodeMeta,
        cardCode.isAcceptableOrUnknown(data['card_code']!, _cardCodeMeta),
      );
    }
    if (data.containsKey('statement_date')) {
      context.handle(
        _statementDateMeta,
        statementDate.isAcceptableOrUnknown(
          data['statement_date']!,
          _statementDateMeta,
        ),
      );
    }
    if (data.containsKey('repayment_date')) {
      context.handle(
        _repaymentDateMeta,
        repaymentDate.isAcceptableOrUnknown(
          data['repayment_date']!,
          _repaymentDateMeta,
        ),
      );
    }
    if (data.containsKey('remark')) {
      context.handle(
        _remarkMeta,
        remark.isAcceptableOrUnknown(data['remark']!, _remarkMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('yimu_asset_id')) {
      context.handle(
        _yimuAssetIdMeta,
        yimuAssetId.isAcceptableOrUnknown(
          data['yimu_asset_id']!,
          _yimuAssetIdMeta,
        ),
      );
    }
    if (data.containsKey('zhouhu_account_id')) {
      context.handle(
        _zhouhuAccountIdMeta,
        zhouhuAccountId.isAcceptableOrUnknown(
          data['zhouhu_account_id']!,
          _zhouhuAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('qianji_asset_id')) {
      context.handle(
        _qianjiAssetIdMeta,
        qianjiAssetId.isAcceptableOrUnknown(
          data['qianji_asset_id']!,
          _qianjiAssetIdMeta,
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
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      initialBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_balance'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_balance'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      includeInAssets: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_assets'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit'],
      ),
      cardCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_code'],
      ),
      statementDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_date'],
      ),
      repaymentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repayment_date'],
      ),
      remark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remark'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      yimuAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yimu_asset_id'],
      ),
      zhouhuAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}zhouhu_account_id'],
      ),
      qianjiAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qianji_asset_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String name;
  final String category;
  final String type;
  final String? icon;
  final String? color;
  final int initialBalance;
  final int currentBalance;
  final String currency;
  final bool includeInAssets;
  final int? creditLimit;
  final String? cardCode;
  final int? statementDate;
  final int? repaymentDate;
  final String? remark;
  final bool enabled;
  final int? yimuAssetId;
  final int? zhouhuAccountId;
  final int? qianjiAssetId;
  final int createdAt;
  final int updatedAt;
  const Account({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    this.icon,
    this.color,
    required this.initialBalance,
    required this.currentBalance,
    required this.currency,
    required this.includeInAssets,
    this.creditLimit,
    this.cardCode,
    this.statementDate,
    this.repaymentDate,
    this.remark,
    required this.enabled,
    this.yimuAssetId,
    this.zhouhuAccountId,
    this.qianjiAssetId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['initial_balance'] = Variable<int>(initialBalance);
    map['current_balance'] = Variable<int>(currentBalance);
    map['currency'] = Variable<String>(currency);
    map['include_in_assets'] = Variable<bool>(includeInAssets);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<int>(creditLimit);
    }
    if (!nullToAbsent || cardCode != null) {
      map['card_code'] = Variable<String>(cardCode);
    }
    if (!nullToAbsent || statementDate != null) {
      map['statement_date'] = Variable<int>(statementDate);
    }
    if (!nullToAbsent || repaymentDate != null) {
      map['repayment_date'] = Variable<int>(repaymentDate);
    }
    if (!nullToAbsent || remark != null) {
      map['remark'] = Variable<String>(remark);
    }
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || yimuAssetId != null) {
      map['yimu_asset_id'] = Variable<int>(yimuAssetId);
    }
    if (!nullToAbsent || zhouhuAccountId != null) {
      map['zhouhu_account_id'] = Variable<int>(zhouhuAccountId);
    }
    if (!nullToAbsent || qianjiAssetId != null) {
      map['qianji_asset_id'] = Variable<int>(qianjiAssetId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      type: Value(type),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      initialBalance: Value(initialBalance),
      currentBalance: Value(currentBalance),
      currency: Value(currency),
      includeInAssets: Value(includeInAssets),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      cardCode: cardCode == null && nullToAbsent
          ? const Value.absent()
          : Value(cardCode),
      statementDate: statementDate == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDate),
      repaymentDate: repaymentDate == null && nullToAbsent
          ? const Value.absent()
          : Value(repaymentDate),
      remark: remark == null && nullToAbsent
          ? const Value.absent()
          : Value(remark),
      enabled: Value(enabled),
      yimuAssetId: yimuAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(yimuAssetId),
      zhouhuAccountId: zhouhuAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(zhouhuAccountId),
      qianjiAssetId: qianjiAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(qianjiAssetId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      type: serializer.fromJson<String>(json['type']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      initialBalance: serializer.fromJson<int>(json['initialBalance']),
      currentBalance: serializer.fromJson<int>(json['currentBalance']),
      currency: serializer.fromJson<String>(json['currency']),
      includeInAssets: serializer.fromJson<bool>(json['includeInAssets']),
      creditLimit: serializer.fromJson<int?>(json['creditLimit']),
      cardCode: serializer.fromJson<String?>(json['cardCode']),
      statementDate: serializer.fromJson<int?>(json['statementDate']),
      repaymentDate: serializer.fromJson<int?>(json['repaymentDate']),
      remark: serializer.fromJson<String?>(json['remark']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      yimuAssetId: serializer.fromJson<int?>(json['yimuAssetId']),
      zhouhuAccountId: serializer.fromJson<int?>(json['zhouhuAccountId']),
      qianjiAssetId: serializer.fromJson<int?>(json['qianjiAssetId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'type': serializer.toJson<String>(type),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'initialBalance': serializer.toJson<int>(initialBalance),
      'currentBalance': serializer.toJson<int>(currentBalance),
      'currency': serializer.toJson<String>(currency),
      'includeInAssets': serializer.toJson<bool>(includeInAssets),
      'creditLimit': serializer.toJson<int?>(creditLimit),
      'cardCode': serializer.toJson<String?>(cardCode),
      'statementDate': serializer.toJson<int?>(statementDate),
      'repaymentDate': serializer.toJson<int?>(repaymentDate),
      'remark': serializer.toJson<String?>(remark),
      'enabled': serializer.toJson<bool>(enabled),
      'yimuAssetId': serializer.toJson<int?>(yimuAssetId),
      'zhouhuAccountId': serializer.toJson<int?>(zhouhuAccountId),
      'qianjiAssetId': serializer.toJson<int?>(qianjiAssetId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Account copyWith({
    String? id,
    String? name,
    String? category,
    String? type,
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    int? initialBalance,
    int? currentBalance,
    String? currency,
    bool? includeInAssets,
    Value<int?> creditLimit = const Value.absent(),
    Value<String?> cardCode = const Value.absent(),
    Value<int?> statementDate = const Value.absent(),
    Value<int?> repaymentDate = const Value.absent(),
    Value<String?> remark = const Value.absent(),
    bool? enabled,
    Value<int?> yimuAssetId = const Value.absent(),
    Value<int?> zhouhuAccountId = const Value.absent(),
    Value<int?> qianjiAssetId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    type: type ?? this.type,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    initialBalance: initialBalance ?? this.initialBalance,
    currentBalance: currentBalance ?? this.currentBalance,
    currency: currency ?? this.currency,
    includeInAssets: includeInAssets ?? this.includeInAssets,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    cardCode: cardCode.present ? cardCode.value : this.cardCode,
    statementDate: statementDate.present
        ? statementDate.value
        : this.statementDate,
    repaymentDate: repaymentDate.present
        ? repaymentDate.value
        : this.repaymentDate,
    remark: remark.present ? remark.value : this.remark,
    enabled: enabled ?? this.enabled,
    yimuAssetId: yimuAssetId.present ? yimuAssetId.value : this.yimuAssetId,
    zhouhuAccountId: zhouhuAccountId.present
        ? zhouhuAccountId.value
        : this.zhouhuAccountId,
    qianjiAssetId: qianjiAssetId.present
        ? qianjiAssetId.value
        : this.qianjiAssetId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      type: data.type.present ? data.type.value : this.type,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      initialBalance: data.initialBalance.present
          ? data.initialBalance.value
          : this.initialBalance,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      currency: data.currency.present ? data.currency.value : this.currency,
      includeInAssets: data.includeInAssets.present
          ? data.includeInAssets.value
          : this.includeInAssets,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      cardCode: data.cardCode.present ? data.cardCode.value : this.cardCode,
      statementDate: data.statementDate.present
          ? data.statementDate.value
          : this.statementDate,
      repaymentDate: data.repaymentDate.present
          ? data.repaymentDate.value
          : this.repaymentDate,
      remark: data.remark.present ? data.remark.value : this.remark,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      yimuAssetId: data.yimuAssetId.present
          ? data.yimuAssetId.value
          : this.yimuAssetId,
      zhouhuAccountId: data.zhouhuAccountId.present
          ? data.zhouhuAccountId.value
          : this.zhouhuAccountId,
      qianjiAssetId: data.qianjiAssetId.present
          ? data.qianjiAssetId.value
          : this.qianjiAssetId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('currency: $currency, ')
          ..write('includeInAssets: $includeInAssets, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('cardCode: $cardCode, ')
          ..write('statementDate: $statementDate, ')
          ..write('repaymentDate: $repaymentDate, ')
          ..write('remark: $remark, ')
          ..write('enabled: $enabled, ')
          ..write('yimuAssetId: $yimuAssetId, ')
          ..write('zhouhuAccountId: $zhouhuAccountId, ')
          ..write('qianjiAssetId: $qianjiAssetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    category,
    type,
    icon,
    color,
    initialBalance,
    currentBalance,
    currency,
    includeInAssets,
    creditLimit,
    cardCode,
    statementDate,
    repaymentDate,
    remark,
    enabled,
    yimuAssetId,
    zhouhuAccountId,
    qianjiAssetId,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.type == this.type &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.initialBalance == this.initialBalance &&
          other.currentBalance == this.currentBalance &&
          other.currency == this.currency &&
          other.includeInAssets == this.includeInAssets &&
          other.creditLimit == this.creditLimit &&
          other.cardCode == this.cardCode &&
          other.statementDate == this.statementDate &&
          other.repaymentDate == this.repaymentDate &&
          other.remark == this.remark &&
          other.enabled == this.enabled &&
          other.yimuAssetId == this.yimuAssetId &&
          other.zhouhuAccountId == this.zhouhuAccountId &&
          other.qianjiAssetId == this.qianjiAssetId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<String> type;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<int> initialBalance;
  final Value<int> currentBalance;
  final Value<String> currency;
  final Value<bool> includeInAssets;
  final Value<int?> creditLimit;
  final Value<String?> cardCode;
  final Value<int?> statementDate;
  final Value<int?> repaymentDate;
  final Value<String?> remark;
  final Value<bool> enabled;
  final Value<int?> yimuAssetId;
  final Value<int?> zhouhuAccountId;
  final Value<int?> qianjiAssetId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.type = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.currency = const Value.absent(),
    this.includeInAssets = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.cardCode = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.repaymentDate = const Value.absent(),
    this.remark = const Value.absent(),
    this.enabled = const Value.absent(),
    this.yimuAssetId = const Value.absent(),
    this.zhouhuAccountId = const Value.absent(),
    this.qianjiAssetId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    required String category,
    required String type,
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.initialBalance = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.currency = const Value.absent(),
    this.includeInAssets = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.cardCode = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.repaymentDate = const Value.absent(),
    this.remark = const Value.absent(),
    this.enabled = const Value.absent(),
    this.yimuAssetId = const Value.absent(),
    this.zhouhuAccountId = const Value.absent(),
    this.qianjiAssetId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? type,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<int>? initialBalance,
    Expression<int>? currentBalance,
    Expression<String>? currency,
    Expression<bool>? includeInAssets,
    Expression<int>? creditLimit,
    Expression<String>? cardCode,
    Expression<int>? statementDate,
    Expression<int>? repaymentDate,
    Expression<String>? remark,
    Expression<bool>? enabled,
    Expression<int>? yimuAssetId,
    Expression<int>? zhouhuAccountId,
    Expression<int>? qianjiAssetId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (initialBalance != null) 'initial_balance': initialBalance,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (currency != null) 'currency': currency,
      if (includeInAssets != null) 'include_in_assets': includeInAssets,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (cardCode != null) 'card_code': cardCode,
      if (statementDate != null) 'statement_date': statementDate,
      if (repaymentDate != null) 'repayment_date': repaymentDate,
      if (remark != null) 'remark': remark,
      if (enabled != null) 'enabled': enabled,
      if (yimuAssetId != null) 'yimu_asset_id': yimuAssetId,
      if (zhouhuAccountId != null) 'zhouhu_account_id': zhouhuAccountId,
      if (qianjiAssetId != null) 'qianji_asset_id': qianjiAssetId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<String>? type,
    Value<String?>? icon,
    Value<String?>? color,
    Value<int>? initialBalance,
    Value<int>? currentBalance,
    Value<String>? currency,
    Value<bool>? includeInAssets,
    Value<int?>? creditLimit,
    Value<String?>? cardCode,
    Value<int?>? statementDate,
    Value<int?>? repaymentDate,
    Value<String?>? remark,
    Value<bool>? enabled,
    Value<int?>? yimuAssetId,
    Value<int?>? zhouhuAccountId,
    Value<int?>? qianjiAssetId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      currency: currency ?? this.currency,
      includeInAssets: includeInAssets ?? this.includeInAssets,
      creditLimit: creditLimit ?? this.creditLimit,
      cardCode: cardCode ?? this.cardCode,
      statementDate: statementDate ?? this.statementDate,
      repaymentDate: repaymentDate ?? this.repaymentDate,
      remark: remark ?? this.remark,
      enabled: enabled ?? this.enabled,
      yimuAssetId: yimuAssetId ?? this.yimuAssetId,
      zhouhuAccountId: zhouhuAccountId ?? this.zhouhuAccountId,
      qianjiAssetId: qianjiAssetId ?? this.qianjiAssetId,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (initialBalance.present) {
      map['initial_balance'] = Variable<int>(initialBalance.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<int>(currentBalance.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (includeInAssets.present) {
      map['include_in_assets'] = Variable<bool>(includeInAssets.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<int>(creditLimit.value);
    }
    if (cardCode.present) {
      map['card_code'] = Variable<String>(cardCode.value);
    }
    if (statementDate.present) {
      map['statement_date'] = Variable<int>(statementDate.value);
    }
    if (repaymentDate.present) {
      map['repayment_date'] = Variable<int>(repaymentDate.value);
    }
    if (remark.present) {
      map['remark'] = Variable<String>(remark.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (yimuAssetId.present) {
      map['yimu_asset_id'] = Variable<int>(yimuAssetId.value);
    }
    if (zhouhuAccountId.present) {
      map['zhouhu_account_id'] = Variable<int>(zhouhuAccountId.value);
    }
    if (qianjiAssetId.present) {
      map['qianji_asset_id'] = Variable<int>(qianjiAssetId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
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
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('initialBalance: $initialBalance, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('currency: $currency, ')
          ..write('includeInAssets: $includeInAssets, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('cardCode: $cardCode, ')
          ..write('statementDate: $statementDate, ')
          ..write('repaymentDate: $repaymentDate, ')
          ..write('remark: $remark, ')
          ..write('enabled: $enabled, ')
          ..write('yimuAssetId: $yimuAssetId, ')
          ..write('zhouhuAccountId: $zhouhuAccountId, ')
          ..write('qianjiAssetId: $qianjiAssetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customNameMeta = const VerificationMeta(
    'customName',
  );
  @override
  late final GeneratedColumn<bool> customName = GeneratedColumn<bool>(
    'custom_name',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("custom_name" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultSelectMeta = const VerificationMeta(
    'defaultSelect',
  );
  @override
  late final GeneratedColumn<bool> defaultSelect = GeneratedColumn<bool>(
    'default_select',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("default_select" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _seedKeyMeta = const VerificationMeta(
    'seedKey',
  );
  @override
  late final GeneratedColumn<String> seedKey = GeneratedColumn<String>(
    'seed_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    name,
    icon,
    color,
    parentId,
    customName,
    defaultSelect,
    sort,
    seedKey,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
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
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('custom_name')) {
      context.handle(
        _customNameMeta,
        customName.isAcceptableOrUnknown(data['custom_name']!, _customNameMeta),
      );
    }
    if (data.containsKey('default_select')) {
      context.handle(
        _defaultSelectMeta,
        defaultSelect.isAcceptableOrUnknown(
          data['default_select']!,
          _defaultSelectMeta,
        ),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
      );
    }
    if (data.containsKey('seed_key')) {
      context.handle(
        _seedKeyMeta,
        seedKey.isAcceptableOrUnknown(data['seed_key']!, _seedKeyMeta),
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
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
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
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      customName: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}custom_name'],
      )!,
      defaultSelect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}default_select'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      seedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seed_key'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String type;
  final String name;
  final String? icon;
  final String? color;
  final String? parentId;
  final bool customName;
  final bool defaultSelect;
  final int sort;
  final String? seedKey;
  final int createdAt;
  final int updatedAt;
  const Category({
    required this.id,
    required this.type,
    required this.name,
    this.icon,
    this.color,
    this.parentId,
    required this.customName,
    required this.defaultSelect,
    required this.sort,
    this.seedKey,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['custom_name'] = Variable<bool>(customName);
    map['default_select'] = Variable<bool>(defaultSelect);
    map['sort'] = Variable<int>(sort);
    if (!nullToAbsent || seedKey != null) {
      map['seed_key'] = Variable<String>(seedKey);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      type: Value(type),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      customName: Value(customName),
      defaultSelect: Value(defaultSelect),
      sort: Value(sort),
      seedKey: seedKey == null && nullToAbsent
          ? const Value.absent()
          : Value(seedKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      customName: serializer.fromJson<bool>(json['customName']),
      defaultSelect: serializer.fromJson<bool>(json['defaultSelect']),
      sort: serializer.fromJson<int>(json['sort']),
      seedKey: serializer.fromJson<String?>(json['seedKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'parentId': serializer.toJson<String?>(parentId),
      'customName': serializer.toJson<bool>(customName),
      'defaultSelect': serializer.toJson<bool>(defaultSelect),
      'sort': serializer.toJson<int>(sort),
      'seedKey': serializer.toJson<String?>(seedKey),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Category copyWith({
    String? id,
    String? type,
    String? name,
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> parentId = const Value.absent(),
    bool? customName,
    bool? defaultSelect,
    int? sort,
    Value<String?> seedKey = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Category(
    id: id ?? this.id,
    type: type ?? this.type,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    parentId: parentId.present ? parentId.value : this.parentId,
    customName: customName ?? this.customName,
    defaultSelect: defaultSelect ?? this.defaultSelect,
    sort: sort ?? this.sort,
    seedKey: seedKey.present ? seedKey.value : this.seedKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      customName: data.customName.present
          ? data.customName.value
          : this.customName,
      defaultSelect: data.defaultSelect.present
          ? data.defaultSelect.value
          : this.defaultSelect,
      sort: data.sort.present ? data.sort.value : this.sort,
      seedKey: data.seedKey.present ? data.seedKey.value : this.seedKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('customName: $customName, ')
          ..write('defaultSelect: $defaultSelect, ')
          ..write('sort: $sort, ')
          ..write('seedKey: $seedKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    name,
    icon,
    color,
    parentId,
    customName,
    defaultSelect,
    sort,
    seedKey,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.type == this.type &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.parentId == this.parentId &&
          other.customName == this.customName &&
          other.defaultSelect == this.defaultSelect &&
          other.sort == this.sort &&
          other.seedKey == this.seedKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<String?> parentId;
  final Value<bool> customName;
  final Value<bool> defaultSelect;
  final Value<int> sort;
  final Value<String?> seedKey;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.customName = const Value.absent(),
    this.defaultSelect = const Value.absent(),
    this.sort = const Value.absent(),
    this.seedKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String type,
    required String name,
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.customName = const Value.absent(),
    this.defaultSelect = const Value.absent(),
    this.sort = const Value.absent(),
    this.seedKey = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<String>? parentId,
    Expression<bool>? customName,
    Expression<bool>? defaultSelect,
    Expression<int>? sort,
    Expression<String>? seedKey,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (parentId != null) 'parent_id': parentId,
      if (customName != null) 'custom_name': customName,
      if (defaultSelect != null) 'default_select': defaultSelect,
      if (sort != null) 'sort': sort,
      if (seedKey != null) 'seed_key': seedKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? name,
    Value<String?>? icon,
    Value<String?>? color,
    Value<String?>? parentId,
    Value<bool>? customName,
    Value<bool>? defaultSelect,
    Value<int>? sort,
    Value<String?>? seedKey,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      customName: customName ?? this.customName,
      defaultSelect: defaultSelect ?? this.defaultSelect,
      sort: sort ?? this.sort,
      seedKey: seedKey ?? this.seedKey,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<bool>(customName.value);
    }
    if (defaultSelect.present) {
      map['default_select'] = Variable<bool>(defaultSelect.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (seedKey.present) {
      map['seed_key'] = Variable<String>(seedKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('customName: $customName, ')
          ..write('defaultSelect: $defaultSelect, ')
          ..write('sort: $sort, ')
          ..write('seedKey: $seedKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferCurrencyMeta = const VerificationMeta(
    'preferCurrency',
  );
  @override
  late final GeneratedColumn<String> preferCurrency = GeneratedColumn<String>(
    'prefer_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    groupId,
    preferCurrency,
    sort,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
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
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('prefer_currency')) {
      context.handle(
        _preferCurrencyMeta,
        preferCurrency.isAcceptableOrUnknown(
          data['prefer_currency']!,
          _preferCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
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
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      preferCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefer_currency'],
      ),
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final String? color;
  final String? groupId;
  final String? preferCurrency;
  final int sort;
  final int createdAt;
  final int updatedAt;
  const Tag({
    required this.id,
    required this.name,
    this.color,
    this.groupId,
    this.preferCurrency,
    required this.sort,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || preferCurrency != null) {
      map['prefer_currency'] = Variable<String>(preferCurrency);
    }
    map['sort'] = Variable<int>(sort);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      preferCurrency: preferCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(preferCurrency),
      sort: Value(sort),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      preferCurrency: serializer.fromJson<String?>(json['preferCurrency']),
      sort: serializer.fromJson<int>(json['sort']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'groupId': serializer.toJson<String?>(groupId),
      'preferCurrency': serializer.toJson<String?>(preferCurrency),
      'sort': serializer.toJson<int>(sort),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    Value<String?> color = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    Value<String?> preferCurrency = const Value.absent(),
    int? sort,
    int? createdAt,
    int? updatedAt,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    groupId: groupId.present ? groupId.value : this.groupId,
    preferCurrency: preferCurrency.present
        ? preferCurrency.value
        : this.preferCurrency,
    sort: sort ?? this.sort,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      preferCurrency: data.preferCurrency.present
          ? data.preferCurrency.value
          : this.preferCurrency,
      sort: data.sort.present ? data.sort.value : this.sort,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('groupId: $groupId, ')
          ..write('preferCurrency: $preferCurrency, ')
          ..write('sort: $sort, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    color,
    groupId,
    preferCurrency,
    sort,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.groupId == this.groupId &&
          other.preferCurrency == this.preferCurrency &&
          other.sort == this.sort &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> color;
  final Value<String?> groupId;
  final Value<String?> preferCurrency;
  final Value<int> sort;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.groupId = const Value.absent(),
    this.preferCurrency = const Value.absent(),
    this.sort = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    this.groupId = const Value.absent(),
    this.preferCurrency = const Value.absent(),
    this.sort = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? groupId,
    Expression<String>? preferCurrency,
    Expression<int>? sort,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (groupId != null) 'group_id': groupId,
      if (preferCurrency != null) 'prefer_currency': preferCurrency,
      if (sort != null) 'sort': sort,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? color,
    Value<String?>? groupId,
    Value<String?>? preferCurrency,
    Value<int>? sort,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      groupId: groupId ?? this.groupId,
      preferCurrency: preferCurrency ?? this.preferCurrency,
      sort: sort ?? this.sort,
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
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (preferCurrency.present) {
      map['prefer_currency'] = Variable<String>(preferCurrency.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('groupId: $groupId, ')
          ..write('preferCurrency: $preferCurrency, ')
          ..write('sort: $sort, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagGroupsTable extends TagGroups
    with TableInfo<$TagGroupsTable, TagGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagGroupsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sortMeta = const VerificationMeta('sort');
  @override
  late final GeneratedColumn<int> sort = GeneratedColumn<int>(
    'sort',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sort, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagGroup> instance, {
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
    if (data.containsKey('sort')) {
      context.handle(
        _sortMeta,
        sort.isAcceptableOrUnknown(data['sort']!, _sortMeta),
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
  TagGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagGroupsTable createAlias(String alias) {
    return $TagGroupsTable(attachedDatabase, alias);
  }
}

class TagGroup extends DataClass implements Insertable<TagGroup> {
  final String id;
  final String name;
  final int sort;
  final int createdAt;
  const TagGroup({
    required this.id,
    required this.name,
    required this.sort,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort'] = Variable<int>(sort);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  TagGroupsCompanion toCompanion(bool nullToAbsent) {
    return TagGroupsCompanion(
      id: Value(id),
      name: Value(name),
      sort: Value(sort),
      createdAt: Value(createdAt),
    );
  }

  factory TagGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagGroup(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sort: serializer.fromJson<int>(json['sort']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sort': serializer.toJson<int>(sort),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  TagGroup copyWith({String? id, String? name, int? sort, int? createdAt}) =>
      TagGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        sort: sort ?? this.sort,
        createdAt: createdAt ?? this.createdAt,
      );
  TagGroup copyWithCompanion(TagGroupsCompanion data) {
    return TagGroup(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sort: data.sort.present ? data.sort.value : this.sort,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagGroup(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sort: $sort, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sort, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagGroup &&
          other.id == this.id &&
          other.name == this.name &&
          other.sort == this.sort &&
          other.createdAt == this.createdAt);
}

class TagGroupsCompanion extends UpdateCompanion<TagGroup> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sort;
  final Value<int> createdAt;
  final Value<int> rowid;
  const TagGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sort = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagGroupsCompanion.insert({
    required String id,
    required String name,
    this.sort = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<TagGroup> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sort,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sort != null) 'sort': sort,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? sort,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return TagGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sort: sort ?? this.sort,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sort.present) {
      map['sort'] = Variable<int>(sort.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sort: $sort, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, Bill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _incomeAccountIdMeta = const VerificationMeta(
    'incomeAccountId',
  );
  @override
  late final GeneratedColumn<String> incomeAccountId = GeneratedColumn<String>(
    'income_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLatMeta = const VerificationMeta(
    'locationLat',
  );
  @override
  late final GeneratedColumn<double> locationLat = GeneratedColumn<double>(
    'location_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationLngMeta = const VerificationMeta(
    'locationLng',
  );
  @override
  late final GeneratedColumn<double> locationLng = GeneratedColumn<double>(
    'location_lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagesMeta = const VerificationMeta('images');
  @override
  late final GeneratedColumn<String> images = GeneratedColumn<String>(
    'images',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyAmountMeta = const VerificationMeta(
    'currencyAmount',
  );
  @override
  late final GeneratedColumn<int> currencyAmount = GeneratedColumn<int>(
    'currency_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extraMeta = const VerificationMeta('extra');
  @override
  late final GeneratedColumn<String> extra = GeneratedColumn<String>(
    'extra',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    categoryId,
    amount,
    accountId,
    incomeAccountId,
    time,
    comment,
    locationLat,
    locationLng,
    images,
    currencyCode,
    currencyAmount,
    baseCurrency,
    extra,
    creatorId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bill> instance, {
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
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('income_account_id')) {
      context.handle(
        _incomeAccountIdMeta,
        incomeAccountId.isAcceptableOrUnknown(
          data['income_account_id']!,
          _incomeAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('location_lat')) {
      context.handle(
        _locationLatMeta,
        locationLat.isAcceptableOrUnknown(
          data['location_lat']!,
          _locationLatMeta,
        ),
      );
    }
    if (data.containsKey('location_lng')) {
      context.handle(
        _locationLngMeta,
        locationLng.isAcceptableOrUnknown(
          data['location_lng']!,
          _locationLngMeta,
        ),
      );
    }
    if (data.containsKey('images')) {
      context.handle(
        _imagesMeta,
        images.isAcceptableOrUnknown(data['images']!, _imagesMeta),
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
    if (data.containsKey('currency_amount')) {
      context.handle(
        _currencyAmountMeta,
        currencyAmount.isAcceptableOrUnknown(
          data['currency_amount']!,
          _currencyAmountMeta,
        ),
      );
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('extra')) {
      context.handle(
        _extraMeta,
        extra.isAcceptableOrUnknown(data['extra']!, _extraMeta),
      );
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
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
  Bill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      incomeAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}income_account_id'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      locationLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lat'],
      ),
      locationLng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}location_lng'],
      ),
      images: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}images'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      ),
      currencyAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}currency_amount'],
      ),
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      ),
      extra: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extra'],
      ),
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class Bill extends DataClass implements Insertable<Bill> {
  final String id;
  final String type;
  final String categoryId;
  final int amount;
  final String? accountId;
  final String? incomeAccountId;
  final int time;
  final String? comment;
  final double? locationLat;
  final double? locationLng;
  final String? images;
  final String? currencyCode;
  final int? currencyAmount;
  final String? baseCurrency;
  final String? extra;
  final String? creatorId;
  final int createdAt;
  final int updatedAt;
  const Bill({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.amount,
    this.accountId,
    this.incomeAccountId,
    required this.time,
    this.comment,
    this.locationLat,
    this.locationLng,
    this.images,
    this.currencyCode,
    this.currencyAmount,
    this.baseCurrency,
    this.extra,
    this.creatorId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['category_id'] = Variable<String>(categoryId);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || incomeAccountId != null) {
      map['income_account_id'] = Variable<String>(incomeAccountId);
    }
    map['time'] = Variable<int>(time);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || locationLat != null) {
      map['location_lat'] = Variable<double>(locationLat);
    }
    if (!nullToAbsent || locationLng != null) {
      map['location_lng'] = Variable<double>(locationLng);
    }
    if (!nullToAbsent || images != null) {
      map['images'] = Variable<String>(images);
    }
    if (!nullToAbsent || currencyCode != null) {
      map['currency_code'] = Variable<String>(currencyCode);
    }
    if (!nullToAbsent || currencyAmount != null) {
      map['currency_amount'] = Variable<int>(currencyAmount);
    }
    if (!nullToAbsent || baseCurrency != null) {
      map['base_currency'] = Variable<String>(baseCurrency);
    }
    if (!nullToAbsent || extra != null) {
      map['extra'] = Variable<String>(extra);
    }
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      type: Value(type),
      categoryId: Value(categoryId),
      amount: Value(amount),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      incomeAccountId: incomeAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(incomeAccountId),
      time: Value(time),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      locationLat: locationLat == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLat),
      locationLng: locationLng == null && nullToAbsent
          ? const Value.absent()
          : Value(locationLng),
      images: images == null && nullToAbsent
          ? const Value.absent()
          : Value(images),
      currencyCode: currencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyCode),
      currencyAmount: currencyAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyAmount),
      baseCurrency: baseCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(baseCurrency),
      extra: extra == null && nullToAbsent
          ? const Value.absent()
          : Value(extra),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Bill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bill(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      amount: serializer.fromJson<int>(json['amount']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      incomeAccountId: serializer.fromJson<String?>(json['incomeAccountId']),
      time: serializer.fromJson<int>(json['time']),
      comment: serializer.fromJson<String?>(json['comment']),
      locationLat: serializer.fromJson<double?>(json['locationLat']),
      locationLng: serializer.fromJson<double?>(json['locationLng']),
      images: serializer.fromJson<String?>(json['images']),
      currencyCode: serializer.fromJson<String?>(json['currencyCode']),
      currencyAmount: serializer.fromJson<int?>(json['currencyAmount']),
      baseCurrency: serializer.fromJson<String?>(json['baseCurrency']),
      extra: serializer.fromJson<String?>(json['extra']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'categoryId': serializer.toJson<String>(categoryId),
      'amount': serializer.toJson<int>(amount),
      'accountId': serializer.toJson<String?>(accountId),
      'incomeAccountId': serializer.toJson<String?>(incomeAccountId),
      'time': serializer.toJson<int>(time),
      'comment': serializer.toJson<String?>(comment),
      'locationLat': serializer.toJson<double?>(locationLat),
      'locationLng': serializer.toJson<double?>(locationLng),
      'images': serializer.toJson<String?>(images),
      'currencyCode': serializer.toJson<String?>(currencyCode),
      'currencyAmount': serializer.toJson<int?>(currencyAmount),
      'baseCurrency': serializer.toJson<String?>(baseCurrency),
      'extra': serializer.toJson<String?>(extra),
      'creatorId': serializer.toJson<String?>(creatorId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Bill copyWith({
    String? id,
    String? type,
    String? categoryId,
    int? amount,
    Value<String?> accountId = const Value.absent(),
    Value<String?> incomeAccountId = const Value.absent(),
    int? time,
    Value<String?> comment = const Value.absent(),
    Value<double?> locationLat = const Value.absent(),
    Value<double?> locationLng = const Value.absent(),
    Value<String?> images = const Value.absent(),
    Value<String?> currencyCode = const Value.absent(),
    Value<int?> currencyAmount = const Value.absent(),
    Value<String?> baseCurrency = const Value.absent(),
    Value<String?> extra = const Value.absent(),
    Value<String?> creatorId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Bill(
    id: id ?? this.id,
    type: type ?? this.type,
    categoryId: categoryId ?? this.categoryId,
    amount: amount ?? this.amount,
    accountId: accountId.present ? accountId.value : this.accountId,
    incomeAccountId: incomeAccountId.present
        ? incomeAccountId.value
        : this.incomeAccountId,
    time: time ?? this.time,
    comment: comment.present ? comment.value : this.comment,
    locationLat: locationLat.present ? locationLat.value : this.locationLat,
    locationLng: locationLng.present ? locationLng.value : this.locationLng,
    images: images.present ? images.value : this.images,
    currencyCode: currencyCode.present ? currencyCode.value : this.currencyCode,
    currencyAmount: currencyAmount.present
        ? currencyAmount.value
        : this.currencyAmount,
    baseCurrency: baseCurrency.present ? baseCurrency.value : this.baseCurrency,
    extra: extra.present ? extra.value : this.extra,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Bill copyWithCompanion(BillsCompanion data) {
    return Bill(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      incomeAccountId: data.incomeAccountId.present
          ? data.incomeAccountId.value
          : this.incomeAccountId,
      time: data.time.present ? data.time.value : this.time,
      comment: data.comment.present ? data.comment.value : this.comment,
      locationLat: data.locationLat.present
          ? data.locationLat.value
          : this.locationLat,
      locationLng: data.locationLng.present
          ? data.locationLng.value
          : this.locationLng,
      images: data.images.present ? data.images.value : this.images,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      currencyAmount: data.currencyAmount.present
          ? data.currencyAmount.value
          : this.currencyAmount,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      extra: data.extra.present ? data.extra.value : this.extra,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bill(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('incomeAccountId: $incomeAccountId, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLng: $locationLng, ')
          ..write('images: $images, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencyAmount: $currencyAmount, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('extra: $extra, ')
          ..write('creatorId: $creatorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    categoryId,
    amount,
    accountId,
    incomeAccountId,
    time,
    comment,
    locationLat,
    locationLng,
    images,
    currencyCode,
    currencyAmount,
    baseCurrency,
    extra,
    creatorId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bill &&
          other.id == this.id &&
          other.type == this.type &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.accountId == this.accountId &&
          other.incomeAccountId == this.incomeAccountId &&
          other.time == this.time &&
          other.comment == this.comment &&
          other.locationLat == this.locationLat &&
          other.locationLng == this.locationLng &&
          other.images == this.images &&
          other.currencyCode == this.currencyCode &&
          other.currencyAmount == this.currencyAmount &&
          other.baseCurrency == this.baseCurrency &&
          other.extra == this.extra &&
          other.creatorId == this.creatorId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BillsCompanion extends UpdateCompanion<Bill> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> categoryId;
  final Value<int> amount;
  final Value<String?> accountId;
  final Value<String?> incomeAccountId;
  final Value<int> time;
  final Value<String?> comment;
  final Value<double?> locationLat;
  final Value<double?> locationLng;
  final Value<String?> images;
  final Value<String?> currencyCode;
  final Value<int?> currencyAmount;
  final Value<String?> baseCurrency;
  final Value<String?> extra;
  final Value<String?> creatorId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.accountId = const Value.absent(),
    this.incomeAccountId = const Value.absent(),
    this.time = const Value.absent(),
    this.comment = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLng = const Value.absent(),
    this.images = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencyAmount = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.extra = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillsCompanion.insert({
    required String id,
    required String type,
    required String categoryId,
    required int amount,
    this.accountId = const Value.absent(),
    this.incomeAccountId = const Value.absent(),
    required int time,
    this.comment = const Value.absent(),
    this.locationLat = const Value.absent(),
    this.locationLng = const Value.absent(),
    this.images = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencyAmount = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.extra = const Value.absent(),
    this.creatorId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       categoryId = Value(categoryId),
       amount = Value(amount),
       time = Value(time),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Bill> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? categoryId,
    Expression<int>? amount,
    Expression<String>? accountId,
    Expression<String>? incomeAccountId,
    Expression<int>? time,
    Expression<String>? comment,
    Expression<double>? locationLat,
    Expression<double>? locationLng,
    Expression<String>? images,
    Expression<String>? currencyCode,
    Expression<int>? currencyAmount,
    Expression<String>? baseCurrency,
    Expression<String>? extra,
    Expression<String>? creatorId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (accountId != null) 'account_id': accountId,
      if (incomeAccountId != null) 'income_account_id': incomeAccountId,
      if (time != null) 'time': time,
      if (comment != null) 'comment': comment,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      if (images != null) 'images': images,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (currencyAmount != null) 'currency_amount': currencyAmount,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (extra != null) 'extra': extra,
      if (creatorId != null) 'creator_id': creatorId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? categoryId,
    Value<int>? amount,
    Value<String?>? accountId,
    Value<String?>? incomeAccountId,
    Value<int>? time,
    Value<String?>? comment,
    Value<double?>? locationLat,
    Value<double?>? locationLng,
    Value<String?>? images,
    Value<String?>? currencyCode,
    Value<int?>? currencyAmount,
    Value<String?>? baseCurrency,
    Value<String?>? extra,
    Value<String?>? creatorId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return BillsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      incomeAccountId: incomeAccountId ?? this.incomeAccountId,
      time: time ?? this.time,
      comment: comment ?? this.comment,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      images: images ?? this.images,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyAmount: currencyAmount ?? this.currencyAmount,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      extra: extra ?? this.extra,
      creatorId: creatorId ?? this.creatorId,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (incomeAccountId.present) {
      map['income_account_id'] = Variable<String>(incomeAccountId.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (locationLat.present) {
      map['location_lat'] = Variable<double>(locationLat.value);
    }
    if (locationLng.present) {
      map['location_lng'] = Variable<double>(locationLng.value);
    }
    if (images.present) {
      map['images'] = Variable<String>(images.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (currencyAmount.present) {
      map['currency_amount'] = Variable<int>(currencyAmount.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (extra.present) {
      map['extra'] = Variable<String>(extra.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('incomeAccountId: $incomeAccountId, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('locationLat: $locationLat, ')
          ..write('locationLng: $locationLng, ')
          ..write('images: $images, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencyAmount: $currencyAmount, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('extra: $extra, ')
          ..write('creatorId: $creatorId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillTagsTable extends BillTags with TableInfo<$BillTagsTable, BillTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [billId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {billId, tagId};
  @override
  BillTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillTag(
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $BillTagsTable createAlias(String alias) {
    return $BillTagsTable(attachedDatabase, alias);
  }
}

class BillTag extends DataClass implements Insertable<BillTag> {
  final String billId;
  final String tagId;
  const BillTag({required this.billId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['bill_id'] = Variable<String>(billId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  BillTagsCompanion toCompanion(bool nullToAbsent) {
    return BillTagsCompanion(billId: Value(billId), tagId: Value(tagId));
  }

  factory BillTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillTag(
      billId: serializer.fromJson<String>(json['billId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'billId': serializer.toJson<String>(billId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  BillTag copyWith({String? billId, String? tagId}) =>
      BillTag(billId: billId ?? this.billId, tagId: tagId ?? this.tagId);
  BillTag copyWithCompanion(BillTagsCompanion data) {
    return BillTag(
      billId: data.billId.present ? data.billId.value : this.billId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillTag(')
          ..write('billId: $billId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(billId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillTag &&
          other.billId == this.billId &&
          other.tagId == this.tagId);
}

class BillTagsCompanion extends UpdateCompanion<BillTag> {
  final Value<String> billId;
  final Value<String> tagId;
  final Value<int> rowid;
  const BillTagsCompanion({
    this.billId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillTagsCompanion.insert({
    required String billId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : billId = Value(billId),
       tagId = Value(tagId);
  static Insertable<BillTag> custom({
    Expression<String>? billId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (billId != null) 'bill_id': billId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillTagsCompanion copyWith({
    Value<String>? billId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return BillTagsCompanion(
      billId: billId ?? this.billId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillTagsCompanion(')
          ..write('billId: $billId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BalanceSnapshotsTable extends BalanceSnapshots
    with TableInfo<$BalanceSnapshotsTable, BalanceSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BalanceSnapshotsTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isValidMeta = const VerificationMeta(
    'isValid',
  );
  @override
  late final GeneratedColumn<bool> isValid = GeneratedColumn<bool>(
    'is_valid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_valid" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yimuAssetHistoryIdMeta =
      const VerificationMeta('yimuAssetHistoryId');
  @override
  late final GeneratedColumn<int> yimuAssetHistoryId = GeneratedColumn<int>(
    'yimu_asset_history_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    balance,
    timestamp,
    note,
    isValid,
    billId,
    type,
    yimuAssetHistoryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'balance_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<BalanceSnapshot> instance, {
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
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_valid')) {
      context.handle(
        _isValidMeta,
        isValid.isAcceptableOrUnknown(data['is_valid']!, _isValidMeta),
      );
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('yimu_asset_history_id')) {
      context.handle(
        _yimuAssetHistoryIdMeta,
        yimuAssetHistoryId.isAcceptableOrUnknown(
          data['yimu_asset_history_id']!,
          _yimuAssetHistoryIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BalanceSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BalanceSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isValid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_valid'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      yimuAssetHistoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yimu_asset_history_id'],
      ),
    );
  }

  @override
  $BalanceSnapshotsTable createAlias(String alias) {
    return $BalanceSnapshotsTable(attachedDatabase, alias);
  }
}

class BalanceSnapshot extends DataClass implements Insertable<BalanceSnapshot> {
  final String id;
  final String accountId;
  final int balance;
  final int timestamp;
  final String? note;
  final bool isValid;
  final String? billId;
  final int type;
  final int? yimuAssetHistoryId;
  const BalanceSnapshot({
    required this.id,
    required this.accountId,
    required this.balance,
    required this.timestamp,
    this.note,
    required this.isValid,
    this.billId,
    required this.type,
    this.yimuAssetHistoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['balance'] = Variable<int>(balance);
    map['timestamp'] = Variable<int>(timestamp);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_valid'] = Variable<bool>(isValid);
    if (!nullToAbsent || billId != null) {
      map['bill_id'] = Variable<String>(billId);
    }
    map['type'] = Variable<int>(type);
    if (!nullToAbsent || yimuAssetHistoryId != null) {
      map['yimu_asset_history_id'] = Variable<int>(yimuAssetHistoryId);
    }
    return map;
  }

  BalanceSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return BalanceSnapshotsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      balance: Value(balance),
      timestamp: Value(timestamp),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isValid: Value(isValid),
      billId: billId == null && nullToAbsent
          ? const Value.absent()
          : Value(billId),
      type: Value(type),
      yimuAssetHistoryId: yimuAssetHistoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(yimuAssetHistoryId),
    );
  }

  factory BalanceSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BalanceSnapshot(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      balance: serializer.fromJson<int>(json['balance']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      note: serializer.fromJson<String?>(json['note']),
      isValid: serializer.fromJson<bool>(json['isValid']),
      billId: serializer.fromJson<String?>(json['billId']),
      type: serializer.fromJson<int>(json['type']),
      yimuAssetHistoryId: serializer.fromJson<int?>(json['yimuAssetHistoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'balance': serializer.toJson<int>(balance),
      'timestamp': serializer.toJson<int>(timestamp),
      'note': serializer.toJson<String?>(note),
      'isValid': serializer.toJson<bool>(isValid),
      'billId': serializer.toJson<String?>(billId),
      'type': serializer.toJson<int>(type),
      'yimuAssetHistoryId': serializer.toJson<int?>(yimuAssetHistoryId),
    };
  }

  BalanceSnapshot copyWith({
    String? id,
    String? accountId,
    int? balance,
    int? timestamp,
    Value<String?> note = const Value.absent(),
    bool? isValid,
    Value<String?> billId = const Value.absent(),
    int? type,
    Value<int?> yimuAssetHistoryId = const Value.absent(),
  }) => BalanceSnapshot(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    balance: balance ?? this.balance,
    timestamp: timestamp ?? this.timestamp,
    note: note.present ? note.value : this.note,
    isValid: isValid ?? this.isValid,
    billId: billId.present ? billId.value : this.billId,
    type: type ?? this.type,
    yimuAssetHistoryId: yimuAssetHistoryId.present
        ? yimuAssetHistoryId.value
        : this.yimuAssetHistoryId,
  );
  BalanceSnapshot copyWithCompanion(BalanceSnapshotsCompanion data) {
    return BalanceSnapshot(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      balance: data.balance.present ? data.balance.value : this.balance,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      note: data.note.present ? data.note.value : this.note,
      isValid: data.isValid.present ? data.isValid.value : this.isValid,
      billId: data.billId.present ? data.billId.value : this.billId,
      type: data.type.present ? data.type.value : this.type,
      yimuAssetHistoryId: data.yimuAssetHistoryId.present
          ? data.yimuAssetHistoryId.value
          : this.yimuAssetHistoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BalanceSnapshot(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('balance: $balance, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('isValid: $isValid, ')
          ..write('billId: $billId, ')
          ..write('type: $type, ')
          ..write('yimuAssetHistoryId: $yimuAssetHistoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    balance,
    timestamp,
    note,
    isValid,
    billId,
    type,
    yimuAssetHistoryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BalanceSnapshot &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.balance == this.balance &&
          other.timestamp == this.timestamp &&
          other.note == this.note &&
          other.isValid == this.isValid &&
          other.billId == this.billId &&
          other.type == this.type &&
          other.yimuAssetHistoryId == this.yimuAssetHistoryId);
}

class BalanceSnapshotsCompanion extends UpdateCompanion<BalanceSnapshot> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<int> balance;
  final Value<int> timestamp;
  final Value<String?> note;
  final Value<bool> isValid;
  final Value<String?> billId;
  final Value<int> type;
  final Value<int?> yimuAssetHistoryId;
  final Value<int> rowid;
  const BalanceSnapshotsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.balance = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.note = const Value.absent(),
    this.isValid = const Value.absent(),
    this.billId = const Value.absent(),
    this.type = const Value.absent(),
    this.yimuAssetHistoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BalanceSnapshotsCompanion.insert({
    required String id,
    required String accountId,
    required int balance,
    required int timestamp,
    this.note = const Value.absent(),
    this.isValid = const Value.absent(),
    this.billId = const Value.absent(),
    required int type,
    this.yimuAssetHistoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       balance = Value(balance),
       timestamp = Value(timestamp),
       type = Value(type);
  static Insertable<BalanceSnapshot> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<int>? balance,
    Expression<int>? timestamp,
    Expression<String>? note,
    Expression<bool>? isValid,
    Expression<String>? billId,
    Expression<int>? type,
    Expression<int>? yimuAssetHistoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (balance != null) 'balance': balance,
      if (timestamp != null) 'timestamp': timestamp,
      if (note != null) 'note': note,
      if (isValid != null) 'is_valid': isValid,
      if (billId != null) 'bill_id': billId,
      if (type != null) 'type': type,
      if (yimuAssetHistoryId != null)
        'yimu_asset_history_id': yimuAssetHistoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BalanceSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<int>? balance,
    Value<int>? timestamp,
    Value<String?>? note,
    Value<bool>? isValid,
    Value<String?>? billId,
    Value<int>? type,
    Value<int?>? yimuAssetHistoryId,
    Value<int>? rowid,
  }) {
    return BalanceSnapshotsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      balance: balance ?? this.balance,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      isValid: isValid ?? this.isValid,
      billId: billId ?? this.billId,
      type: type ?? this.type,
      yimuAssetHistoryId: yimuAssetHistoryId ?? this.yimuAssetHistoryId,
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
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isValid.present) {
      map['is_valid'] = Variable<bool>(isValid.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (yimuAssetHistoryId.present) {
      map['yimu_asset_history_id'] = Variable<int>(yimuAssetHistoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BalanceSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('balance: $balance, ')
          ..write('timestamp: $timestamp, ')
          ..write('note: $note, ')
          ..write('isValid: $isValid, ')
          ..write('billId: $billId, ')
          ..write('type: $type, ')
          ..write('yimuAssetHistoryId: $yimuAssetHistoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, Transfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromAccountIdMeta = const VerificationMeta(
    'fromAccountId',
  );
  @override
  late final GeneratedColumn<String> fromAccountId = GeneratedColumn<String>(
    'from_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
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
  static const VerificationMeta _toAmountMeta = const VerificationMeta(
    'toAmount',
  );
  @override
  late final GeneratedColumn<int> toAmount = GeneratedColumn<int>(
    'to_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  @override
  late final GeneratedColumn<int> fee = GeneratedColumn<int>(
    'fee',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yimuTransferIdMeta = const VerificationMeta(
    'yimuTransferId',
  );
  @override
  late final GeneratedColumn<int> yimuTransferId = GeneratedColumn<int>(
    'yimu_transfer_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    billId,
    fromAccountId,
    toAccountId,
    amount,
    toAmount,
    fee,
    time,
    comment,
    yimuTransferId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
        _fromAccountIdMeta,
        fromAccountId.isAcceptableOrUnknown(
          data['from_account_id']!,
          _fromAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAccountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toAccountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('to_amount')) {
      context.handle(
        _toAmountMeta,
        toAmount.isAcceptableOrUnknown(data['to_amount']!, _toAmountMeta),
      );
    }
    if (data.containsKey('fee')) {
      context.handle(
        _feeMeta,
        fee.isAcceptableOrUnknown(data['fee']!, _feeMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('yimu_transfer_id')) {
      context.handle(
        _yimuTransferIdMeta,
        yimuTransferId.isAcceptableOrUnknown(
          data['yimu_transfer_id']!,
          _yimuTransferIdMeta,
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
  Transfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      fromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      toAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_amount'],
      ),
      fee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fee'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      yimuTransferId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yimu_transfer_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }
}

class Transfer extends DataClass implements Insertable<Transfer> {
  final String id;
  final String billId;
  final String fromAccountId;
  final String toAccountId;
  final int amount;
  final int? toAmount;
  final int fee;
  final int time;
  final String? comment;
  final int? yimuTransferId;
  final int createdAt;
  final int updatedAt;
  const Transfer({
    required this.id,
    required this.billId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    this.toAmount,
    required this.fee,
    required this.time,
    this.comment,
    this.yimuTransferId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_id'] = Variable<String>(billId);
    map['from_account_id'] = Variable<String>(fromAccountId);
    map['to_account_id'] = Variable<String>(toAccountId);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || toAmount != null) {
      map['to_amount'] = Variable<int>(toAmount);
    }
    map['fee'] = Variable<int>(fee);
    map['time'] = Variable<int>(time);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || yimuTransferId != null) {
      map['yimu_transfer_id'] = Variable<int>(yimuTransferId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      id: Value(id),
      billId: Value(billId),
      fromAccountId: Value(fromAccountId),
      toAccountId: Value(toAccountId),
      amount: Value(amount),
      toAmount: toAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(toAmount),
      fee: Value(fee),
      time: Value(time),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      yimuTransferId: yimuTransferId == null && nullToAbsent
          ? const Value.absent()
          : Value(yimuTransferId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Transfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transfer(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String>(json['billId']),
      fromAccountId: serializer.fromJson<String>(json['fromAccountId']),
      toAccountId: serializer.fromJson<String>(json['toAccountId']),
      amount: serializer.fromJson<int>(json['amount']),
      toAmount: serializer.fromJson<int?>(json['toAmount']),
      fee: serializer.fromJson<int>(json['fee']),
      time: serializer.fromJson<int>(json['time']),
      comment: serializer.fromJson<String?>(json['comment']),
      yimuTransferId: serializer.fromJson<int?>(json['yimuTransferId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String>(billId),
      'fromAccountId': serializer.toJson<String>(fromAccountId),
      'toAccountId': serializer.toJson<String>(toAccountId),
      'amount': serializer.toJson<int>(amount),
      'toAmount': serializer.toJson<int?>(toAmount),
      'fee': serializer.toJson<int>(fee),
      'time': serializer.toJson<int>(time),
      'comment': serializer.toJson<String?>(comment),
      'yimuTransferId': serializer.toJson<int?>(yimuTransferId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Transfer copyWith({
    String? id,
    String? billId,
    String? fromAccountId,
    String? toAccountId,
    int? amount,
    Value<int?> toAmount = const Value.absent(),
    int? fee,
    int? time,
    Value<String?> comment = const Value.absent(),
    Value<int?> yimuTransferId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Transfer(
    id: id ?? this.id,
    billId: billId ?? this.billId,
    fromAccountId: fromAccountId ?? this.fromAccountId,
    toAccountId: toAccountId ?? this.toAccountId,
    amount: amount ?? this.amount,
    toAmount: toAmount.present ? toAmount.value : this.toAmount,
    fee: fee ?? this.fee,
    time: time ?? this.time,
    comment: comment.present ? comment.value : this.comment,
    yimuTransferId: yimuTransferId.present
        ? yimuTransferId.value
        : this.yimuTransferId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Transfer copyWithCompanion(TransfersCompanion data) {
    return Transfer(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      toAmount: data.toAmount.present ? data.toAmount.value : this.toAmount,
      fee: data.fee.present ? data.fee.value : this.fee,
      time: data.time.present ? data.time.value : this.time,
      comment: data.comment.present ? data.comment.value : this.comment,
      yimuTransferId: data.yimuTransferId.present
          ? data.yimuTransferId.value
          : this.yimuTransferId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transfer(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('amount: $amount, ')
          ..write('toAmount: $toAmount, ')
          ..write('fee: $fee, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('yimuTransferId: $yimuTransferId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    billId,
    fromAccountId,
    toAccountId,
    amount,
    toAmount,
    fee,
    time,
    comment,
    yimuTransferId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transfer &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.amount == this.amount &&
          other.toAmount == this.toAmount &&
          other.fee == this.fee &&
          other.time == this.time &&
          other.comment == this.comment &&
          other.yimuTransferId == this.yimuTransferId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TransfersCompanion extends UpdateCompanion<Transfer> {
  final Value<String> id;
  final Value<String> billId;
  final Value<String> fromAccountId;
  final Value<String> toAccountId;
  final Value<int> amount;
  final Value<int?> toAmount;
  final Value<int> fee;
  final Value<int> time;
  final Value<String?> comment;
  final Value<int?> yimuTransferId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.toAmount = const Value.absent(),
    this.fee = const Value.absent(),
    this.time = const Value.absent(),
    this.comment = const Value.absent(),
    this.yimuTransferId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransfersCompanion.insert({
    required String id,
    required String billId,
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    this.toAmount = const Value.absent(),
    this.fee = const Value.absent(),
    required int time,
    this.comment = const Value.absent(),
    this.yimuTransferId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       billId = Value(billId),
       fromAccountId = Value(fromAccountId),
       toAccountId = Value(toAccountId),
       amount = Value(amount),
       time = Value(time),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Transfer> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<String>? fromAccountId,
    Expression<String>? toAccountId,
    Expression<int>? amount,
    Expression<int>? toAmount,
    Expression<int>? fee,
    Expression<int>? time,
    Expression<String>? comment,
    Expression<int>? yimuTransferId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (amount != null) 'amount': amount,
      if (toAmount != null) 'to_amount': toAmount,
      if (fee != null) 'fee': fee,
      if (time != null) 'time': time,
      if (comment != null) 'comment': comment,
      if (yimuTransferId != null) 'yimu_transfer_id': yimuTransferId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransfersCompanion copyWith({
    Value<String>? id,
    Value<String>? billId,
    Value<String>? fromAccountId,
    Value<String>? toAccountId,
    Value<int>? amount,
    Value<int?>? toAmount,
    Value<int>? fee,
    Value<int>? time,
    Value<String?>? comment,
    Value<int?>? yimuTransferId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return TransfersCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amount: amount ?? this.amount,
      toAmount: toAmount ?? this.toAmount,
      fee: fee ?? this.fee,
      time: time ?? this.time,
      comment: comment ?? this.comment,
      yimuTransferId: yimuTransferId ?? this.yimuTransferId,
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
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<String>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (toAmount.present) {
      map['to_amount'] = Variable<int>(toAmount.value);
    }
    if (fee.present) {
      map['fee'] = Variable<int>(fee.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (yimuTransferId.present) {
      map['yimu_transfer_id'] = Variable<int>(yimuTransferId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransfersCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('amount: $amount, ')
          ..write('toAmount: $toAmount, ')
          ..write('fee: $fee, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('yimuTransferId: $yimuTransferId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LendsTable extends Lends with TableInfo<$LendsTable, Lend> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LendsTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _repaymentAccountIdMeta =
      const VerificationMeta('repaymentAccountId');
  @override
  late final GeneratedColumn<String> repaymentAccountId =
      GeneratedColumn<String>(
        'repayment_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
  static const VerificationMeta _interestMeta = const VerificationMeta(
    'interest',
  );
  @override
  late final GeneratedColumn<int> interest = GeneratedColumn<int>(
    'interest',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _originalAmountMeta = const VerificationMeta(
    'originalAmount',
  );
  @override
  late final GeneratedColumn<int> originalAmount = GeneratedColumn<int>(
    'original_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yimuLendIdMeta = const VerificationMeta(
    'yimuLendId',
  );
  @override
  late final GeneratedColumn<int> yimuLendId = GeneratedColumn<int>(
    'yimu_lend_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    accountId,
    repaymentAccountId,
    amount,
    interest,
    originalAmount,
    billId,
    time,
    comment,
    yimuLendId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lends';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lend> instance, {
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
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('repayment_account_id')) {
      context.handle(
        _repaymentAccountIdMeta,
        repaymentAccountId.isAcceptableOrUnknown(
          data['repayment_account_id']!,
          _repaymentAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('interest')) {
      context.handle(
        _interestMeta,
        interest.isAcceptableOrUnknown(data['interest']!, _interestMeta),
      );
    }
    if (data.containsKey('original_amount')) {
      context.handle(
        _originalAmountMeta,
        originalAmount.isAcceptableOrUnknown(
          data['original_amount']!,
          _originalAmountMeta,
        ),
      );
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('yimu_lend_id')) {
      context.handle(
        _yimuLendIdMeta,
        yimuLendId.isAcceptableOrUnknown(
          data['yimu_lend_id']!,
          _yimuLendIdMeta,
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
  Lend map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lend(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      repaymentAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repayment_account_id'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      interest: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interest'],
      )!,
      originalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_amount'],
      ),
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      yimuLendId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yimu_lend_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LendsTable createAlias(String alias) {
    return $LendsTable(attachedDatabase, alias);
  }
}

class Lend extends DataClass implements Insertable<Lend> {
  final String id;
  final String type;
  final String accountId;
  final String? repaymentAccountId;
  final int amount;
  final int interest;
  final int? originalAmount;
  final String? billId;
  final int time;
  final String? comment;
  final int? yimuLendId;
  final int createdAt;
  final int updatedAt;
  const Lend({
    required this.id,
    required this.type,
    required this.accountId,
    this.repaymentAccountId,
    required this.amount,
    required this.interest,
    this.originalAmount,
    this.billId,
    required this.time,
    this.comment,
    this.yimuLendId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || repaymentAccountId != null) {
      map['repayment_account_id'] = Variable<String>(repaymentAccountId);
    }
    map['amount'] = Variable<int>(amount);
    map['interest'] = Variable<int>(interest);
    if (!nullToAbsent || originalAmount != null) {
      map['original_amount'] = Variable<int>(originalAmount);
    }
    if (!nullToAbsent || billId != null) {
      map['bill_id'] = Variable<String>(billId);
    }
    map['time'] = Variable<int>(time);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || yimuLendId != null) {
      map['yimu_lend_id'] = Variable<int>(yimuLendId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LendsCompanion toCompanion(bool nullToAbsent) {
    return LendsCompanion(
      id: Value(id),
      type: Value(type),
      accountId: Value(accountId),
      repaymentAccountId: repaymentAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(repaymentAccountId),
      amount: Value(amount),
      interest: Value(interest),
      originalAmount: originalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(originalAmount),
      billId: billId == null && nullToAbsent
          ? const Value.absent()
          : Value(billId),
      time: Value(time),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      yimuLendId: yimuLendId == null && nullToAbsent
          ? const Value.absent()
          : Value(yimuLendId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Lend.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lend(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      accountId: serializer.fromJson<String>(json['accountId']),
      repaymentAccountId: serializer.fromJson<String?>(
        json['repaymentAccountId'],
      ),
      amount: serializer.fromJson<int>(json['amount']),
      interest: serializer.fromJson<int>(json['interest']),
      originalAmount: serializer.fromJson<int?>(json['originalAmount']),
      billId: serializer.fromJson<String?>(json['billId']),
      time: serializer.fromJson<int>(json['time']),
      comment: serializer.fromJson<String?>(json['comment']),
      yimuLendId: serializer.fromJson<int?>(json['yimuLendId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'accountId': serializer.toJson<String>(accountId),
      'repaymentAccountId': serializer.toJson<String?>(repaymentAccountId),
      'amount': serializer.toJson<int>(amount),
      'interest': serializer.toJson<int>(interest),
      'originalAmount': serializer.toJson<int?>(originalAmount),
      'billId': serializer.toJson<String?>(billId),
      'time': serializer.toJson<int>(time),
      'comment': serializer.toJson<String?>(comment),
      'yimuLendId': serializer.toJson<int?>(yimuLendId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Lend copyWith({
    String? id,
    String? type,
    String? accountId,
    Value<String?> repaymentAccountId = const Value.absent(),
    int? amount,
    int? interest,
    Value<int?> originalAmount = const Value.absent(),
    Value<String?> billId = const Value.absent(),
    int? time,
    Value<String?> comment = const Value.absent(),
    Value<int?> yimuLendId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Lend(
    id: id ?? this.id,
    type: type ?? this.type,
    accountId: accountId ?? this.accountId,
    repaymentAccountId: repaymentAccountId.present
        ? repaymentAccountId.value
        : this.repaymentAccountId,
    amount: amount ?? this.amount,
    interest: interest ?? this.interest,
    originalAmount: originalAmount.present
        ? originalAmount.value
        : this.originalAmount,
    billId: billId.present ? billId.value : this.billId,
    time: time ?? this.time,
    comment: comment.present ? comment.value : this.comment,
    yimuLendId: yimuLendId.present ? yimuLendId.value : this.yimuLendId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Lend copyWithCompanion(LendsCompanion data) {
    return Lend(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      repaymentAccountId: data.repaymentAccountId.present
          ? data.repaymentAccountId.value
          : this.repaymentAccountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      interest: data.interest.present ? data.interest.value : this.interest,
      originalAmount: data.originalAmount.present
          ? data.originalAmount.value
          : this.originalAmount,
      billId: data.billId.present ? data.billId.value : this.billId,
      time: data.time.present ? data.time.value : this.time,
      comment: data.comment.present ? data.comment.value : this.comment,
      yimuLendId: data.yimuLendId.present
          ? data.yimuLendId.value
          : this.yimuLendId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lend(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('repaymentAccountId: $repaymentAccountId, ')
          ..write('amount: $amount, ')
          ..write('interest: $interest, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('billId: $billId, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('yimuLendId: $yimuLendId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    accountId,
    repaymentAccountId,
    amount,
    interest,
    originalAmount,
    billId,
    time,
    comment,
    yimuLendId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lend &&
          other.id == this.id &&
          other.type == this.type &&
          other.accountId == this.accountId &&
          other.repaymentAccountId == this.repaymentAccountId &&
          other.amount == this.amount &&
          other.interest == this.interest &&
          other.originalAmount == this.originalAmount &&
          other.billId == this.billId &&
          other.time == this.time &&
          other.comment == this.comment &&
          other.yimuLendId == this.yimuLendId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LendsCompanion extends UpdateCompanion<Lend> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> accountId;
  final Value<String?> repaymentAccountId;
  final Value<int> amount;
  final Value<int> interest;
  final Value<int?> originalAmount;
  final Value<String?> billId;
  final Value<int> time;
  final Value<String?> comment;
  final Value<int?> yimuLendId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LendsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.accountId = const Value.absent(),
    this.repaymentAccountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.interest = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.billId = const Value.absent(),
    this.time = const Value.absent(),
    this.comment = const Value.absent(),
    this.yimuLendId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LendsCompanion.insert({
    required String id,
    required String type,
    required String accountId,
    this.repaymentAccountId = const Value.absent(),
    required int amount,
    this.interest = const Value.absent(),
    this.originalAmount = const Value.absent(),
    this.billId = const Value.absent(),
    required int time,
    this.comment = const Value.absent(),
    this.yimuLendId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       accountId = Value(accountId),
       amount = Value(amount),
       time = Value(time),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Lend> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? accountId,
    Expression<String>? repaymentAccountId,
    Expression<int>? amount,
    Expression<int>? interest,
    Expression<int>? originalAmount,
    Expression<String>? billId,
    Expression<int>? time,
    Expression<String>? comment,
    Expression<int>? yimuLendId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (accountId != null) 'account_id': accountId,
      if (repaymentAccountId != null)
        'repayment_account_id': repaymentAccountId,
      if (amount != null) 'amount': amount,
      if (interest != null) 'interest': interest,
      if (originalAmount != null) 'original_amount': originalAmount,
      if (billId != null) 'bill_id': billId,
      if (time != null) 'time': time,
      if (comment != null) 'comment': comment,
      if (yimuLendId != null) 'yimu_lend_id': yimuLendId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LendsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? accountId,
    Value<String?>? repaymentAccountId,
    Value<int>? amount,
    Value<int>? interest,
    Value<int?>? originalAmount,
    Value<String?>? billId,
    Value<int>? time,
    Value<String?>? comment,
    Value<int?>? yimuLendId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return LendsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      repaymentAccountId: repaymentAccountId ?? this.repaymentAccountId,
      amount: amount ?? this.amount,
      interest: interest ?? this.interest,
      originalAmount: originalAmount ?? this.originalAmount,
      billId: billId ?? this.billId,
      time: time ?? this.time,
      comment: comment ?? this.comment,
      yimuLendId: yimuLendId ?? this.yimuLendId,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (repaymentAccountId.present) {
      map['repayment_account_id'] = Variable<String>(repaymentAccountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (interest.present) {
      map['interest'] = Variable<int>(interest.value);
    }
    if (originalAmount.present) {
      map['original_amount'] = Variable<int>(originalAmount.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (yimuLendId.present) {
      map['yimu_lend_id'] = Variable<int>(yimuLendId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LendsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('repaymentAccountId: $repaymentAccountId, ')
          ..write('amount: $amount, ')
          ..write('interest: $interest, ')
          ..write('originalAmount: $originalAmount, ')
          ..write('billId: $billId, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('yimuLendId: $yimuLendId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RefundsTable extends Refunds with TableInfo<$RefundsTable, Refund> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RefundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
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
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yimuRefundIdMeta = const VerificationMeta(
    'yimuRefundId',
  );
  @override
  late final GeneratedColumn<int> yimuRefundId = GeneratedColumn<int>(
    'yimu_refund_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    billId,
    amount,
    time,
    comment,
    yimuRefundId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'refunds';
  @override
  VerificationContext validateIntegrity(
    Insertable<Refund> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('yimu_refund_id')) {
      context.handle(
        _yimuRefundIdMeta,
        yimuRefundId.isAcceptableOrUnknown(
          data['yimu_refund_id']!,
          _yimuRefundIdMeta,
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
  Refund map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Refund(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      yimuRefundId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yimu_refund_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RefundsTable createAlias(String alias) {
    return $RefundsTable(attachedDatabase, alias);
  }
}

class Refund extends DataClass implements Insertable<Refund> {
  final String id;
  final String billId;
  final int amount;
  final int time;
  final String? comment;
  final int? yimuRefundId;
  final int createdAt;
  final int updatedAt;
  const Refund({
    required this.id,
    required this.billId,
    required this.amount,
    required this.time,
    this.comment,
    this.yimuRefundId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_id'] = Variable<String>(billId);
    map['amount'] = Variable<int>(amount);
    map['time'] = Variable<int>(time);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || yimuRefundId != null) {
      map['yimu_refund_id'] = Variable<int>(yimuRefundId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RefundsCompanion toCompanion(bool nullToAbsent) {
    return RefundsCompanion(
      id: Value(id),
      billId: Value(billId),
      amount: Value(amount),
      time: Value(time),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      yimuRefundId: yimuRefundId == null && nullToAbsent
          ? const Value.absent()
          : Value(yimuRefundId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Refund.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Refund(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String>(json['billId']),
      amount: serializer.fromJson<int>(json['amount']),
      time: serializer.fromJson<int>(json['time']),
      comment: serializer.fromJson<String?>(json['comment']),
      yimuRefundId: serializer.fromJson<int?>(json['yimuRefundId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String>(billId),
      'amount': serializer.toJson<int>(amount),
      'time': serializer.toJson<int>(time),
      'comment': serializer.toJson<String?>(comment),
      'yimuRefundId': serializer.toJson<int?>(yimuRefundId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Refund copyWith({
    String? id,
    String? billId,
    int? amount,
    int? time,
    Value<String?> comment = const Value.absent(),
    Value<int?> yimuRefundId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Refund(
    id: id ?? this.id,
    billId: billId ?? this.billId,
    amount: amount ?? this.amount,
    time: time ?? this.time,
    comment: comment.present ? comment.value : this.comment,
    yimuRefundId: yimuRefundId.present ? yimuRefundId.value : this.yimuRefundId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Refund copyWithCompanion(RefundsCompanion data) {
    return Refund(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      amount: data.amount.present ? data.amount.value : this.amount,
      time: data.time.present ? data.time.value : this.time,
      comment: data.comment.present ? data.comment.value : this.comment,
      yimuRefundId: data.yimuRefundId.present
          ? data.yimuRefundId.value
          : this.yimuRefundId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Refund(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('amount: $amount, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('yimuRefundId: $yimuRefundId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    billId,
    amount,
    time,
    comment,
    yimuRefundId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Refund &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.amount == this.amount &&
          other.time == this.time &&
          other.comment == this.comment &&
          other.yimuRefundId == this.yimuRefundId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RefundsCompanion extends UpdateCompanion<Refund> {
  final Value<String> id;
  final Value<String> billId;
  final Value<int> amount;
  final Value<int> time;
  final Value<String?> comment;
  final Value<int?> yimuRefundId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const RefundsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.amount = const Value.absent(),
    this.time = const Value.absent(),
    this.comment = const Value.absent(),
    this.yimuRefundId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RefundsCompanion.insert({
    required String id,
    required String billId,
    required int amount,
    required int time,
    this.comment = const Value.absent(),
    this.yimuRefundId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       billId = Value(billId),
       amount = Value(amount),
       time = Value(time),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Refund> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<int>? amount,
    Expression<int>? time,
    Expression<String>? comment,
    Expression<int>? yimuRefundId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (amount != null) 'amount': amount,
      if (time != null) 'time': time,
      if (comment != null) 'comment': comment,
      if (yimuRefundId != null) 'yimu_refund_id': yimuRefundId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RefundsCompanion copyWith({
    Value<String>? id,
    Value<String>? billId,
    Value<int>? amount,
    Value<int>? time,
    Value<String?>? comment,
    Value<int?>? yimuRefundId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return RefundsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      amount: amount ?? this.amount,
      time: time ?? this.time,
      comment: comment ?? this.comment,
      yimuRefundId: yimuRefundId ?? this.yimuRefundId,
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
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (yimuRefundId.present) {
      map['yimu_refund_id'] = Variable<int>(yimuRefundId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RefundsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('amount: $amount, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('yimuRefundId: $yimuRefundId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReimbursementsTable extends Reimbursements
    with TableInfo<$ReimbursementsTable, Reimbursement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReimbursementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
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
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reimbursementAccountIdMeta =
      const VerificationMeta('reimbursementAccountId');
  @override
  late final GeneratedColumn<String> reimbursementAccountId =
      GeneratedColumn<String>(
        'reimbursement_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endedMeta = const VerificationMeta('ended');
  @override
  late final GeneratedColumn<bool> ended = GeneratedColumn<bool>(
    'ended',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ended" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yimuReimbursementIdMeta =
      const VerificationMeta('yimuReimbursementId');
  @override
  late final GeneratedColumn<int> yimuReimbursementId = GeneratedColumn<int>(
    'yimu_reimbursement_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    billId,
    amount,
    accountId,
    reimbursementAccountId,
    ended,
    time,
    comment,
    yimuReimbursementId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reimbursements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reimbursement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('reimbursement_account_id')) {
      context.handle(
        _reimbursementAccountIdMeta,
        reimbursementAccountId.isAcceptableOrUnknown(
          data['reimbursement_account_id']!,
          _reimbursementAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('ended')) {
      context.handle(
        _endedMeta,
        ended.isAcceptableOrUnknown(data['ended']!, _endedMeta),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    }
    if (data.containsKey('yimu_reimbursement_id')) {
      context.handle(
        _yimuReimbursementIdMeta,
        yimuReimbursementId.isAcceptableOrUnknown(
          data['yimu_reimbursement_id']!,
          _yimuReimbursementIdMeta,
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
  Reimbursement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reimbursement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      reimbursementAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reimbursement_account_id'],
      ),
      ended: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ended'],
      )!,
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      ),
      yimuReimbursementId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yimu_reimbursement_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReimbursementsTable createAlias(String alias) {
    return $ReimbursementsTable(attachedDatabase, alias);
  }
}

class Reimbursement extends DataClass implements Insertable<Reimbursement> {
  final String id;
  final String billId;
  final int amount;
  final String? accountId;
  final String? reimbursementAccountId;
  final bool ended;
  final int time;
  final String? comment;
  final int? yimuReimbursementId;
  final int createdAt;
  final int updatedAt;
  const Reimbursement({
    required this.id,
    required this.billId,
    required this.amount,
    this.accountId,
    this.reimbursementAccountId,
    required this.ended,
    required this.time,
    this.comment,
    this.yimuReimbursementId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_id'] = Variable<String>(billId);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || reimbursementAccountId != null) {
      map['reimbursement_account_id'] = Variable<String>(
        reimbursementAccountId,
      );
    }
    map['ended'] = Variable<bool>(ended);
    map['time'] = Variable<int>(time);
    if (!nullToAbsent || comment != null) {
      map['comment'] = Variable<String>(comment);
    }
    if (!nullToAbsent || yimuReimbursementId != null) {
      map['yimu_reimbursement_id'] = Variable<int>(yimuReimbursementId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ReimbursementsCompanion toCompanion(bool nullToAbsent) {
    return ReimbursementsCompanion(
      id: Value(id),
      billId: Value(billId),
      amount: Value(amount),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      reimbursementAccountId: reimbursementAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(reimbursementAccountId),
      ended: Value(ended),
      time: Value(time),
      comment: comment == null && nullToAbsent
          ? const Value.absent()
          : Value(comment),
      yimuReimbursementId: yimuReimbursementId == null && nullToAbsent
          ? const Value.absent()
          : Value(yimuReimbursementId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reimbursement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reimbursement(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String>(json['billId']),
      amount: serializer.fromJson<int>(json['amount']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      reimbursementAccountId: serializer.fromJson<String?>(
        json['reimbursementAccountId'],
      ),
      ended: serializer.fromJson<bool>(json['ended']),
      time: serializer.fromJson<int>(json['time']),
      comment: serializer.fromJson<String?>(json['comment']),
      yimuReimbursementId: serializer.fromJson<int?>(
        json['yimuReimbursementId'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String>(billId),
      'amount': serializer.toJson<int>(amount),
      'accountId': serializer.toJson<String?>(accountId),
      'reimbursementAccountId': serializer.toJson<String?>(
        reimbursementAccountId,
      ),
      'ended': serializer.toJson<bool>(ended),
      'time': serializer.toJson<int>(time),
      'comment': serializer.toJson<String?>(comment),
      'yimuReimbursementId': serializer.toJson<int?>(yimuReimbursementId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Reimbursement copyWith({
    String? id,
    String? billId,
    int? amount,
    Value<String?> accountId = const Value.absent(),
    Value<String?> reimbursementAccountId = const Value.absent(),
    bool? ended,
    int? time,
    Value<String?> comment = const Value.absent(),
    Value<int?> yimuReimbursementId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Reimbursement(
    id: id ?? this.id,
    billId: billId ?? this.billId,
    amount: amount ?? this.amount,
    accountId: accountId.present ? accountId.value : this.accountId,
    reimbursementAccountId: reimbursementAccountId.present
        ? reimbursementAccountId.value
        : this.reimbursementAccountId,
    ended: ended ?? this.ended,
    time: time ?? this.time,
    comment: comment.present ? comment.value : this.comment,
    yimuReimbursementId: yimuReimbursementId.present
        ? yimuReimbursementId.value
        : this.yimuReimbursementId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reimbursement copyWithCompanion(ReimbursementsCompanion data) {
    return Reimbursement(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      amount: data.amount.present ? data.amount.value : this.amount,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      reimbursementAccountId: data.reimbursementAccountId.present
          ? data.reimbursementAccountId.value
          : this.reimbursementAccountId,
      ended: data.ended.present ? data.ended.value : this.ended,
      time: data.time.present ? data.time.value : this.time,
      comment: data.comment.present ? data.comment.value : this.comment,
      yimuReimbursementId: data.yimuReimbursementId.present
          ? data.yimuReimbursementId.value
          : this.yimuReimbursementId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reimbursement(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('reimbursementAccountId: $reimbursementAccountId, ')
          ..write('ended: $ended, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('yimuReimbursementId: $yimuReimbursementId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    billId,
    amount,
    accountId,
    reimbursementAccountId,
    ended,
    time,
    comment,
    yimuReimbursementId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reimbursement &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.amount == this.amount &&
          other.accountId == this.accountId &&
          other.reimbursementAccountId == this.reimbursementAccountId &&
          other.ended == this.ended &&
          other.time == this.time &&
          other.comment == this.comment &&
          other.yimuReimbursementId == this.yimuReimbursementId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReimbursementsCompanion extends UpdateCompanion<Reimbursement> {
  final Value<String> id;
  final Value<String> billId;
  final Value<int> amount;
  final Value<String?> accountId;
  final Value<String?> reimbursementAccountId;
  final Value<bool> ended;
  final Value<int> time;
  final Value<String?> comment;
  final Value<int?> yimuReimbursementId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ReimbursementsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.amount = const Value.absent(),
    this.accountId = const Value.absent(),
    this.reimbursementAccountId = const Value.absent(),
    this.ended = const Value.absent(),
    this.time = const Value.absent(),
    this.comment = const Value.absent(),
    this.yimuReimbursementId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReimbursementsCompanion.insert({
    required String id,
    required String billId,
    required int amount,
    this.accountId = const Value.absent(),
    this.reimbursementAccountId = const Value.absent(),
    this.ended = const Value.absent(),
    required int time,
    this.comment = const Value.absent(),
    this.yimuReimbursementId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       billId = Value(billId),
       amount = Value(amount),
       time = Value(time),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Reimbursement> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<int>? amount,
    Expression<String>? accountId,
    Expression<String>? reimbursementAccountId,
    Expression<bool>? ended,
    Expression<int>? time,
    Expression<String>? comment,
    Expression<int>? yimuReimbursementId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (amount != null) 'amount': amount,
      if (accountId != null) 'account_id': accountId,
      if (reimbursementAccountId != null)
        'reimbursement_account_id': reimbursementAccountId,
      if (ended != null) 'ended': ended,
      if (time != null) 'time': time,
      if (comment != null) 'comment': comment,
      if (yimuReimbursementId != null)
        'yimu_reimbursement_id': yimuReimbursementId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReimbursementsCompanion copyWith({
    Value<String>? id,
    Value<String>? billId,
    Value<int>? amount,
    Value<String?>? accountId,
    Value<String?>? reimbursementAccountId,
    Value<bool>? ended,
    Value<int>? time,
    Value<String?>? comment,
    Value<int?>? yimuReimbursementId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReimbursementsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      reimbursementAccountId:
          reimbursementAccountId ?? this.reimbursementAccountId,
      ended: ended ?? this.ended,
      time: time ?? this.time,
      comment: comment ?? this.comment,
      yimuReimbursementId: yimuReimbursementId ?? this.yimuReimbursementId,
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
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (reimbursementAccountId.present) {
      map['reimbursement_account_id'] = Variable<String>(
        reimbursementAccountId.value,
      );
    }
    if (ended.present) {
      map['ended'] = Variable<bool>(ended.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (yimuReimbursementId.present) {
      map['yimu_reimbursement_id'] = Variable<int>(yimuReimbursementId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReimbursementsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('reimbursementAccountId: $reimbursementAccountId, ')
          ..write('ended: $ended, ')
          ..write('time: $time, ')
          ..write('comment: $comment, ')
          ..write('yimuReimbursementId: $yimuReimbursementId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstalmentsTable extends Instalments
    with TableInfo<$InstalmentsTable, Instalment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstalmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
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
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<int> totalAmount = GeneratedColumn<int>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serviceFeeMeta = const VerificationMeta(
    'serviceFee',
  );
  @override
  late final GeneratedColumn<int> serviceFee = GeneratedColumn<int>(
    'service_fee',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _periodsMeta = const VerificationMeta(
    'periods',
  );
  @override
  late final GeneratedColumn<int> periods = GeneratedColumn<int>(
    'periods',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountMonthMeta = const VerificationMeta(
    'accountMonth',
  );
  @override
  late final GeneratedColumn<String> accountMonth = GeneratedColumn<String>(
    'account_month',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<int> time = GeneratedColumn<int>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yimuInstalmentIdMeta = const VerificationMeta(
    'yimuInstalmentId',
  );
  @override
  late final GeneratedColumn<int> yimuInstalmentId = GeneratedColumn<int>(
    'yimu_instalment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    billId,
    accountId,
    totalAmount,
    serviceFee,
    periods,
    accountMonth,
    time,
    yimuInstalmentId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instalments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Instalment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    } else if (isInserting) {
      context.missing(_billIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('service_fee')) {
      context.handle(
        _serviceFeeMeta,
        serviceFee.isAcceptableOrUnknown(data['service_fee']!, _serviceFeeMeta),
      );
    }
    if (data.containsKey('periods')) {
      context.handle(
        _periodsMeta,
        periods.isAcceptableOrUnknown(data['periods']!, _periodsMeta),
      );
    } else if (isInserting) {
      context.missing(_periodsMeta);
    }
    if (data.containsKey('account_month')) {
      context.handle(
        _accountMonthMeta,
        accountMonth.isAcceptableOrUnknown(
          data['account_month']!,
          _accountMonthMeta,
        ),
      );
    }
    if (data.containsKey('time')) {
      context.handle(
        _timeMeta,
        time.isAcceptableOrUnknown(data['time']!, _timeMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('yimu_instalment_id')) {
      context.handle(
        _yimuInstalmentIdMeta,
        yimuInstalmentId.isAcceptableOrUnknown(
          data['yimu_instalment_id']!,
          _yimuInstalmentIdMeta,
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
  Instalment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Instalment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_amount'],
      )!,
      serviceFee: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_fee'],
      )!,
      periods: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}periods'],
      )!,
      accountMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_month'],
      ),
      time: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time'],
      )!,
      yimuInstalmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yimu_instalment_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InstalmentsTable createAlias(String alias) {
    return $InstalmentsTable(attachedDatabase, alias);
  }
}

class Instalment extends DataClass implements Insertable<Instalment> {
  final String id;
  final String billId;
  final String accountId;
  final int totalAmount;
  final int serviceFee;
  final int periods;
  final String? accountMonth;
  final int time;
  final int? yimuInstalmentId;
  final int createdAt;
  final int updatedAt;
  const Instalment({
    required this.id,
    required this.billId,
    required this.accountId,
    required this.totalAmount,
    required this.serviceFee,
    required this.periods,
    this.accountMonth,
    required this.time,
    this.yimuInstalmentId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bill_id'] = Variable<String>(billId);
    map['account_id'] = Variable<String>(accountId);
    map['total_amount'] = Variable<int>(totalAmount);
    map['service_fee'] = Variable<int>(serviceFee);
    map['periods'] = Variable<int>(periods);
    if (!nullToAbsent || accountMonth != null) {
      map['account_month'] = Variable<String>(accountMonth);
    }
    map['time'] = Variable<int>(time);
    if (!nullToAbsent || yimuInstalmentId != null) {
      map['yimu_instalment_id'] = Variable<int>(yimuInstalmentId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  InstalmentsCompanion toCompanion(bool nullToAbsent) {
    return InstalmentsCompanion(
      id: Value(id),
      billId: Value(billId),
      accountId: Value(accountId),
      totalAmount: Value(totalAmount),
      serviceFee: Value(serviceFee),
      periods: Value(periods),
      accountMonth: accountMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(accountMonth),
      time: Value(time),
      yimuInstalmentId: yimuInstalmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(yimuInstalmentId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Instalment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Instalment(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String>(json['billId']),
      accountId: serializer.fromJson<String>(json['accountId']),
      totalAmount: serializer.fromJson<int>(json['totalAmount']),
      serviceFee: serializer.fromJson<int>(json['serviceFee']),
      periods: serializer.fromJson<int>(json['periods']),
      accountMonth: serializer.fromJson<String?>(json['accountMonth']),
      time: serializer.fromJson<int>(json['time']),
      yimuInstalmentId: serializer.fromJson<int?>(json['yimuInstalmentId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String>(billId),
      'accountId': serializer.toJson<String>(accountId),
      'totalAmount': serializer.toJson<int>(totalAmount),
      'serviceFee': serializer.toJson<int>(serviceFee),
      'periods': serializer.toJson<int>(periods),
      'accountMonth': serializer.toJson<String?>(accountMonth),
      'time': serializer.toJson<int>(time),
      'yimuInstalmentId': serializer.toJson<int?>(yimuInstalmentId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Instalment copyWith({
    String? id,
    String? billId,
    String? accountId,
    int? totalAmount,
    int? serviceFee,
    int? periods,
    Value<String?> accountMonth = const Value.absent(),
    int? time,
    Value<int?> yimuInstalmentId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Instalment(
    id: id ?? this.id,
    billId: billId ?? this.billId,
    accountId: accountId ?? this.accountId,
    totalAmount: totalAmount ?? this.totalAmount,
    serviceFee: serviceFee ?? this.serviceFee,
    periods: periods ?? this.periods,
    accountMonth: accountMonth.present ? accountMonth.value : this.accountMonth,
    time: time ?? this.time,
    yimuInstalmentId: yimuInstalmentId.present
        ? yimuInstalmentId.value
        : this.yimuInstalmentId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Instalment copyWithCompanion(InstalmentsCompanion data) {
    return Instalment(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      serviceFee: data.serviceFee.present
          ? data.serviceFee.value
          : this.serviceFee,
      periods: data.periods.present ? data.periods.value : this.periods,
      accountMonth: data.accountMonth.present
          ? data.accountMonth.value
          : this.accountMonth,
      time: data.time.present ? data.time.value : this.time,
      yimuInstalmentId: data.yimuInstalmentId.present
          ? data.yimuInstalmentId.value
          : this.yimuInstalmentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Instalment(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('accountId: $accountId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('serviceFee: $serviceFee, ')
          ..write('periods: $periods, ')
          ..write('accountMonth: $accountMonth, ')
          ..write('time: $time, ')
          ..write('yimuInstalmentId: $yimuInstalmentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    billId,
    accountId,
    totalAmount,
    serviceFee,
    periods,
    accountMonth,
    time,
    yimuInstalmentId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Instalment &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.accountId == this.accountId &&
          other.totalAmount == this.totalAmount &&
          other.serviceFee == this.serviceFee &&
          other.periods == this.periods &&
          other.accountMonth == this.accountMonth &&
          other.time == this.time &&
          other.yimuInstalmentId == this.yimuInstalmentId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InstalmentsCompanion extends UpdateCompanion<Instalment> {
  final Value<String> id;
  final Value<String> billId;
  final Value<String> accountId;
  final Value<int> totalAmount;
  final Value<int> serviceFee;
  final Value<int> periods;
  final Value<String?> accountMonth;
  final Value<int> time;
  final Value<int?> yimuInstalmentId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const InstalmentsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.serviceFee = const Value.absent(),
    this.periods = const Value.absent(),
    this.accountMonth = const Value.absent(),
    this.time = const Value.absent(),
    this.yimuInstalmentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstalmentsCompanion.insert({
    required String id,
    required String billId,
    required String accountId,
    required int totalAmount,
    this.serviceFee = const Value.absent(),
    required int periods,
    this.accountMonth = const Value.absent(),
    required int time,
    this.yimuInstalmentId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       billId = Value(billId),
       accountId = Value(accountId),
       totalAmount = Value(totalAmount),
       periods = Value(periods),
       time = Value(time),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Instalment> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<String>? accountId,
    Expression<int>? totalAmount,
    Expression<int>? serviceFee,
    Expression<int>? periods,
    Expression<String>? accountMonth,
    Expression<int>? time,
    Expression<int>? yimuInstalmentId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (accountId != null) 'account_id': accountId,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (serviceFee != null) 'service_fee': serviceFee,
      if (periods != null) 'periods': periods,
      if (accountMonth != null) 'account_month': accountMonth,
      if (time != null) 'time': time,
      if (yimuInstalmentId != null) 'yimu_instalment_id': yimuInstalmentId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstalmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? billId,
    Value<String>? accountId,
    Value<int>? totalAmount,
    Value<int>? serviceFee,
    Value<int>? periods,
    Value<String?>? accountMonth,
    Value<int>? time,
    Value<int?>? yimuInstalmentId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return InstalmentsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      accountId: accountId ?? this.accountId,
      totalAmount: totalAmount ?? this.totalAmount,
      serviceFee: serviceFee ?? this.serviceFee,
      periods: periods ?? this.periods,
      accountMonth: accountMonth ?? this.accountMonth,
      time: time ?? this.time,
      yimuInstalmentId: yimuInstalmentId ?? this.yimuInstalmentId,
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
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<int>(totalAmount.value);
    }
    if (serviceFee.present) {
      map['service_fee'] = Variable<int>(serviceFee.value);
    }
    if (periods.present) {
      map['periods'] = Variable<int>(periods.value);
    }
    if (accountMonth.present) {
      map['account_month'] = Variable<String>(accountMonth.value);
    }
    if (time.present) {
      map['time'] = Variable<int>(time.value);
    }
    if (yimuInstalmentId.present) {
      map['yimu_instalment_id'] = Variable<int>(yimuInstalmentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstalmentsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('accountId: $accountId, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('serviceFee: $serviceFee, ')
          ..write('periods: $periods, ')
          ..write('accountMonth: $accountMonth, ')
          ..write('time: $time, ')
          ..write('yimuInstalmentId: $yimuInstalmentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _periodTypeMeta = const VerificationMeta(
    'periodType',
  );
  @override
  late final GeneratedColumn<String> periodType = GeneratedColumn<String>(
    'period_type',
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
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<int> endTime = GeneratedColumn<int>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _yimuBudgetIdMeta = const VerificationMeta(
    'yimuBudgetId',
  );
  @override
  late final GeneratedColumn<int> yimuBudgetId = GeneratedColumn<int>(
    'yimu_budget_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    categoryId,
    type,
    periodType,
    amount,
    startTime,
    endTime,
    enabled,
    yimuBudgetId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
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
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('period_type')) {
      context.handle(
        _periodTypeMeta,
        periodType.isAcceptableOrUnknown(data['period_type']!, _periodTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_periodTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('yimu_budget_id')) {
      context.handle(
        _yimuBudgetIdMeta,
        yimuBudgetId.isAcceptableOrUnknown(
          data['yimu_budget_id']!,
          _yimuBudgetIdMeta,
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
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      periodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_time'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      yimuBudgetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yimu_budget_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;
  final String name;
  final String? categoryId;
  final String type;
  final String periodType;
  final int amount;
  final int? startTime;
  final int? endTime;
  final bool enabled;
  final int? yimuBudgetId;
  final int createdAt;
  final int updatedAt;
  const Budget({
    required this.id,
    required this.name,
    this.categoryId,
    required this.type,
    required this.periodType,
    required this.amount,
    this.startTime,
    this.endTime,
    required this.enabled,
    this.yimuBudgetId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['type'] = Variable<String>(type);
    map['period_type'] = Variable<String>(periodType);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<int>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<int>(endTime);
    }
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || yimuBudgetId != null) {
      map['yimu_budget_id'] = Variable<int>(yimuBudgetId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      name: Value(name),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      type: Value(type),
      periodType: Value(periodType),
      amount: Value(amount),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      enabled: Value(enabled),
      yimuBudgetId: yimuBudgetId == null && nullToAbsent
          ? const Value.absent()
          : Value(yimuBudgetId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      type: serializer.fromJson<String>(json['type']),
      periodType: serializer.fromJson<String>(json['periodType']),
      amount: serializer.fromJson<int>(json['amount']),
      startTime: serializer.fromJson<int?>(json['startTime']),
      endTime: serializer.fromJson<int?>(json['endTime']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      yimuBudgetId: serializer.fromJson<int?>(json['yimuBudgetId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<String?>(categoryId),
      'type': serializer.toJson<String>(type),
      'periodType': serializer.toJson<String>(periodType),
      'amount': serializer.toJson<int>(amount),
      'startTime': serializer.toJson<int?>(startTime),
      'endTime': serializer.toJson<int?>(endTime),
      'enabled': serializer.toJson<bool>(enabled),
      'yimuBudgetId': serializer.toJson<int?>(yimuBudgetId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Budget copyWith({
    String? id,
    String? name,
    Value<String?> categoryId = const Value.absent(),
    String? type,
    String? periodType,
    int? amount,
    Value<int?> startTime = const Value.absent(),
    Value<int?> endTime = const Value.absent(),
    bool? enabled,
    Value<int?> yimuBudgetId = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Budget(
    id: id ?? this.id,
    name: name ?? this.name,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    type: type ?? this.type,
    periodType: periodType ?? this.periodType,
    amount: amount ?? this.amount,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    enabled: enabled ?? this.enabled,
    yimuBudgetId: yimuBudgetId.present ? yimuBudgetId.value : this.yimuBudgetId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      type: data.type.present ? data.type.value : this.type,
      periodType: data.periodType.present
          ? data.periodType.value
          : this.periodType,
      amount: data.amount.present ? data.amount.value : this.amount,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      yimuBudgetId: data.yimuBudgetId.present
          ? data.yimuBudgetId.value
          : this.yimuBudgetId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('periodType: $periodType, ')
          ..write('amount: $amount, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('enabled: $enabled, ')
          ..write('yimuBudgetId: $yimuBudgetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    categoryId,
    type,
    periodType,
    amount,
    startTime,
    endTime,
    enabled,
    yimuBudgetId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.type == this.type &&
          other.periodType == this.periodType &&
          other.amount == this.amount &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.enabled == this.enabled &&
          other.yimuBudgetId == this.yimuBudgetId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> categoryId;
  final Value<String> type;
  final Value<String> periodType;
  final Value<int> amount;
  final Value<int?> startTime;
  final Value<int?> endTime;
  final Value<bool> enabled;
  final Value<int?> yimuBudgetId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.type = const Value.absent(),
    this.periodType = const Value.absent(),
    this.amount = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.enabled = const Value.absent(),
    this.yimuBudgetId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String name,
    this.categoryId = const Value.absent(),
    required String type,
    required String periodType,
    required int amount,
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.enabled = const Value.absent(),
    this.yimuBudgetId = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       periodType = Value(periodType),
       amount = Value(amount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? categoryId,
    Expression<String>? type,
    Expression<String>? periodType,
    Expression<int>? amount,
    Expression<int>? startTime,
    Expression<int>? endTime,
    Expression<bool>? enabled,
    Expression<int>? yimuBudgetId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (type != null) 'type': type,
      if (periodType != null) 'period_type': periodType,
      if (amount != null) 'amount': amount,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (enabled != null) 'enabled': enabled,
      if (yimuBudgetId != null) 'yimu_budget_id': yimuBudgetId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? categoryId,
    Value<String>? type,
    Value<String>? periodType,
    Value<int>? amount,
    Value<int?>? startTime,
    Value<int?>? endTime,
    Value<bool>? enabled,
    Value<int?>? yimuBudgetId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      periodType: periodType ?? this.periodType,
      amount: amount ?? this.amount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      enabled: enabled ?? this.enabled,
      yimuBudgetId: yimuBudgetId ?? this.yimuBudgetId,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (periodType.present) {
      map['period_type'] = Variable<String>(periodType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<int>(endTime.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (yimuBudgetId.present) {
      map['yimu_budget_id'] = Variable<int>(yimuBudgetId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('type: $type, ')
          ..write('periodType: $periodType, ')
          ..write('amount: $amount, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('enabled: $enabled, ')
          ..write('yimuBudgetId: $yimuBudgetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportMappingsTable extends ImportMappings
    with TableInfo<$ImportMappingsTable, ImportMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    provider,
    entityType,
    sourceId,
    targetId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {provider, entityType, sourceId},
  ];
  @override
  ImportMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportMapping(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ImportMappingsTable createAlias(String alias) {
    return $ImportMappingsTable(attachedDatabase, alias);
  }
}

class ImportMapping extends DataClass implements Insertable<ImportMapping> {
  final String id;
  final String provider;
  final String entityType;
  final String sourceId;
  final String targetId;
  final int createdAt;
  final int updatedAt;
  const ImportMapping({
    required this.id,
    required this.provider,
    required this.entityType,
    required this.sourceId,
    required this.targetId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider'] = Variable<String>(provider);
    map['entity_type'] = Variable<String>(entityType);
    map['source_id'] = Variable<String>(sourceId);
    map['target_id'] = Variable<String>(targetId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ImportMappingsCompanion toCompanion(bool nullToAbsent) {
    return ImportMappingsCompanion(
      id: Value(id),
      provider: Value(provider),
      entityType: Value(entityType),
      sourceId: Value(sourceId),
      targetId: Value(targetId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ImportMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportMapping(
      id: serializer.fromJson<String>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      entityType: serializer.fromJson<String>(json['entityType']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      targetId: serializer.fromJson<String>(json['targetId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'provider': serializer.toJson<String>(provider),
      'entityType': serializer.toJson<String>(entityType),
      'sourceId': serializer.toJson<String>(sourceId),
      'targetId': serializer.toJson<String>(targetId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ImportMapping copyWith({
    String? id,
    String? provider,
    String? entityType,
    String? sourceId,
    String? targetId,
    int? createdAt,
    int? updatedAt,
  }) => ImportMapping(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    entityType: entityType ?? this.entityType,
    sourceId: sourceId ?? this.sourceId,
    targetId: targetId ?? this.targetId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ImportMapping copyWithCompanion(ImportMappingsCompanion data) {
    return ImportMapping(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportMapping(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('entityType: $entityType, ')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    provider,
    entityType,
    sourceId,
    targetId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportMapping &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.entityType == this.entityType &&
          other.sourceId == this.sourceId &&
          other.targetId == this.targetId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ImportMappingsCompanion extends UpdateCompanion<ImportMapping> {
  final Value<String> id;
  final Value<String> provider;
  final Value<String> entityType;
  final Value<String> sourceId;
  final Value<String> targetId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ImportMappingsCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.entityType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImportMappingsCompanion.insert({
    required String id,
    required String provider,
    required String entityType,
    required String sourceId,
    required String targetId,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       provider = Value(provider),
       entityType = Value(entityType),
       sourceId = Value(sourceId),
       targetId = Value(targetId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ImportMapping> custom({
    Expression<String>? id,
    Expression<String>? provider,
    Expression<String>? entityType,
    Expression<String>? sourceId,
    Expression<String>? targetId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (entityType != null) 'entity_type': entityType,
      if (sourceId != null) 'source_id': sourceId,
      if (targetId != null) 'target_id': targetId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImportMappingsCompanion copyWith({
    Value<String>? id,
    Value<String>? provider,
    Value<String>? entityType,
    Value<String>? sourceId,
    Value<String>? targetId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ImportMappingsCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      entityType: entityType ?? this.entityType,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
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
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportMappingsCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('entityType: $entityType, ')
          ..write('sourceId: $sourceId, ')
          ..write('targetId: $targetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $YearReportsTable extends YearReports
    with TableInfo<$YearReportsTable, YearReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $YearReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _incomeMeta = const VerificationMeta('income');
  @override
  late final GeneratedColumn<int> income = GeneratedColumn<int>(
    'income',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseMeta = const VerificationMeta(
    'expense',
  );
  @override
  late final GeneratedColumn<int> expense = GeneratedColumn<int>(
    'expense',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adjustNetMeta = const VerificationMeta(
    'adjustNet',
  );
  @override
  late final GeneratedColumn<int> adjustNet = GeneratedColumn<int>(
    'adjust_net',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAssetsMeta = const VerificationMeta(
    'startAssets',
  );
  @override
  late final GeneratedColumn<int> startAssets = GeneratedColumn<int>(
    'start_assets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAssetsMeta = const VerificationMeta(
    'endAssets',
  );
  @override
  late final GeneratedColumn<int> endAssets = GeneratedColumn<int>(
    'end_assets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billCountMeta = const VerificationMeta(
    'billCount',
  );
  @override
  late final GeneratedColumn<int> billCount = GeneratedColumn<int>(
    'bill_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adjustCountMeta = const VerificationMeta(
    'adjustCount',
  );
  @override
  late final GeneratedColumn<int> adjustCount = GeneratedColumn<int>(
    'adjust_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasAssetBaselineMeta = const VerificationMeta(
    'hasAssetBaseline',
  );
  @override
  late final GeneratedColumn<bool> hasAssetBaseline = GeneratedColumn<bool>(
    'has_asset_baseline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_asset_baseline" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceSigMeta = const VerificationMeta(
    'sourceSig',
  );
  @override
  late final GeneratedColumn<String> sourceSig = GeneratedColumn<String>(
    'source_sig',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<int> computedAt = GeneratedColumn<int>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    year,
    income,
    expense,
    adjustNet,
    startAssets,
    endAssets,
    billCount,
    adjustCount,
    hasAssetBaseline,
    sourceSig,
    computedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'year_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<YearReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('income')) {
      context.handle(
        _incomeMeta,
        income.isAcceptableOrUnknown(data['income']!, _incomeMeta),
      );
    } else if (isInserting) {
      context.missing(_incomeMeta);
    }
    if (data.containsKey('expense')) {
      context.handle(
        _expenseMeta,
        expense.isAcceptableOrUnknown(data['expense']!, _expenseMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseMeta);
    }
    if (data.containsKey('adjust_net')) {
      context.handle(
        _adjustNetMeta,
        adjustNet.isAcceptableOrUnknown(data['adjust_net']!, _adjustNetMeta),
      );
    } else if (isInserting) {
      context.missing(_adjustNetMeta);
    }
    if (data.containsKey('start_assets')) {
      context.handle(
        _startAssetsMeta,
        startAssets.isAcceptableOrUnknown(
          data['start_assets']!,
          _startAssetsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startAssetsMeta);
    }
    if (data.containsKey('end_assets')) {
      context.handle(
        _endAssetsMeta,
        endAssets.isAcceptableOrUnknown(data['end_assets']!, _endAssetsMeta),
      );
    } else if (isInserting) {
      context.missing(_endAssetsMeta);
    }
    if (data.containsKey('bill_count')) {
      context.handle(
        _billCountMeta,
        billCount.isAcceptableOrUnknown(data['bill_count']!, _billCountMeta),
      );
    } else if (isInserting) {
      context.missing(_billCountMeta);
    }
    if (data.containsKey('adjust_count')) {
      context.handle(
        _adjustCountMeta,
        adjustCount.isAcceptableOrUnknown(
          data['adjust_count']!,
          _adjustCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_adjustCountMeta);
    }
    if (data.containsKey('has_asset_baseline')) {
      context.handle(
        _hasAssetBaselineMeta,
        hasAssetBaseline.isAcceptableOrUnknown(
          data['has_asset_baseline']!,
          _hasAssetBaselineMeta,
        ),
      );
    }
    if (data.containsKey('source_sig')) {
      context.handle(
        _sourceSigMeta,
        sourceSig.isAcceptableOrUnknown(data['source_sig']!, _sourceSigMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceSigMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {year};
  @override
  YearReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return YearReport(
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      income: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}income'],
      )!,
      expense: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expense'],
      )!,
      adjustNet: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adjust_net'],
      )!,
      startAssets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_assets'],
      )!,
      endAssets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_assets'],
      )!,
      billCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bill_count'],
      )!,
      adjustCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}adjust_count'],
      )!,
      hasAssetBaseline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_asset_baseline'],
      )!,
      sourceSig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_sig'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $YearReportsTable createAlias(String alias) {
    return $YearReportsTable(attachedDatabase, alias);
  }
}

class YearReport extends DataClass implements Insertable<YearReport> {
  /// 公历年（本地时区）
  final int year;

  /// 记录收入（不含调账、不含「不计入收支」账单）
  final int income;

  /// 记录支出（同上口径）
  final int expense;

  /// 调账净额（收入调账 − 支出调账；负值表示手动调低）
  final int adjustNet;

  /// 年初资产（上年 12/31 24:00 = 本年 1/1 00:00 时点；无基准时为 0）
  final int startAssets;

  /// 年末资产
  final int endAssets;

  /// 该年常规记账条数
  final int billCount;

  /// 该年调账次数
  final int adjustCount;

  /// 期初/期末是否都有可用快照基准；false 时资产变动分区降级展示
  final bool hasAssetBaseline;

  /// 重算时的全库账单指纹 `"count:maxUpdatedAt"`，与当前不一致则整年重算
  final String sourceSig;
  final int computedAt;
  const YearReport({
    required this.year,
    required this.income,
    required this.expense,
    required this.adjustNet,
    required this.startAssets,
    required this.endAssets,
    required this.billCount,
    required this.adjustCount,
    required this.hasAssetBaseline,
    required this.sourceSig,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['year'] = Variable<int>(year);
    map['income'] = Variable<int>(income);
    map['expense'] = Variable<int>(expense);
    map['adjust_net'] = Variable<int>(adjustNet);
    map['start_assets'] = Variable<int>(startAssets);
    map['end_assets'] = Variable<int>(endAssets);
    map['bill_count'] = Variable<int>(billCount);
    map['adjust_count'] = Variable<int>(adjustCount);
    map['has_asset_baseline'] = Variable<bool>(hasAssetBaseline);
    map['source_sig'] = Variable<String>(sourceSig);
    map['computed_at'] = Variable<int>(computedAt);
    return map;
  }

  YearReportsCompanion toCompanion(bool nullToAbsent) {
    return YearReportsCompanion(
      year: Value(year),
      income: Value(income),
      expense: Value(expense),
      adjustNet: Value(adjustNet),
      startAssets: Value(startAssets),
      endAssets: Value(endAssets),
      billCount: Value(billCount),
      adjustCount: Value(adjustCount),
      hasAssetBaseline: Value(hasAssetBaseline),
      sourceSig: Value(sourceSig),
      computedAt: Value(computedAt),
    );
  }

  factory YearReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return YearReport(
      year: serializer.fromJson<int>(json['year']),
      income: serializer.fromJson<int>(json['income']),
      expense: serializer.fromJson<int>(json['expense']),
      adjustNet: serializer.fromJson<int>(json['adjustNet']),
      startAssets: serializer.fromJson<int>(json['startAssets']),
      endAssets: serializer.fromJson<int>(json['endAssets']),
      billCount: serializer.fromJson<int>(json['billCount']),
      adjustCount: serializer.fromJson<int>(json['adjustCount']),
      hasAssetBaseline: serializer.fromJson<bool>(json['hasAssetBaseline']),
      sourceSig: serializer.fromJson<String>(json['sourceSig']),
      computedAt: serializer.fromJson<int>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'year': serializer.toJson<int>(year),
      'income': serializer.toJson<int>(income),
      'expense': serializer.toJson<int>(expense),
      'adjustNet': serializer.toJson<int>(adjustNet),
      'startAssets': serializer.toJson<int>(startAssets),
      'endAssets': serializer.toJson<int>(endAssets),
      'billCount': serializer.toJson<int>(billCount),
      'adjustCount': serializer.toJson<int>(adjustCount),
      'hasAssetBaseline': serializer.toJson<bool>(hasAssetBaseline),
      'sourceSig': serializer.toJson<String>(sourceSig),
      'computedAt': serializer.toJson<int>(computedAt),
    };
  }

  YearReport copyWith({
    int? year,
    int? income,
    int? expense,
    int? adjustNet,
    int? startAssets,
    int? endAssets,
    int? billCount,
    int? adjustCount,
    bool? hasAssetBaseline,
    String? sourceSig,
    int? computedAt,
  }) => YearReport(
    year: year ?? this.year,
    income: income ?? this.income,
    expense: expense ?? this.expense,
    adjustNet: adjustNet ?? this.adjustNet,
    startAssets: startAssets ?? this.startAssets,
    endAssets: endAssets ?? this.endAssets,
    billCount: billCount ?? this.billCount,
    adjustCount: adjustCount ?? this.adjustCount,
    hasAssetBaseline: hasAssetBaseline ?? this.hasAssetBaseline,
    sourceSig: sourceSig ?? this.sourceSig,
    computedAt: computedAt ?? this.computedAt,
  );
  YearReport copyWithCompanion(YearReportsCompanion data) {
    return YearReport(
      year: data.year.present ? data.year.value : this.year,
      income: data.income.present ? data.income.value : this.income,
      expense: data.expense.present ? data.expense.value : this.expense,
      adjustNet: data.adjustNet.present ? data.adjustNet.value : this.adjustNet,
      startAssets: data.startAssets.present
          ? data.startAssets.value
          : this.startAssets,
      endAssets: data.endAssets.present ? data.endAssets.value : this.endAssets,
      billCount: data.billCount.present ? data.billCount.value : this.billCount,
      adjustCount: data.adjustCount.present
          ? data.adjustCount.value
          : this.adjustCount,
      hasAssetBaseline: data.hasAssetBaseline.present
          ? data.hasAssetBaseline.value
          : this.hasAssetBaseline,
      sourceSig: data.sourceSig.present ? data.sourceSig.value : this.sourceSig,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('YearReport(')
          ..write('year: $year, ')
          ..write('income: $income, ')
          ..write('expense: $expense, ')
          ..write('adjustNet: $adjustNet, ')
          ..write('startAssets: $startAssets, ')
          ..write('endAssets: $endAssets, ')
          ..write('billCount: $billCount, ')
          ..write('adjustCount: $adjustCount, ')
          ..write('hasAssetBaseline: $hasAssetBaseline, ')
          ..write('sourceSig: $sourceSig, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    year,
    income,
    expense,
    adjustNet,
    startAssets,
    endAssets,
    billCount,
    adjustCount,
    hasAssetBaseline,
    sourceSig,
    computedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is YearReport &&
          other.year == this.year &&
          other.income == this.income &&
          other.expense == this.expense &&
          other.adjustNet == this.adjustNet &&
          other.startAssets == this.startAssets &&
          other.endAssets == this.endAssets &&
          other.billCount == this.billCount &&
          other.adjustCount == this.adjustCount &&
          other.hasAssetBaseline == this.hasAssetBaseline &&
          other.sourceSig == this.sourceSig &&
          other.computedAt == this.computedAt);
}

class YearReportsCompanion extends UpdateCompanion<YearReport> {
  final Value<int> year;
  final Value<int> income;
  final Value<int> expense;
  final Value<int> adjustNet;
  final Value<int> startAssets;
  final Value<int> endAssets;
  final Value<int> billCount;
  final Value<int> adjustCount;
  final Value<bool> hasAssetBaseline;
  final Value<String> sourceSig;
  final Value<int> computedAt;
  const YearReportsCompanion({
    this.year = const Value.absent(),
    this.income = const Value.absent(),
    this.expense = const Value.absent(),
    this.adjustNet = const Value.absent(),
    this.startAssets = const Value.absent(),
    this.endAssets = const Value.absent(),
    this.billCount = const Value.absent(),
    this.adjustCount = const Value.absent(),
    this.hasAssetBaseline = const Value.absent(),
    this.sourceSig = const Value.absent(),
    this.computedAt = const Value.absent(),
  });
  YearReportsCompanion.insert({
    this.year = const Value.absent(),
    required int income,
    required int expense,
    required int adjustNet,
    required int startAssets,
    required int endAssets,
    required int billCount,
    required int adjustCount,
    this.hasAssetBaseline = const Value.absent(),
    required String sourceSig,
    required int computedAt,
  }) : income = Value(income),
       expense = Value(expense),
       adjustNet = Value(adjustNet),
       startAssets = Value(startAssets),
       endAssets = Value(endAssets),
       billCount = Value(billCount),
       adjustCount = Value(adjustCount),
       sourceSig = Value(sourceSig),
       computedAt = Value(computedAt);
  static Insertable<YearReport> custom({
    Expression<int>? year,
    Expression<int>? income,
    Expression<int>? expense,
    Expression<int>? adjustNet,
    Expression<int>? startAssets,
    Expression<int>? endAssets,
    Expression<int>? billCount,
    Expression<int>? adjustCount,
    Expression<bool>? hasAssetBaseline,
    Expression<String>? sourceSig,
    Expression<int>? computedAt,
  }) {
    return RawValuesInsertable({
      if (year != null) 'year': year,
      if (income != null) 'income': income,
      if (expense != null) 'expense': expense,
      if (adjustNet != null) 'adjust_net': adjustNet,
      if (startAssets != null) 'start_assets': startAssets,
      if (endAssets != null) 'end_assets': endAssets,
      if (billCount != null) 'bill_count': billCount,
      if (adjustCount != null) 'adjust_count': adjustCount,
      if (hasAssetBaseline != null) 'has_asset_baseline': hasAssetBaseline,
      if (sourceSig != null) 'source_sig': sourceSig,
      if (computedAt != null) 'computed_at': computedAt,
    });
  }

  YearReportsCompanion copyWith({
    Value<int>? year,
    Value<int>? income,
    Value<int>? expense,
    Value<int>? adjustNet,
    Value<int>? startAssets,
    Value<int>? endAssets,
    Value<int>? billCount,
    Value<int>? adjustCount,
    Value<bool>? hasAssetBaseline,
    Value<String>? sourceSig,
    Value<int>? computedAt,
  }) {
    return YearReportsCompanion(
      year: year ?? this.year,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      adjustNet: adjustNet ?? this.adjustNet,
      startAssets: startAssets ?? this.startAssets,
      endAssets: endAssets ?? this.endAssets,
      billCount: billCount ?? this.billCount,
      adjustCount: adjustCount ?? this.adjustCount,
      hasAssetBaseline: hasAssetBaseline ?? this.hasAssetBaseline,
      sourceSig: sourceSig ?? this.sourceSig,
      computedAt: computedAt ?? this.computedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (income.present) {
      map['income'] = Variable<int>(income.value);
    }
    if (expense.present) {
      map['expense'] = Variable<int>(expense.value);
    }
    if (adjustNet.present) {
      map['adjust_net'] = Variable<int>(adjustNet.value);
    }
    if (startAssets.present) {
      map['start_assets'] = Variable<int>(startAssets.value);
    }
    if (endAssets.present) {
      map['end_assets'] = Variable<int>(endAssets.value);
    }
    if (billCount.present) {
      map['bill_count'] = Variable<int>(billCount.value);
    }
    if (adjustCount.present) {
      map['adjust_count'] = Variable<int>(adjustCount.value);
    }
    if (hasAssetBaseline.present) {
      map['has_asset_baseline'] = Variable<bool>(hasAssetBaseline.value);
    }
    if (sourceSig.present) {
      map['source_sig'] = Variable<String>(sourceSig.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<int>(computedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('YearReportsCompanion(')
          ..write('year: $year, ')
          ..write('income: $income, ')
          ..write('expense: $expense, ')
          ..write('adjustNet: $adjustNet, ')
          ..write('startAssets: $startAssets, ')
          ..write('endAssets: $endAssets, ')
          ..write('billCount: $billCount, ')
          ..write('adjustCount: $adjustCount, ')
          ..write('hasAssetBaseline: $hasAssetBaseline, ')
          ..write('sourceSig: $sourceSig, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TagGroupsTable tagGroups = $TagGroupsTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $BillTagsTable billTags = $BillTagsTable(this);
  late final $BalanceSnapshotsTable balanceSnapshots = $BalanceSnapshotsTable(
    this,
  );
  late final $TransfersTable transfers = $TransfersTable(this);
  late final $LendsTable lends = $LendsTable(this);
  late final $RefundsTable refunds = $RefundsTable(this);
  late final $ReimbursementsTable reimbursements = $ReimbursementsTable(this);
  late final $InstalmentsTable instalments = $InstalmentsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $ImportMappingsTable importMappings = $ImportMappingsTable(this);
  late final $YearReportsTable yearReports = $YearReportsTable(this);
  late final Index idxAccountsCategory = Index(
    'idx_accounts_category',
    'CREATE INDEX idx_accounts_category ON accounts (category, enabled)',
  );
  late final Index idxCategoriesParent = Index(
    'idx_categories_parent',
    'CREATE INDEX idx_categories_parent ON categories (parent_id)',
  );
  late final Index idxBillsTime = Index(
    'idx_bills_time',
    'CREATE INDEX idx_bills_time ON bills (time)',
  );
  late final Index idxBillsAccount = Index(
    'idx_bills_account',
    'CREATE INDEX idx_bills_account ON bills (account_id)',
  );
  late final Index idxBillsCategory = Index(
    'idx_bills_category',
    'CREATE INDEX idx_bills_category ON bills (category_id)',
  );
  late final Index idxBillTagsTag = Index(
    'idx_bill_tags_tag',
    'CREATE INDEX idx_bill_tags_tag ON bill_tags (tag_id)',
  );
  late final Index idxSnapshotsAccount = Index(
    'idx_snapshots_account',
    'CREATE INDEX idx_snapshots_account ON balance_snapshots (account_id, timestamp)',
  );
  late final Index idxTransfersBill = Index(
    'idx_transfers_bill',
    'CREATE INDEX idx_transfers_bill ON transfers (bill_id)',
  );
  late final Index idxMappingsProvider = Index(
    'idx_mappings_provider',
    'CREATE INDEX idx_mappings_provider ON import_mappings (provider, entity_type)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    categories,
    tags,
    tagGroups,
    bills,
    billTags,
    balanceSnapshots,
    transfers,
    lends,
    refunds,
    reimbursements,
    instalments,
    budgets,
    importMappings,
    yearReports,
    idxAccountsCategory,
    idxCategoriesParent,
    idxBillsTime,
    idxBillsAccount,
    idxBillsCategory,
    idxBillTagsTag,
    idxSnapshotsAccount,
    idxTransfersBill,
    idxMappingsProvider,
  ];
}

typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String name,
      required String category,
      required String type,
      Value<String?> icon,
      Value<String?> color,
      Value<int> initialBalance,
      Value<int> currentBalance,
      Value<String> currency,
      Value<bool> includeInAssets,
      Value<int?> creditLimit,
      Value<String?> cardCode,
      Value<int?> statementDate,
      Value<int?> repaymentDate,
      Value<String?> remark,
      Value<bool> enabled,
      Value<int?> yimuAssetId,
      Value<int?> zhouhuAccountId,
      Value<int?> qianjiAssetId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<String> type,
      Value<String?> icon,
      Value<String?> color,
      Value<int> initialBalance,
      Value<int> currentBalance,
      Value<String> currency,
      Value<bool> includeInAssets,
      Value<int?> creditLimit,
      Value<String?> cardCode,
      Value<int?> statementDate,
      Value<int?> repaymentDate,
      Value<String?> remark,
      Value<bool> enabled,
      Value<int?> yimuAssetId,
      Value<int?> zhouhuAccountId,
      Value<int?> qianjiAssetId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInAssets => $composableBuilder(
    column: $table.includeInAssets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardCode => $composableBuilder(
    column: $table.cardCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statementDate => $composableBuilder(
    column: $table.statementDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repaymentDate => $composableBuilder(
    column: $table.repaymentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yimuAssetId => $composableBuilder(
    column: $table.yimuAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get zhouhuAccountId => $composableBuilder(
    column: $table.zhouhuAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qianjiAssetId => $composableBuilder(
    column: $table.qianjiAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInAssets => $composableBuilder(
    column: $table.includeInAssets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardCode => $composableBuilder(
    column: $table.cardCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statementDate => $composableBuilder(
    column: $table.statementDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repaymentDate => $composableBuilder(
    column: $table.repaymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remark => $composableBuilder(
    column: $table.remark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yimuAssetId => $composableBuilder(
    column: $table.yimuAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get zhouhuAccountId => $composableBuilder(
    column: $table.zhouhuAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qianjiAssetId => $composableBuilder(
    column: $table.qianjiAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get initialBalance => $composableBuilder(
    column: $table.initialBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<bool> get includeInAssets => $composableBuilder(
    column: $table.includeInAssets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cardCode =>
      $composableBuilder(column: $table.cardCode, builder: (column) => column);

  GeneratedColumn<int> get statementDate => $composableBuilder(
    column: $table.statementDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repaymentDate => $composableBuilder(
    column: $table.repaymentDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remark =>
      $composableBuilder(column: $table.remark, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get yimuAssetId => $composableBuilder(
    column: $table.yimuAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get zhouhuAccountId => $composableBuilder(
    column: $table.zhouhuAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get qianjiAssetId => $composableBuilder(
    column: $table.qianjiAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
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
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> initialBalance = const Value.absent(),
                Value<int> currentBalance = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> includeInAssets = const Value.absent(),
                Value<int?> creditLimit = const Value.absent(),
                Value<String?> cardCode = const Value.absent(),
                Value<int?> statementDate = const Value.absent(),
                Value<int?> repaymentDate = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> yimuAssetId = const Value.absent(),
                Value<int?> zhouhuAccountId = const Value.absent(),
                Value<int?> qianjiAssetId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                category: category,
                type: type,
                icon: icon,
                color: color,
                initialBalance: initialBalance,
                currentBalance: currentBalance,
                currency: currency,
                includeInAssets: includeInAssets,
                creditLimit: creditLimit,
                cardCode: cardCode,
                statementDate: statementDate,
                repaymentDate: repaymentDate,
                remark: remark,
                enabled: enabled,
                yimuAssetId: yimuAssetId,
                zhouhuAccountId: zhouhuAccountId,
                qianjiAssetId: qianjiAssetId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required String type,
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int> initialBalance = const Value.absent(),
                Value<int> currentBalance = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<bool> includeInAssets = const Value.absent(),
                Value<int?> creditLimit = const Value.absent(),
                Value<String?> cardCode = const Value.absent(),
                Value<int?> statementDate = const Value.absent(),
                Value<int?> repaymentDate = const Value.absent(),
                Value<String?> remark = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> yimuAssetId = const Value.absent(),
                Value<int?> zhouhuAccountId = const Value.absent(),
                Value<int?> qianjiAssetId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                category: category,
                type: type,
                icon: icon,
                color: color,
                initialBalance: initialBalance,
                currentBalance: currentBalance,
                currency: currency,
                includeInAssets: includeInAssets,
                creditLimit: creditLimit,
                cardCode: cardCode,
                statementDate: statementDate,
                repaymentDate: repaymentDate,
                remark: remark,
                enabled: enabled,
                yimuAssetId: yimuAssetId,
                zhouhuAccountId: zhouhuAccountId,
                qianjiAssetId: qianjiAssetId,
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

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String type,
      required String name,
      Value<String?> icon,
      Value<String?> color,
      Value<String?> parentId,
      Value<bool> customName,
      Value<bool> defaultSelect,
      Value<int> sort,
      Value<String?> seedKey,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> name,
      Value<String?> icon,
      Value<String?> color,
      Value<String?> parentId,
      Value<bool> customName,
      Value<bool> defaultSelect,
      Value<int> sort,
      Value<String?> seedKey,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get defaultSelect => $composableBuilder(
    column: $table.defaultSelect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get defaultSelect => $composableBuilder(
    column: $table.defaultSelect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seedKey => $composableBuilder(
    column: $table.seedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<bool> get customName => $composableBuilder(
    column: $table.customName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get defaultSelect => $composableBuilder(
    column: $table.defaultSelect,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<String> get seedKey =>
      $composableBuilder(column: $table.seedKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> customName = const Value.absent(),
                Value<bool> defaultSelect = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<String?> seedKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                type: type,
                name: name,
                icon: icon,
                color: color,
                parentId: parentId,
                customName: customName,
                defaultSelect: defaultSelect,
                sort: sort,
                seedKey: seedKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> customName = const Value.absent(),
                Value<bool> defaultSelect = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<String?> seedKey = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                type: type,
                name: name,
                icon: icon,
                color: color,
                parentId: parentId,
                customName: customName,
                defaultSelect: defaultSelect,
                sort: sort,
                seedKey: seedKey,
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

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      Value<String?> color,
      Value<String?> groupId,
      Value<String?> preferCurrency,
      Value<int> sort,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> color,
      Value<String?> groupId,
      Value<String?> preferCurrency,
      Value<int> sort,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferCurrency => $composableBuilder(
    column: $table.preferCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferCurrency => $composableBuilder(
    column: $table.preferCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
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

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get preferCurrency => $composableBuilder(
    column: $table.preferCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> preferCurrency = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                groupId: groupId,
                preferCurrency: preferCurrency,
                sort: sort,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> color = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<String?> preferCurrency = const Value.absent(),
                Value<int> sort = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                groupId: groupId,
                preferCurrency: preferCurrency,
                sort: sort,
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

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$TagGroupsTableCreateCompanionBuilder =
    TagGroupsCompanion Function({
      required String id,
      required String name,
      Value<int> sort,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$TagGroupsTableUpdateCompanionBuilder =
    TagGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> sort,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$TagGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $TagGroupsTable> {
  $$TagGroupsTableFilterComposer({
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

  ColumnFilters<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $TagGroupsTable> {
  $$TagGroupsTableOrderingComposer({
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

  ColumnOrderings<int> get sort => $composableBuilder(
    column: $table.sort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagGroupsTable> {
  $$TagGroupsTableAnnotationComposer({
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

  GeneratedColumn<int> get sort =>
      $composableBuilder(column: $table.sort, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TagGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagGroupsTable,
          TagGroup,
          $$TagGroupsTableFilterComposer,
          $$TagGroupsTableOrderingComposer,
          $$TagGroupsTableAnnotationComposer,
          $$TagGroupsTableCreateCompanionBuilder,
          $$TagGroupsTableUpdateCompanionBuilder,
          (TagGroup, BaseReferences<_$AppDatabase, $TagGroupsTable, TagGroup>),
          TagGroup,
          PrefetchHooks Function()
        > {
  $$TagGroupsTableTableManager(_$AppDatabase db, $TagGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sort = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagGroupsCompanion(
                id: id,
                name: name,
                sort: sort,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> sort = const Value.absent(),
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TagGroupsCompanion.insert(
                id: id,
                name: name,
                sort: sort,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagGroupsTable,
      TagGroup,
      $$TagGroupsTableFilterComposer,
      $$TagGroupsTableOrderingComposer,
      $$TagGroupsTableAnnotationComposer,
      $$TagGroupsTableCreateCompanionBuilder,
      $$TagGroupsTableUpdateCompanionBuilder,
      (TagGroup, BaseReferences<_$AppDatabase, $TagGroupsTable, TagGroup>),
      TagGroup,
      PrefetchHooks Function()
    >;
typedef $$BillsTableCreateCompanionBuilder =
    BillsCompanion Function({
      required String id,
      required String type,
      required String categoryId,
      required int amount,
      Value<String?> accountId,
      Value<String?> incomeAccountId,
      required int time,
      Value<String?> comment,
      Value<double?> locationLat,
      Value<double?> locationLng,
      Value<String?> images,
      Value<String?> currencyCode,
      Value<int?> currencyAmount,
      Value<String?> baseCurrency,
      Value<String?> extra,
      Value<String?> creatorId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$BillsTableUpdateCompanionBuilder =
    BillsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> categoryId,
      Value<int> amount,
      Value<String?> accountId,
      Value<String?> incomeAccountId,
      Value<int> time,
      Value<String?> comment,
      Value<double?> locationLat,
      Value<double?> locationLng,
      Value<String?> images,
      Value<String?> currencyCode,
      Value<int?> currencyAmount,
      Value<String?> baseCurrency,
      Value<String?> extra,
      Value<String?> creatorId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$BillsTableFilterComposer extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incomeAccountId => $composableBuilder(
    column: $table.incomeAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currencyAmount => $composableBuilder(
    column: $table.currencyAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BillsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incomeAccountId => $composableBuilder(
    column: $table.incomeAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get images => $composableBuilder(
    column: $table.images,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currencyAmount => $composableBuilder(
    column: $table.currencyAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extra => $composableBuilder(
    column: $table.extra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableAnnotationComposer({
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

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get incomeAccountId => $composableBuilder(
    column: $table.incomeAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<double> get locationLat => $composableBuilder(
    column: $table.locationLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get locationLng => $composableBuilder(
    column: $table.locationLng,
    builder: (column) => column,
  );

  GeneratedColumn<String> get images =>
      $composableBuilder(column: $table.images, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currencyAmount => $composableBuilder(
    column: $table.currencyAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extra =>
      $composableBuilder(column: $table.extra, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillsTable,
          Bill,
          $$BillsTableFilterComposer,
          $$BillsTableOrderingComposer,
          $$BillsTableAnnotationComposer,
          $$BillsTableCreateCompanionBuilder,
          $$BillsTableUpdateCompanionBuilder,
          (Bill, BaseReferences<_$AppDatabase, $BillsTable, Bill>),
          Bill,
          PrefetchHooks Function()
        > {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> incomeAccountId = const Value.absent(),
                Value<int> time = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<double?> locationLat = const Value.absent(),
                Value<double?> locationLng = const Value.absent(),
                Value<String?> images = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<int?> currencyAmount = const Value.absent(),
                Value<String?> baseCurrency = const Value.absent(),
                Value<String?> extra = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion(
                id: id,
                type: type,
                categoryId: categoryId,
                amount: amount,
                accountId: accountId,
                incomeAccountId: incomeAccountId,
                time: time,
                comment: comment,
                locationLat: locationLat,
                locationLng: locationLng,
                images: images,
                currencyCode: currencyCode,
                currencyAmount: currencyAmount,
                baseCurrency: baseCurrency,
                extra: extra,
                creatorId: creatorId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String categoryId,
                required int amount,
                Value<String?> accountId = const Value.absent(),
                Value<String?> incomeAccountId = const Value.absent(),
                required int time,
                Value<String?> comment = const Value.absent(),
                Value<double?> locationLat = const Value.absent(),
                Value<double?> locationLng = const Value.absent(),
                Value<String?> images = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<int?> currencyAmount = const Value.absent(),
                Value<String?> baseCurrency = const Value.absent(),
                Value<String?> extra = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion.insert(
                id: id,
                type: type,
                categoryId: categoryId,
                amount: amount,
                accountId: accountId,
                incomeAccountId: incomeAccountId,
                time: time,
                comment: comment,
                locationLat: locationLat,
                locationLng: locationLng,
                images: images,
                currencyCode: currencyCode,
                currencyAmount: currencyAmount,
                baseCurrency: baseCurrency,
                extra: extra,
                creatorId: creatorId,
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

typedef $$BillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillsTable,
      Bill,
      $$BillsTableFilterComposer,
      $$BillsTableOrderingComposer,
      $$BillsTableAnnotationComposer,
      $$BillsTableCreateCompanionBuilder,
      $$BillsTableUpdateCompanionBuilder,
      (Bill, BaseReferences<_$AppDatabase, $BillsTable, Bill>),
      Bill,
      PrefetchHooks Function()
    >;
typedef $$BillTagsTableCreateCompanionBuilder =
    BillTagsCompanion Function({
      required String billId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$BillTagsTableUpdateCompanionBuilder =
    BillTagsCompanion Function({
      Value<String> billId,
      Value<String> tagId,
      Value<int> rowid,
    });

class $$BillTagsTableFilterComposer
    extends Composer<_$AppDatabase, $BillTagsTable> {
  $$BillTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BillTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillTagsTable> {
  $$BillTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BillTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillTagsTable> {
  $$BillTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get billId =>
      $composableBuilder(column: $table.billId, builder: (column) => column);

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$BillTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillTagsTable,
          BillTag,
          $$BillTagsTableFilterComposer,
          $$BillTagsTableOrderingComposer,
          $$BillTagsTableAnnotationComposer,
          $$BillTagsTableCreateCompanionBuilder,
          $$BillTagsTableUpdateCompanionBuilder,
          (BillTag, BaseReferences<_$AppDatabase, $BillTagsTable, BillTag>),
          BillTag,
          PrefetchHooks Function()
        > {
  $$BillTagsTableTableManager(_$AppDatabase db, $BillTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> billId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  BillTagsCompanion(billId: billId, tagId: tagId, rowid: rowid),
          createCompanionCallback:
              ({
                required String billId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => BillTagsCompanion.insert(
                billId: billId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BillTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillTagsTable,
      BillTag,
      $$BillTagsTableFilterComposer,
      $$BillTagsTableOrderingComposer,
      $$BillTagsTableAnnotationComposer,
      $$BillTagsTableCreateCompanionBuilder,
      $$BillTagsTableUpdateCompanionBuilder,
      (BillTag, BaseReferences<_$AppDatabase, $BillTagsTable, BillTag>),
      BillTag,
      PrefetchHooks Function()
    >;
typedef $$BalanceSnapshotsTableCreateCompanionBuilder =
    BalanceSnapshotsCompanion Function({
      required String id,
      required String accountId,
      required int balance,
      required int timestamp,
      Value<String?> note,
      Value<bool> isValid,
      Value<String?> billId,
      required int type,
      Value<int?> yimuAssetHistoryId,
      Value<int> rowid,
    });
typedef $$BalanceSnapshotsTableUpdateCompanionBuilder =
    BalanceSnapshotsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<int> balance,
      Value<int> timestamp,
      Value<String?> note,
      Value<bool> isValid,
      Value<String?> billId,
      Value<int> type,
      Value<int?> yimuAssetHistoryId,
      Value<int> rowid,
    });

class $$BalanceSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableFilterComposer({
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

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isValid => $composableBuilder(
    column: $table.isValid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yimuAssetHistoryId => $composableBuilder(
    column: $table.yimuAssetHistoryId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BalanceSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableOrderingComposer({
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

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isValid => $composableBuilder(
    column: $table.isValid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yimuAssetHistoryId => $composableBuilder(
    column: $table.yimuAssetHistoryId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BalanceSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BalanceSnapshotsTable> {
  $$BalanceSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isValid =>
      $composableBuilder(column: $table.isValid, builder: (column) => column);

  GeneratedColumn<String> get billId =>
      $composableBuilder(column: $table.billId, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get yimuAssetHistoryId => $composableBuilder(
    column: $table.yimuAssetHistoryId,
    builder: (column) => column,
  );
}

class $$BalanceSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BalanceSnapshotsTable,
          BalanceSnapshot,
          $$BalanceSnapshotsTableFilterComposer,
          $$BalanceSnapshotsTableOrderingComposer,
          $$BalanceSnapshotsTableAnnotationComposer,
          $$BalanceSnapshotsTableCreateCompanionBuilder,
          $$BalanceSnapshotsTableUpdateCompanionBuilder,
          (
            BalanceSnapshot,
            BaseReferences<
              _$AppDatabase,
              $BalanceSnapshotsTable,
              BalanceSnapshot
            >,
          ),
          BalanceSnapshot,
          PrefetchHooks Function()
        > {
  $$BalanceSnapshotsTableTableManager(
    _$AppDatabase db,
    $BalanceSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BalanceSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BalanceSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BalanceSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> balance = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isValid = const Value.absent(),
                Value<String?> billId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int?> yimuAssetHistoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceSnapshotsCompanion(
                id: id,
                accountId: accountId,
                balance: balance,
                timestamp: timestamp,
                note: note,
                isValid: isValid,
                billId: billId,
                type: type,
                yimuAssetHistoryId: yimuAssetHistoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required int balance,
                required int timestamp,
                Value<String?> note = const Value.absent(),
                Value<bool> isValid = const Value.absent(),
                Value<String?> billId = const Value.absent(),
                required int type,
                Value<int?> yimuAssetHistoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BalanceSnapshotsCompanion.insert(
                id: id,
                accountId: accountId,
                balance: balance,
                timestamp: timestamp,
                note: note,
                isValid: isValid,
                billId: billId,
                type: type,
                yimuAssetHistoryId: yimuAssetHistoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BalanceSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BalanceSnapshotsTable,
      BalanceSnapshot,
      $$BalanceSnapshotsTableFilterComposer,
      $$BalanceSnapshotsTableOrderingComposer,
      $$BalanceSnapshotsTableAnnotationComposer,
      $$BalanceSnapshotsTableCreateCompanionBuilder,
      $$BalanceSnapshotsTableUpdateCompanionBuilder,
      (
        BalanceSnapshot,
        BaseReferences<_$AppDatabase, $BalanceSnapshotsTable, BalanceSnapshot>,
      ),
      BalanceSnapshot,
      PrefetchHooks Function()
    >;
typedef $$TransfersTableCreateCompanionBuilder =
    TransfersCompanion Function({
      required String id,
      required String billId,
      required String fromAccountId,
      required String toAccountId,
      required int amount,
      Value<int?> toAmount,
      Value<int> fee,
      required int time,
      Value<String?> comment,
      Value<int?> yimuTransferId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$TransfersTableUpdateCompanionBuilder =
    TransfersCompanion Function({
      Value<String> id,
      Value<String> billId,
      Value<String> fromAccountId,
      Value<String> toAccountId,
      Value<int> amount,
      Value<int?> toAmount,
      Value<int> fee,
      Value<int> time,
      Value<String?> comment,
      Value<int?> yimuTransferId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$TransfersTableFilterComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
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

  ColumnFilters<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toAmount => $composableBuilder(
    column: $table.toAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fee => $composableBuilder(
    column: $table.fee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yimuTransferId => $composableBuilder(
    column: $table.yimuTransferId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
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

  ColumnOrderings<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAmount => $composableBuilder(
    column: $table.toAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fee => $composableBuilder(
    column: $table.fee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yimuTransferId => $composableBuilder(
    column: $table.yimuTransferId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get billId =>
      $composableBuilder(column: $table.billId, builder: (column) => column);

  GeneratedColumn<String> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get toAmount =>
      $composableBuilder(column: $table.toAmount, builder: (column) => column);

  GeneratedColumn<int> get fee =>
      $composableBuilder(column: $table.fee, builder: (column) => column);

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<int> get yimuTransferId => $composableBuilder(
    column: $table.yimuTransferId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransfersTable,
          Transfer,
          $$TransfersTableFilterComposer,
          $$TransfersTableOrderingComposer,
          $$TransfersTableAnnotationComposer,
          $$TransfersTableCreateCompanionBuilder,
          $$TransfersTableUpdateCompanionBuilder,
          (Transfer, BaseReferences<_$AppDatabase, $TransfersTable, Transfer>),
          Transfer,
          PrefetchHooks Function()
        > {
  $$TransfersTableTableManager(_$AppDatabase db, $TransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<String> fromAccountId = const Value.absent(),
                Value<String> toAccountId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int?> toAmount = const Value.absent(),
                Value<int> fee = const Value.absent(),
                Value<int> time = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int?> yimuTransferId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion(
                id: id,
                billId: billId,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                amount: amount,
                toAmount: toAmount,
                fee: fee,
                time: time,
                comment: comment,
                yimuTransferId: yimuTransferId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String billId,
                required String fromAccountId,
                required String toAccountId,
                required int amount,
                Value<int?> toAmount = const Value.absent(),
                Value<int> fee = const Value.absent(),
                required int time,
                Value<String?> comment = const Value.absent(),
                Value<int?> yimuTransferId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion.insert(
                id: id,
                billId: billId,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                amount: amount,
                toAmount: toAmount,
                fee: fee,
                time: time,
                comment: comment,
                yimuTransferId: yimuTransferId,
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

typedef $$TransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransfersTable,
      Transfer,
      $$TransfersTableFilterComposer,
      $$TransfersTableOrderingComposer,
      $$TransfersTableAnnotationComposer,
      $$TransfersTableCreateCompanionBuilder,
      $$TransfersTableUpdateCompanionBuilder,
      (Transfer, BaseReferences<_$AppDatabase, $TransfersTable, Transfer>),
      Transfer,
      PrefetchHooks Function()
    >;
typedef $$LendsTableCreateCompanionBuilder =
    LendsCompanion Function({
      required String id,
      required String type,
      required String accountId,
      Value<String?> repaymentAccountId,
      required int amount,
      Value<int> interest,
      Value<int?> originalAmount,
      Value<String?> billId,
      required int time,
      Value<String?> comment,
      Value<int?> yimuLendId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$LendsTableUpdateCompanionBuilder =
    LendsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> accountId,
      Value<String?> repaymentAccountId,
      Value<int> amount,
      Value<int> interest,
      Value<int?> originalAmount,
      Value<String?> billId,
      Value<int> time,
      Value<String?> comment,
      Value<int?> yimuLendId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$LendsTableFilterComposer extends Composer<_$AppDatabase, $LendsTable> {
  $$LendsTableFilterComposer({
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

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repaymentAccountId => $composableBuilder(
    column: $table.repaymentAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get interest => $composableBuilder(
    column: $table.interest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yimuLendId => $composableBuilder(
    column: $table.yimuLendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LendsTableOrderingComposer
    extends Composer<_$AppDatabase, $LendsTable> {
  $$LendsTableOrderingComposer({
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

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repaymentAccountId => $composableBuilder(
    column: $table.repaymentAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get interest => $composableBuilder(
    column: $table.interest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yimuLendId => $composableBuilder(
    column: $table.yimuLendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LendsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LendsTable> {
  $$LendsTableAnnotationComposer({
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

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get repaymentAccountId => $composableBuilder(
    column: $table.repaymentAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get interest =>
      $composableBuilder(column: $table.interest, builder: (column) => column);

  GeneratedColumn<int> get originalAmount => $composableBuilder(
    column: $table.originalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get billId =>
      $composableBuilder(column: $table.billId, builder: (column) => column);

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<int> get yimuLendId => $composableBuilder(
    column: $table.yimuLendId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LendsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LendsTable,
          Lend,
          $$LendsTableFilterComposer,
          $$LendsTableOrderingComposer,
          $$LendsTableAnnotationComposer,
          $$LendsTableCreateCompanionBuilder,
          $$LendsTableUpdateCompanionBuilder,
          (Lend, BaseReferences<_$AppDatabase, $LendsTable, Lend>),
          Lend,
          PrefetchHooks Function()
        > {
  $$LendsTableTableManager(_$AppDatabase db, $LendsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LendsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LendsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LendsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> repaymentAccountId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> interest = const Value.absent(),
                Value<int?> originalAmount = const Value.absent(),
                Value<String?> billId = const Value.absent(),
                Value<int> time = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int?> yimuLendId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LendsCompanion(
                id: id,
                type: type,
                accountId: accountId,
                repaymentAccountId: repaymentAccountId,
                amount: amount,
                interest: interest,
                originalAmount: originalAmount,
                billId: billId,
                time: time,
                comment: comment,
                yimuLendId: yimuLendId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String accountId,
                Value<String?> repaymentAccountId = const Value.absent(),
                required int amount,
                Value<int> interest = const Value.absent(),
                Value<int?> originalAmount = const Value.absent(),
                Value<String?> billId = const Value.absent(),
                required int time,
                Value<String?> comment = const Value.absent(),
                Value<int?> yimuLendId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LendsCompanion.insert(
                id: id,
                type: type,
                accountId: accountId,
                repaymentAccountId: repaymentAccountId,
                amount: amount,
                interest: interest,
                originalAmount: originalAmount,
                billId: billId,
                time: time,
                comment: comment,
                yimuLendId: yimuLendId,
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

typedef $$LendsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LendsTable,
      Lend,
      $$LendsTableFilterComposer,
      $$LendsTableOrderingComposer,
      $$LendsTableAnnotationComposer,
      $$LendsTableCreateCompanionBuilder,
      $$LendsTableUpdateCompanionBuilder,
      (Lend, BaseReferences<_$AppDatabase, $LendsTable, Lend>),
      Lend,
      PrefetchHooks Function()
    >;
typedef $$RefundsTableCreateCompanionBuilder =
    RefundsCompanion Function({
      required String id,
      required String billId,
      required int amount,
      required int time,
      Value<String?> comment,
      Value<int?> yimuRefundId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$RefundsTableUpdateCompanionBuilder =
    RefundsCompanion Function({
      Value<String> id,
      Value<String> billId,
      Value<int> amount,
      Value<int> time,
      Value<String?> comment,
      Value<int?> yimuRefundId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$RefundsTableFilterComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableFilterComposer({
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

  ColumnFilters<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yimuRefundId => $composableBuilder(
    column: $table.yimuRefundId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RefundsTableOrderingComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableOrderingComposer({
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

  ColumnOrderings<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yimuRefundId => $composableBuilder(
    column: $table.yimuRefundId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RefundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RefundsTable> {
  $$RefundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get billId =>
      $composableBuilder(column: $table.billId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<int> get yimuRefundId => $composableBuilder(
    column: $table.yimuRefundId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RefundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RefundsTable,
          Refund,
          $$RefundsTableFilterComposer,
          $$RefundsTableOrderingComposer,
          $$RefundsTableAnnotationComposer,
          $$RefundsTableCreateCompanionBuilder,
          $$RefundsTableUpdateCompanionBuilder,
          (Refund, BaseReferences<_$AppDatabase, $RefundsTable, Refund>),
          Refund,
          PrefetchHooks Function()
        > {
  $$RefundsTableTableManager(_$AppDatabase db, $RefundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RefundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RefundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RefundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> time = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int?> yimuRefundId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RefundsCompanion(
                id: id,
                billId: billId,
                amount: amount,
                time: time,
                comment: comment,
                yimuRefundId: yimuRefundId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String billId,
                required int amount,
                required int time,
                Value<String?> comment = const Value.absent(),
                Value<int?> yimuRefundId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RefundsCompanion.insert(
                id: id,
                billId: billId,
                amount: amount,
                time: time,
                comment: comment,
                yimuRefundId: yimuRefundId,
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

typedef $$RefundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RefundsTable,
      Refund,
      $$RefundsTableFilterComposer,
      $$RefundsTableOrderingComposer,
      $$RefundsTableAnnotationComposer,
      $$RefundsTableCreateCompanionBuilder,
      $$RefundsTableUpdateCompanionBuilder,
      (Refund, BaseReferences<_$AppDatabase, $RefundsTable, Refund>),
      Refund,
      PrefetchHooks Function()
    >;
typedef $$ReimbursementsTableCreateCompanionBuilder =
    ReimbursementsCompanion Function({
      required String id,
      required String billId,
      required int amount,
      Value<String?> accountId,
      Value<String?> reimbursementAccountId,
      Value<bool> ended,
      required int time,
      Value<String?> comment,
      Value<int?> yimuReimbursementId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ReimbursementsTableUpdateCompanionBuilder =
    ReimbursementsCompanion Function({
      Value<String> id,
      Value<String> billId,
      Value<int> amount,
      Value<String?> accountId,
      Value<String?> reimbursementAccountId,
      Value<bool> ended,
      Value<int> time,
      Value<String?> comment,
      Value<int?> yimuReimbursementId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ReimbursementsTableFilterComposer
    extends Composer<_$AppDatabase, $ReimbursementsTable> {
  $$ReimbursementsTableFilterComposer({
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

  ColumnFilters<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reimbursementAccountId => $composableBuilder(
    column: $table.reimbursementAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ended => $composableBuilder(
    column: $table.ended,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yimuReimbursementId => $composableBuilder(
    column: $table.yimuReimbursementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReimbursementsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReimbursementsTable> {
  $$ReimbursementsTableOrderingComposer({
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

  ColumnOrderings<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reimbursementAccountId => $composableBuilder(
    column: $table.reimbursementAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ended => $composableBuilder(
    column: $table.ended,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yimuReimbursementId => $composableBuilder(
    column: $table.yimuReimbursementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReimbursementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReimbursementsTable> {
  $$ReimbursementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get billId =>
      $composableBuilder(column: $table.billId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get reimbursementAccountId => $composableBuilder(
    column: $table.reimbursementAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get ended =>
      $composableBuilder(column: $table.ended, builder: (column) => column);

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<int> get yimuReimbursementId => $composableBuilder(
    column: $table.yimuReimbursementId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReimbursementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReimbursementsTable,
          Reimbursement,
          $$ReimbursementsTableFilterComposer,
          $$ReimbursementsTableOrderingComposer,
          $$ReimbursementsTableAnnotationComposer,
          $$ReimbursementsTableCreateCompanionBuilder,
          $$ReimbursementsTableUpdateCompanionBuilder,
          (
            Reimbursement,
            BaseReferences<_$AppDatabase, $ReimbursementsTable, Reimbursement>,
          ),
          Reimbursement,
          PrefetchHooks Function()
        > {
  $$ReimbursementsTableTableManager(
    _$AppDatabase db,
    $ReimbursementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReimbursementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReimbursementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReimbursementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> reimbursementAccountId = const Value.absent(),
                Value<bool> ended = const Value.absent(),
                Value<int> time = const Value.absent(),
                Value<String?> comment = const Value.absent(),
                Value<int?> yimuReimbursementId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReimbursementsCompanion(
                id: id,
                billId: billId,
                amount: amount,
                accountId: accountId,
                reimbursementAccountId: reimbursementAccountId,
                ended: ended,
                time: time,
                comment: comment,
                yimuReimbursementId: yimuReimbursementId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String billId,
                required int amount,
                Value<String?> accountId = const Value.absent(),
                Value<String?> reimbursementAccountId = const Value.absent(),
                Value<bool> ended = const Value.absent(),
                required int time,
                Value<String?> comment = const Value.absent(),
                Value<int?> yimuReimbursementId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReimbursementsCompanion.insert(
                id: id,
                billId: billId,
                amount: amount,
                accountId: accountId,
                reimbursementAccountId: reimbursementAccountId,
                ended: ended,
                time: time,
                comment: comment,
                yimuReimbursementId: yimuReimbursementId,
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

typedef $$ReimbursementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReimbursementsTable,
      Reimbursement,
      $$ReimbursementsTableFilterComposer,
      $$ReimbursementsTableOrderingComposer,
      $$ReimbursementsTableAnnotationComposer,
      $$ReimbursementsTableCreateCompanionBuilder,
      $$ReimbursementsTableUpdateCompanionBuilder,
      (
        Reimbursement,
        BaseReferences<_$AppDatabase, $ReimbursementsTable, Reimbursement>,
      ),
      Reimbursement,
      PrefetchHooks Function()
    >;
typedef $$InstalmentsTableCreateCompanionBuilder =
    InstalmentsCompanion Function({
      required String id,
      required String billId,
      required String accountId,
      required int totalAmount,
      Value<int> serviceFee,
      required int periods,
      Value<String?> accountMonth,
      required int time,
      Value<int?> yimuInstalmentId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$InstalmentsTableUpdateCompanionBuilder =
    InstalmentsCompanion Function({
      Value<String> id,
      Value<String> billId,
      Value<String> accountId,
      Value<int> totalAmount,
      Value<int> serviceFee,
      Value<int> periods,
      Value<String?> accountMonth,
      Value<int> time,
      Value<int?> yimuInstalmentId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$InstalmentsTableFilterComposer
    extends Composer<_$AppDatabase, $InstalmentsTable> {
  $$InstalmentsTableFilterComposer({
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

  ColumnFilters<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceFee => $composableBuilder(
    column: $table.serviceFee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get periods => $composableBuilder(
    column: $table.periods,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountMonth => $composableBuilder(
    column: $table.accountMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yimuInstalmentId => $composableBuilder(
    column: $table.yimuInstalmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InstalmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstalmentsTable> {
  $$InstalmentsTableOrderingComposer({
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

  ColumnOrderings<String> get billId => $composableBuilder(
    column: $table.billId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceFee => $composableBuilder(
    column: $table.serviceFee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get periods => $composableBuilder(
    column: $table.periods,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountMonth => $composableBuilder(
    column: $table.accountMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get time => $composableBuilder(
    column: $table.time,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yimuInstalmentId => $composableBuilder(
    column: $table.yimuInstalmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstalmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstalmentsTable> {
  $$InstalmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get billId =>
      $composableBuilder(column: $table.billId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceFee => $composableBuilder(
    column: $table.serviceFee,
    builder: (column) => column,
  );

  GeneratedColumn<int> get periods =>
      $composableBuilder(column: $table.periods, builder: (column) => column);

  GeneratedColumn<String> get accountMonth => $composableBuilder(
    column: $table.accountMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get time =>
      $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<int> get yimuInstalmentId => $composableBuilder(
    column: $table.yimuInstalmentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InstalmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstalmentsTable,
          Instalment,
          $$InstalmentsTableFilterComposer,
          $$InstalmentsTableOrderingComposer,
          $$InstalmentsTableAnnotationComposer,
          $$InstalmentsTableCreateCompanionBuilder,
          $$InstalmentsTableUpdateCompanionBuilder,
          (
            Instalment,
            BaseReferences<_$AppDatabase, $InstalmentsTable, Instalment>,
          ),
          Instalment,
          PrefetchHooks Function()
        > {
  $$InstalmentsTableTableManager(_$AppDatabase db, $InstalmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstalmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstalmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstalmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> billId = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<int> totalAmount = const Value.absent(),
                Value<int> serviceFee = const Value.absent(),
                Value<int> periods = const Value.absent(),
                Value<String?> accountMonth = const Value.absent(),
                Value<int> time = const Value.absent(),
                Value<int?> yimuInstalmentId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstalmentsCompanion(
                id: id,
                billId: billId,
                accountId: accountId,
                totalAmount: totalAmount,
                serviceFee: serviceFee,
                periods: periods,
                accountMonth: accountMonth,
                time: time,
                yimuInstalmentId: yimuInstalmentId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String billId,
                required String accountId,
                required int totalAmount,
                Value<int> serviceFee = const Value.absent(),
                required int periods,
                Value<String?> accountMonth = const Value.absent(),
                required int time,
                Value<int?> yimuInstalmentId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InstalmentsCompanion.insert(
                id: id,
                billId: billId,
                accountId: accountId,
                totalAmount: totalAmount,
                serviceFee: serviceFee,
                periods: periods,
                accountMonth: accountMonth,
                time: time,
                yimuInstalmentId: yimuInstalmentId,
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

typedef $$InstalmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstalmentsTable,
      Instalment,
      $$InstalmentsTableFilterComposer,
      $$InstalmentsTableOrderingComposer,
      $$InstalmentsTableAnnotationComposer,
      $$InstalmentsTableCreateCompanionBuilder,
      $$InstalmentsTableUpdateCompanionBuilder,
      (
        Instalment,
        BaseReferences<_$AppDatabase, $InstalmentsTable, Instalment>,
      ),
      Instalment,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      required String id,
      required String name,
      Value<String?> categoryId,
      required String type,
      required String periodType,
      required int amount,
      Value<int?> startTime,
      Value<int?> endTime,
      Value<bool> enabled,
      Value<int?> yimuBudgetId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> categoryId,
      Value<String> type,
      Value<String> periodType,
      Value<int> amount,
      Value<int?> startTime,
      Value<int?> endTime,
      Value<bool> enabled,
      Value<int?> yimuBudgetId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
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

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yimuBudgetId => $composableBuilder(
    column: $table.yimuBudgetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
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

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yimuBudgetId => $composableBuilder(
    column: $table.yimuBudgetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
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

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get yimuBudgetId => $composableBuilder(
    column: $table.yimuBudgetId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
          Budget,
          PrefetchHooks Function()
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> periodType = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int?> startTime = const Value.absent(),
                Value<int?> endTime = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> yimuBudgetId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                name: name,
                categoryId: categoryId,
                type: type,
                periodType: periodType,
                amount: amount,
                startTime: startTime,
                endTime: endTime,
                enabled: enabled,
                yimuBudgetId: yimuBudgetId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> categoryId = const Value.absent(),
                required String type,
                required String periodType,
                required int amount,
                Value<int?> startTime = const Value.absent(),
                Value<int?> endTime = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int?> yimuBudgetId = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                name: name,
                categoryId: categoryId,
                type: type,
                periodType: periodType,
                amount: amount,
                startTime: startTime,
                endTime: endTime,
                enabled: enabled,
                yimuBudgetId: yimuBudgetId,
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

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, BaseReferences<_$AppDatabase, $BudgetsTable, Budget>),
      Budget,
      PrefetchHooks Function()
    >;
typedef $$ImportMappingsTableCreateCompanionBuilder =
    ImportMappingsCompanion Function({
      required String id,
      required String provider,
      required String entityType,
      required String sourceId,
      required String targetId,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ImportMappingsTableUpdateCompanionBuilder =
    ImportMappingsCompanion Function({
      Value<String> id,
      Value<String> provider,
      Value<String> entityType,
      Value<String> sourceId,
      Value<String> targetId,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ImportMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $ImportMappingsTable> {
  $$ImportMappingsTableFilterComposer({
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

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ImportMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ImportMappingsTable> {
  $$ImportMappingsTableOrderingComposer({
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

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ImportMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImportMappingsTable> {
  $$ImportMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ImportMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImportMappingsTable,
          ImportMapping,
          $$ImportMappingsTableFilterComposer,
          $$ImportMappingsTableOrderingComposer,
          $$ImportMappingsTableAnnotationComposer,
          $$ImportMappingsTableCreateCompanionBuilder,
          $$ImportMappingsTableUpdateCompanionBuilder,
          (
            ImportMapping,
            BaseReferences<_$AppDatabase, $ImportMappingsTable, ImportMapping>,
          ),
          ImportMapping,
          PrefetchHooks Function()
        > {
  $$ImportMappingsTableTableManager(
    _$AppDatabase db,
    $ImportMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportMappingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImportMappingsCompanion(
                id: id,
                provider: provider,
                entityType: entityType,
                sourceId: sourceId,
                targetId: targetId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String provider,
                required String entityType,
                required String sourceId,
                required String targetId,
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ImportMappingsCompanion.insert(
                id: id,
                provider: provider,
                entityType: entityType,
                sourceId: sourceId,
                targetId: targetId,
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

typedef $$ImportMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImportMappingsTable,
      ImportMapping,
      $$ImportMappingsTableFilterComposer,
      $$ImportMappingsTableOrderingComposer,
      $$ImportMappingsTableAnnotationComposer,
      $$ImportMappingsTableCreateCompanionBuilder,
      $$ImportMappingsTableUpdateCompanionBuilder,
      (
        ImportMapping,
        BaseReferences<_$AppDatabase, $ImportMappingsTable, ImportMapping>,
      ),
      ImportMapping,
      PrefetchHooks Function()
    >;
typedef $$YearReportsTableCreateCompanionBuilder =
    YearReportsCompanion Function({
      Value<int> year,
      required int income,
      required int expense,
      required int adjustNet,
      required int startAssets,
      required int endAssets,
      required int billCount,
      required int adjustCount,
      Value<bool> hasAssetBaseline,
      required String sourceSig,
      required int computedAt,
    });
typedef $$YearReportsTableUpdateCompanionBuilder =
    YearReportsCompanion Function({
      Value<int> year,
      Value<int> income,
      Value<int> expense,
      Value<int> adjustNet,
      Value<int> startAssets,
      Value<int> endAssets,
      Value<int> billCount,
      Value<int> adjustCount,
      Value<bool> hasAssetBaseline,
      Value<String> sourceSig,
      Value<int> computedAt,
    });

class $$YearReportsTableFilterComposer
    extends Composer<_$AppDatabase, $YearReportsTable> {
  $$YearReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get income => $composableBuilder(
    column: $table.income,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expense => $composableBuilder(
    column: $table.expense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adjustNet => $composableBuilder(
    column: $table.adjustNet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAssets => $composableBuilder(
    column: $table.startAssets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAssets => $composableBuilder(
    column: $table.endAssets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billCount => $composableBuilder(
    column: $table.billCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get adjustCount => $composableBuilder(
    column: $table.adjustCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasAssetBaseline => $composableBuilder(
    column: $table.hasAssetBaseline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSig => $composableBuilder(
    column: $table.sourceSig,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$YearReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $YearReportsTable> {
  $$YearReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get income => $composableBuilder(
    column: $table.income,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expense => $composableBuilder(
    column: $table.expense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adjustNet => $composableBuilder(
    column: $table.adjustNet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAssets => $composableBuilder(
    column: $table.startAssets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAssets => $composableBuilder(
    column: $table.endAssets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billCount => $composableBuilder(
    column: $table.billCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get adjustCount => $composableBuilder(
    column: $table.adjustCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasAssetBaseline => $composableBuilder(
    column: $table.hasAssetBaseline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSig => $composableBuilder(
    column: $table.sourceSig,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$YearReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $YearReportsTable> {
  $$YearReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get income =>
      $composableBuilder(column: $table.income, builder: (column) => column);

  GeneratedColumn<int> get expense =>
      $composableBuilder(column: $table.expense, builder: (column) => column);

  GeneratedColumn<int> get adjustNet =>
      $composableBuilder(column: $table.adjustNet, builder: (column) => column);

  GeneratedColumn<int> get startAssets => $composableBuilder(
    column: $table.startAssets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endAssets =>
      $composableBuilder(column: $table.endAssets, builder: (column) => column);

  GeneratedColumn<int> get billCount =>
      $composableBuilder(column: $table.billCount, builder: (column) => column);

  GeneratedColumn<int> get adjustCount => $composableBuilder(
    column: $table.adjustCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasAssetBaseline => $composableBuilder(
    column: $table.hasAssetBaseline,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceSig =>
      $composableBuilder(column: $table.sourceSig, builder: (column) => column);

  GeneratedColumn<int> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );
}

class $$YearReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $YearReportsTable,
          YearReport,
          $$YearReportsTableFilterComposer,
          $$YearReportsTableOrderingComposer,
          $$YearReportsTableAnnotationComposer,
          $$YearReportsTableCreateCompanionBuilder,
          $$YearReportsTableUpdateCompanionBuilder,
          (
            YearReport,
            BaseReferences<_$AppDatabase, $YearReportsTable, YearReport>,
          ),
          YearReport,
          PrefetchHooks Function()
        > {
  $$YearReportsTableTableManager(_$AppDatabase db, $YearReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$YearReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$YearReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$YearReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                Value<int> income = const Value.absent(),
                Value<int> expense = const Value.absent(),
                Value<int> adjustNet = const Value.absent(),
                Value<int> startAssets = const Value.absent(),
                Value<int> endAssets = const Value.absent(),
                Value<int> billCount = const Value.absent(),
                Value<int> adjustCount = const Value.absent(),
                Value<bool> hasAssetBaseline = const Value.absent(),
                Value<String> sourceSig = const Value.absent(),
                Value<int> computedAt = const Value.absent(),
              }) => YearReportsCompanion(
                year: year,
                income: income,
                expense: expense,
                adjustNet: adjustNet,
                startAssets: startAssets,
                endAssets: endAssets,
                billCount: billCount,
                adjustCount: adjustCount,
                hasAssetBaseline: hasAssetBaseline,
                sourceSig: sourceSig,
                computedAt: computedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> year = const Value.absent(),
                required int income,
                required int expense,
                required int adjustNet,
                required int startAssets,
                required int endAssets,
                required int billCount,
                required int adjustCount,
                Value<bool> hasAssetBaseline = const Value.absent(),
                required String sourceSig,
                required int computedAt,
              }) => YearReportsCompanion.insert(
                year: year,
                income: income,
                expense: expense,
                adjustNet: adjustNet,
                startAssets: startAssets,
                endAssets: endAssets,
                billCount: billCount,
                adjustCount: adjustCount,
                hasAssetBaseline: hasAssetBaseline,
                sourceSig: sourceSig,
                computedAt: computedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$YearReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $YearReportsTable,
      YearReport,
      $$YearReportsTableFilterComposer,
      $$YearReportsTableOrderingComposer,
      $$YearReportsTableAnnotationComposer,
      $$YearReportsTableCreateCompanionBuilder,
      $$YearReportsTableUpdateCompanionBuilder,
      (
        YearReport,
        BaseReferences<_$AppDatabase, $YearReportsTable, YearReport>,
      ),
      YearReport,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TagGroupsTableTableManager get tagGroups =>
      $$TagGroupsTableTableManager(_db, _db.tagGroups);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$BillTagsTableTableManager get billTags =>
      $$BillTagsTableTableManager(_db, _db.billTags);
  $$BalanceSnapshotsTableTableManager get balanceSnapshots =>
      $$BalanceSnapshotsTableTableManager(_db, _db.balanceSnapshots);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
  $$LendsTableTableManager get lends =>
      $$LendsTableTableManager(_db, _db.lends);
  $$RefundsTableTableManager get refunds =>
      $$RefundsTableTableManager(_db, _db.refunds);
  $$ReimbursementsTableTableManager get reimbursements =>
      $$ReimbursementsTableTableManager(_db, _db.reimbursements);
  $$InstalmentsTableTableManager get instalments =>
      $$InstalmentsTableTableManager(_db, _db.instalments);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$ImportMappingsTableTableManager get importMappings =>
      $$ImportMappingsTableTableManager(_db, _db.importMappings);
  $$YearReportsTableTableManager get yearReports =>
      $$YearReportsTableTableManager(_db, _db.yearReports);
}
