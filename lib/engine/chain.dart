/// Engine outputs. Chains are computed from the log on demand, never stored.
library;

import 'models.dart';

/// How an anchor pins the tank level.
enum AnchorKind {
  /// Gauge bars read BEFORE filling. The start anchor's fill is counted; the
  /// end anchor's fill is not (it starts the next chain).
  prefill,

  /// Filled to the neck. The start anchor's fill is not counted; the end
  /// anchor's fill is.
  full,
}

/// The tank level an anchor stands for. A chain closes only at an equal level.
class AnchorLevel {
  const AnchorLevel.full() : kind = AnchorKind.full, bars = null;
  const AnchorLevel.bars(int this.bars) : kind = AnchorKind.prefill;

  /// The level of an anchor refuel.
  factory AnchorLevel.of(RefuelEntry anchor) => anchor.isFull
      ? const AnchorLevel.full()
      : AnchorLevel.bars(anchor.gaugeBars!);

  final AnchorKind kind;

  /// Bars read before filling; null for [AnchorKind.full].
  final int? bars;

  @override
  bool operator ==(Object other) =>
      other is AnchorLevel && other.kind == kind && other.bars == bars;

  @override
  int get hashCode => Object.hash(kind, bars);

  @override
  String toString() => switch (kind) {
    AnchorKind.full => 'Full',
    AnchorKind.prefill => bars == 1 ? '1 bar' : '$bars bars',
  };
}

/// How much to trust a result. Comes from the litres it rests on, not from
/// the number of refuels.
enum Confidence {
  low,
  medium,
  high;

  /// From this many litres: Medium.
  static const double mediumFromLitres = 4;

  /// Above this many litres: High.
  static const double highAboveLitres = 8;

  /// < 4 L Low, 4–8 L Medium, > 8 L High.
  static Confidence forLitres(double litres) {
    if (litres < mediumFromLitres) return Confidence.low;
    if (litres <= highAboveLitres) return Confidence.medium;
    return Confidence.high;
  }

  /// Litres still to log before the next label; null once High.
  static double? litresToNextLevel(double litres) =>
      switch (forLitres(litres)) {
        Confidence.low => mediumFromLitres - litres,
        Confidence.medium => highAboveLitres - litres,
        Confidence.high => null,
      };
}

/// The km/L range a result could really be, given the anchor uncertainty U.
class KmplBand {
  const KmplBand({required this.low, required this.high});

  /// low = distance ÷ (litres + U), high = distance ÷ (litres − U).
  factory KmplBand.from({
    required int distanceKm,
    required double litres,
    required double uncertaintyLitres,
  }) => KmplBand(
    low: distanceKm / (litres + uncertaintyLitres),
    high: litres > uncertaintyLitres
        ? distanceKm / (litres - uncertaintyLitres)
        : null,
  );

  final double low;

  /// Null when litres ≤ U: too little fuel to bound the top.
  final double? high;
}

/// Where a closed chain's km/L sits against the bike's expected range.
enum Plausibility {
  inRange,

  /// Too low: a refuel logged twice or with a wrong amount, mismatched
  /// anchor readings, or the bike really is using more fuel.
  belowRange,

  /// Too high: usually a missed refuel.
  aboveRange,
}

enum ChainStatus {
  /// Waiting for an anchor at the same level.
  open,

  /// Has a result that counts toward the estimate: in range, or out of range
  /// and accepted by the user.
  closed,

  /// Has a result outside the expected range; waiting for the user.
  flagged,

  /// Has a result, but the user discarded it.
  discarded,

  /// Ended without a result. See [Chain.breakReason].
  broken,
}

/// Why a chain ended without a result.
enum BreakReason {
  /// A service event ended it.
  service,

  /// An anchor at a different level started a new chain.
  levelChanged,

  /// The closing anchor's odometer is not above the start anchor's.
  odometerNotIncreasing,

  /// No fuel was counted (₹0 fills), so km/L is undefined.
  noFuelCounted,
}

/// A run of refuels from one anchor to the next anchor at the same level.
class Chain {
  Chain({
    required this.status,
    required this.level,
    required this.start,
    required this.end,
    required List<RefuelEntry> refuels,
    required List<RefuelEntry> countedFills,
    required this.litres,
    required this.distanceKm,
    required this.uncertaintyLitres,
    this.kmpl,
    this.band,
    this.plausibility,
    this.decision,
    this.breakReason,
    this.brokenBy,
  }) : refuels = List.unmodifiable(refuels),
       countedFills = List.unmodifiable(countedFills);

  final ChainStatus status;
  final AnchorLevel level;

  /// The anchor that opened the chain.
  final RefuelEntry start;

  /// The same-level anchor that closed it; null while open, or when broken
  /// by a service or a level change.
  final RefuelEntry? end;

  /// Every refuel in the chain, in log order, including both anchors.
  final List<RefuelEntry> refuels;

  /// The refuels whose litres are counted (see [AnchorKind]).
  final List<RefuelEntry> countedFills;

  /// Litres counted; so far, for open and broken chains.
  final double litres;

  /// End odometer − start odometer. For open and broken chains: the distance
  /// up to the latest odometer reading inside the chain.
  final int? distanceKm;

  /// The chain's U: √2 × the per-reading U, since the start and end readings
  /// each carry their own error. Used for [band].
  final double uncertaintyLitres;

  /// distance ÷ litres. Set only for closed, flagged and discarded chains, as
  /// are [band] and [plausibility].
  final double? kmpl;
  final KmplBand? band;
  final Plausibility? plausibility;

  /// The user's decision that applied, if any.
  final ChainDecisionKind? decision;

  /// Set only for broken chains, as is [brokenBy].
  final BreakReason? breakReason;

  /// The entry that ended a broken chain: the service, the different-level
  /// anchor, or the closing anchor with the bad odometer.
  final LogEntry? brokenBy;

  /// Chains are identified by their start anchor.
  String get id => start.id;

  Confidence get confidence => Confidence.forLitres(litres);

  bool get countsTowardEstimate => status == ChainStatus.closed;
}
