/// The bundled bike catalog (assets/bikes.json): model specs and expected
/// km/L ranges. Parsing only; the caller loads the text.
library;

import 'dart:convert';

import 'models.dart';

class BikeModel {
  const BikeModel({
    required this.model,
    required this.tankLitres,
    required this.gaugeBars,
    required this.expectedKmplMin,
    required this.expectedKmplMax,
    required this.verified,
  });

  factory BikeModel.fromJson(Map<String, Object?> json) => BikeModel(
    model: _field<String>(json, 'model'),
    tankLitres: _field<num>(json, 'tankLitres').toDouble(),
    gaugeBars: _field<int>(json, 'gaugeBars'),
    expectedKmplMin: _field<num>(json, 'expectedKmplMin').toDouble(),
    expectedKmplMax: _field<num>(json, 'expectedKmplMax').toDouble(),
    verified: _field<bool>(json, 'verified'),
  );

  final String model;
  final double tankLitres;
  final int gaugeBars;
  final double expectedKmplMin;
  final double expectedKmplMax;

  /// False until the owner has checked these numbers.
  final bool verified;

  /// A [Bike] of this model, with the overrides from Bike setup.
  Bike toBike({
    double? tankLitres,
    int? gaugeBars,
    double? prefillUncertaintyLitres,
    int? odometerDigits,
  }) => Bike(
    model: model,
    tankLitres: tankLitres ?? this.tankLitres,
    gaugeBars: gaugeBars ?? this.gaugeBars,
    expectedKmplMin: expectedKmplMin,
    expectedKmplMax: expectedKmplMax,
    prefillUncertaintyLitres:
        prefillUncertaintyLitres ?? Bike.defaultPrefillUncertaintyLitres,
    odometerDigits: odometerDigits ?? Bike.defaultOdometerDigits,
  );
}

/// Parses `{"models": [{...}, ...]}`. Throws [FormatException] if malformed.
List<BikeModel> parseBikeCatalog(String jsonText) {
  final root = jsonDecode(jsonText);
  if (root is! Map<String, Object?>) {
    throw const FormatException('bikes.json: expected a JSON object');
  }
  final models = root['models'];
  if (models is! List<Object?>) {
    throw const FormatException('bikes.json: "models" must be a list');
  }
  return [
    for (final model in models)
      if (model is Map<String, Object?>)
        BikeModel.fromJson(model)
      else
        throw const FormatException('bikes.json: each model must be an object'),
  ];
}

T _field<T>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! T) {
    throw FormatException('bikes.json: "$key" must be a $T, got $value');
  }
  return value;
}
