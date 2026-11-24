import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness.dart';

void main() {
  testWidgets('first launch: onboarding, then Home with the owner\'s data', (
    tester,
  ) async {
    final h = AppHarness();
    await h.launch(tester);
    await h.passOnboarding(tester);

    // 32.1 km/L is below the placeholder Glamour fence (40–65), so chain 1
    // waits for review and there is no estimate yet.
    expect(find.text('1 chain needs your review'), findsOneWidget);
    expect(find.text('No result yet'), findsOneWidget);
    expect(
      find.text('2.4 L logged, ~2 L more to reach Medium'),
      findsOneWidget,
    );
    expect(find.text('Km left (rough estimate)'), findsOneWidget);
  });

  testWidgets('a low flagged chain offers the low-side prompts; accepting '
      'it gives the estimate', (tester) async {
    final h = AppHarness();
    await h.launch(tester);
    await h.passOnboarding(tester);
    await h.tap(tester, find.text('History'));

    expect(find.text('Flagged'), findsOneWidget);
    expect(find.text('Logged a fill twice or a wrong amount?'), findsOneWidget);
    expect(find.text('Missed a refuel?'), findsNothing);
    await h.tap(tester, find.text('Bike may need attention'));

    await h.tap(tester, find.text('Home'));
    expect(find.text('29.5–35.2 km/L, High'), findsOneWidget);
  });

  testWidgets('log refuel: the anchor toggle follows the gauge', (
    tester,
  ) async {
    final h = AppHarness();
    await h.launch(tester);
    await h.passOnboarding(tester);
    await h.tap(tester, find.text('Log refuel'));

    expect(find.widgetWithText(TextFormField, '83336'), findsOneWidget);
    SwitchListTile toggle() =>
        tester.widget<SwitchListTile>(find.byType(SwitchListTile));

    await h.tap(tester, find.text('1 bar'));
    expect(toggle().value, isTrue);
    expect(find.textContaining('Closes your 1 bar chain'), findsOneWidget);

    await h.tap(tester, find.text('Filled to full'));
    expect(toggle().value, isFalse);
    expect(find.textContaining('Warning: your open chain'), findsOneWidget);

    await h.tap(tester, find.text("I don't know"));
    expect(toggle().onChanged, isNull);
  });

  testWidgets('an anchor with the odometer left unchanged is refused', (
    tester,
  ) async {
    final h = AppHarness();
    await h.launch(tester);
    await h.passOnboarding(tester);
    await h.tap(tester, find.text('Log refuel'));
    await h.tap(tester, find.text('₹200'));
    await h.tap(tester, find.text('1 bar'));
    await h.tap(tester, find.text('Save refuel'));

    expect(find.textContaining('Update the odometer'), findsOneWidget);
    expect(h.state.log, hasLength(5), reason: 'nothing saved');
  });

  testWidgets('every input on every form has a label', (tester) async {
    final h = AppHarness();
    await h.launch(tester);
    await h.passOnboarding(tester);

    void expectAllLabelled(String screen) {
      final fields = tester.widgetList<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(fields, isNotEmpty, reason: screen);
      for (final field in fields) {
        expect(
          field.decoration.labelText,
          isNotNull,
          reason: 'unlabelled field on $screen',
        );
      }
    }

    await h.tap(tester, find.text('Log refuel'));
    expectAllLabelled('Log refuel');
    await h.tap(tester, find.byTooltip('Back'));

    await h.tap(tester, find.text('Add missed refuel'));
    expectAllLabelled('Add missed refuel');
    await h.tap(tester, find.byTooltip('Back'));

    await h.tap(tester, find.text('Log service'));
    expectAllLabelled('Log service');
    await h.tap(tester, find.byTooltip('Back'));

    await h.tap(tester, find.text('Bike'));
    expectAllLabelled('Bike setup and reminders');
  });
}
