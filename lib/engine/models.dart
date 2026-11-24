/// Engine inputs: the bike, and the ordered log of refuels and services.
///
/// Pure Dart. Nothing under lib/engine/ may import Flutter or do I/O.
library;

/// The bike being tracked, with the values the engine needs.
class Bike {
  Bike({
    required this.model,
    required this.tankLitres,
    required this.gaugeBars,
    required this.expectedKmplMin,
    required this.expectedKmplMax,
    this.prefillUncertaintyLitres = defaultPrefillUncertaintyLitres,
    this.fullUncertaintyLitres = defaultFullUncertaintyLitres,
    this.odometerDigits = defaultOdometerDigits,
  }) {
    _require(
      odometerDigits >= 4 && odometerDigits <= 7,
      'odometerDigits must be 4 to 7',
    );
    _require(tankLitres.isFinite && tankLitres > 0, 'tankLitres must be > 0');
    _require(gaugeBars > 0, 'gaugeBars must be > 0');
    _require(
      expectedKmplMin.isFinite &&
          expectedKmplMax.isFinite &&
          expectedKmplMin > 0 &&
          expectedKmplMin < expectedKmplMax,
      'expected range must satisfy 0 < expectedKmplMin < expectedKmplMax',
    );
    _require(
      prefillUncertaintyLitres.isFinite && prefillUncertaintyLitres >= 0,
      'prefillUncertaintyLitres must be >= 0',
    );
    _require(
      fullUncertaintyLitres.isFinite && fullUncertaintyLitres >= 0,
      'fullUncertaintyLitres must be >= 0',
    );
  }

  /// Default U per gauge-bar (pre-fill) reading, in litres.
  static const double defaultPrefillUncertaintyLitres = 0.5;

  /// Default U per FULL (filled to the neck) reading, in litres.
  static const double defaultFullUncertaintyLitres = 0.15;

  /// Until the owner checks the bike: a 5-digit odometer rolls over at 99,999.
  static const int defaultOdometerDigits = 5;

  final String model;

  /// Tank capacity in litres.
  final double tankLitres;

  /// Number of bars the fuel gauge shows when full.
  final int gaugeBars;

  /// Plausibility fence: a closed chain outside this km/L range is flagged.
  final double expectedKmplMin;
  final double expectedKmplMax;

  /// U for one gauge-bar reading: how fuzzy the anchor level is, ± litres.
  /// A chain has two readings, so its band uses √2 × U.
  final double prefillUncertaintyLitres;

  /// U for one FULL reading, ± litres.
  final double fullUncertaintyLitres;

  /// Digits on the odometer. A drop of more than 90% of the maximum reading
  /// is a rollover, not an error.
  final int odometerDigits;

  /// The reading after the maximum: 100000 for 5 digits.
  int get odometerModulus {
    var modulus = 1;
    for (var i = 0; i < odometerDigits; i++) {
      modulus *= 10;
    }
    return modulus;
  }

  /// The highest reading the odometer can show: 99999 for 5 digits.
  int get odometerMax => odometerModulus - 1;
}

/// One item in the bike's log. The engine reads the log in list order.
sealed class LogEntry {
  LogEntry({required this.id, required this.date});

  /// Stable unique id, assigned by storage.
  final String id;

  /// When it happened. Only checked for ordering mistakes: list order is
  /// what the engine follows.
  final DateTime date;

  /// Odometer reading in km, if known.
  int? get odometer;
}

/// A refuel. An intermediate refuel needs only [amount], [pricePerLitre]
/// and [date]; an anchor also needs [odometer] and a gauge level.
final class RefuelEntry extends LogEntry {
  RefuelEntry({
    required super.id,
    required super.date,
    this.odometer,
    required this.amount,
    required this.pricePerLitre,
    this.gaugeBars,
    this.isFull = false,
    this.isAnchor = false,
    this.grade,
    this.note = '',
  }) {
    final odo = odometer;
    final bars = gaugeBars;
    _require(amount.isFinite && amount >= 0, 'amount (₹) must be >= 0');
    _require(
      pricePerLitre.isFinite && pricePerLitre > 0,
      'pricePerLitre (₹/L) must be > 0',
    );
    _require(odo == null || odo >= 0, 'odometer (km) must be >= 0');
    _require(bars == null || bars >= 0, 'gaugeBars must be >= 0');
    _require(
      !(isFull && bars != null),
      'the gauge is either bars (read before filling) or Full, not both',
    );
    if (isAnchor) {
      _require(odo != null, 'an anchor needs an odometer reading');
      _require(isFull || bars != null, 'an anchor needs bars or Full');
    }
  }

  @override
  final int? odometer;

  /// Money paid, in ₹.
  final double amount;

  /// Price in ₹ per litre.
  final double pricePerLitre;

  /// Gauge bars read BEFORE filling. Null when unknown, or when [isFull].
  final int? gaugeBars;

  /// The tank was filled to the neck.
  final bool isFull;

  /// This refuel is a chain anchor.
  final bool isAnchor;

  /// What kind of petrol it was, if recorded. Only used for comparisons.
  final FuelGrade? grade;

  /// Free text for the owner. The engine ignores it.
  final String note;

  /// Litres added: amount ÷ price per litre.
  double get litres => amount / pricePerLitre;
}

/// The kind of petrol in a refuel. Recording it lets the owner compare
/// mileage by fuel with evidence instead of anecdotes.
enum FuelGrade {
  /// Regular petrol (E20 at most Indian pumps since 2025).
  regular,

  /// Premium / high-octane (XP95, Power, Speed, V-Power, ...).
  premium,

  /// Ethanol-free or E10, where a pump sells it.
  lowEthanol,
}

/// A service visit. It ends any open chain without a result and starts a new
/// estimate period: results from before and after it are never averaged.
final class ServiceEvent extends LogEntry {
  ServiceEvent({
    required super.id,
    required super.date,
    required this.odometer,
    this.note = '',
  }) {
    _require(odometer >= 0, 'odometer (km) must be >= 0');
  }

  @override
  final int odometer;

  final String note;
}

/// The user's answer for a closed chain.
enum ChainDecisionKind {
  /// "Bike may need attention": count it even though it is out of range.
  accept,

  /// "Discard chain": never count it.
  discard,
}

/// A decision about the chain between two anchors. Keyed by both anchors, so
/// it stops applying if the chain's boundaries change.
class ChainDecision {
  const ChainDecision({
    required this.startEntryId,
    required this.endEntryId,
    required this.kind,
  });

  final String startEntryId;
  final String endEntryId;
  final ChainDecisionKind kind;
}

void _require(bool condition, String message) {
  if (!condition) throw ArgumentError(message);
}
