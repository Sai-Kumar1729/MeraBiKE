import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/app/app_state.dart';
import 'package:mera_bike/data/auto_backup.dart';
import 'package:mera_bike/data/backup.dart';
import 'package:mera_bike/data/database.dart';
import 'package:mera_bike/data/repository.dart';
import 'package:mera_bike/data/seed.dart';
import 'package:mera_bike/engine/engine.dart';

import '../support/fake_bridge.dart';

/// The Phase 2 (schema 1) tables, as an installed app would have them.
const _schema1 = '''
CREATE TABLE "bike_profiles" ("id" INTEGER NOT NULL, "model" TEXT NOT NULL,
  "tank_litres" REAL NOT NULL, "gauge_bars" INTEGER NOT NULL,
  "expected_kmpl_min" REAL NOT NULL, "expected_kmpl_max" REAL NOT NULL,
  "prefill_uncertainty_litres" REAL NOT NULL,
  "full_uncertainty_litres" REAL NOT NULL, "odometer_digits" INTEGER NOT NULL,
  PRIMARY KEY ("id"));
CREATE TABLE "log_entries" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  "position" INTEGER NOT NULL, "kind" TEXT NOT NULL, "date" INTEGER NOT NULL,
  "odometer" INTEGER NULL, "amount" REAL NULL, "price_per_litre" REAL NULL,
  "gauge_bars" INTEGER NULL,
  "is_full" INTEGER NOT NULL DEFAULT 0 CHECK ("is_full" IN (0, 1)),
  "is_anchor" INTEGER NOT NULL DEFAULT 0 CHECK ("is_anchor" IN (0, 1)),
  "note" TEXT NOT NULL DEFAULT '');
CREATE TABLE "chain_decisions" ("start_entry_id" INTEGER NOT NULL,
  "end_entry_id" INTEGER NOT NULL, "kind" TEXT NOT NULL,
  PRIMARY KEY ("start_entry_id", "end_entry_id"));
CREATE TABLE "app_settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL,
  PRIMARY KEY ("key"));
INSERT INTO "log_entries" ("position", "kind", "date", "odometer", "amount",
  "price_per_litre", "gauge_bars", "is_full", "is_anchor", "note")
  VALUES (0, 'refuel', 1761969600, 83050, 116.0, 116.0, 1, 0, 1, 'kept');
PRAGMA user_version = 1;
''';

