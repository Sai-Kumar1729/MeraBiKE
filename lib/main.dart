import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app_state.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'data/seed.dart';
import 'engine/engine.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final catalog = parseBikeCatalog(
    await rootBundle.loadString('assets/bikes.json'),
  );
  final repo = MileageRepository(AppDatabase.onDevice());
  await seedOnFirstLaunch(repo, catalog);
  final state = AppState(repo, catalog);
  await state.load();
  runApp(MeraBikeApp(state: state));
}
