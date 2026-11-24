import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mera_bike/engine/engine.dart';

import 'harness.dart';

void main() {
  final today = DateTime(2026, 11, 24);

  testWidgets('Insights: cost range, trend, spend and the fuel comparison', (
    tester,
  ) async {
    final h = AppHarness();
    await h.launch(tester, today: today);
    await h.passOnboarding(tester);
    await h.acceptFlaggedChain(tester);
    await h.tap(tester, find.text('Insights'));

    // ₹116 ÷ 35.21..29.51 km/L.
    expect(find.text('₹3.29–3.93'), findsOneWidget);
    // The five seeded fills (1–14 Nov): ₹1,208, about ₹40 a day.
    expect(find.text('₹1,208'), findsWidgets);
    expect(find.text('About ₹40 a day'), findsOneWidget);
    expect(find.text('Mileage trend'), findsOneWidget);
    expect(
      find.textContaining('32.1 km/L (29.5–35.2 km/L) · 8.03 L · Accepted'),
      findsOneWidget,
    );
    expect(find.text('Nov 2026'), findsOneWidget);
    // The seeded fills have no fuel type yet.
    expect(find.textContaining('Pick the fuel type'), findsOneWidget);
    expect(find.textContaining('Left out: 1 untagged chain.'), findsOneWidget);
  });

  testWidgets('log refuel: fuel type starts at Regular and is saved', (
    tester,
  ) async {
    final h = AppHarness();
    await h.launch(tester, today: today);
    await h.passOnboarding(tester);
    await h.tap(tester, find.text('Log refuel'));

    ChoiceChip chip(String label) =>
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));
    expect(chip('Regular').selected, isTrue);

    await tester.enterText(
      find.widgetWithText(TextFormField, '83336'),
      '83420',
    );
    await h.tap(tester, find.text('₹200'));
    await h.tap(tester, find.text('Premium'));
    await h.tap(tester, find.text('Save refuel'));

    final saved = h.state.log.last as RefuelEntry;
    expect(saved.amount, 200);
    expect(saved.odometer, 83420);
    expect(saved.grade, FuelGrade.premium);
    expect(h.state.lastFuelGrade, FuelGrade.premium);
  });

  testWidgets('Home asks for a backup folder; turning it on backs up now', (
    tester,
  ) async {
    final h = AppHarness();
    await h.launch(tester, today: today);
    await h.passOnboarding(tester);

    expect(find.text('Your data lives only on this phone'), findsOneWidget);
    await h.tap(tester, find.text('Turn on'));

    expect(h.bridge.files.keys, ['merabike-auto-2026-11-24.json']);
    expect(find.text('Your data lives only on this phone'), findsNothing);
  });

  testWidgets('reminders set on the Bike tab show on Home', (tester) async {
    final h = AppHarness();
    await h.launch(tester, today: today);
    await h.passOnboarding(tester);
    await h.tap(tester, find.text('Bike'));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Service every').first,
      '3000',
    );
    await h.tap(tester, find.text('Save reminders'));
    await tester.runAsync(
      () => h.state.saveReminders(
        ReminderSettings(
          serviceEveryKm: h.state.reminderSettings.serviceEveryKm,
          insuranceExpiry: DateTime(2026, 12, 4),
        ),
      ),
    );
    await h.tap(tester, find.text('Home'));

    expect(find.text('Service'), findsOneWidget);
    expect(find.textContaining('Log your last service'), findsOneWidget);
    expect(find.text('Insurance'), findsOneWidget);
    expect(find.textContaining('Expires in 10 days'), findsOneWidget);
  });

  testWidgets('the share card shows the range and what it rests on', (
    tester,
  ) async {
    final h = AppHarness();
    await h.launch(tester, today: today);
    await h.passOnboarding(tester);
    await h.acceptFlaggedChain(tester);
    await h.tap(tester, find.text('Home'));
    await h.tap(tester, find.byTooltip('Share your mileage'));

    expect(find.text('Share your mileage'), findsWidgets);
    expect(find.text('29.5–35.2 km/L'), findsOneWidget);
    expect(
      find.text('High confidence · measured from 8.03 L of real fills'),
      findsOneWidget,
    );
    expect(find.text('₹3.29–3.93 per km'), findsOneWidget);
  });
}
