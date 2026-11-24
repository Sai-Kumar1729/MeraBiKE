/// The engine's core: turns the ordered log into chains, estimate periods and
/// data warnings. A pure function of its inputs.
library;

import 'dart:math' as math;

import 'chain.dart';
import 'estimate.dart';
import 'models.dart';

/// Something in the log worth a look. The analysis still runs.
enum IssueKind {
  odometerWentBackwards,

  /// Not an error: the odometer passed its maximum and started again at 0.
  odometerRolledOver,
  odometerAboveMax,
  dateWentBackwards,
  gaugeAboveBikeBars,
  fillExceedsTank,
}

class LogIssue {
  const LogIssue({
    required this.kind,
    required this.entryId,
    required this.message,
  });

  final IssueKind kind;
  final String entryId;
  final String message;

  @override
  String toString() => '${kind.name} at $entryId: $message';
}

/// The chains between two services (or before the first one), with their
/// estimate. Estimates never cross a service.
class ServicePeriod {
  ServicePeriod({required this.startedBy, required List<Chain> chains})
    : chains = List.unmodifiable(chains),
      estimate = overallEstimate(chains);

  /// The service that started this period; null for the period before any.
  final ServiceEvent? startedBy;
  final List<Chain> chains;

  /// Over this period's accepted chains; null if there are none.
  final OverallEstimate? estimate;
}

class LogAnalysis {
  LogAnalysis({
    required List<Chain> chains,
    required List<ServicePeriod> periods,
    required List<RefuelEntry> unchained,
    required List<LogIssue> issues,
    this._odometers = const {},
  }) : chains = List.unmodifiable(chains),
       periods = List.unmodifiable(periods),
       unchained = List.unmodifiable(unchained),
       issues = List.unmodifiable(issues);

  final Map<LogEntry, int> _odometers;

  /// [entry]'s odometer with rollovers added back, so readings always grow.
  /// Null if the entry has no reading.
  int? correctedOdometer(LogEntry entry) => _odometers[entry];

  /// The last odometer reading in log order, rollover-corrected.
  int? get latestOdometer => _odometers.isEmpty ? null : _odometers.values.last;

  /// Every chain, in log order.
  final List<Chain> chains;

  /// Oldest first. Never empty.
  final List<ServicePeriod> periods;

  /// Refuels in no chain: before the first anchor, or after a service and
  /// before the next anchor.
  final List<RefuelEntry> unchained;

  final List<LogIssue> issues;

  /// The current estimate: accepted chains since the last service.
  OverallEstimate? get current => periods.last.estimate;

  /// The chain waiting for its closing anchor, if any.
  Chain? get openChain =>
      chains.isNotEmpty && chains.last.status == ChainStatus.open
      ? chains.last
      : null;
}

/// Analyses [log], which must be in the order things happened (storage owns
/// the ordering). [decisions] are the user's accept/discard answers.
LogAnalysis analyzeLog(
  List<LogEntry> log,
  Bike bike, {
  List<ChainDecision> decisions = const [],
}) {
  final issues = <LogIssue>[];
  final odometers = _trackOdometer(log, bike, issues);
  _checkEntries(log, bike, issues);

  final chains = <Chain>[];
  final periods = <ServicePeriod>[];
  final unchained = <RefuelEntry>[];
  ServiceEvent? periodStart;
  var periodChains = <Chain>[];
  _Draft? draft;

  void emit(Chain chain) {
    chains.add(chain);
    periodChains.add(chain);
  }

  for (final entry in log) {
    switch (entry) {
      case final ServiceEvent service:
        if (draft != null) {
          emit(draft.broken(BreakReason.service, service));
          draft = null;
        }
        periods.add(
          ServicePeriod(startedBy: periodStart, chains: periodChains),
        );
        periodStart = service;
        periodChains = <Chain>[];
      case final RefuelEntry refuel when !refuel.isAnchor:
        if (draft != null) {
          draft.refuels.add(refuel);
        } else {
          unchained.add(refuel);
        }
      case final RefuelEntry anchor:
        final level = AnchorLevel.of(anchor);
        if (draft != null) {
          emit(
            draft.level == level
                ? draft.close(anchor, decisions)
                : draft.broken(BreakReason.levelChanged, anchor),
          );
        }
        draft = _Draft(anchor, level, bike, odometers);
    }
  }
  if (draft != null) emit(draft.open());
  periods.add(ServicePeriod(startedBy: periodStart, chains: periodChains));

  return LogAnalysis(
    chains: chains,
    periods: periods,
    unchained: unchained,
    issues: issues,
    odometers: odometers,
  );
}

/// A chain being walked: its start anchor plus every refuel since.
class _Draft {
  _Draft(this.start, this.level, this.bike, this.odometers) : refuels = [start];

  final RefuelEntry start;
  final AnchorLevel level;
  final Bike bike;

  /// Rollover-corrected odometer of every entry that has a reading.
  final Map<LogEntry, int> odometers;
  final List<RefuelEntry> refuels;

  bool get _isFull => level.kind == AnchorKind.full;

  /// Two readings per chain (start and end), each ± the per-reading U.
  double get _uncertainty =>
      math.sqrt2 *
      (_isFull ? bike.fullUncertaintyLitres : bike.prefillUncertaintyLitres);

  int _distanceTo(RefuelEntry entry) => odometers[entry]! - odometers[start]!;

  Chain open() => _unfinished(ChainStatus.open, null, null);

  Chain broken(BreakReason reason, LogEntry by) =>
      _unfinished(ChainStatus.broken, reason, by);

