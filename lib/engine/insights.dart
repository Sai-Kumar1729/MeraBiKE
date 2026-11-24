/// What the owner can learn beyond the current estimate: cost, trend and
/// comparisons by fuel grade. Pure functions of the log and its analysis.
library;

import 'analysis.dart';
import 'chain.dart';
import 'estimate.dart';
import 'models.dart';

/// ₹ per km at the latest price, from the current km/L band.
class CostPerKm {
  const CostPerKm({
    required this.pricePerLitre,
    required this.estimate,
    required this.low,
    required this.high,
  });

  final double pricePerLitre;

  /// price ÷ km/L.
  final double estimate;

  /// price ÷ the band's high km/L; null when the band has no top.
  final double? low;

  /// price ÷ the band's low km/L.
  final double high;
}

/// The cost of riding one km at the last price paid, as an honest range.
/// Null until there is an estimate.
CostPerKm? costPerKm(List<LogEntry> log, OverallEstimate? current) {
  final last = log.whereType<RefuelEntry>().lastOrNull;
  if (current == null || last == null) return null;
  final price = last.pricePerLitre;
  final bandHigh = current.band.high;
  return CostPerKm(
    pricePerLitre: price,
    estimate: price / current.kmpl,
    low: bandHigh == null ? null : price / bandHigh,
    high: price / current.band.low,
  );
}

/// Fuel bought in one calendar month.
class MonthSpend {
  const MonthSpend({
    required this.year,
    required this.month,
    required this.rupees,
    required this.litres,
    required this.fills,
  });

  final int year;
  final int month;
  final double rupees;
  final double litres;
  final int fills;
}

/// Spend per calendar month, newest first. Every refuel counts, in a chain
/// or not: money spent is money spent.
List<MonthSpend> monthlySpend(List<LogEntry> log) {
  final byMonth = <int, MonthSpend>{};
  for (final refuel in log.whereType<RefuelEntry>()) {
    final key = refuel.date.year * 12 + refuel.date.month - 1;
    final soFar = byMonth[key];
    byMonth[key] = MonthSpend(
      year: refuel.date.year,
      month: refuel.date.month,
      rupees: (soFar?.rupees ?? 0) + refuel.amount,
      litres: (soFar?.litres ?? 0) + refuel.litres,
      fills: (soFar?.fills ?? 0) + 1,
    );
  }
  final keys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final key in keys) byMonth[key]!];
}

/// Money spent on fuel in the [days] days up to and including [today].
double spendInLastDays(List<LogEntry> log, DateTime today, {int days = 30}) {
  final end = _day(today);
  final start = end.subtract(Duration(days: days - 1));
  var total = 0.0;
  for (final refuel in log.whereType<RefuelEntry>()) {
    final day = _day(refuel.date);
    if (!day.isBefore(start) && !day.isAfter(end)) total += refuel.amount;
  }
  return total;
}

/// The estimate for one fuel grade.
class GradeEstimate {
  const GradeEstimate({required this.grade, required this.estimate});

  final FuelGrade grade;
  final OverallEstimate estimate;
}

class GradeComparison {
  const GradeComparison({
    required this.byGrade,
    required this.mixedChains,
    required this.untaggedChains,
  });

  /// One entry per grade with at least one single-grade accepted chain, in
  /// [FuelGrade] order.
  final List<GradeEstimate> byGrade;

  /// Accepted chains whose counted fills mix grades: left out.
  final int mixedChains;

  /// Accepted chains with a counted fill whose grade wasn't recorded: left out.
  final int untaggedChains;
}

/// Compares fuel grades using the chains since the last service only, so a
/// service never mixes into a fuel comparison. A chain counts for a grade
/// only when every fill counted in it is that grade.
GradeComparison compareGrades(LogAnalysis analysis) {
  final chainsByGrade = <FuelGrade, List<Chain>>{};
  var mixed = 0;
  var untagged = 0;
  for (final chain in analysis.periods.last.chains) {
    if (!chain.countsTowardEstimate) continue;
    final grades = {for (final fill in chain.countedFills) fill.grade};
    if (grades.contains(null)) {
      untagged++;
    } else if (grades.length > 1) {
      mixed++;
    } else {
      chainsByGrade.putIfAbsent(grades.single!, () => []).add(chain);
    }
  }
  return GradeComparison(
    byGrade: [
      for (final grade in FuelGrade.values)
        if (chainsByGrade[grade] case final chains?)
          GradeEstimate(grade: grade, estimate: overallEstimate(chains)!),
    ],
    mixedChains: mixed,
    untaggedChains: untagged,
  );
}

/// Chains with a result, oldest first, and where services fall between them.
class TrendSeries {
  const TrendSeries({required this.points, required this.servicesBefore});

  /// Closed, flagged and discarded chains (anything with a km/L).
  final List<Chain> points;

  /// For each service, the index in [points] of the first result after it.
  /// Equal to `points.length` when no result has come after it yet.
  final List<int> servicesBefore;
}

TrendSeries trendSeries(LogAnalysis analysis) {
  final points = <Chain>[];
  final servicesBefore = <int>[];
  for (final period in analysis.periods) {
    if (period.startedBy != null) servicesBefore.add(points.length);
    points.addAll(period.chains.where((c) => c.kmpl != null));
  }
  return TrendSeries(points: points, servicesBefore: servicesBefore);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
