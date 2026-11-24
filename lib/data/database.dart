import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// The bike profile: one row (id 1).
@DataClassName('BikeRow')
class BikeProfiles extends Table {
  IntColumn get id => integer()();
  TextColumn get model => text()();
  RealColumn get tankLitres => real()();
  IntColumn get gaugeBars => integer()();
  RealColumn get expectedKmplMin => real()();
  RealColumn get expectedKmplMax => real()();
  RealColumn get prefillUncertaintyLitres => real()();
  RealColumn get fullUncertaintyLitres => real()();
  IntColumn get odometerDigits => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Refuels and services in one timeline, ordered by [position].
@DataClassName('LogRow')
class LogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Order in the log, 0-based and gap-free. The engine follows this order.
  IntColumn get position => integer()();

  /// 'refuel' or 'service'.
  TextColumn get kind => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get odometer => integer().nullable()();
  RealColumn get amount => real().nullable()();
  RealColumn get pricePerLitre => real().nullable()();
  IntColumn get gaugeBars => integer().nullable()();
  BoolColumn get isFull => boolean().withDefault(const Constant(false))();
  BoolColumn get isAnchor => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().withDefault(const Constant(''))();
}

/// The user's accept/discard answer for the chain between two anchors.
@DataClassName('DecisionRow')
class ChainDecisions extends Table {
  IntColumn get startEntryId => integer()();
  IntColumn get endEntryId => integer()();

  /// 'accept' or 'discard'.
  TextColumn get kind => text()();

  @override
  Set<Column> get primaryKey => {startEntryId, endEntryId};
}

@DataClassName('SettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [BikeProfiles, LogEntries, ChainDecisions, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The database file in the app's private documents folder.
  factory AppDatabase.onDevice() => AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File('${dir.path}${Platform.pathSeparator}merabike.sqlite'),
      );
    }),
  );

  @override
  int get schemaVersion => 1;
}
