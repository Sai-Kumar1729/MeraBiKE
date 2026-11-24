/// The overall estimate across chains.
library;

import 'dart:math' as math;

import 'chain.dart';

/// The litres-weighted average of accepted chains. Weighting each chain's
/// km/L by its litres is the same as Σdistance ÷ Σlitres.
class OverallEstimate {
  const OverallEstimate({
    required this.chains,
    required this.distanceKm,
    required this.litres,
    required this.uncertaintyLitres,
  });

  /// The accepted chains behind this estimate.
  final List<Chain> chains;
  final int distanceKm;
  final double litres;

  /// Combined U. Back-to-back chains share their middle anchors, so those
  /// errors cancel: each unbroken run of chains has only its first and last
  /// readings left, worth one chain U (√2 × the per-reading U). Independent
  /// runs combine as √ΣU².
  final double uncertaintyLitres;

  double get kmpl => distanceKm / litres;

  KmplBand get band => KmplBand.from(
    distanceKm: distanceKm,
    litres: litres,
    uncertaintyLitres: uncertaintyLitres,
  );

  Confidence get confidence => Confidence.forLitres(litres);
}

/// The estimate over the accepted chains in [chains]; null if there are none.
/// Callers pass one service period's chains, never chains from both sides of
/// a service.
OverallEstimate? overallEstimate(List<Chain> chains) {
  final accepted = chains.where((c) => c.countsTowardEstimate).toList();
  if (accepted.isEmpty) return null;

  var distance = 0;
  var litres = 0.0;
  var uSquaredSum = 0.0;
  Chain? previous;
  for (final chain in accepted) {
    distance += chain.distanceKm!;
    litres += chain.litres;
    final continuesRun = previous != null && previous.end?.id == chain.start.id;
    if (!continuesRun) {
      uSquaredSum += chain.uncertaintyLitres * chain.uncertaintyLitres;
    }
    previous = chain;
  }
  return OverallEstimate(
    chains: List.unmodifiable(accepted),
    distanceKm: distance,
    litres: litres,
    uncertaintyLitres: math.sqrt(uSquaredSum),
  );
}
