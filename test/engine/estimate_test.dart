import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/engine/engine.dart';

import 'helpers.dart';

void main() {
  // Three back-to-back 1-bar chains: 225 km/5 L (45), 330 km/6 L (55),
  // 225 km/5 L (45).
  LogBuilder threeChains() => LogBuilder()
    ..barsAnchor('a1', odo: 1000, bars: 1, amount: 100)
    ..fill('m1', 400)
    ..barsAnchor('a2', odo: 1225, bars: 1, amount: 100)
    ..fill('m2', 500)
    ..barsAnchor('a3', odo: 1555, bars: 1, amount: 100)
    ..fill('m3', 400)
    ..barsAnchor('a4', odo: 1780, bars: 1, amount: 100);

  group('overall estimate', () {
    test('is the litres-weighted average of accepted chains', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 1000, bars: 1, amount: 100)
        ..fill('m1', 400)
        ..barsAnchor('a2', odo: 1225, bars: 1, amount: 100)
        ..fill('m2', 500)
        ..barsAnchor('a3', odo: 1555, bars: 1, amount: 100);
      final current = analyzeLog(log.entries, testBike).current!;

      const weighted = (45 * 5 + 55 * 6) / (5 + 6);
      expect(current.chains, hasLength(2));
      expect(current.kmpl, closeTo(weighted, 1e-9));
      expect(current.kmpl, closeTo(555 / 11, 1e-9));
      expect(current.confidence, Confidence.high);
    });

    test('back-to-back chains share anchors, so the band uses one U', () {
      final current = analyzeLog(threeChains().entries, testBike).current!;
      expect(current.uncertaintyLitres, closeTo(0.5, 1e-9));
      expect(current.band.low, closeTo(780 / 16.5, 1e-9));
      expect(current.band.high, closeTo(780 / 15.5, 1e-9));
    });

    test('a gap between accepted chains adds a second U, in quadrature', () {
      final current = analyzeLog(
        threeChains().entries,
        testBike,
        decisions: const [
          ChainDecision(
            startEntryId: 'a2',
            endEntryId: 'a3',
            kind: ChainDecisionKind.discard,
          ),
        ],
      ).current!;
      expect(current.chains.map((c) => c.id), ['a1', 'a3']);
      expect(current.kmpl, closeTo(45, 1e-9));
      expect(current.uncertaintyLitres, closeTo(math.sqrt(0.5), 1e-9));
    });
  });

  group('confidence', () {
    test('<4 L Low, 4–8 L Medium, >8 L High', () {
      expect(Confidence.forLitres(3.99), Confidence.low);
      expect(Confidence.forLitres(4), Confidence.medium);
      expect(Confidence.forLitres(8), Confidence.medium);
      expect(Confidence.forLitres(8.01), Confidence.high);
    });

    test('litres to the next level', () {
      expect(Confidence.litresToNextLevel(1), closeTo(3, 1e-9));
      expect(Confidence.litresToNextLevel(4.2), closeTo(3.8, 1e-9));
      expect(Confidence.litresToNextLevel(9), isNull);
    });
  });

  test('band has no upper bound when litres <= U', () {
    final band = KmplBand.from(
      distanceKm: 20,
      litres: 0.4,
      uncertaintyLitres: 0.5,
    );
    expect(band.low, closeTo(20 / 0.9, 1e-9));
    expect(band.high, isNull);
  });
}
