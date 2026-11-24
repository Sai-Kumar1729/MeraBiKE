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

String gradeLabel(FuelGrade grade) => switch (grade) {
  FuelGrade.regular => 'Regular',
  FuelGrade.premium => 'Premium',
  FuelGrade.lowEthanol => 'E10 / ethanol-free',
};

/// "₹3.29–3.93", or "up to ₹3.93" when the band has no top.
String costRange(CostPerKm cost) {
  final low = cost.low;
  final high = cost.high.toStringAsFixed(2);
  return low == null ? 'up to ₹$high' : '₹${low.toStringAsFixed(2)}–$high';
}

/// "₹3.29–3.93 per km".
String costPerKmText(CostPerKm cost) => '${costRange(cost)} per km';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Nov 2026".
String monthLabel(int year, int month) => '${_months[month - 1]} $year';

String reminderTitle(ReminderKind kind) => switch (kind) {
  ReminderKind.service => 'Service',
  ReminderKind.insurance => 'Insurance',
  ReminderKind.puc => 'PUC certificate',
};

/// "Due in 200 km or 12 days (6 Dec)", "Overdue by 4 days (1 Apr)",
/// "Expires in 10 days (4 Dec)", "Expired 1 day ago (23 Nov)".
String reminderDetail(BuildContext context, ReminderStatus status) {
  if (status.needsLastService) {
    return 'Log your last service so the countdown can start';
  }
  final on = status.dueDate == null
      ? ''
      : ' (${date(context, status.dueDate!)})';
  final kmLeft = status.kmLeft;
  final daysLeft = status.daysLeft;

  if (status.kind != ReminderKind.service) {
    final left = daysLeft!;
    if (left < 0) return 'Expired ${_days(-left)} ago$on';
    if (left == 0) return 'Expires today$on';
    return 'Expires in ${_days(left)}$on';
  }
  if (status.state == DueState.overdue) {
    final by = [
      if (kmLeft != null && kmLeft < 0) km(-kmLeft),
      if (daysLeft != null && daysLeft < 0) _days(-daysLeft),
    ];
    return 'Overdue by ${by.join(' and ')}$on';
  }
  if (daysLeft == 0) return 'Due today$on';
  final within = [
    if (kmLeft != null) km(kmLeft),
    if (daysLeft != null) _days(daysLeft),
  ];
  return 'Due in ${within.join(' or ')}$on';
}

String _days(int n) => n == 1 ? '1 day' : '$n days';
