import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/engine/engine.dart';

/// The owner's Hero Glamour log at ₹116/L. The dates are placeholders.
final realLog = <LogEntry>[
  // 1. 83050 km, 1 bar, ₹116 (anchor)
  RefuelEntry(
    id: 'r1',
    date: DateTime(2026, 11, 1),
    odometer: 83050,
    amount: 116,
    pricePerLitre: 116,
    gaugeBars: 1,
    isAnchor: true,
  ),
  // 2. no odometer, ₹416
  RefuelEntry(
    id: 'r2',
    date: DateTime(2026, 11, 3),
    amount: 416,
    pricePerLitre: 116,
  ),
  // 3. no odometer, ₹400
  RefuelEntry(
    id: 'r3',
    date: DateTime(2026, 11, 6),
    amount: 400,
    pricePerLitre: 116,
  ),
  // 4. 83308 km, 1 bar, ₹116 (anchor)
  RefuelEntry(
    id: 'r4',
    date: DateTime(2026, 11, 9),
    odometer: 83308,
    amount: 116,
    pricePerLitre: 116,
    gaugeBars: 1,
    isAnchor: true,
  ),
  // 5. 83336 km, gauge unknown, ₹160
  RefuelEntry(
    id: 'r5',
    date: DateTime(2026, 11, 10),
    odometer: 83336,
    amount: 160,
    pricePerLitre: 116,
  ),
];

Bike glamour({required double minKmpl, required double maxKmpl}) => Bike(
  model: 'Hero Glamour',
  tankLitres: 10,
  gaugeBars: 5,
  expectedKmplMin: minKmpl,
  expectedKmplMax: maxKmpl,
);

void main() {
  // A fence wide enough to hold this bike's measured ~32 km/L. The last test
  // shows what a typical Glamour fence does with the same data.
  final analysis = analyzeLog(realLog, glamour(minKmpl: 25, maxKmpl: 70));

  test('entry 4 closes chain 1: 258 km, 8.03 L, about 32.1 km/L, High', () {
    expect(analysis.chains, hasLength(2));
    final chain = analysis.chains[0];
    expect(chain.status, ChainStatus.closed);
    expect(chain.level, const AnchorLevel.bars(1));
    expect(chain.start.id, 'r1');
    expect(chain.end?.id, 'r4');
    expect(chain.distanceKm, 258);
    // Pre-fill anchors: r1's fill counts, r4's fill starts chain 2.
    expect([for (final r in chain.countedFills) r.id], ['r1', 'r2', 'r3']);
    expect(chain.litres, closeTo(8.03, 0.01)); // ₹932 / ₹116
    expect(chain.kmpl, closeTo(32.1, 0.05));
    expect(chain.uncertaintyLitres, 0.5);
    expect(chain.band!.low, closeTo(30.23, 0.01)); // 258 / (8.03 + 0.5)
    expect(chain.band!.high, closeTo(34.24, 0.01)); // 258 / (8.03 - 0.5)
    expect(chain.confidence, Confidence.high);
    expect(chain.plausibility, Plausibility.inRange);
  });

  test('entry 5 leaves chain 2 open with 2.38 L logged', () {
    final chain = analysis.chains[1];
    expect(chain.status, ChainStatus.open);
    expect(chain.start.id, 'r4');
    expect(chain.end, isNull);
    expect([for (final r in chain.countedFills) r.id], ['r4', 'r5']);
    expect(chain.litres, closeTo(2.38, 0.01)); // (₹116 + ₹160) / ₹116
    expect(chain.distanceKm, 28); // so far: 83336 − 83308
    expect(chain.kmpl, isNull);
    expect(chain.band, isNull);
    expect(chain.confidence, Confidence.low);
    expect(Confidence.litresToNextLevel(chain.litres), closeTo(1.62, 0.01));
    expect(analysis.openChain, same(chain));
  });

  test('the current estimate is chain 1 alone', () {
    final current = analysis.current!;
    expect(current.chains, hasLength(1));
    expect(current.kmpl, closeTo(32.1, 0.05));
    expect(current.band.low, closeTo(30.23, 0.01));
    expect(current.band.high, closeTo(34.24, 0.01));
    expect(current.confidence, Confidence.high);
    expect(analysis.issues, isEmpty);
    expect(analysis.unchained, isEmpty);
  });

  test('a typical Glamour fence (40–65 km/L) flags chain 1 as below range', () {
    final flagged = analyzeLog(realLog, glamour(minKmpl: 40, maxKmpl: 65));
    expect(flagged.chains[0].status, ChainStatus.flagged);
    expect(flagged.chains[0].plausibility, Plausibility.belowRange);
    expect(flagged.current, isNull, reason: 'flagged chains wait for the user');
  });
}
