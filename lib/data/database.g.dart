// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BikeProfilesTable extends BikeProfiles
    with TableInfo<$BikeProfilesTable, BikeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BikeProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tankLitresMeta = const VerificationMeta(
    'tankLitres',
  );
  @override
  late final GeneratedColumn<double> tankLitres = GeneratedColumn<double>(
    'tank_litres',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gaugeBarsMeta = const VerificationMeta(
    'gaugeBars',
  );
  @override
  late final GeneratedColumn<int> gaugeBars = GeneratedColumn<int>(
    'gauge_bars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedKmplMinMeta = const VerificationMeta(
    'expectedKmplMin',
  );
  @override
  late final GeneratedColumn<double> expectedKmplMin = GeneratedColumn<double>(
    'expected_kmpl_min',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedKmplMaxMeta = const VerificationMeta(
    'expectedKmplMax',
  );
  @override
  late final GeneratedColumn<double> expectedKmplMax = GeneratedColumn<double>(
    'expected_kmpl_max',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prefillUncertaintyLitresMeta =
      const VerificationMeta('prefillUncertaintyLitres');
  @override
  late final GeneratedColumn<double> prefillUncertaintyLitres =
      GeneratedColumn<double>(
        'prefill_uncertainty_litres',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fullUncertaintyLitresMeta =
      const VerificationMeta('fullUncertaintyLitres');
  @override
  late final GeneratedColumn<double> fullUncertaintyLitres =
      GeneratedColumn<double>(
        'full_uncertainty_litres',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _odometerDigitsMeta = const VerificationMeta(
    'odometerDigits',
  );
  @override
  late final GeneratedColumn<int> odometerDigits = GeneratedColumn<int>(
    'odometer_digits',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    model,
    tankLitres,
    gaugeBars,
    expectedKmplMin,
    expectedKmplMax,
    prefillUncertaintyLitres,
    fullUncertaintyLitres,
    odometerDigits,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bike_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<BikeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('tank_litres')) {
      context.handle(
        _tankLitresMeta,
        tankLitres.isAcceptableOrUnknown(data['tank_litres']!, _tankLitresMeta),
      );
    } else if (isInserting) {
      context.missing(_tankLitresMeta);
    }
    if (data.containsKey('gauge_bars')) {
      context.handle(
        _gaugeBarsMeta,
        gaugeBars.isAcceptableOrUnknown(data['gauge_bars']!, _gaugeBarsMeta),
      );
    } else if (isInserting) {
      context.missing(_gaugeBarsMeta);
    }
    if (data.containsKey('expected_kmpl_min')) {
      context.handle(
        _expectedKmplMinMeta,
        expectedKmplMin.isAcceptableOrUnknown(
          data['expected_kmpl_min']!,
          _expectedKmplMinMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedKmplMinMeta);
    }
    if (data.containsKey('expected_kmpl_max')) {
      context.handle(
        _expectedKmplMaxMeta,
        expectedKmplMax.isAcceptableOrUnknown(
          data['expected_kmpl_max']!,
          _expectedKmplMaxMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expectedKmplMaxMeta);
    }
    if (data.containsKey('prefill_uncertainty_litres')) {
      context.handle(
        _prefillUncertaintyLitresMeta,
        prefillUncertaintyLitres.isAcceptableOrUnknown(
          data['prefill_uncertainty_litres']!,
          _prefillUncertaintyLitresMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prefillUncertaintyLitresMeta);
    }
    if (data.containsKey('full_uncertainty_litres')) {
      context.handle(
        _fullUncertaintyLitresMeta,
        fullUncertaintyLitres.isAcceptableOrUnknown(
          data['full_uncertainty_litres']!,
          _fullUncertaintyLitresMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fullUncertaintyLitresMeta);
    }
    if (data.containsKey('odometer_digits')) {
      context.handle(
        _odometerDigitsMeta,
        odometerDigits.isAcceptableOrUnknown(
          data['odometer_digits']!,
          _odometerDigitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_odometerDigitsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BikeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BikeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      tankLitres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tank_litres'],
      )!,
      gaugeBars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gauge_bars'],
      )!,
      expectedKmplMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}expected_kmpl_min'],
      )!,
      expectedKmplMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}expected_kmpl_max'],
      )!,
      prefillUncertaintyLitres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prefill_uncertainty_litres'],
      )!,
      fullUncertaintyLitres: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}full_uncertainty_litres'],
      )!,
      odometerDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}odometer_digits'],
      )!,
    );
  }

  @override
  $BikeProfilesTable createAlias(String alias) {
    return $BikeProfilesTable(attachedDatabase, alias);
  }
}