  /// An open chain, or one broken before reaching a same-level anchor.
  Chain _unfinished(ChainStatus status, BreakReason? reason, LogEntry? by) {
    final counted = _isFull ? refuels.sublist(1) : refuels;
    final lastRead = refuels.lastWhere((r) => r.odometer != null);
    return Chain(
      status: status,
      level: level,
      start: start,
      end: null,
      refuels: refuels,
      countedFills: counted,
      litres: _sumLitres(counted),
      distanceKm: _distanceTo(lastRead),
      uncertaintyLitres: _uncertainty,
      breakReason: reason,
      brokenBy: by,
    );
  }

  Chain close(RefuelEntry end, List<ChainDecision> decisions) {
    final all = [...refuels, end];
    // PRE-FILL: the start fill is counted; the end fill starts the next chain.
    // FULL: the start fill only topped up to the anchor level; the end fill
    // is counted.
    final counted = _isFull ? all.sublist(1) : refuels;
    final litres = _sumLitres(counted);
    final distance = _distanceTo(end);
    final u = _uncertainty;

    Chain withoutResult(BreakReason reason) => Chain(
      status: ChainStatus.broken,
      level: level,
      start: start,
      end: end,
      refuels: all,
      countedFills: counted,
      litres: litres,
      distanceKm: distance,
      uncertaintyLitres: u,
      breakReason: reason,
      brokenBy: end,
    );
    if (distance <= 0) return withoutResult(BreakReason.odometerNotIncreasing);
    if (litres <= 0) return withoutResult(BreakReason.noFuelCounted);

    final kmpl = distance / litres;
    final plausibility = kmpl < bike.expectedKmplMin
        ? Plausibility.belowRange
        : kmpl > bike.expectedKmplMax
        ? Plausibility.aboveRange
        : Plausibility.inRange;
    final decision = _decisionFor(decisions, start.id, end.id);
    final status = switch (decision) {
      ChainDecisionKind.discard => ChainStatus.discarded,
      ChainDecisionKind.accept => ChainStatus.closed,
      null when plausibility == Plausibility.inRange => ChainStatus.closed,
      null => ChainStatus.flagged,
    };
    return Chain(
      status: status,
      level: level,
      start: start,
      end: end,
      refuels: all,
      countedFills: counted,
      litres: litres,
      distanceKm: distance,
      uncertaintyLitres: u,
      kmpl: kmpl,
      band: KmplBand.from(
        distanceKm: distance,
        litres: litres,
        uncertaintyLitres: u,
      ),
      plausibility: plausibility,
      decision: decision,
    );
  }
}

double _sumLitres(List<RefuelEntry> fills) =>
    fills.fold(0.0, (sum, r) => sum + r.litres);

/// The latest decision for the chain between these two anchors.
ChainDecisionKind? _decisionFor(
  List<ChainDecision> decisions,
  String startId,
  String endId,
) {
  for (final d in decisions.reversed) {
    if (d.startEntryId == startId && d.endEntryId == endId) return d.kind;
  }
  return null;
}

/// Rollover-corrected odometers, keyed by entry. A drop of more than 90% of
/// the odometer's maximum is a rollover; any other drop is reported.
Map<LogEntry, int> _trackOdometer(
  List<LogEntry> log,
  Bike bike,
  List<LogIssue> issues,
) {
  final corrected = Map<LogEntry, int>.identity();
  var offset = 0;
  int? lastReading;
  for (final entry in log) {
    final reading = entry.odometer;
    if (reading == null) continue;
    if (reading > bike.odometerMax) {
      issues.add(
        LogIssue(
          kind: IssueKind.odometerAboveMax,
          entryId: entry.id,
          message:
              '$reading km has more digits than the ${bike.odometerDigits}-digit '
              'odometer in Bike setup. Check the reading or the setting.',
        ),
      );
    }
    if (lastReading != null && reading < lastReading) {
      if (lastReading - reading > 0.9 * bike.odometerMax) {
        offset += bike.odometerModulus;
        issues.add(
          LogIssue(
            kind: IssueKind.odometerRolledOver,
            entryId: entry.id,
            message:
                'Odometer rolled over ($lastReading → $reading km); counted '
                'as ${reading + offset} km. If that is a typo, fix the reading.',
          ),
        );
      } else {
        issues.add(
          LogIssue(
            kind: IssueKind.odometerWentBackwards,
            entryId: entry.id,
            message:
                'Odometer $reading km is below the previous reading of '
                '$lastReading km. Check the reading or the entry order.',
          ),
        );
      }
    }
    lastReading = reading;
    corrected[entry] = reading + offset;
  }
  return corrected;
}

void _checkEntries(List<LogEntry> log, Bike bike, List<LogIssue> issues) {
  DateTime? lastDate;
  for (final entry in log) {
    if (lastDate != null && entry.date.isBefore(lastDate)) {
      issues.add(
        LogIssue(
          kind: IssueKind.dateWentBackwards,
          entryId: entry.id,
          message: 'Dated before the entry above it. Check the date or order.',
        ),
      );
    }
    lastDate = entry.date;
    if (entry is RefuelEntry) {
      final bars = entry.gaugeBars;
      if (bars != null && bars > bike.gaugeBars) {
        issues.add(
          LogIssue(
            kind: IssueKind.gaugeAboveBikeBars,
            entryId: entry.id,
            message: 'Gauge $bars bars, but this bike shows ${bike.gaugeBars}.',
          ),
        );
      }
      if (entry.litres > bike.tankLitres) {
        issues.add(
          LogIssue(
            kind: IssueKind.fillExceedsTank,
            entryId: entry.id,
            message:
                '${entry.litres.toStringAsFixed(2)} L is more than the '
                '${bike.tankLitres} L tank holds. Check the amount and price.',
          ),
        );
      }
    }
  }
}
