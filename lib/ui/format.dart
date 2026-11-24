import 'package:material_ui/material_ui.dart';

import '../engine/engine.dart';

/// Indian digit grouping: 83,336 and 1,00,125.
String groupedInt(int value) {
  final digits = value.abs().toString();
  if (digits.length <= 3) return value < 0 ? '-$digits' : digits;
  final last3 = digits.substring(digits.length - 3);
  var rest = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  parts.insert(0, rest);
  return '${value < 0 ? '-' : ''}${parts.join(',')},$last3';
}

String km(int value) => '${groupedInt(value)} km';

String litres(double value) => '${value.toStringAsFixed(2)} L';

String rupees(double value) => value == value.roundToDouble()
    ? '₹${groupedInt(value.round())}'
    : '₹${value.toStringAsFixed(2)}';

String kmpl(double value) => value.toStringAsFixed(1);

/// "29.5–35.2 km/L", or "29.5+ km/L" when the top is unbounded.
String bandText(KmplBand band) {
  final high = band.high;
  return high == null
      ? '${kmpl(band.low)}+ km/L'
      : '${kmpl(band.low)}–${kmpl(high)} km/L';
}

String confidenceLabel(Confidence c) => switch (c) {
  Confidence.low => 'Low',
  Confidence.medium => 'Medium',
  Confidence.high => 'High',
};

String date(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatMediumDate(value);

String statusLabel(Chain chain) => switch (chain.status) {
  ChainStatus.open => 'Open',
  ChainStatus.closed =>
    chain.plausibility == Plausibility.inRange ? 'Closed' : 'Accepted',
  ChainStatus.flagged => 'Flagged',
  ChainStatus.discarded => 'Discarded',
  ChainStatus.broken => 'Broken',
};

String breakReasonText(BreakReason reason) => switch (reason) {
  BreakReason.service => 'Ended by a service',
  BreakReason.levelChanged => 'Ended by an anchor at a different level',
  BreakReason.odometerNotIncreasing =>
    'Closing odometer is not above the start: check the readings',
  BreakReason.noFuelCounted => 'No fuel counted',
};

/// Short label for picking a chain: "1 Nov → 12 Nov · 1 bar · Closed".
String chainLabel(BuildContext context, Chain chain) {
  final endEntry = chain.end ?? chain.brokenBy;
  final span = endEntry == null
      ? '${date(context, chain.start.date)} → now'
      : '${date(context, chain.start.date)} → ${date(context, endEntry.date)}';
  return '$span · ${chain.level} · ${statusLabel(chain)}';
}
