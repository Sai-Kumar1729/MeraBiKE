import 'package:flutter_test/flutter_test.dart';
import 'package:mera_bike/engine/engine.dart';

import 'helpers.dart';

void main() {
  RefuelEntry fill(String id, DateTime date, int odo) => RefuelEntry(
    id: id,
    date: date,
    odometer: odo,
    amount: 200,
    pricePerLitre: 100,
  );

  List<ReminderStatus> statuses(
    List<LogEntry> log,
    ReminderSettings settings,
    DateTime today, {
    Bike? bike,
  }) => reminderStatuses(
    log: log,
    analysis: analyzeLog(log, bike ?? testBike),
    settings: settings,
    today: today,
  );

  group('service', () {
    final log = <LogEntry>[
      ServiceEvent(id: 's', date: DateTime(2026, 1, 1), odometer: 10000),
      fill('f', DateTime(2026, 2, 1), 12800),
    ];

    test('by km: due soon within 300 km of the interval', () {
      final service = statuses(
        log,
        const ReminderSettings(serviceEveryKm: 3000),
        DateTime(2026, 2, 1),
      ).single;
      expect(service.kind, ReminderKind.service);
      expect(service.dueOdometer, 13000);
      expect(service.kmLeft, 200);
      expect(service.state, DueState.dueSoon);
    });

    test('by days: overdue once the date passes, whichever comes first', () {
      final service = statuses(
        log,
        const ReminderSettings(serviceEveryKm: 5000, serviceEveryDays: 90),
        DateTime(2026, 4, 5),
      ).single;
      expect(service.kmLeft, 2200);
      expect(service.dueDate, DateTime(2026, 4, 1));
      expect(service.daysLeft, -4);
      expect(service.state, DueState.overdue);
    });

    test('needs a logged service to count from', () {
      final service = statuses(
        [fill('f', DateTime(2026, 2, 1), 12800)],
        const ReminderSettings(serviceEveryKm: 3000),
        DateTime(2026, 2, 1),
      ).single;
      expect(service.needsLastService, isTrue);
    });

    test('counts across an odometer rollover', () {
      final rolled = <LogEntry>[
        ServiceEvent(id: 's', date: DateTime(2026, 1, 1), odometer: 99000),
        fill('f', DateTime(2026, 2, 1), 500), // 100,500 after the rollover
      ];
      final service = statuses(
        rolled,
        const ReminderSettings(serviceEveryKm: 3000),
        DateTime(2026, 2, 1),
      ).single;
      expect(service.kmLeft, 1500);
      expect(service.state, DueState.ok);
    });
  });

  test('insurance and PUC: due soon within 15 days, overdue after', () {
    final today = DateTime(2026, 11, 24);
    final result = statuses(
      const [],
      ReminderSettings(
        insuranceExpiry: DateTime(2026, 12, 4), // 10 days
        pucExpiry: DateTime(2026, 11, 23), // yesterday
      ),
      today,
    );
    expect(result.map((r) => r.kind), [
      ReminderKind.insurance,
      ReminderKind.puc,
    ]);
    expect(result[0].daysLeft, 10);
    expect(result[0].state, DueState.dueSoon);
    expect(result[1].daysLeft, -1);
    expect(result[1].state, DueState.overdue);

    final later = statuses(
      const [],
      ReminderSettings(insuranceExpiry: DateTime(2027, 3, 1)),
      today,
    ).single;
    expect(later.state, DueState.ok);
  });

  test('nothing set, nothing shown', () {
    expect(
      statuses(const [], const ReminderSettings(), DateTime(2026)),
      isEmpty,
    );
  });
}
