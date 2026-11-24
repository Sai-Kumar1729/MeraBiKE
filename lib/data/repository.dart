import 'package:drift/drift.dart';

import '../engine/engine.dart';
import 'backup.dart';
import 'database.dart';

/// Setting keys.
abstract final class SettingKeys {
  static const lastPricePerLitre = 'lastPricePerLitre';
  static const lastFuelGrade = 'lastFuelGrade';
  static const onboardingDone = 'onboardingDone';
  static const seeded = 'seeded';

  // Reminders. Dates are stored as yyyy-mm-dd.
  static const serviceEveryKm = 'serviceEveryKm';
  static const serviceEveryDays = 'serviceEveryDays';
  static const insuranceExpiry = 'insuranceExpiry';
  static const pucExpiry = 'pucExpiry';

  // Automatic backup.
  static const backupFolderUri = 'backupFolderUri';
  static const backupFolderName = 'backupFolderName';
  static const lastBackupAt = 'lastBackupAt';
  static const lastBackupError = 'lastBackupError';

  /// Settings that belong to this phone (a folder permission is only valid
  /// on the device that granted it), so they never go into backup files.
  static const deviceOnly = {
    backupFolderUri,
    backupFolderName,
    lastBackupAt,
    lastBackupError,
  };
}

/// Everything stored, as engine types. Entry ids are database ids as strings.
class StoredData {
  const StoredData({
    required this.bike,
    required this.log,
    required this.decisions,
    required this.settings,
  });

  final Bike? bike;
  final List<LogEntry> log;
  final List<ChainDecision> decisions;
  final Map<String, String> settings;
}

/// Reads and writes the database in engine terms.
class MileageRepository {
  MileageRepository(this.db);

  final AppDatabase db;

  Future<StoredData> load() async {
    final bikeRow = await (db.select(
      db.bikeProfiles,
    )..where((b) => b.id.equals(1))).getSingleOrNull();
    final rows = await (db.select(
      db.logEntries,
    )..orderBy([(e) => OrderingTerm.asc(e.position)])).get();
    final decisions = await db.select(db.chainDecisions).get();
    final settings = await db.select(db.appSettings).get();
    return StoredData(
      bike: bikeRow == null ? null : _bikeFromRow(bikeRow),
      log: [for (final row in rows) _entryFromRow(row)],
      decisions: [
        for (final d in decisions)
          ChainDecision(
            startEntryId: '${d.startEntryId}',
            endEntryId: '${d.endEntryId}',
            kind: ChainDecisionKind.values.byName(d.kind),
          ),
      ],
      settings: {for (final s in settings) s.key: s.value},
    );
  }

  Future<void> saveBike(Bike bike) =>
      db.into(db.bikeProfiles).insertOnConflictUpdate(_bikeCompanion(bike));

  /// Inserts [entry] at [index] in the log (the end if null) and returns its
  /// new id. The id on [entry] is ignored.
  Future<int> insertEntry(LogEntry entry, {int? index}) =>
      db.transaction(() async {
        final count = await _count();
        final at = (index ?? count).clamp(0, count);
        await db.customUpdate(
          'UPDATE log_entries SET position = position + 1 WHERE position >= ?',
          variables: [Variable.withInt(at)],
          updates: {db.logEntries},
        );
        return db
            .into(db.logEntries)
            .insert(_entryCompanion(entry).copyWith(position: Value(at)));
      });

  /// Saves new values for an existing entry; its place in the log stays.
  Future<void> updateEntry(LogEntry entry) =>
      (db.update(db.logEntries)..where((e) => e.id.equals(int.parse(entry.id))))
          .write(_entryCompanion(entry));

  /// Deletes an entry, closes the gap, and drops decisions that named it.
  Future<void> deleteEntry(String id) => db.transaction(() async {
    final key = int.parse(id);
    final row = await (db.select(
      db.logEntries,
    )..where((e) => e.id.equals(key))).getSingleOrNull();
    if (row == null) return;
    await (db.delete(db.logEntries)..where((e) => e.id.equals(key))).go();
    await db.customUpdate(
      'UPDATE log_entries SET position = position - 1 WHERE position > ?',
      variables: [Variable.withInt(row.position)],
      updates: {db.logEntries},
    );
    await (db.delete(db.chainDecisions)
          ..where((d) => d.startEntryId.equals(key) | d.endEntryId.equals(key)))
        .go();
  });

  Future<void> saveDecision(ChainDecision decision) => db
      .into(db.chainDecisions)
      .insertOnConflictUpdate(
        ChainDecisionsCompanion.insert(
          startEntryId: int.parse(decision.startEntryId),
          endEntryId: int.parse(decision.endEntryId),
          kind: decision.kind.name,
        ),
      );

