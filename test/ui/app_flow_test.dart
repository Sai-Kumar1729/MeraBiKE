import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mera_bike/app/app_state.dart';
import 'package:mera_bike/data/database.dart';
import 'package:mera_bike/data/repository.dart';
import 'package:mera_bike/data/seed.dart';
import 'package:mera_bike/engine/engine.dart';
import 'package:mera_bike/ui/app.dart';

void main() {
  late AppDatabase db;
  late AppState state;

  /// The app as on first launch: Glamour + the owner's five entries.
  Future<void> launch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      db = AppDatabase(NativeDatabase.memory());
      final repo = MileageRepository(db);
      final catalog = parseBikeCatalog(
        File('assets/bikes.json').readAsStringSync(),
      );
      await seedOnFirstLaunch(repo, catalog);
      state = AppState(repo, catalog);
      await state.load();
    });
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(MeraBikeApp(state: state));
  }

  /// Taps, lets the database write finish, then settles the UI.
  Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> passOnboarding(WidgetTester tester) async {
    expect(find.text('The anchor'), findsOneWidget);
    expect(find.textContaining('second-last bar disappears'), findsOneWidget);
    await tapAndWait(tester, find.text('Start'));
  }

  testWidgets('first launch: onboarding, then Home with the owner\'s data', (
    tester,
  ) async {
    await launch(tester);
    await passOnboarding(tester);

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
    await launch(tester);
    await passOnboarding(tester);
    await tapAndWait(tester, find.text('History'));

    expect(find.text('Flagged'), findsOneWidget);
    expect(find.text('Logged a fill twice or a wrong amount?'), findsOneWidget);
    expect(find.text('Missed a refuel?'), findsNothing);
    await tapAndWait(tester, find.text('Bike may need attention'));

    await tapAndWait(tester, find.text('Home'));
    expect(find.text('29.5–35.2 km/L, High'), findsOneWidget);
  });

  testWidgets('log refuel: the anchor toggle follows the gauge', (
    tester,
  ) async {
    await launch(tester);
    await passOnboarding(tester);
    await tapAndWait(tester, find.text('Log refuel'));

    expect(find.widgetWithText(TextFormField, '83336'), findsOneWidget);
    SwitchListTile toggle() =>
        tester.widget<SwitchListTile>(find.byType(SwitchListTile));

    await tapAndWait(tester, find.text('1 bar'));
    expect(toggle().value, isTrue);
    expect(find.textContaining('Closes your 1 bar chain'), findsOneWidget);

    await tapAndWait(tester, find.text('Filled to full'));
    expect(toggle().value, isFalse);
    expect(find.textContaining('Warning: your open chain'), findsOneWidget);

    await tapAndWait(tester, find.text("I don't know"));
    expect(toggle().onChanged, isNull);
  });

  testWidgets('an anchor with the odometer left unchanged is refused', (
    tester,
  ) async {
    await launch(tester);
    await passOnboarding(tester);
    await tapAndWait(tester, find.text('Log refuel'));
    await tapAndWait(tester, find.text('₹200'));
    await tapAndWait(tester, find.text('1 bar'));
    await tapAndWait(tester, find.text('Save refuel'));

    expect(find.textContaining('Update the odometer'), findsOneWidget);
    expect(state.log, hasLength(5), reason: 'nothing saved');
  });

  testWidgets('every input on every form has a label', (tester) async {
    await launch(tester);
    await passOnboarding(tester);

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

    await tapAndWait(tester, find.text('Log refuel'));
    expectAllLabelled('Log refuel');
    await tapAndWait(tester, find.byTooltip('Back'));

    await tapAndWait(tester, find.text('Add missed refuel'));
    expectAllLabelled('Add missed refuel');
    await tapAndWait(tester, find.byTooltip('Back'));

    await tapAndWait(tester, find.text('Log service'));
    expectAllLabelled('Log service');
    await tapAndWait(tester, find.byTooltip('Back'));

    await tapAndWait(tester, find.text('Bike'));
    expectAllLabelled('Bike setup');
  });
}
