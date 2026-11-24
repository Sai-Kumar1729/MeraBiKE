import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/data/backup.dart';
import 'package:mera_bike/engine/engine.dart';

void main() {
  final bike = Bike(
    model: 'Hero Glamour',
    tankLitres: 10,
    gaugeBars: 5,
    expectedKmplMin: 40,
    expectedKmplMax: 65,
    prefillUncertaintyLitres: 0.6,
    odometerDigits: 6,
  );
  final log = <LogEntry>[
    RefuelEntry(
      id: '1',
      date: DateTime(2026, 11, 1, 9),
      odometer: 83050,
      amount: 116,
      pricePerLitre: 116,
      gaugeBars: 1,
      isAnchor: true,
      note: 'placeholder date',
    ),
    RefuelEntry(
      id: '2',
      date: DateTime(2026, 11, 4),
      amount: 416.5,
      pricePerLitre: 116,
    ),
    ServiceEvent(
      id: '7',
      date: DateTime(2026, 11, 5),
      odometer: 83200,
      note: 'oil change',
    ),
    RefuelEntry(
      id: '3',
      date: DateTime(2026, 11, 6),
      odometer: 83250,
      amount: 500,
      pricePerLitre: 116,
      isFull: true,
      isAnchor: true,
    ),
  ];
  const decisions = [
    ChainDecision(
      startEntryId: '1',
      endEntryId: '3',
      kind: ChainDecisionKind.accept,
    ),
  ];

  test('export then import gives back the same data', () {
    final text = encodeBackup(
      Backup(
        bike: bike,
        log: log,
        decisions: decisions,
        settings: const {'lastPricePerLitre': '116.0'},
      ),
      exportedAt: DateTime(2026, 11, 24),
    );
    final back = decodeBackup(text);

    expect(back.bike!.odometerDigits, 6);
    expect(back.bike!.prefillUncertaintyLitres, 0.6);
    expect(back.log.map((e) => e.id), ['1', '2', '7', '3']);
    final first = back.log[0] as RefuelEntry;
    expect(first.odometer, 83050);
    expect(first.isAnchor, isTrue);
    expect(first.gaugeBars, 1);
    expect(first.note, 'placeholder date');
    expect((back.log[1] as RefuelEntry).amount, 416.5);
    expect((back.log[2] as ServiceEvent).note, 'oil change');
    expect((back.log[3] as RefuelEntry).isFull, isTrue);
    expect(back.log[0].date, DateTime(2026, 11, 1, 9));
    expect(back.decisions.single.kind, ChainDecisionKind.accept);
    expect(back.settings, {'lastPricePerLitre': '116.0'});
  });

  test('a file that is not a backup is refused with a clear message', () {
    expect(
      () => decodeBackup('not json'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'This file is not valid JSON.',
        ),
      ),
    );
    expect(
      () => decodeBackup('{"hello": 1}'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('not a MeraBiKE backup'),
        ),
      ),
    );
  });

  test('a damaged backup is refused, not half-read', () {
    final text = encodeBackup(
      Backup(bike: bike, log: log, decisions: decisions, settings: const {}),
      exportedAt: DateTime(2026, 11, 24),
    ).replaceFirst('"pricePerLitre": 116.0', '"pricePerLitre": 0');
    expect(
      () => decodeBackup(text),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('invalid value'),
        ),
      ),
    );
  });

  test('a backup from a newer app version is refused', () {
    expect(
      () => decodeBackup('{"format": "merabike-backup", "version": 99}'),
      throwsFormatException,
    );
  });
}