  Future<void> clearDecision(String startEntryId, String endEntryId) =>
      (db.delete(db.chainDecisions)..where(
            (d) =>
                d.startEntryId.equals(int.parse(startEntryId)) &
                d.endEntryId.equals(int.parse(endEntryId)),
          ))
          .go();

  Future<void> setSetting(String key, String value) => db
      .into(db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );

  Future<void> removeSetting(String key) =>
      (db.delete(db.appSettings)..where((s) => s.key.equals(key))).go();

  /// Replaces everything with [backup], keeping its entry ids so decisions
  /// still point at the right anchors. All or nothing.
  Future<void> replaceAll(Backup backup) => db.transaction(() async {
    await db.delete(db.chainDecisions).go();
    await db.delete(db.logEntries).go();
    await db.delete(db.bikeProfiles).go();
    await db.delete(db.appSettings).go();
    final bike = backup.bike;
    if (bike != null) await saveBike(bike);
    for (final (i, entry) in backup.log.indexed) {
      await db
          .into(db.logEntries)
          .insert(
            _entryCompanion(entry)
                .copyWith(id: Value(int.parse(entry.id)), position: Value(i)),
          );
    }
    for (final decision in backup.decisions) {
      await saveDecision(decision);
    }
    for (final MapEntry(:key, :value) in backup.settings.entries) {
      await setSetting(key, value);
    }
  });

  Future<int> _count() async {
    final count = db.logEntries.id.count();
    final row = await (db.selectOnly(
      db.logEntries,
    )..addColumns([count])).getSingle();
    return row.read(count)!;
  }
}

Bike _bikeFromRow(BikeRow row) => Bike(
  model: row.model,
  tankLitres: row.tankLitres,
  gaugeBars: row.gaugeBars,
  expectedKmplMin: row.expectedKmplMin,
  expectedKmplMax: row.expectedKmplMax,
  prefillUncertaintyLitres: row.prefillUncertaintyLitres,
  fullUncertaintyLitres: row.fullUncertaintyLitres,
  odometerDigits: row.odometerDigits,
);

BikeProfilesCompanion _bikeCompanion(Bike bike) => BikeProfilesCompanion(
  id: const Value(1),
  model: Value(bike.model),
  tankLitres: Value(bike.tankLitres),
  gaugeBars: Value(bike.gaugeBars),
  expectedKmplMin: Value(bike.expectedKmplMin),
  expectedKmplMax: Value(bike.expectedKmplMax),
  prefillUncertaintyLitres: Value(bike.prefillUncertaintyLitres),
  fullUncertaintyLitres: Value(bike.fullUncertaintyLitres),
  odometerDigits: Value(bike.odometerDigits),
);

LogEntry _entryFromRow(LogRow row) => switch (row.kind) {
  'service' => ServiceEvent(
    id: '${row.id}',
    date: row.date,
    odometer: row.odometer!,
    note: row.note,
  ),
  _ => RefuelEntry(
    id: '${row.id}',
    date: row.date,
    odometer: row.odometer,
    amount: row.amount!,
    pricePerLitre: row.pricePerLitre!,
    gaugeBars: row.gaugeBars,
    isFull: row.isFull,
    isAnchor: row.isAnchor,
    grade: _grade(row.fuelGrade),
    note: row.note,
  ),
};

/// Unknown names (say, from a newer app version) read as "not recorded".
FuelGrade? _grade(String? name) {
  for (final grade in FuelGrade.values) {
    if (grade.name == name) return grade;
  }
  return null;
}

/// Every column except id and position.
LogEntriesCompanion _entryCompanion(LogEntry entry) => switch (entry) {
  RefuelEntry() => LogEntriesCompanion(
    kind: const Value('refuel'),
    date: Value(entry.date),
    odometer: Value(entry.odometer),
    amount: Value(entry.amount),
    pricePerLitre: Value(entry.pricePerLitre),
    gaugeBars: Value(entry.gaugeBars),
    isFull: Value(entry.isFull),
    isAnchor: Value(entry.isAnchor),
    fuelGrade: Value(entry.grade?.name),
    note: Value(entry.note),
  ),
  ServiceEvent() => LogEntriesCompanion(
    kind: const Value('service'),
    date: Value(entry.date),
    odometer: Value(entry.odometer),
    amount: const Value(null),
    pricePerLitre: const Value(null),
    gaugeBars: const Value(null),
    isFull: const Value(false),
    isAnchor: const Value(false),
    fuelGrade: const Value(null),
    note: Value(entry.note),
  ),
};
