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

import '../support/fake_bridge.dart';

/// The real app over an in-memory database and a fake Android bridge.
class AppHarness {
  late AppDatabase db;
  late AppState state;
  final bridge = FakeBridge();

  /// The app as on first launch: Glamour + the owner's five entries.
  Future<void> launch(WidgetTester tester, {DateTime? today}) async {
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
      state = AppState(
        repo,
        catalog,
        bridge: bridge,
        clock: today == null ? null : () => today,
      );
      await state.load();
    });
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(MeraBikeApp(state: state));
  }

  /// Taps, lets the database write finish, then settles the UI.
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await settle(tester);
  }

  /// Lets pending database work finish, then settles the UI.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> passOnboarding(WidgetTester tester) async {
    expect(find.text('The anchor'), findsOneWidget);
    expect(find.textContaining('second-last bar disappears'), findsOneWidget);
    await tap(tester, find.text('Start'));
  }

  /// Accepts the owner's flagged first chain ("Bike may need attention").
  Future<void> acceptFlaggedChain(WidgetTester tester) async {
    await tap(tester, find.text('History'));
    await tap(tester, find.text('Bike may need attention'));
  }
}
