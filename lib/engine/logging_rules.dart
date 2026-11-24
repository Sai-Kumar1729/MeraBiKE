/// Pure rules behind the logging screens: the anchor toggle's default, where a
/// missed refuel goes, and the rough km-left figure.
library;

import 'analysis.dart';
import 'chain.dart';
import 'models.dart';

/// What marking a new refuel as an anchor would do.
enum AnchorEffect {
  /// Gauge unknown (or no odometer): it cannot be an anchor.
  notPossible,

  /// No chain is open: it starts one.
  startsChain,

  /// Same level as the open chain: it closes it and starts the next.
  closesChain,

  /// Different level from the open chain: it ends that chain with no result.
  breaksChain,
}

/// [level] is null when the gauge is unknown.
AnchorEffect anchorEffect(Chain? openChain, AnchorLevel? level) {
  if (level == null) return AnchorEffect.notPossible;
  if (openChain == null) return AnchorEffect.startsChain;
  return openChain.level == level
      ? AnchorEffect.closesChain
      : AnchorEffect.breaksChain;
}

/// The anchor toggle starts on unless that would throw away the open chain.
bool anchorOnByDefault(AnchorEffect effect) =>
    effect == AnchorEffect.startsChain || effect == AnchorEffect.closesChain;

/// The chain a missed refuel on [date] most likely belongs to: the last chain
/// that started on or before that day. Null when no chain covers it.
Chain? chainForDate(List<Chain> chains, DateTime date) {
  final day = _day(date);
  Chain? found;
  for (final chain in chains) {
    if (!_day(chain.start.date).isAfter(day)) found = chain;
  }
  return found;
}

/// Where in [log] to insert a missed refuel dated [date] so that it lands
/// inside [chain]: after the chain's last entry on or before that day, but
/// never after its closing anchor (or the entry that broke it).
int missedRefuelIndex(List<LogEntry> log, Chain chain, DateTime date) {
  final candidates = chain.end == null
      ? chain.refuels
      : chain.refuels.sublist(0, chain.refuels.length - 1);
  final day = _day(date);
  var after = candidates.first;
  for (final entry in candidates) {
    if (!_day(entry.date).isAfter(day)) after = entry;
  }
  return log.indexWhere((e) => e.id == after.id) + 1;
}

/// A rough range figure. Approximate by nature: it assumes the gauge is
/// linear and that you ride at your current km/L.
class KmLeftEstimate {
  const KmLeftEstimate({
    required this.kmLeft,
    required this.fuelLitres,
    required this.kmplUsed,
    required this.kmplIsModelGuess,
    required this.litresAtAnchor,
    required this.asOfOdometer,
  });

  final double kmLeft;
  final double fuelLitres;
  final double kmplUsed;

  /// True when there is no estimate yet and the fence's midpoint was used.
  final bool kmplIsModelGuess;

  /// Fuel assumed in the tank at the anchor: bars × (tank ÷ bars), or the
  /// full tank.
  final double litresAtAnchor;

  /// The odometer reading the figure is valid for (the latest in the chain).
  final int asOfOdometer;
}

/// Km left in the tank, from the open chain. Null when no chain is open.
KmLeftEstimate? estimateKmLeft(LogAnalysis analysis, Bike bike) {
  final chain = analysis.openChain;
  if (chain == null) return null;
  final current = analysis.current;
  final kmpl =
      current?.kmpl ?? (bike.expectedKmplMin + bike.expectedKmplMax) / 2;
  final atAnchor = chain.level.kind == AnchorKind.full
      ? bike.tankLitres
      : chain.level.bars! * bike.tankLitres / bike.gaugeBars;
  final fuel = (atAnchor + chain.litres - chain.distanceKm! / kmpl).clamp(
    0.0,
    bike.tankLitres,
  );
  final lastRead = chain.refuels.lastWhere((r) => r.odometer != null);
  return KmLeftEstimate(
    kmLeft: fuel * kmpl,
    fuelLitres: fuel,
    kmplUsed: kmpl,
    kmplIsModelGuess: current == null,
    litresAtAnchor: atAnchor,
    asOfOdometer: lastRead.odometer!,
  );
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
