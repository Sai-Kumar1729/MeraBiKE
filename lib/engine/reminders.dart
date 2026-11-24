/// Service, insurance and PUC reminders, worked out from the log. Shown in
/// the app; no notifications.
library;

import 'analysis.dart';
import 'models.dart';

/// What the owner wants reminding about. Everything is optional.
class ReminderSettings {
  const ReminderSettings({
    this.serviceEveryKm,
    this.serviceEveryDays,
    this.insuranceExpiry,
    this.pucExpiry,
  });

  final int? serviceEveryKm;
  final int? serviceEveryDays;
  final DateTime? insuranceExpiry;
  final DateTime? pucExpiry;
}

enum ReminderKind { service, insurance, puc }

enum DueState { ok, dueSoon, overdue }

/// A service is due soon within this many km...
const serviceSoonKm = 300;

/// ...or this many days.
const serviceSoonDays = 7;

/// Insurance and PUC are due soon within this many days of expiry.
const papersSoonDays = 15;

class ReminderStatus {
  const ReminderStatus({
    required this.kind,
    required this.state,
    this.kmLeft,
    this.daysLeft,
    this.dueOdometer,
    this.dueDate,
    this.needsLastService = false,
  });

  final ReminderKind kind;
  final DueState state;

  /// Negative once overdue.
  final int? kmLeft;

  /// Negative once overdue.
  final int? daysLeft;

  /// The (rollover-corrected) reading at which a service is due.
  final int? dueOdometer;
  final DateTime? dueDate;

  /// A service interval is set, but no service is logged to count from.
  final bool needsLastService;
}

/// Reminder states on [today]. Services count from the last logged service;
/// km use the latest odometer reading in the log.
List<ReminderStatus> reminderStatuses({
  required List<LogEntry> log,
  required LogAnalysis analysis,
  required ReminderSettings settings,
  required DateTime today,
}) => [
  if (settings.serviceEveryKm != null || settings.serviceEveryDays != null)
    _service(log, analysis, settings, today),
  if (settings.insuranceExpiry case final expiry?)
    _paper(ReminderKind.insurance, expiry, today),
  if (settings.pucExpiry case final expiry?)
    _paper(ReminderKind.puc, expiry, today),
];

ReminderStatus _service(
  List<LogEntry> log,
  LogAnalysis analysis,
  ReminderSettings settings,
  DateTime today,
) {
  final last = log.whereType<ServiceEvent>().lastOrNull;
  if (last == null) {
    return const ReminderStatus(
      kind: ReminderKind.service,
      state: DueState.ok,
      needsLastService: true,
    );
  }
  final everyKm = settings.serviceEveryKm;
  final everyDays = settings.serviceEveryDays;
  final base = analysis.correctedOdometer(last) ?? last.odometer;
  final dueOdometer = everyKm == null ? null : base + everyKm;
  final kmLeft = dueOdometer == null
      ? null
      : dueOdometer - (analysis.latestOdometer ?? base);
  final dueDate = everyDays == null
      ? null
      : _day(last.date).add(Duration(days: everyDays));
  final daysLeft = dueDate == null ? null : _daysBetween(today, dueDate);

  final overdue =
      (kmLeft != null && kmLeft < 0) || (daysLeft != null && daysLeft < 0);
  final soon =
      (kmLeft != null && kmLeft <= serviceSoonKm) ||
      (daysLeft != null && daysLeft <= serviceSoonDays);
  return ReminderStatus(
    kind: ReminderKind.service,
    state: overdue
        ? DueState.overdue
        : soon
        ? DueState.dueSoon
        : DueState.ok,
    kmLeft: kmLeft,
    daysLeft: daysLeft,
    dueOdometer: dueOdometer,
    dueDate: dueDate,
  );
}

ReminderStatus _paper(ReminderKind kind, DateTime expiry, DateTime today) {
  final daysLeft = _daysBetween(today, expiry);
  return ReminderStatus(
    kind: kind,
    state: daysLeft < 0
        ? DueState.overdue
        : daysLeft <= papersSoonDays
        ? DueState.dueSoon
        : DueState.ok,
    daysLeft: daysLeft,
    dueDate: _day(expiry),
  );
}

/// Whole calendar days from [from] to [to] (negative if [to] is earlier).
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