void main() {
  final catalog = parseBikeCatalog(
    File('assets/bikes.json').readAsStringSync(),
  );

  RefuelEntry refuel({FuelGrade? grade, DateTime? on}) => RefuelEntry(
    id: 'new',
    date: on ?? DateTime(2026, 11, 24),
    amount: 100,
    pricePerLitre: 116,
    grade: grade,
  );

  group('database', () {
    test('a schema-1 database upgrades in place and keeps its data', () async {
      final db = AppDatabase(
        NativeDatabase.memory(setup: (raw) => raw.execute(_schema1)),
      );
      addTearDown(db.close);
      final repo = MileageRepository(db);

      final before = (await repo.load()).log.single as RefuelEntry;
      expect(before.note, 'kept');
      expect(before.odometer, 83050);
      expect(before.grade, isNull);

      await repo.insertEntry(refuel(grade: FuelGrade.premium));
      final after = (await repo.load()).log.last as RefuelEntry;
      expect(after.grade, FuelGrade.premium);

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.data.values.single, 2);
    });
  });

  group('backup file', () {
    test('keeps the fuel grade, and older files without it still load', () {
      final text = encodeBackup(
        Backup(
          bike: null,
          log: [
            RefuelEntry(
              id: '1',
              date: DateTime(2026, 11, 1),
              amount: 116,
              pricePerLitre: 116,
              grade: FuelGrade.lowEthanol,
            ),
          ],
          decisions: const [],
          settings: const {},
        ),
        exportedAt: DateTime(2026, 11, 24),
      );
      final back = decodeBackup(text).log.single as RefuelEntry;
      expect(back.grade, FuelGrade.lowEthanol);

      final old = decodeBackup(text.replaceFirst('"grade": "lowEthanol",', ''));
      expect((old.log.single as RefuelEntry).grade, isNull);
    });
  });

  group('auto-backup files', () {
    test('one file per day', () {
      expect(
        autoBackupFileName(DateTime(2026, 3, 7, 22)),
        'merabike-auto-2026-03-07.json',
      );
    });

    test('prunes our oldest files beyond seven and nothing else', () {
      final names = [
        for (var d = 1; d <= 9; d++) autoBackupFileName(DateTime(2026, 11, d)),
        'notes.txt',
        'merabike-backup-2026-11-01.json', // a manual export
      ];
      expect(autoBackupsToDelete(names), [
        'merabike-auto-2026-11-01.json',
        'merabike-auto-2026-11-02.json',
      ]);
      expect(autoBackupsToDelete(names.take(7)), isEmpty);
    });
  });

  group('app state', () {
    late AppDatabase db;
    late FakeBridge bridge;
    late AppState state;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final repo = MileageRepository(db);
      await seedOnFirstLaunch(repo, catalog);
      bridge = FakeBridge();
      state = AppState(
        repo,
        catalog,
        bridge: bridge,
        clock: () => DateTime(2026, 11, 24, 10, 30),
      );
      await state.load();
    });
    tearDown(() => db.close());

    test('turning on auto-backup writes today\'s file at once', () async {
      expect(state.autoBackupOn, isFalse);
      expect(await state.chooseBackupFolder(), isTrue);
      expect(bridge.files.keys, ['merabike-auto-2026-11-24.json']);
      expect(decodeBackup(bridge.files.values.single).log, hasLength(5));
      expect(state.lastBackupAt, DateTime(2026, 11, 24, 10, 30));
      expect(state.backupFolderName, 'MeraBiKE');
    });

    test(
      'every change is backed up; old days are pruned, other files kept',
      () async {
        bridge.files.addAll({
          for (var d = 1; d <= 8; d++)
            autoBackupFileName(DateTime(2026, 11, d)): '{}',
          'notes.txt': 'mine',
        });
        await state.chooseBackupFolder();
        final ours = bridge.files.keys.where(
          (n) => n.startsWith('merabike-auto'),
        );
        expect(ours, hasLength(7));
        expect(bridge.files, contains('notes.txt'));
        expect(bridge.files, isNot(contains('merabike-auto-2026-11-01.json')));

        await state.addRefuel(refuel(grade: FuelGrade.premium));
        final today = decodeBackup(
          bridge.files['merabike-auto-2026-11-24.json']!,
        );
        expect(today.log, hasLength(6));
      },
    );

    test(
      'a failed backup is recorded, and the change is still saved',
      () async {
        await state.chooseBackupFolder();
        bridge.failWrites = true;
        await state.addRefuel(refuel());
        expect(state.log, hasLength(6));
        expect(state.lastBackupError, contains('Pick the folder again'));

        bridge.failWrites = false;
        await state.backupNow();
        expect(state.lastBackupError, isNull);
      },
    );

    test('exports leave out this phone\'s folder; imports keep it', () async {
      await state.chooseBackupFolder();
      final json = state.exportJson(DateTime(2026, 11, 24));
      final settings = decodeBackup(json).settings;
      for (final key in SettingKeys.deviceOnly) {
        expect(settings, isNot(contains(key)), reason: key);
      }
      await state.importJson(json);
      expect(state.autoBackupOn, isTrue);
      expect(state.log, hasLength(5));
    });

    test('reminders are saved, shown, and cleared', () async {
      await state.saveReminders(
        ReminderSettings(
          serviceEveryKm: 3000,
          insuranceExpiry: DateTime(2026, 12, 4),
        ),
      );
      expect(state.reminderSettings.serviceEveryKm, 3000);
      expect(state.reminderSettings.insuranceExpiry, DateTime(2026, 12, 4));
      final reminders = state.reminders;
      expect(reminders.map((r) => r.kind), [
        ReminderKind.service,
        ReminderKind.insurance,
      ]);
      expect(reminders.first.needsLastService, isTrue);
      expect(reminders.last.state, DueState.dueSoon);

      await state.saveReminders(const ReminderSettings());
      expect(state.reminders, isEmpty);
    });

    test('the last fuel grade used is the next default', () async {
      expect(state.lastFuelGrade, FuelGrade.regular);
      await state.addRefuel(refuel(grade: FuelGrade.lowEthanol));
      expect(state.lastFuelGrade, FuelGrade.lowEthanol);
      await state.addRefuel(refuel());
      expect(state.lastFuelGrade, FuelGrade.lowEthanol, reason: '"Not sure"');
    });
  });
}
