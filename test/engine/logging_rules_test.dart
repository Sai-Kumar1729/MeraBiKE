import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/engine/engine.dart';

import 'helpers.dart';

void main() {
  group('anchor toggle default', () {
    final open1Bar = analyzeLog(
      (LogBuilder()..barsAnchor('a1', odo: 1000, bars: 1, amount: 100)).entries,
      testBike,
    ).openChain;

    test('gauge unknown: cannot be an anchor', () {
      expect(anchorEffect(open1Bar, null), AnchorEffect.notPossible);
    });

    test('no open chain: starts one, on by default', () {
      final effect = anchorEffect(null, const AnchorLevel.bars(1));
      expect(effect, AnchorEffect.startsChain);
      expect(anchorOnByDefault(effect), isTrue);
    });

    test('same level as the open chain: closes it, on by default', () {
      final effect = anchorEffect(open1Bar, const AnchorLevel.bars(1));
      expect(effect, AnchorEffect.closesChain);
      expect(anchorOnByDefault(effect), isTrue);
    });

    test('different level: would break the chain, off by default', () {
      final effect = anchorEffect(open1Bar, const AnchorLevel.full());
      expect(effect, AnchorEffect.breaksChain);
      expect(anchorOnByDefault(effect), isFalse);
    });
  });

  group('missed refuel placement', () {
    // Dates: a1 2 Jan, m1 3 Jan, a2 4 Jan, m2 5 Jan.
    final log =
        (LogBuilder()
              ..barsAnchor('a1', odo: 1000, bars: 1, amount: 100)
              ..fill('m1', 300)
              ..barsAnchor('a2', odo: 1200, bars: 1, amount: 100)
              ..fill('m2', 200))
            .entries;
    final chains = analyzeLog(log, testBike).chains;
    final closed = chains[0];
    final open = chains[1];

    test('goes after the chain entries on or before its date', () {
      expect(missedRefuelIndex(log, closed, DateTime(2026, 1, 3, 18)), 2);
    });

    test('never after the closing anchor, even on a later date', () {
      expect(missedRefuelIndex(log, closed, DateTime(2026, 1, 9)), 2);
    });

    test('never before the start anchor', () {
      expect(missedRefuelIndex(log, closed, DateTime(2025, 12, 1)), 1);
    });

    test('in the open chain it goes in date order', () {
      expect(missedRefuelIndex(log, open, DateTime(2026, 1, 4)), 3);
      expect(missedRefuelIndex(log, open, DateTime(2026, 1, 9)), 4);
    });

    test('the default chain is the last one started on or before the date', () {
      expect(chainForDate(chains, DateTime(2026, 1, 3)), same(closed));
      expect(chainForDate(chains, DateTime(2026, 1, 4)), same(open));
      expect(chainForDate(chains, DateTime(2025, 12, 1)), isNull);
    });

    test('inserting it there adds its litres to that chain', () {
      final withMissed = [...log]
        ..insert(
          missedRefuelIndex(log, closed, DateTime(2026, 1, 3)),
          RefuelEntry(
            id: 'missed',
            date: DateTime(2026, 1, 3),
            amount: 100,
            pricePerLitre: 100,
          ),
        );
      final chain = analyzeLog(withMissed, testBike).chains.first;
      expect(chain.countedFills.map((r) => r.id), ['a1', 'm1', 'missed']);
    });
  });

  group('km left (approximate)', () {
    final log =
        (LogBuilder(price: 116)
              ..barsAnchor('r1', odo: 83050, bars: 1, amount: 116)
              ..fill('r2', 416)
              ..fill('r3', 400)
              ..barsAnchor('r4', odo: 83308, bars: 1, amount: 116)
              ..fill('r5', 160, odo: 83336))
            .entries;
    final glamour = Bike(
      model: 'Hero Glamour',
      tankLitres: 10,
      gaugeBars: 5,
      expectedKmplMin: 25,
      expectedKmplMax: 70,
    );

    test('anchor fuel + fills since − fuel used, at the current km/L', () {
      final analysis = analyzeLog(log, glamour);
      final estimate = estimateKmLeft(analysis, glamour)!;
      final kmpl = analysis.current!.kmpl;
      const atAnchor = 1 * 10 / 5; // 1 bar of a 5-bar, 10 L gauge
      final fuel = atAnchor + (116 + 160) / 116 - 28 / kmpl;
      expect(estimate.litresAtAnchor, atAnchor);
      expect(estimate.fuelLitres, closeTo(fuel, 1e-9));
      expect(estimate.kmLeft, closeTo(fuel * kmpl, 1e-9));
      expect(estimate.kmLeft, closeTo(112.6, 0.1));
      expect(estimate.kmplIsModelGuess, isFalse);
      expect(estimate.asOfOdometer, 83336);
    });

    test('before any result it uses the middle of the expected range', () {
      final analysis = analyzeLog(log.sublist(3), glamour);
      final estimate = estimateKmLeft(analysis, glamour)!;
      expect(estimate.kmplUsed, 47.5);
      expect(estimate.kmplIsModelGuess, isTrue);
    });

    test('no open chain: no estimate', () {
      final analysis = analyzeLog(log.sublist(0, 3), glamour);
      expect(analysis.openChain, isNotNull);
      final none = analyzeLog(const [], glamour);
      expect(estimateKmLeft(none, glamour), isNull);
    });
  });
}
