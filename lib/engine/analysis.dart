/// The engine's core: turns the ordered log into chains, estimate periods and
/// data warnings. A pure function of its inputs.
library;

import 'chain.dart';
import 'estimate.dart';
import 'models.dart';

/// Something in the log that looks like a typing or ordering mistake. These
/// are warnings: the analysis still runs.
enum IssueKind {
  odometerWentBackwards,
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
  }) : chains = List.unmodifiable(chains),
       periods = List.unmodifiable(periods),
       unchained = List.unmodifiable(unchained),
       issues = List.unmodifiable(issues);

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
          emit(draft.broken(bike, BreakReason.service, service));
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
                ? draft.close(anchor, bike, decisions)
                : draft.broken(bike, BreakReason.levelChanged, anchor),
          );
        }
        draft = _Draft(anchor, level);
    }
  }
  if (draft != null) emit(draft.open(bike));
  periods.add(ServicePeriod(startedBy: periodStart, chains: periodChains));

  return LogAnalysis(
    chains: chains,
    periods: periods,
    unchained: unchained,
    issues: _findIssues(log, bike),
  );
}

/// A chain being walked: its start anchor plus every refuel since.
class _Draft {
  _Draft(this.start, this.level) : refuels = [start];

  final RefuelEntry start;
  final AnchorLevel level;
  final List<RefuelEntry> refuels;

  bool get _isFull => level.kind == AnchorKind.full;

  double _uncertainty(Bike bike) =>
      _isFull ? bike.fullUncertaintyLitres : bike.prefillUncertaintyLitres;

  Chain open(Bike bike) => _unfinished(bike, ChainStatus.open, null, null);

  Chain broken(Bike bike, BreakReason reason, LogEntry by) =>
      _unfinished(bike, ChainStatus.broken, reason, by);

  /// An open chain, or one broken before reaching a same-level anchor.
  Chain _unfinished(
    Bike bike,
    ChainStatus status,
    BreakReason? reason,
    LogEntry? by,
  ) {
    final counted = _isFull ? refuels.sublist(1) : refuels;
    final lastOdometer = refuels.lastWhere((r) => r.odometer != null).odometer!;
    return Chain(
      status: status,
      level: level,
      start: start,
      end: null,
      refuels: refuels,
      countedFills: counted,
      litres: _sumLitres(counted),
      distanceKm: lastOdometer - start.odometer!,
      uncertaintyLitres: _uncertainty(bike),
      breakReason: reason,
      brokenBy: by,
    );
  }

  Chain close(RefuelEntry end, Bike bike, List<ChainDecision> decisions) {
    final all = [...refuels, end];
    // PRE-FILL: the start fill is counted; the end fill starts the next chain.
    // FULL: the start fill only topped up to the anchor level; the end fill
    // is counted.
    final counted = _isFull ? all.sublist(1) : refuels;
    final litres = _sumLitres(counted);
    final distance = end.odometer! - start.odometer!;
    final u = _uncertainty(bike);

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

List<LogIssue> _findIssues(List<LogEntry> log, Bike bike) {
  final issues = <LogIssue>[];
  int? lastOdometer;
  DateTime? lastDate;
  for (final entry in log) {
    final odometer = entry.odometer;
    if (odometer != null) {
      if (lastOdometer != null && odometer < lastOdometer) {
        issues.add(
          LogIssue(
            kind: IssueKind.odometerWentBackwards,
            entryId: entry.id,
            message:
                'Odometer $odometer km is below the previous reading of '
                '$lastOdometer km. Check the reading or the entry order.',
          ),
        );
      }
      lastOdometer = odometer;
    }
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
  return issues;
}
