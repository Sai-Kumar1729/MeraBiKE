import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/data/backup.dart';
import 'package:mera_bike/data/database.dart';
import 'package:mera_bike/data/repository.dart';
import 'package:mera_bike/data/seed.dart';
import 'package:mera_bike/engine/engine.dart';

void main() {
  late AppDatabase db;
  late MileageRepository repo;
  final catalog = parseBikeCatalog(
    File('assets/bikes.json').readAsStringSync(),
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = MileageRepository(db);
  });
  tearDown(() => db.close());

  RefuelEntry fill(double amount, {DateTime? on}) => RefuelEntry(
    id: 'new',
    date: on ?? DateTime(2026, 11, 20),
    amount: amount,
    pricePerLitre: 116,
  );

  test(
    'first launch loads the Glamour and the owner\'s five entries',
    () async {
      await seedOnFirstLaunch(repo, catalog);
      final data = await repo.load();
      expect(data.bike!.model, 'Hero Glamour');
      expect(data.log, hasLength(5));
      expect(data.log.map((e) => e.odometer), [
        83050,
        null,
        null,
        83308,
        83336,
      ]);
      expect((data.log.first as RefuelEntry).note, placeholderDateNote);
      expect(data.settings[SettingKeys.lastPricePerLitre], '116');

      final chain = analyzeLog(data.log, data.bike!).chains.first;
      expect(chain.distanceKm, 258);
      expect(chain.kmpl, closeTo(32.1, 0.05));
    },
  );

  test('seeding runs once, even after the log is emptied', () async {
    await seedOnFirstLaunch(repo, catalog);
    for (final entry in (await repo.load()).log) {
      await repo.deleteEntry(entry.id);
    }
    await seedOnFirstLaunch(repo, catalog);
    expect((await repo.load()).log, isEmpty);
  });

  test('inserting in the middle keeps the order (missed refuel)', () async {
    await seedOnFirstLaunch(repo, catalog);
    var data = await repo.load();
    final chain = analyzeLog(data.log, data.bike!).chains.first;
    final missed = fill(232, on: DateTime(2026, 11, 10));
    await repo.insertEntry(
      missed,
      index: missedRefuelIndex(data.log, chain, missed.date),
    );

    data = await repo.load();
    expect(data.log.map((e) => e.odometer), [
      83050,
      null,
      null,
      null, // the missed refuel, before the closing anchor
      83308,
      83336,
    ]);
    final updated = analyzeLog(data.log, data.bike!).chains.first;
    expect(updated.litres, closeTo((932 + 232) / 116, 1e-9));
  });

  test(
    'deleting closes the gap and drops decisions about that anchor',
    () async {
      await seedOnFirstLaunch(repo, catalog);
      var data = await repo.load();
      final start = data.log[0].id;
      final end = data.log[3].id;
      await repo.saveDecision(
        ChainDecision(
          startEntryId: start,
          endEntryId: end,
          kind: ChainDecisionKind.accept,
        ),
      );
      await repo.deleteEntry(end);
      await repo.insertEntry(fill(100));

      data = await repo.load();
      expect(data.decisions, isEmpty);
      expect(data.log, hasLength(5));
      final positions = await (db.select(db.logEntries)).get();
      expect(positions.map((r) => r.position).toList()..sort(), [
        0,
        1,
        2,
        3,
        4,
      ]);
    },
  );

  test('editing keeps the entry in its place', () async {
    await seedOnFirstLaunch(repo, catalog);
    final data = await repo.load();
    final second = data.log[1] as RefuelEntry;
    await repo.updateEntry(
      RefuelEntry(
        id: second.id,
        date: second.date,
        amount: 420,
        pricePerLitre: 116,
      ),
    );
    final after = await repo.load();
    expect(after.log[1].id, second.id);
    expect((after.log[1] as RefuelEntry).amount, 420);
  });

  test(
    'import replaces everything and keeps ids, so decisions still apply',
    () async {
      await seedOnFirstLaunch(repo, catalog);
      final data = await repo.load();
      final decision = ChainDecision(
        startEntryId: data.log[0].id,
        endEntryId: data.log[3].id,
        kind: ChainDecisionKind.discard,
      );
      final backup = decodeBackup(
        encodeBackup(
          Backup(
            bike: data.bike,
            log: data.log,
            decisions: [decision],
            settings: data.settings,
          ),
          exportedAt: DateTime(2026, 11, 24),
        ),
      );

      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      final fresh = MileageRepository(other);
      await fresh.insertEntry(fill(999)); // replaced by the import
      await fresh.replaceAll(backup);

      final restored = await fresh.load();
      expect(restored.log.map((e) => e.id), data.log.map((e) => e.id));
      final chain = analyzeLog(
        restored.log,
        restored.bike!,
        decisions: restored.decisions,
      ).chains.first;
      expect(chain.status, ChainStatus.discarded);
    },
  );
}