class BikeRow extends DataClass implements Insertable<BikeRow> {
  final int id;
  final String model;
  final double tankLitres;
  final int gaugeBars;
  final double expectedKmplMin;
  final double expectedKmplMax;
  final double prefillUncertaintyLitres;
  final double fullUncertaintyLitres;
  final int odometerDigits;
  const BikeRow({
    required this.id,
    required this.model,
    required this.tankLitres,
    required this.gaugeBars,
    required this.expectedKmplMin,
    required this.expectedKmplMax,
    required this.prefillUncertaintyLitres,
    required this.fullUncertaintyLitres,
    required this.odometerDigits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['model'] = Variable<String>(model);
    map['tank_litres'] = Variable<double>(tankLitres);
    map['gauge_bars'] = Variable<int>(gaugeBars);
    map['expected_kmpl_min'] = Variable<double>(expectedKmplMin);
    map['expected_kmpl_max'] = Variable<double>(expectedKmplMax);
    map['prefill_uncertainty_litres'] = Variable<double>(
      prefillUncertaintyLitres,
    );
    map['full_uncertainty_litres'] = Variable<double>(fullUncertaintyLitres);
    map['odometer_digits'] = Variable<int>(odometerDigits);
    return map;
  }

  BikeProfilesCompanion toCompanion(bool nullToAbsent) {
    return BikeProfilesCompanion(
      id: Value(id),
      model: Value(model),
      tankLitres: Value(tankLitres),
      gaugeBars: Value(gaugeBars),
      expectedKmplMin: Value(expectedKmplMin),
      expectedKmplMax: Value(expectedKmplMax),
      prefillUncertaintyLitres: Value(prefillUncertaintyLitres),
      fullUncertaintyLitres: Value(fullUncertaintyLitres),
      odometerDigits: Value(odometerDigits),
    );
  }

  factory BikeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BikeRow(
      id: serializer.fromJson<int>(json['id']),
      model: serializer.fromJson<String>(json['model']),
      tankLitres: serializer.fromJson<double>(json['tankLitres']),
      gaugeBars: serializer.fromJson<int>(json['gaugeBars']),
      expectedKmplMin: serializer.fromJson<double>(json['expectedKmplMin']),
      expectedKmplMax: serializer.fromJson<double>(json['expectedKmplMax']),
      prefillUncertaintyLitres: serializer.fromJson<double>(
        json['prefillUncertaintyLitres'],
      ),
      fullUncertaintyLitres: serializer.fromJson<double>(
        json['fullUncertaintyLitres'],
      ),
      odometerDigits: serializer.fromJson<int>(json['odometerDigits']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'model': serializer.toJson<String>(model),
      'tankLitres': serializer.toJson<double>(tankLitres),
      'gaugeBars': serializer.toJson<int>(gaugeBars),
      'expectedKmplMin': serializer.toJson<double>(expectedKmplMin),
      'expectedKmplMax': serializer.toJson<double>(expectedKmplMax),
      'prefillUncertaintyLitres': serializer.toJson<double>(
        prefillUncertaintyLitres,
      ),
      'fullUncertaintyLitres': serializer.toJson<double>(fullUncertaintyLitres),
      'odometerDigits': serializer.toJson<int>(odometerDigits),
    };
  }

  BikeRow copyWith({
    int? id,
    String? model,
    double? tankLitres,
    int? gaugeBars,
    double? expectedKmplMin,
    double? expectedKmplMax,
    double? prefillUncertaintyLitres,
    double? fullUncertaintyLitres,
    int? odometerDigits,
  }) => BikeRow(
    id: id ?? this.id,
    model: model ?? this.model,
    tankLitres: tankLitres ?? this.tankLitres,
    gaugeBars: gaugeBars ?? this.gaugeBars,
    expectedKmplMin: expectedKmplMin ?? this.expectedKmplMin,
    expectedKmplMax: expectedKmplMax ?? this.expectedKmplMax,
    prefillUncertaintyLitres:
        prefillUncertaintyLitres ?? this.prefillUncertaintyLitres,
    fullUncertaintyLitres: fullUncertaintyLitres ?? this.fullUncertaintyLitres,
    odometerDigits: odometerDigits ?? this.odometerDigits,
  );
  BikeRow copyWithCompanion(BikeProfilesCompanion data) {
    return BikeRow(
      id: data.id.present ? data.id.value : this.id,
      model: data.model.present ? data.model.value : this.model,
      tankLitres: data.tankLitres.present
          ? data.tankLitres.value
          : this.tankLitres,
      gaugeBars: data.gaugeBars.present ? data.gaugeBars.value : this.gaugeBars,
      expectedKmplMin: data.expectedKmplMin.present
          ? data.expectedKmplMin.value
          : this.expectedKmplMin,
      expectedKmplMax: data.expectedKmplMax.present
          ? data.expectedKmplMax.value
          : this.expectedKmplMax,
      prefillUncertaintyLitres: data.prefillUncertaintyLitres.present
          ? data.prefillUncertaintyLitres.value
          : this.prefillUncertaintyLitres,
      fullUncertaintyLitres: data.fullUncertaintyLitres.present
          ? data.fullUncertaintyLitres.value
          : this.fullUncertaintyLitres,
      odometerDigits: data.odometerDigits.present
          ? data.odometerDigits.value
          : this.odometerDigits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BikeRow(')
          ..write('id: $id, ')
          ..write('model: $model, ')
          ..write('tankLitres: $tankLitres, ')
          ..write('gaugeBars: $gaugeBars, ')
          ..write('expectedKmplMin: $expectedKmplMin, ')
          ..write('expectedKmplMax: $expectedKmplMax, ')
          ..write('prefillUncertaintyLitres: $prefillUncertaintyLitres, ')
          ..write('fullUncertaintyLitres: $fullUncertaintyLitres, ')
          ..write('odometerDigits: $odometerDigits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    model,
    tankLitres,
    gaugeBars,
    expectedKmplMin,
    expectedKmplMax,
    prefillUncertaintyLitres,
    fullUncertaintyLitres,
    odometerDigits,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BikeRow &&
          other.id == this.id &&
          other.model == this.model &&
          other.tankLitres == this.tankLitres &&
          other.gaugeBars == this.gaugeBars &&
          other.expectedKmplMin == this.expectedKmplMin &&
          other.expectedKmplMax == this.expectedKmplMax &&
          other.prefillUncertaintyLitres == this.prefillUncertaintyLitres &&
          other.fullUncertaintyLitres == this.fullUncertaintyLitres &&
          other.odometerDigits == this.odometerDigits);
}

class BikeProfilesCompanion extends UpdateCompanion<BikeRow> {
  final Value<int> id;
  final Value<String> model;
  final Value<double> tankLitres;
  final Value<int> gaugeBars;
  final Value<double> expectedKmplMin;
  final Value<double> expectedKmplMax;
  final Value<double> prefillUncertaintyLitres;
  final Value<double> fullUncertaintyLitres;
  final Value<int> odometerDigits;
  const BikeProfilesCompanion({
    this.id = const Value.absent(),
    this.model = const Value.absent(),
    this.tankLitres = const Value.absent(),
    this.gaugeBars = const Value.absent(),
    this.expectedKmplMin = const Value.absent(),
    this.expectedKmplMax = const Value.absent(),
    this.prefillUncertaintyLitres = const Value.absent(),
    this.fullUncertaintyLitres = const Value.absent(),
    this.odometerDigits = const Value.absent(),
  });
  BikeProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String model,
    required double tankLitres,
    required int gaugeBars,
    required double expectedKmplMin,
    required double expectedKmplMax,
    required double prefillUncertaintyLitres,
    required double fullUncertaintyLitres,
    required int odometerDigits,
  }) : model = Value(model),
       tankLitres = Value(tankLitres),
       gaugeBars = Value(gaugeBars),
       expectedKmplMin = Value(expectedKmplMin),
       expectedKmplMax = Value(expectedKmplMax),
       prefillUncertaintyLitres = Value(prefillUncertaintyLitres),
       fullUncertaintyLitres = Value(fullUncertaintyLitres),
       odometerDigits = Value(odometerDigits);
  static Insertable<BikeRow> custom({
    Expression<int>? id,
    Expression<String>? model,
    Expression<double>? tankLitres,
    Expression<int>? gaugeBars,
    Expression<double>? expectedKmplMin,
    Expression<double>? expectedKmplMax,
    Expression<double>? prefillUncertaintyLitres,
    Expression<double>? fullUncertaintyLitres,
    Expression<int>? odometerDigits,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (model != null) 'model': model,
      if (tankLitres != null) 'tank_litres': tankLitres,
      if (gaugeBars != null) 'gauge_bars': gaugeBars,
      if (expectedKmplMin != null) 'expected_kmpl_min': expectedKmplMin,
      if (expectedKmplMax != null) 'expected_kmpl_max': expectedKmplMax,
      if (prefillUncertaintyLitres != null)
        'prefill_uncertainty_litres': prefillUncertaintyLitres,
      if (fullUncertaintyLitres != null)
        'full_uncertainty_litres': fullUncertaintyLitres,
      if (odometerDigits != null) 'odometer_digits': odometerDigits,
    });
  }

  BikeProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? model,
    Value<double>? tankLitres,
    Value<int>? gaugeBars,
    Value<double>? expectedKmplMin,
    Value<double>? expectedKmplMax,
    Value<double>? prefillUncertaintyLitres,
    Value<double>? fullUncertaintyLitres,
    Value<int>? odometerDigits,
  }) {
    return BikeProfilesCompanion(
      id: id ?? this.id,
      model: model ?? this.model,
      tankLitres: tankLitres ?? this.tankLitres,
      gaugeBars: gaugeBars ?? this.gaugeBars,
      expectedKmplMin: expectedKmplMin ?? this.expectedKmplMin,
      expectedKmplMax: expectedKmplMax ?? this.expectedKmplMax,
      prefillUncertaintyLitres:
          prefillUncertaintyLitres ?? this.prefillUncertaintyLitres,
      fullUncertaintyLitres:
          fullUncertaintyLitres ?? this.fullUncertaintyLitres,
      odometerDigits: odometerDigits ?? this.odometerDigits,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (tankLitres.present) {
      map['tank_litres'] = Variable<double>(tankLitres.value);
    }
    if (gaugeBars.present) {
      map['gauge_bars'] = Variable<int>(gaugeBars.value);
    }
    if (expectedKmplMin.present) {
      map['expected_kmpl_min'] = Variable<double>(expectedKmplMin.value);
    }
    if (expectedKmplMax.present) {
      map['expected_kmpl_max'] = Variable<double>(expectedKmplMax.value);
    }
    if (prefillUncertaintyLitres.present) {
      map['prefill_uncertainty_litres'] = Variable<double>(
        prefillUncertaintyLitres.value,
      );
    }
    if (fullUncertaintyLitres.present) {
      map['full_uncertainty_litres'] = Variable<double>(
        fullUncertaintyLitres.value,
      );
    }
    if (odometerDigits.present) {
      map['odometer_digits'] = Variable<int>(odometerDigits.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BikeProfilesCompanion(')
          ..write('id: $id, ')
          ..write('model: $model, ')
          ..write('tankLitres: $tankLitres, ')
          ..write('gaugeBars: $gaugeBars, ')
          ..write('expectedKmplMin: $expectedKmplMin, ')
          ..write('expectedKmplMax: $expectedKmplMax, ')
          ..write('prefillUncertaintyLitres: $prefillUncertaintyLitres, ')
          ..write('fullUncertaintyLitres: $fullUncertaintyLitres, ')
          ..write('odometerDigits: $odometerDigits')
          ..write(')'))
        .toString();
  }
}

class $LogEntriesTable extends LogEntries
    with TableInfo<$LogEntriesTable, LogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LogEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _odometerMeta = const VerificationMeta(
    'odometer',
  );
  @override
  late final GeneratedColumn<int> odometer = GeneratedColumn<int>(
    'odometer',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pricePerLitreMeta = const VerificationMeta(
    'pricePerLitre',
  );
  @override
  late final GeneratedColumn<double> pricePerLitre = GeneratedColumn<double>(
    'price_per_litre',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gaugeBarsMeta = const VerificationMeta(
    'gaugeBars',
  );
  @override
  late final GeneratedColumn<int> gaugeBars = GeneratedColumn<int>(
    'gauge_bars',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFullMeta = const VerificationMeta('isFull');
  @override
  late final GeneratedColumn<bool> isFull = GeneratedColumn<bool>(
    'is_full',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_full" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isAnchorMeta = const VerificationMeta(
    'isAnchor',
  );
  @override
  late final GeneratedColumn<bool> isAnchor = GeneratedColumn<bool>(
    'is_anchor',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_anchor" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    position,
    kind,
    date,
    odometer,
    amount,
    pricePerLitre,
    gaugeBars,
    isFull,
    isAnchor,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('odometer')) {
      context.handle(
        _odometerMeta,
        odometer.isAcceptableOrUnknown(data['odometer']!, _odometerMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('price_per_litre')) {
      context.handle(
        _pricePerLitreMeta,
        pricePerLitre.isAcceptableOrUnknown(
          data['price_per_litre']!,
          _pricePerLitreMeta,
        ),
      );
    }
    if (data.containsKey('gauge_bars')) {
      context.handle(
        _gaugeBarsMeta,
        gaugeBars.isAcceptableOrUnknown(data['gauge_bars']!, _gaugeBarsMeta),
      );
    }
    if (data.containsKey('is_full')) {
      context.handle(
        _isFullMeta,
        isFull.isAcceptableOrUnknown(data['is_full']!, _isFullMeta),
      );
    }
    if (data.containsKey('is_anchor')) {
      context.handle(
        _isAnchorMeta,
        isAnchor.isAcceptableOrUnknown(data['is_anchor']!, _isAnchorMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      odometer: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}odometer'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      pricePerLitre: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_litre'],
      ),
      gaugeBars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gauge_bars'],
      ),
      isFull: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_full'],
      )!,
      isAnchor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_anchor'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $LogEntriesTable createAlias(String alias) {
    return $LogEntriesTable(attachedDatabase, alias);
  }
}

class LogRow extends DataClass implements Insertable<LogRow> {
  final int id;

  /// Order in the log, 0-based and gap-free. The engine follows this order.
  final int position;

  /// 'refuel' or 'service'.
  final String kind;
  final DateTime date;
  final int? odometer;
  final double? amount;
  final double? pricePerLitre;
  final int? gaugeBars;
  final bool isFull;
  final bool isAnchor;
  final String note;
  const LogRow({
    required this.id,
    required this.position,
    required this.kind,
    required this.date,
    this.odometer,
    this.amount,
    this.pricePerLitre,
    this.gaugeBars,
    required this.isFull,
    required this.isAnchor,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['position'] = Variable<int>(position);
    map['kind'] = Variable<String>(kind);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || odometer != null) {
      map['odometer'] = Variable<int>(odometer);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || pricePerLitre != null) {
      map['price_per_litre'] = Variable<double>(pricePerLitre);
    }
    if (!nullToAbsent || gaugeBars != null) {
      map['gauge_bars'] = Variable<int>(gaugeBars);
    }
    map['is_full'] = Variable<bool>(isFull);
    map['is_anchor'] = Variable<bool>(isAnchor);
    map['note'] = Variable<String>(note);
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: Value(id),
      position: Value(position),
      kind: Value(kind),
      date: Value(date),
      odometer: odometer == null && nullToAbsent
          ? const Value.absent()
          : Value(odometer),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      pricePerLitre: pricePerLitre == null && nullToAbsent
          ? const Value.absent()
          : Value(pricePerLitre),
      gaugeBars: gaugeBars == null && nullToAbsent
          ? const Value.absent()
          : Value(gaugeBars),
      isFull: Value(isFull),
      isAnchor: Value(isAnchor),
      note: Value(note),
    );
  }

  factory LogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogRow(
      id: serializer.fromJson<int>(json['id']),
      position: serializer.fromJson<int>(json['position']),
      kind: serializer.fromJson<String>(json['kind']),
      date: serializer.fromJson<DateTime>(json['date']),
      odometer: serializer.fromJson<int?>(json['odometer']),
      amount: serializer.fromJson<double?>(json['amount']),
      pricePerLitre: serializer.fromJson<double?>(json['pricePerLitre']),
      gaugeBars: serializer.fromJson<int?>(json['gaugeBars']),
      isFull: serializer.fromJson<bool>(json['isFull']),
      isAnchor: serializer.fromJson<bool>(json['isAnchor']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'position': serializer.toJson<int>(position),
      'kind': serializer.toJson<String>(kind),
      'date': serializer.toJson<DateTime>(date),
      'odometer': serializer.toJson<int?>(odometer),
      'amount': serializer.toJson<double?>(amount),
      'pricePerLitre': serializer.toJson<double?>(pricePerLitre),
      'gaugeBars': serializer.toJson<int?>(gaugeBars),
      'isFull': serializer.toJson<bool>(isFull),
      'isAnchor': serializer.toJson<bool>(isAnchor),
      'note': serializer.toJson<String>(note),
    };
  }

  LogRow copyWith({
    int? id,
    int? position,
    String? kind,
    DateTime? date,
    Value<int?> odometer = const Value.absent(),
    Value<double?> amount = const Value.absent(),
    Value<double?> pricePerLitre = const Value.absent(),
    Value<int?> gaugeBars = const Value.absent(),
    bool? isFull,
    bool? isAnchor,
    String? note,
  }) => LogRow(
    id: id ?? this.id,
    position: position ?? this.position,
    kind: kind ?? this.kind,
    date: date ?? this.date,
    odometer: odometer.present ? odometer.value : this.odometer,
    amount: amount.present ? amount.value : this.amount,
    pricePerLitre: pricePerLitre.present
        ? pricePerLitre.value
        : this.pricePerLitre,
    gaugeBars: gaugeBars.present ? gaugeBars.value : this.gaugeBars,
    isFull: isFull ?? this.isFull,
    isAnchor: isAnchor ?? this.isAnchor,
    note: note ?? this.note,
  );
  LogRow copyWithCompanion(LogEntriesCompanion data) {
    return LogRow(
      id: data.id.present ? data.id.value : this.id,
      position: data.position.present ? data.position.value : this.position,
      kind: data.kind.present ? data.kind.value : this.kind,
      date: data.date.present ? data.date.value : this.date,
      odometer: data.odometer.present ? data.odometer.value : this.odometer,
      amount: data.amount.present ? data.amount.value : this.amount,
      pricePerLitre: data.pricePerLitre.present
          ? data.pricePerLitre.value
          : this.pricePerLitre,
      gaugeBars: data.gaugeBars.present ? data.gaugeBars.value : this.gaugeBars,
      isFull: data.isFull.present ? data.isFull.value : this.isFull,
      isAnchor: data.isAnchor.present ? data.isAnchor.value : this.isAnchor,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LogRow(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('kind: $kind, ')
          ..write('date: $date, ')
          ..write('odometer: $odometer, ')
          ..write('amount: $amount, ')
          ..write('pricePerLitre: $pricePerLitre, ')
          ..write('gaugeBars: $gaugeBars, ')
          ..write('isFull: $isFull, ')
          ..write('isAnchor: $isAnchor, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    position,
    kind,
    date,
    odometer,
    amount,
    pricePerLitre,
    gaugeBars,
    isFull,
    isAnchor,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogRow &&
          other.id == this.id &&
          other.position == this.position &&
          other.kind == this.kind &&
          other.date == this.date &&
          other.odometer == this.odometer &&
          other.amount == this.amount &&
          other.pricePerLitre == this.pricePerLitre &&
          other.gaugeBars == this.gaugeBars &&
          other.isFull == this.isFull &&
          other.isAnchor == this.isAnchor &&
          other.note == this.note);
}

class LogEntriesCompanion extends UpdateCompanion<LogRow> {
  final Value<int> id;
  final Value<int> position;
  final Value<String> kind;
  final Value<DateTime> date;
  final Value<int?> odometer;
  final Value<double?> amount;
  final Value<double?> pricePerLitre;
  final Value<int?> gaugeBars;
  final Value<bool> isFull;
  final Value<bool> isAnchor;
  final Value<String> note;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.position = const Value.absent(),
    this.kind = const Value.absent(),
    this.date = const Value.absent(),
    this.odometer = const Value.absent(),
    this.amount = const Value.absent(),
    this.pricePerLitre = const Value.absent(),
    this.gaugeBars = const Value.absent(),
    this.isFull = const Value.absent(),
    this.isAnchor = const Value.absent(),
    this.note = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int position,
    required String kind,
    required DateTime date,
    this.odometer = const Value.absent(),
    this.amount = const Value.absent(),
    this.pricePerLitre = const Value.absent(),
    this.gaugeBars = const Value.absent(),
    this.isFull = const Value.absent(),
    this.isAnchor = const Value.absent(),
    this.note = const Value.absent(),
  }) : position = Value(position),
       kind = Value(kind),
       date = Value(date);
  static Insertable<LogRow> custom({
    Expression<int>? id,
    Expression<int>? position,
    Expression<String>? kind,
    Expression<DateTime>? date,
    Expression<int>? odometer,
    Expression<double>? amount,
    Expression<double>? pricePerLitre,
    Expression<int>? gaugeBars,
    Expression<bool>? isFull,
    Expression<bool>? isAnchor,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (position != null) 'position': position,
      if (kind != null) 'kind': kind,
      if (date != null) 'date': date,
      if (odometer != null) 'odometer': odometer,
      if (amount != null) 'amount': amount,
      if (pricePerLitre != null) 'price_per_litre': pricePerLitre,
      if (gaugeBars != null) 'gauge_bars': gaugeBars,
      if (isFull != null) 'is_full': isFull,
      if (isAnchor != null) 'is_anchor': isAnchor,
      if (note != null) 'note': note,
    });
  }

  LogEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? position,
    Value<String>? kind,
    Value<DateTime>? date,
    Value<int?>? odometer,
    Value<double?>? amount,
    Value<double?>? pricePerLitre,
    Value<int?>? gaugeBars,
    Value<bool>? isFull,
    Value<bool>? isAnchor,
    Value<String>? note,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      position: position ?? this.position,
      kind: kind ?? this.kind,
      date: date ?? this.date,
      odometer: odometer ?? this.odometer,
      amount: amount ?? this.amount,
      pricePerLitre: pricePerLitre ?? this.pricePerLitre,
      gaugeBars: gaugeBars ?? this.gaugeBars,
      isFull: isFull ?? this.isFull,
      isAnchor: isAnchor ?? this.isAnchor,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (odometer.present) {
      map['odometer'] = Variable<int>(odometer.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (pricePerLitre.present) {
      map['price_per_litre'] = Variable<double>(pricePerLitre.value);
    }
    if (gaugeBars.present) {
      map['gauge_bars'] = Variable<int>(gaugeBars.value);
    }
    if (isFull.present) {
      map['is_full'] = Variable<bool>(isFull.value);
    }
    if (isAnchor.present) {
      map['is_anchor'] = Variable<bool>(isAnchor.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('position: $position, ')
          ..write('kind: $kind, ')
          ..write('date: $date, ')
          ..write('odometer: $odometer, ')
          ..write('amount: $amount, ')
          ..write('pricePerLitre: $pricePerLitre, ')
          ..write('gaugeBars: $gaugeBars, ')
          ..write('isFull: $isFull, ')
          ..write('isAnchor: $isAnchor, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $ChainDecisionsTable extends ChainDecisions
    with TableInfo<$ChainDecisionsTable, DecisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChainDecisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _startEntryIdMeta = const VerificationMeta(
    'startEntryId',
  );
  @override
  late final GeneratedColumn<int> startEntryId = GeneratedColumn<int>(
    'start_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endEntryIdMeta = const VerificationMeta(
    'endEntryId',
  );
  @override
  late final GeneratedColumn<int> endEntryId = GeneratedColumn<int>(
    'end_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [startEntryId, endEntryId, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chain_decisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DecisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('start_entry_id')) {
      context.handle(
        _startEntryIdMeta,
        startEntryId.isAcceptableOrUnknown(
          data['start_entry_id']!,
          _startEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startEntryIdMeta);
    }
    if (data.containsKey('end_entry_id')) {
      context.handle(
        _endEntryIdMeta,
        endEntryId.isAcceptableOrUnknown(
          data['end_entry_id']!,
          _endEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endEntryIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {startEntryId, endEntryId};
  @override
  DecisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DecisionRow(
      startEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_entry_id'],
      )!,
      endEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_entry_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $ChainDecisionsTable createAlias(String alias) {
    return $ChainDecisionsTable(attachedDatabase, alias);
  }
}

class DecisionRow extends DataClass implements Insertable<DecisionRow> {
  final int startEntryId;
  final int endEntryId;

  /// 'accept' or 'discard'.
  final String kind;
  const DecisionRow({
    required this.startEntryId,
    required this.endEntryId,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['start_entry_id'] = Variable<int>(startEntryId);
    map['end_entry_id'] = Variable<int>(endEntryId);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  ChainDecisionsCompanion toCompanion(bool nullToAbsent) {
    return ChainDecisionsCompanion(
      startEntryId: Value(startEntryId),
      endEntryId: Value(endEntryId),
      kind: Value(kind),
    );
  }

  factory DecisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DecisionRow(
      startEntryId: serializer.fromJson<int>(json['startEntryId']),
      endEntryId: serializer.fromJson<int>(json['endEntryId']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'startEntryId': serializer.toJson<int>(startEntryId),
      'endEntryId': serializer.toJson<int>(endEntryId),
      'kind': serializer.toJson<String>(kind),
    };
  }

  DecisionRow copyWith({int? startEntryId, int? endEntryId, String? kind}) =>
      DecisionRow(
        startEntryId: startEntryId ?? this.startEntryId,
        endEntryId: endEntryId ?? this.endEntryId,
        kind: kind ?? this.kind,
      );
  DecisionRow copyWithCompanion(ChainDecisionsCompanion data) {
    return DecisionRow(
      startEntryId: data.startEntryId.present
          ? data.startEntryId.value
          : this.startEntryId,
      endEntryId: data.endEntryId.present
          ? data.endEntryId.value
          : this.endEntryId,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DecisionRow(')
          ..write('startEntryId: $startEntryId, ')
          ..write('endEntryId: $endEntryId, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(startEntryId, endEntryId, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecisionRow &&
          other.startEntryId == this.startEntryId &&
          other.endEntryId == this.endEntryId &&
          other.kind == this.kind);
}

class ChainDecisionsCompanion extends UpdateCompanion<DecisionRow> {
  final Value<int> startEntryId;
  final Value<int> endEntryId;
  final Value<String> kind;
  final Value<int> rowid;
  const ChainDecisionsCompanion({
    this.startEntryId = const Value.absent(),
    this.endEntryId = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChainDecisionsCompanion.insert({
    required int startEntryId,
    required int endEntryId,
    required String kind,
    this.rowid = const Value.absent(),
  }) : startEntryId = Value(startEntryId),
       endEntryId = Value(endEntryId),
       kind = Value(kind);
  static Insertable<DecisionRow> custom({
    Expression<int>? startEntryId,
    Expression<int>? endEntryId,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (startEntryId != null) 'start_entry_id': startEntryId,
      if (endEntryId != null) 'end_entry_id': endEntryId,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChainDecisionsCompanion copyWith({
    Value<int>? startEntryId,
    Value<int>? endEntryId,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return ChainDecisionsCompanion(
      startEntryId: startEntryId ?? this.startEntryId,
      endEntryId: endEntryId ?? this.endEntryId,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (startEntryId.present) {
      map['start_entry_id'] = Variable<int>(startEntryId.value);
    }
    if (endEntryId.present) {
      map['end_entry_id'] = Variable<int>(endEntryId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChainDecisionsCompanion(')
          ..write('startEntryId: $startEntryId, ')
          ..write('endEntryId: $endEntryId, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(AppSettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BikeProfilesTable bikeProfiles = $BikeProfilesTable(this);
  late final $LogEntriesTable logEntries = $LogEntriesTable(this);
  late final $ChainDecisionsTable chainDecisions = $ChainDecisionsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bikeProfiles,
    logEntries,
    chainDecisions,
    appSettings,
  ];
}

typedef $$BikeProfilesTableCreateCompanionBuilder =
    BikeProfilesCompanion Function({
      Value<int> id,
      required String model,
      required double tankLitres,
      required int gaugeBars,
      required double expectedKmplMin,
      required double expectedKmplMax,
      required double prefillUncertaintyLitres,
      required double fullUncertaintyLitres,
      required int odometerDigits,
    });
typedef $$BikeProfilesTableUpdateCompanionBuilder =
    BikeProfilesCompanion Function({
      Value<int> id,
      Value<String> model,
      Value<double> tankLitres,
      Value<int> gaugeBars,
      Value<double> expectedKmplMin,
      Value<double> expectedKmplMax,
      Value<double> prefillUncertaintyLitres,
      Value<double> fullUncertaintyLitres,
      Value<int> odometerDigits,
    });

class $$BikeProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $BikeProfilesTable> {
  $$BikeProfilesTableFilterComposer({
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

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get tankLitres => $composableBuilder(
    column: $table.tankLitres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gaugeBars => $composableBuilder(
    column: $table.gaugeBars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get expectedKmplMin => $composableBuilder(
    column: $table.expectedKmplMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get expectedKmplMax => $composableBuilder(
    column: $table.expectedKmplMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get prefillUncertaintyLitres => $composableBuilder(
    column: $table.prefillUncertaintyLitres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fullUncertaintyLitres => $composableBuilder(
    column: $table.fullUncertaintyLitres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get odometerDigits => $composableBuilder(
    column: $table.odometerDigits,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BikeProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BikeProfilesTable> {
  $$BikeProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get tankLitres => $composableBuilder(
    column: $table.tankLitres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gaugeBars => $composableBuilder(
    column: $table.gaugeBars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get expectedKmplMin => $composableBuilder(
    column: $table.expectedKmplMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get expectedKmplMax => $composableBuilder(
    column: $table.expectedKmplMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get prefillUncertaintyLitres => $composableBuilder(
    column: $table.prefillUncertaintyLitres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fullUncertaintyLitres => $composableBuilder(
    column: $table.fullUncertaintyLitres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get odometerDigits => $composableBuilder(
    column: $table.odometerDigits,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BikeProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BikeProfilesTable> {
  $$BikeProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<double> get tankLitres => $composableBuilder(
    column: $table.tankLitres,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gaugeBars =>
      $composableBuilder(column: $table.gaugeBars, builder: (column) => column);

  GeneratedColumn<double> get expectedKmplMin => $composableBuilder(
    column: $table.expectedKmplMin,
    builder: (column) => column,
  );

  GeneratedColumn<double> get expectedKmplMax => $composableBuilder(
    column: $table.expectedKmplMax,
    builder: (column) => column,
  );

  GeneratedColumn<double> get prefillUncertaintyLitres => $composableBuilder(
    column: $table.prefillUncertaintyLitres,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fullUncertaintyLitres => $composableBuilder(
    column: $table.fullUncertaintyLitres,
    builder: (column) => column,
  );

  GeneratedColumn<int> get odometerDigits => $composableBuilder(
    column: $table.odometerDigits,
    builder: (column) => column,
  );
}

class $$BikeProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BikeProfilesTable,
          BikeRow,
          $$BikeProfilesTableFilterComposer,
          $$BikeProfilesTableOrderingComposer,
          $$BikeProfilesTableAnnotationComposer,
          $$BikeProfilesTableCreateCompanionBuilder,
          $$BikeProfilesTableUpdateCompanionBuilder,
          (BikeRow, BaseReferences<_$AppDatabase, $BikeProfilesTable, BikeRow>),
          BikeRow,
          PrefetchHooks Function()
        > {
  $$BikeProfilesTableTableManager(_$AppDatabase db, $BikeProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BikeProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BikeProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BikeProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<double> tankLitres = const Value.absent(),
                Value<int> gaugeBars = const Value.absent(),
                Value<double> expectedKmplMin = const Value.absent(),
                Value<double> expectedKmplMax = const Value.absent(),
                Value<double> prefillUncertaintyLitres = const Value.absent(),
                Value<double> fullUncertaintyLitres = const Value.absent(),
                Value<int> odometerDigits = const Value.absent(),
              }) => BikeProfilesCompanion(
                id: id,
                model: model,
                tankLitres: tankLitres,
                gaugeBars: gaugeBars,
                expectedKmplMin: expectedKmplMin,
                expectedKmplMax: expectedKmplMax,
                prefillUncertaintyLitres: prefillUncertaintyLitres,
                fullUncertaintyLitres: fullUncertaintyLitres,
                odometerDigits: odometerDigits,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String model,
                required double tankLitres,
                required int gaugeBars,
                required double expectedKmplMin,
                required double expectedKmplMax,
                required double prefillUncertaintyLitres,
                required double fullUncertaintyLitres,
                required int odometerDigits,
              }) => BikeProfilesCompanion.insert(
                id: id,
                model: model,
                tankLitres: tankLitres,
                gaugeBars: gaugeBars,
                expectedKmplMin: expectedKmplMin,
                expectedKmplMax: expectedKmplMax,
                prefillUncertaintyLitres: prefillUncertaintyLitres,
                fullUncertaintyLitres: fullUncertaintyLitres,
                odometerDigits: odometerDigits,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BikeProfilesTable, BikeRow>(table),
                  BaseReferences<_$AppDatabase, $BikeProfilesTable, BikeRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BikeProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BikeProfilesTable,
      BikeRow,
      $$BikeProfilesTableFilterComposer,
      $$BikeProfilesTableOrderingComposer,
      $$BikeProfilesTableAnnotationComposer,
      $$BikeProfilesTableCreateCompanionBuilder,
      $$BikeProfilesTableUpdateCompanionBuilder,
      (BikeRow, BaseReferences<_$AppDatabase, $BikeProfilesTable, BikeRow>),
      BikeRow,
      PrefetchHooks Function()
    >;
typedef $$LogEntriesTableCreateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  required int position,
  required String kind,
  required DateTime date,
  Value<int?> odometer,
  Value<double?> amount,
  Value<double?> pricePerLitre,
  Value<int?> gaugeBars,
  Value<bool> isFull,
  Value<bool> isAnchor,
  Value<String> note,
});
typedef $$LogEntriesTableUpdateCompanionBuilder = LogEntriesCompanion Function({
  Value<int> id,
  Value<int> position,
  Value<String> kind,
  Value<DateTime> date,
  Value<int?> odometer,
  Value<double?> amount,
  Value<double?> pricePerLitre,
  Value<int?> gaugeBars,
  Value<bool> isFull,
  Value<bool> isAnchor,
  Value<String> note,
});

class $$LogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableFilterComposer({
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

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerLitre => $composableBuilder(
    column: $table.pricePerLitre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gaugeBars => $composableBuilder(
    column: $table.gaugeBars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFull => $composableBuilder(
    column: $table.isFull,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAnchor => $composableBuilder(
    column: $table.isAnchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableOrderingComposer({
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

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get odometer => $composableBuilder(
    column: $table.odometer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerLitre => $composableBuilder(
    column: $table.pricePerLitre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gaugeBars => $composableBuilder(
    column: $table.gaugeBars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFull => $composableBuilder(
    column: $table.isFull,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAnchor => $composableBuilder(
    column: $table.isAnchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LogEntriesTable> {
  $$LogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get odometer =>
      $composableBuilder(column: $table.odometer, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get pricePerLitre => $composableBuilder(
    column: $table.pricePerLitre,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gaugeBars =>
      $composableBuilder(column: $table.gaugeBars, builder: (column) => column);

  GeneratedColumn<bool> get isFull =>
      $composableBuilder(column: $table.isFull, builder: (column) => column);

  GeneratedColumn<bool> get isAnchor =>
      $composableBuilder(column: $table.isAnchor, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LogEntriesTable,
          LogRow,
          $$LogEntriesTableFilterComposer,
          $$LogEntriesTableOrderingComposer,
          $$LogEntriesTableAnnotationComposer,
          $$LogEntriesTableCreateCompanionBuilder,
          $$LogEntriesTableUpdateCompanionBuilder,
          (LogRow, BaseReferences<_$AppDatabase, $LogEntriesTable, LogRow>),
          LogRow,
          PrefetchHooks Function()
        > {
  $$LogEntriesTableTableManager(_$AppDatabase db, $LogEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int?> odometer = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<double?> pricePerLitre = const Value.absent(),
                Value<int?> gaugeBars = const Value.absent(),
                Value<bool> isFull = const Value.absent(),
                Value<bool> isAnchor = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                position: position,
                kind: kind,
                date: date,
                odometer: odometer,
                amount: amount,
                pricePerLitre: pricePerLitre,
                gaugeBars: gaugeBars,
                isFull: isFull,
                isAnchor: isAnchor,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int position,
                required String kind,
                required DateTime date,
                Value<int?> odometer = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<double?> pricePerLitre = const Value.absent(),
                Value<int?> gaugeBars = const Value.absent(),
                Value<bool> isFull = const Value.absent(),
                Value<bool> isAnchor = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => LogEntriesCompanion.insert(
                id: id,
                position: position,
                kind: kind,
                date: date,
                odometer: odometer,
                amount: amount,
                pricePerLitre: pricePerLitre,
                gaugeBars: gaugeBars,
                isFull: isFull,
                isAnchor: isAnchor,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LogEntriesTable, LogRow>(table),
                  BaseReferences<_$AppDatabase, $LogEntriesTable, LogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LogEntriesTable,
      LogRow,
      $$LogEntriesTableFilterComposer,
      $$LogEntriesTableOrderingComposer,
      $$LogEntriesTableAnnotationComposer,
      $$LogEntriesTableCreateCompanionBuilder,
      $$LogEntriesTableUpdateCompanionBuilder,
      (LogRow, BaseReferences<_$AppDatabase, $LogEntriesTable, LogRow>),
      LogRow,
      PrefetchHooks Function()
    >;
typedef $$ChainDecisionsTableCreateCompanionBuilder =
    ChainDecisionsCompanion Function({
      required int startEntryId,
      required int endEntryId,
      required String kind,
      Value<int> rowid,
    });
typedef $$ChainDecisionsTableUpdateCompanionBuilder =
    ChainDecisionsCompanion Function({
      Value<int> startEntryId,
      Value<int> endEntryId,
      Value<String> kind,
      Value<int> rowid,
    });

class $$ChainDecisionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChainDecisionsTable> {
  $$ChainDecisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get startEntryId => $composableBuilder(
    column: $table.startEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endEntryId => $composableBuilder(
    column: $table.endEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChainDecisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChainDecisionsTable> {
  $$ChainDecisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get startEntryId => $composableBuilder(
    column: $table.startEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endEntryId => $composableBuilder(
    column: $table.endEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChainDecisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChainDecisionsTable> {
  $$ChainDecisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get startEntryId => $composableBuilder(
    column: $table.startEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endEntryId => $composableBuilder(
    column: $table.endEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$ChainDecisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChainDecisionsTable,
          DecisionRow,
          $$ChainDecisionsTableFilterComposer,
          $$ChainDecisionsTableOrderingComposer,
          $$ChainDecisionsTableAnnotationComposer,
          $$ChainDecisionsTableCreateCompanionBuilder,
          $$ChainDecisionsTableUpdateCompanionBuilder,
          (
            DecisionRow,
            BaseReferences<_$AppDatabase, $ChainDecisionsTable, DecisionRow>,
          ),
          DecisionRow,
          PrefetchHooks Function()
        > {
  $$ChainDecisionsTableTableManager(
    _$AppDatabase db,
    $ChainDecisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChainDecisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChainDecisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChainDecisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> startEntryId = const Value.absent(),
                Value<int> endEntryId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChainDecisionsCompanion(
                startEntryId: startEntryId,
                endEntryId: endEntryId,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int startEntryId,
                required int endEntryId,
                required String kind,
                Value<int> rowid = const Value.absent(),
              }) => ChainDecisionsCompanion.insert(
                startEntryId: startEntryId,
                endEntryId: endEntryId,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChainDecisionsTable, DecisionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ChainDecisionsTable,
                    DecisionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChainDecisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChainDecisionsTable,
      DecisionRow,
      $$ChainDecisionsTableFilterComposer,
      $$ChainDecisionsTableOrderingComposer,
      $$ChainDecisionsTableAnnotationComposer,
      $$ChainDecisionsTableCreateCompanionBuilder,
      $$ChainDecisionsTableUpdateCompanionBuilder,
      (
        DecisionRow,
        BaseReferences<_$AppDatabase, $ChainDecisionsTable, DecisionRow>,
      ),
      DecisionRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          SettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, SettingRow>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      SettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BikeProfilesTableTableManager get bikeProfiles =>
      $$BikeProfilesTableTableManager(_db, _db.bikeProfiles);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db, _db.logEntries);
  $$ChainDecisionsTableTableManager get chainDecisions =>
      $$ChainDecisionsTableTableManager(_db, _db.chainDecisions);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
