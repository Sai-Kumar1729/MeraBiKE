import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/engine/engine.dart';

import 'helpers.dart';

void main() {
  const regular = FuelGrade.regular;
  const premium = FuelGrade.premium;

  group('cost per km', () {
    // The owner's chain: 258 km on 8.03 L at ₹116/L, band 29.51–35.21 km/L.
    final log =
        (LogBuilder(price: 116)
              ..barsAnchor('r1', odo: 83050, bars: 1, amount: 116)
              ..fill('r2', 416)
              ..fill('r3', 400)
              ..barsAnchor('r4', odo: 83308, bars: 1, amount: 116))
            .entries;
    final bike = Bike(
      model: 'Hero Glamour',
      tankLitres: 10,
      gaugeBars: 5,
      expectedKmplMin: 25,
      expectedKmplMax: 70,
    );

    test('is the price over the km/L band, as a range', () {
      final current = analyzeLog(log, bike).current!;
      final cost = costPerKm(log, current)!;
      expect(cost.pricePerLitre, 116);
      expect(cost.estimate, closeTo(116 / current.kmpl, 1e-9));
      expect(cost.estimate, closeTo(3.61, 0.01));
      expect(cost.low, closeTo(116 / current.band.high!, 1e-9));
      expect(cost.high, closeTo(116 / current.band.low, 1e-9));
      expect(cost.low! < cost.estimate && cost.estimate < cost.high, isTrue);
    });

    test('is unknown before there is an estimate', () {
      expect(costPerKm(log, null), isNull);
    });
  });

  group('spend', () {
    final log = <LogEntry>[
      RefuelEntry(
        id: '1',
        date: DateTime(2026, 10, 30),
        amount: 200,
        pricePerLitre: 100,
      ),
      RefuelEntry(
        id: '2',
        date: DateTime(2026, 11, 2),
        amount: 116,
        pricePerLitre: 116,
      ),
      ServiceEvent(id: 's', date: DateTime(2026, 11, 5), odometer: 1000),
      RefuelEntry(
        id: '3',
        date: DateTime(2026, 11, 20, 18),
        amount: 300,
        pricePerLitre: 100,
      ),
    ];

    test('per month, newest first, every refuel counted', () {
      final months = monthlySpend(log);
      expect(
        [for (final m in months) '${m.year}-${m.month}'],
        ['2026-11', '2026-10'],
      );
      expect(months[0].rupees, 416);
      expect(months[0].litres, closeTo(4, 1e-9));
      expect(months[0].fills, 2);
      expect(months[1].rupees, 200);
    });

    test('over the last 30 days, both ends included', () {
      // 22 Oct – 20 Nov: includes 30 Oct, 2 Nov and 20 Nov.
      expect(spendInLastDays(log, DateTime(2026, 11, 20)), 616);
      // 2 Nov – 1 Dec: 2 Nov is the first day, still in.
      expect(spendInLastDays(log, DateTime(2026, 12, 1)), 416);
      // 3 Nov – 2 Dec: only 20 Nov left.
      expect(spendInLastDays(log, DateTime(2026, 12, 2)), 300);
    });
  });

  group('fuel grade comparison', () {
    LogBuilder graded() => LogBuilder()
      // Regular chain: 225 km / 5 L = 45.
      ..barsAnchor('a1', odo: 1000, bars: 1, amount: 100, grade: regular)
      ..fill('m1', 400, grade: regular)
      // Mixed chain: a2 is regular, m2 premium.
      ..barsAnchor('a2', odo: 1225, bars: 1, amount: 100, grade: regular)
      ..fill('m2', 500, grade: premium)
      // Premium chain: 300 km / 5 L = 60.
      ..barsAnchor('a3', odo: 1555, bars: 1, amount: 100, grade: premium)
      ..fill('m3', 400, grade: premium)
      // Untagged chain: m4 has no grade.
      ..barsAnchor('a4', odo: 1855, bars: 1, amount: 100, grade: premium)
      ..fill('m4', 400)
      ..barsAnchor('a5', odo: 2080, bars: 1, amount: 100, grade: premium);

    test('counts only single-grade chains, and says what it left out', () {
      final comparison = compareGrades(analyzeLog(graded().entries, testBike));
      expect([for (final g in comparison.byGrade) g.grade], [regular, premium]);
      expect(comparison.byGrade[0].estimate.kmpl, closeTo(45, 1e-9));
      expect(comparison.byGrade[1].estimate.kmpl, closeTo(60, 1e-9));
      expect(comparison.mixedChains, 1);
      expect(comparison.untaggedChains, 1);
    });

    test('never reaches back across a service', () {
      final log = graded()
        ..service('s1', odo: 2100)
        ..barsAnchor('b1', odo: 2200, bars: 1, amount: 100, grade: regular)
        ..fill('n1', 400, grade: regular)
        ..barsAnchor('b2', odo: 2450, bars: 1, amount: 100, grade: regular);
      final comparison = compareGrades(analyzeLog(log.entries, testBike));
      expect(comparison.byGrade.single.grade, regular);
      expect(comparison.byGrade.single.estimate.kmpl, closeTo(50, 1e-9));
      expect(comparison.mixedChains, 0);
    });
  });

  test('trend: results in order, with services placed between them', () {
    final log = LogBuilder()
      ..barsAnchor('a1', odo: 1000, bars: 1, amount: 100)
      ..fill('m1', 400)
      ..barsAnchor('a2', odo: 1225, bars: 1, amount: 100)
      ..service('s1', odo: 1250)
      ..barsAnchor('a3', odo: 1300, bars: 1, amount: 100)
      ..fill('m2', 400)
      ..barsAnchor('a4', odo: 1600, bars: 1, amount: 100);
    final series = trendSeries(analyzeLog(log.entries, testBike));
    expect([for (final c in series.points) c.id], ['a1', 'a3']);
    expect(series.servicesBefore, [1]);
  });
}
