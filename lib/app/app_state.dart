import 'package:flutter/widgets.dart';

import '../data/backup.dart';
import '../data/repository.dart';
import '../engine/engine.dart';

/// The app's data and the engine's view of it. Every change is written to
/// the database first, then everything is reloaded and re-analysed, so the
/// screens always show what is stored.
class AppState extends ChangeNotifier {
  AppState(this._repo, this.catalog);

  final MileageRepository _repo;

  /// Bike models from assets/bikes.json.
  final List<BikeModel> catalog;

  StoredData _data = const StoredData(
    bike: null,
    log: [],
    decisions: [],
    settings: {},
  );
  LogAnalysis? _analysis;

  Bike? get bike => _data.bike;
  List<LogEntry> get log => _data.log;

  /// Null until a bike is set up.
  LogAnalysis? get analysis => _analysis;

  double? get lastPricePerLitre =>
      double.tryParse(_data.settings[SettingKeys.lastPricePerLitre] ?? '');

  bool get onboardingDone =>
      _data.settings[SettingKeys.onboardingDone] == 'true';

  /// The most recent odometer reading in the log, as shown on the bike.
  int? get lastOdometer {
    for (final entry in log.reversed) {
      final reading = entry.odometer;
      if (reading != null) return reading;
    }
    return null;
  }

  /// The catalog entry for the bike, if its model is listed.
  BikeModel? get bikeModel {
    final model = bike?.model;
    for (final m in catalog) {
      if (m.model == model) return m;
    }
    return null;
  }

  Future<void> load() async {
    _data = await _repo.load();
    final bike = _data.bike;
    _analysis = bike == null
        ? null
        : analyzeLog(_data.log, bike, decisions: _data.decisions);
    notifyListeners();
  }

  Future<void> addRefuel(RefuelEntry entry) async {
    await _repo.insertEntry(entry);
    await _rememberPrice(entry.pricePerLitre);
    await load();
  }

  /// Puts a forgotten refuel inside [chain], in date order.
  Future<void> addMissedRefuel(Chain chain, RefuelEntry entry) async {
    await _repo.insertEntry(
      entry,
      index: missedRefuelIndex(log, chain, entry.date),
    );
    await load();
  }

  Future<void> addService(ServiceEvent service) async {
    await _repo.insertEntry(service);
    await load();
  }

  Future<void> updateEntry(LogEntry entry) async {
    await _repo.updateEntry(entry);
    if (entry is RefuelEntry) await _rememberPrice(entry.pricePerLitre);
    await load();
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    await load();
  }

  Future<void> decide(Chain chain, ChainDecisionKind kind) async {
    await _repo.saveDecision(
      ChainDecision(
        startEntryId: chain.start.id,
        endEntryId: chain.end!.id,
        kind: kind,
      ),
    );
    await load();
  }

  Future<void> undoDecision(Chain chain) async {
    await _repo.clearDecision(chain.start.id, chain.end!.id);
    await load();
  }

  Future<void> saveBike(Bike bike) async {
    await _repo.saveBike(bike);
    await load();
  }

  Future<void> finishOnboarding() async {
    await _repo.setSetting(SettingKeys.onboardingDone, 'true');
    await load();
  }

  String exportJson(DateTime now) => encodeBackup(
    Backup(
      bike: bike,
      log: log,
      decisions: _data.decisions,
      settings: _data.settings,
    ),
    exportedAt: now,
  );

  /// Replaces all data with the backup. Throws [FormatException] (and
  /// changes nothing) if the file is not a valid backup.
  Future<void> importJson(String text) async {
    await _repo.replaceAll(decodeBackup(text));
    await load();
  }

  Future<void> _rememberPrice(double price) =>
      _repo.setSetting(SettingKeys.lastPricePerLitre, '$price');
}

/// Makes the [AppState] available to every screen.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
