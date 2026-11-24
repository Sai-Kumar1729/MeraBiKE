import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/engine/engine.dart';

void main() {
  test('assets/bikes.json: 8 seeded models that all make valid bikes', () {
    final models = parseBikeCatalog(
      File('assets/bikes.json').readAsStringSync(),
    );
    expect(models.length, greaterThanOrEqualTo(8));
    expect({for (final m in models) m.model}, hasLength(models.length));
    expect(models.map((m) => m.model), contains('Hero Glamour'));
    for (final model in models) {
      expect(model.toBike, returnsNormally, reason: model.model);
    }
  });

  test('Bike setup overrides tank, bars and U', () {
    const model = BikeModel(
      model: 'Hero Glamour',
      tankLitres: 10,
      gaugeBars: 5,
      expectedKmplMin: 40,
      expectedKmplMax: 65,
      verified: false,
    );
    final bike = model.toBike(
      tankLitres: 10.5,
      gaugeBars: 6,
      prefillUncertaintyLitres: 0.8,
    );
    expect(bike.tankLitres, 10.5);
    expect(bike.gaugeBars, 6);
    expect(bike.prefillUncertaintyLitres, 0.8);
    expect(bike.fullUncertaintyLitres, 0.15);
    expect(bike.expectedKmplMin, 40);
    expect(bike.expectedKmplMax, 65);
  });

  test('a malformed catalog throws FormatException', () {
    expect(() => parseBikeCatalog('[]'), throwsFormatException);
    expect(
      () => parseBikeCatalog('{"models": [{"model": "X", "tankLitres": 10}]}'),
      throwsFormatException,
    );
  });
}
