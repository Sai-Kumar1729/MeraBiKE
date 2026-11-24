import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/engine/engine.dart';

import 'helpers.dart';

void main() {
  // testBike has the default 5-digit odometer: maximum 99,999 km.
  test('a drop of more than 90% of the maximum is a rollover', () {
    final log = LogBuilder()
      ..barsAnchor('a1', odo: 99900, bars: 1, amount: 100)
      ..fill('m1', 400)
      ..barsAnchor('a2', odo: 125, bars: 1, amount: 100);
    final analysis = analyzeLog(log.entries, testBike);
    final chain = analysis.chains.first;
    expect(chain.status, ChainStatus.closed);
    expect(chain.distanceKm, 225); // 100,125 − 99,900
    expect(chain.kmpl, closeTo(45, 1e-9));
    expect(analysis.issues.single.kind, IssueKind.odometerRolledOver);
    expect(analysis.issues.single.entryId, 'a2');
  });

  test('readings after a rollover keep counting from the new base', () {
    final log = LogBuilder()
      ..barsAnchor('a1', odo: 99900, bars: 1, amount: 100)
      ..fill('m1', 400, odo: 50) // rolled over here
      ..barsAnchor('a2', odo: 125, bars: 1, amount: 100);
    final chain = analyzeLog(log.entries, testBike).chains.first;
    expect(chain.distanceKm, 225);
  });

  test('a smaller drop is an error, not a rollover', () {
    final log = LogBuilder()
      ..barsAnchor('a1', odo: 95000, bars: 1, amount: 100)
      ..barsAnchor('a2', odo: 10000, bars: 1, amount: 100);
    final analysis = analyzeLog(log.entries, testBike);
    expect(
      analysis.chains.first.breakReason,
      BreakReason.odometerNotIncreasing,
    );
    expect(analysis.issues.single.kind, IssueKind.odometerWentBackwards);
  });

  test('the 90% rule follows the digit count', () {
    final sixDigits = Bike(
      model: 'Test bike',
      tankLitres: 10,
      gaugeBars: 6,
      expectedKmplMin: 40,
      expectedKmplMax: 70,
      odometerDigits: 6,
    );
    final log = LogBuilder()
      ..barsAnchor('a1', odo: 99900, bars: 1, amount: 100)
      ..barsAnchor('a2', odo: 125, bars: 1, amount: 100);
    final analysis = analyzeLog(log.entries, sixDigits);
    expect(analysis.issues.single.kind, IssueKind.odometerWentBackwards);
  });

  test('a reading with more digits than the odometer is reported', () {
    final log = LogBuilder()..fill('m1', 100, odo: 100500);
    final issues = analyzeLog(log.entries, testBike).issues;
    expect(issues.single.kind, IssueKind.odometerAboveMax);
  });
}
