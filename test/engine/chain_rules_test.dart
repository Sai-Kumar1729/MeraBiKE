import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/engine/engine.dart';

import 'helpers.dart';

void main() {
  group('full-to-full', () {
    LogBuilder fullToFull() => LogBuilder()
      ..fullAnchor('f1', odo: 20000, amount: 500)
      ..fill('m1', 300)
      ..fullAnchor('f2', odo: 20300, amount: 300);

    test('start fill not counted, end fill counted, U = 0.15 L', () {
      final chain = analyzeLog(fullToFull().entries, testBike).chains.first;
      expect(chain.status, ChainStatus.closed);
      expect(chain.level, const AnchorLevel.full());
      expect(ids(chain.countedFills), ['m1', 'f2']);
      expect(chain.litres, closeTo(6, 1e-9));
      expect(chain.distanceKm, 300);
      expect(chain.kmpl, closeTo(50, 1e-9));
      const u = math.sqrt2 * 0.15; // two FULL readings at ±0.15 L each
      expect(chain.uncertaintyLitres, closeTo(u, 1e-9));
      expect(chain.band!.low, closeTo(300 / (6 + u), 1e-9));
      expect(chain.band!.high, closeTo(300 / (6 - u), 1e-9));
      expect(chain.confidence, Confidence.medium);
    });

    test('the closing FULL anchor opens the next full chain at 0 L', () {
      final next = analyzeLog(fullToFull().entries, testBike).chains[1];
      expect(next.status, ChainStatus.open);
      expect(next.start.id, 'f2');
      expect(next.litres, 0);
    });

    test('a bars anchor after a FULL anchor breaks the full chain', () {
      final log = fullToFull()
        ..fill('m2', 200)
        ..barsAnchor('a1', odo: 20450, bars: 1, amount: 100);
      final chains = analyzeLog(log.entries, testBike).chains;
      expect(chains[1].status, ChainStatus.broken);
      expect(chains[1].breakReason, BreakReason.levelChanged);
      expect(chains[1].brokenBy?.id, 'a1');
      expect(ids(chains[1].refuels), ['f2', 'm2']);
      expect(chains[2].start.id, 'a1');
      expect(chains[2].status, ChainStatus.open);
    });
  });

  group('service events', () {
    test('a service ends the open chain without a result', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 1000, bars: 1, amount: 200)
        ..fill('m1', 300)
        ..service('s1', odo: 1150, note: 'oil change')
        ..fill('m2', 150)
        ..barsAnchor('a2', odo: 1200, bars: 1, amount: 100)
        ..fill('m3', 400)
        ..barsAnchor('a3', odo: 1500, bars: 1, amount: 100);
      final analysis = analyzeLog(log.entries, testBike);

      final broken = analysis.chains[0];
      expect(broken.status, ChainStatus.broken);
      expect(broken.breakReason, BreakReason.service);
      expect(broken.brokenBy?.id, 's1');
      expect(broken.end, isNull);
      expect(broken.kmpl, isNull);
      expect(broken.litres, closeTo(5, 1e-9), reason: 'logged so far');

      expect(ids(analysis.unchained), ['m2']);
      final after = analysis.chains[1];
      expect(after.status, ChainStatus.closed);
      expect(ids(after.countedFills), ['a2', 'm3']);
      expect(after.kmpl, closeTo(60, 1e-9));

      expect(analysis.periods, hasLength(2));
      expect(analysis.periods[0].estimate, isNull);
      expect(analysis.periods[1].startedBy?.id, 's1');
      expect(analysis.current!.kmpl, closeTo(60, 1e-9));
    });

    test('results before and after a service are never averaged', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 1000, bars: 1, amount: 100)
        ..fill('m1', 400)
        ..barsAnchor('a2', odo: 1225, bars: 1, amount: 100) // 225 km / 5 L
        ..service('s1', odo: 1250)
        ..barsAnchor('a3', odo: 1300, bars: 1, amount: 100)
        ..fill('m2', 400)
        ..barsAnchor('a4', odo: 1600, bars: 1, amount: 100); // 300 km / 5 L
      final analysis = analyzeLog(log.entries, testBike);

      expect(analysis.periods[0].estimate!.kmpl, closeTo(45, 1e-9));
      expect(analysis.current!.kmpl, closeTo(60, 1e-9));
      expect(analysis.current!.chains.map((c) => c.id), [
        'a3',
      ], reason: 'not 52.5 km/L, the cross-service average');
      expect(analysis.chains[1].breakReason, BreakReason.service);
    });
  });

  group('plausibility fence (40–70 km/L)', () {
    // 400 km on 4 L = 100 km/L: a refuel is missing.
    LogBuilder missedRefuel() => LogBuilder()
      ..barsAnchor('a1', odo: 10000, bars: 1, amount: 100)
      ..fill('m1', 300)
      ..barsAnchor('a2', odo: 10400, bars: 1, amount: 100);

    test('above the range: flagged, and not in the estimate', () {
      final analysis = analyzeLog(missedRefuel().entries, testBike);
      final chain = analysis.chains.first;
      expect(chain.status, ChainStatus.flagged);
      expect(chain.plausibility, Plausibility.aboveRange);
      expect(chain.kmpl, closeTo(100, 1e-9));
      expect(analysis.current, isNull);
    });

    test('"Missed a refuel?": adding the amount brings it back in range', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 10000, bars: 1, amount: 100)
        ..fill('m1', 300)
        ..fill('missed', 400) // amount + date only
        ..barsAnchor('a2', odo: 10400, bars: 1, amount: 100);
      final chain = analyzeLog(log.entries, testBike).chains.first;
      expect(chain.status, ChainStatus.closed);
      expect(chain.kmpl, closeTo(50, 1e-9));
    });

    test('"Bike may need service": accepted, so it counts', () {
      final analysis = analyzeLog(
        missedRefuel().entries,
        testBike,
        decisions: const [
          ChainDecision(
            startEntryId: 'a1',
            endEntryId: 'a2',
            kind: ChainDecisionKind.accept,
          ),
        ],
      );
      final chain = analysis.chains.first;
      expect(chain.status, ChainStatus.closed);
      expect(chain.plausibility, Plausibility.aboveRange);
      expect(chain.decision, ChainDecisionKind.accept);
      expect(analysis.current!.kmpl, closeTo(100, 1e-9));
    });

    test('"Discard chain": discarded, never counted', () {
      final analysis = analyzeLog(
        missedRefuel().entries,
        testBike,
        decisions: const [
          ChainDecision(
            startEntryId: 'a1',
            endEntryId: 'a2',
            kind: ChainDecisionKind.discard,
          ),
        ],
      );
      expect(analysis.chains.first.status, ChainStatus.discarded);
      expect(analysis.current, isNull);
    });

    test('a decision for different anchors does not apply', () {
      final chain = analyzeLog(
        missedRefuel().entries,
        testBike,
        decisions: const [
          ChainDecision(
            startEntryId: 'a1',
            endEntryId: 'deleted',
            kind: ChainDecisionKind.discard,
          ),
        ],
      ).chains.first;
      expect(chain.status, ChainStatus.flagged);
    });

    test('below the range is flagged too', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 10000, bars: 1, amount: 100)
        ..fill('m1', 900)
        ..barsAnchor('a2', odo: 10200, bars: 1, amount: 100);
      final chain = analyzeLog(log.entries, testBike).chains.first;
      expect(chain.status, ChainStatus.flagged);
      expect(chain.plausibility, Plausibility.belowRange);
      expect(chain.kmpl, closeTo(20, 1e-9));
    });
  });

  group('missing end anchor', () {
    test('the chain stays open with litres so far and no result', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 5000, bars: 1, amount: 200)
        ..fill('m1', 300)
        // Gauge read at 1 bar but not marked as an anchor: does not close.
        ..fill('m2', 250, odo: 5120, bars: 1);
      final analysis = analyzeLog(log.entries, testBike);

      expect(analysis.chains, hasLength(1));
      final chain = analysis.openChain!;
      expect(chain.end, isNull);
      expect(ids(chain.countedFills), ['a1', 'm1', 'm2']);
      expect(chain.litres, closeTo(7.5, 1e-9));
      expect(chain.distanceKm, 120);
      expect(chain.kmpl, isNull);
      expect(chain.band, isNull);
      expect(chain.confidence, Confidence.medium);
      expect(Confidence.litresToNextLevel(chain.litres), closeTo(0.5, 1e-9));
      expect(analysis.current, isNull);
    });
  });

  group('anchor at a different level', () {
    test('breaks the open chain and starts a new one at its level', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 1000, bars: 1, amount: 100)
        ..fill('m1', 200)
        ..barsAnchor('b1', odo: 1100, bars: 2, amount: 150)
        ..fill('m2', 200)
        ..barsAnchor('b2', odo: 1250, bars: 2, amount: 100);
      final chains = analyzeLog(log.entries, testBike).chains;

      expect(chains[0].status, ChainStatus.broken);
      expect(chains[0].breakReason, BreakReason.levelChanged);
      expect(chains[0].brokenBy?.id, 'b1');
      expect(ids(chains[0].refuels), ['a1', 'm1']);

      expect(chains[1].level, const AnchorLevel.bars(2));
      expect(chains[1].status, ChainStatus.closed);
      expect(ids(chains[1].countedFills), ['b1', 'm2']);
      expect(chains[1].kmpl, closeTo(150 / 3.5, 1e-9));
    });
  });

  group('data problems', () {
    test('closing odometer below the start: broken, and reported', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 5000, bars: 1, amount: 100)
        ..barsAnchor('a2', odo: 4990, bars: 1, amount: 100);
      final analysis = analyzeLog(log.entries, testBike);
      expect(analysis.chains[0].status, ChainStatus.broken);
      expect(analysis.chains[0].breakReason, BreakReason.odometerNotIncreasing);
      expect(analysis.chains[0].end?.id, 'a2');
      expect(analysis.chains[1].start.id, 'a2');
      expect(analysis.issues.single.kind, IssueKind.odometerWentBackwards);
      expect(analysis.issues.single.entryId, 'a2');
    });

    test('same odometer at both anchors: broken, no division by zero', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 5000, bars: 1, amount: 100)
        ..barsAnchor('a2', odo: 5000, bars: 1, amount: 100);
      final chain = analyzeLog(log.entries, testBike).chains[0];
      expect(chain.status, ChainStatus.broken);
      expect(chain.breakReason, BreakReason.odometerNotIncreasing);
      expect(chain.kmpl, isNull);
    });

    test('no fuel counted (₹0 reading-only anchors): broken', () {
      final log = LogBuilder()
        ..barsAnchor('a1', odo: 1000, bars: 1, amount: 0)
        ..barsAnchor('a2', odo: 1100, bars: 1, amount: 0);
      final chain = analyzeLog(log.entries, testBike).chains[0];
      expect(chain.status, ChainStatus.broken);
      expect(chain.breakReason, BreakReason.noFuelCounted);
    });

    test('refuels before the first anchor are unchained', () {
      final log = LogBuilder()
        ..fill('m1', 100)
        ..fill('m2', 200)
        ..barsAnchor('a1', odo: 1000, bars: 1, amount: 100);
      final analysis = analyzeLog(log.entries, testBike);
      expect(ids(analysis.unchained), ['m1', 'm2']);
      expect(analysis.chains.single.start.id, 'a1');
    });

    test(
      'dates out of order, too many bars, or an impossible fill are reported',
      () {
        final log = <LogEntry>[
          RefuelEntry(
            id: 'x1',
            date: DateTime(2026, 5, 10),
            amount: 100,
            pricePerLitre: 100,
          ),
          RefuelEntry(
            id: 'x2',
            date: DateTime(2026, 5, 8),
            amount: 100,
            pricePerLitre: 100,
            gaugeBars: 7,
          ),
          RefuelEntry(
            id: 'x3',
            date: DateTime(2026, 5, 11),
            amount: 1100, // 11 L into a 10 L tank
            pricePerLitre: 100,
          ),
        ];
        final issues = analyzeLog(log, testBike).issues;
        expect(
          [for (final i in issues) '${i.kind.name}@${i.entryId}'],
          [
            'dateWentBackwards@x2',
            'gaugeAboveBikeBars@x2',
            'fillExceedsTank@x3',
          ],
        );
      },
    );

    test('invalid entries are rejected when created', () {
      final date = DateTime(2026, 1, 1);
      // An anchor without an odometer.
      expect(
        () => RefuelEntry(
          id: 'x',
          date: date,
          amount: 100,
          pricePerLitre: 100,
          gaugeBars: 1,
          isAnchor: true,
        ),
        throwsArgumentError,
      );
      // An anchor without a gauge level.
      expect(
        () => RefuelEntry(
          id: 'x',
          date: date,
          odometer: 1000,
          amount: 100,
          pricePerLitre: 100,
          isAnchor: true,
        ),
        throwsArgumentError,
      );
      // Bars and Full at once.
      expect(
        () => RefuelEntry(
          id: 'x',
          date: date,
          amount: 100,
          pricePerLitre: 100,
          gaugeBars: 2,
          isFull: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => RefuelEntry(id: 'x', date: date, amount: 100, pricePerLitre: 0),
        throwsArgumentError,
      );
      expect(
        () => RefuelEntry(id: 'x', date: date, amount: -1, pricePerLitre: 100),
        throwsArgumentError,
      );
      expect(
        () => Bike(
          model: 'x',
          tankLitres: 10,
          gaugeBars: 5,
          expectedKmplMin: 60,
          expectedKmplMax: 40,
        ),
        throwsArgumentError,
      );
    });
  });
}
