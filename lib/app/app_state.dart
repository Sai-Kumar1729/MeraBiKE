import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../data/android_bridge.dart';
import '../data/auto_backup.dart';
import '../data/backup.dart';
import '../data/repository.dart';
import '../engine/engine.dart';

/// The app's data and the engine's view of it. Every change is written to
/// the database first, then everything is reloaded and re-analysed, so the
/// screens always show what is stored. If a backup folder is set, every
/// change is also backed up there.
class AppState extends ChangeNotifier {
  AppState(
    this._repo,
    this.catalog, {
    this.bridge = const AndroidBridge(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final MileageRepository _repo;

  /// Bike models from assets/bikes.json.
  final List<BikeModel> catalog;

  final AndroidBridge bridge;
  final DateTime Function() _clock;

  StoredData _data = const StoredData(
    bike: null,
    log: [],
    decisions: [],
    settings: {},
  );
  LogAnalysis? _analysis;

  Bike? get bike => _data.bike;
  List<LogEntry> get log => _data.log;
  DateTime get today => _clock();

  /// Null until a bike is set up.
  LogAnalysis? get analysis => _analysis;

  String? _setting(String key) => _data.settings[key];

  double? get lastPricePerLitre =>
      double.tryParse(_setting(SettingKeys.lastPricePerLitre) ?? '');

  /// The fuel grade used last, so the next refuel starts with it.
  FuelGrade get lastFuelGrade =>
      FuelGrade.values.asNameMap()[_setting(SettingKeys.lastFuelGrade)] ??
      FuelGrade.regular;

  bool get onboardingDone => _setting(SettingKeys.onboardingDone) == 'true';

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

  // Insights.

  CostPerKm? get rupeesPerKm => costPerKm(log, analysis?.current);
  List<MonthSpend> get spendByMonth => monthlySpend(log);
  double get spendLast30Days => spendInLastDays(log, today);
  GradeComparison? get gradeComparison =>
      analysis == null ? null : compareGrades(analysis!);
  TrendSeries? get trend => analysis == null ? null : trendSeries(analysis!);

  // Reminders.

  ReminderSettings get reminderSettings => ReminderSettings(
    serviceEveryKm: int.tryParse(_setting(SettingKeys.serviceEveryKm) ?? ''),
    serviceEveryDays: int.tryParse(
      _setting(SettingKeys.serviceEveryDays) ?? '',
    ),
    insuranceExpiry: DateTime.tryParse(
      _setting(SettingKeys.insuranceExpiry) ?? '',
    ),
    pucExpiry: DateTime.tryParse(_setting(SettingKeys.pucExpiry) ?? ''),
  );

  List<ReminderStatus> get reminders => analysis == null
      ? const []
      : reminderStatuses(
          log: log,
          analysis: analysis!,
          settings: reminderSettings,
          today: today,
        );

  Future<void> saveReminders(ReminderSettings settings) async {
    await _put(SettingKeys.serviceEveryKm, settings.serviceEveryKm?.toString());
    await _put(
      SettingKeys.serviceEveryDays,
      settings.serviceEveryDays?.toString(),
    );
    await _put(SettingKeys.insuranceExpiry, _isoDay(settings.insuranceExpiry));
    await _put(SettingKeys.pucExpiry, _isoDay(settings.pucExpiry));
    await _changed();
  }

  // Automatic backup.

  bool get autoBackupOn => _setting(SettingKeys.backupFolderUri) != null;
  String? get backupFolderName => _setting(SettingKeys.backupFolderName);
  DateTime? get lastBackupAt =>
      DateTime.tryParse(_setting(SettingKeys.lastBackupAt) ?? '');
  String? get lastBackupError => _setting(SettingKeys.lastBackupError);

  /// Asks for a folder and backs up there from now on. False if cancelled.
  Future<bool> chooseBackupFolder() async {
    final folder = await bridge.pickFolder();
    if (folder == null) return false;
    await _repo.setSetting(SettingKeys.backupFolderUri, folder.uri);
    await _repo.setSetting(SettingKeys.backupFolderName, folder.name);
    await _repo.removeSetting(SettingKeys.lastBackupError);
    await load();
    await backupNow();
    return true;
  }

  Future<void> turnOffAutoBackup() async {
    for (final key in SettingKeys.deviceOnly) {
      await _repo.removeSetting(key);
    }
    await load();
  }

  /// Writes today's backup file and prunes old ones. Failures are recorded
  /// (and shown on Home), never thrown: the owner's change is already saved.
  Future<void> backupNow() async {
    final folder = _setting(SettingKeys.backupFolderUri);
    if (folder == null) return;
    final now = today;
    try {
      await bridge.writeToFolder(
        folder,
        autoBackupFileName(now),
        exportJson(now),
      );
      final stale = autoBackupsToDelete(await bridge.listFolder(folder));
      for (final name in stale) {
        await bridge.deleteFromFolder(folder, name);
      }
      await _repo.setSetting(SettingKeys.lastBackupAt, now.toIso8601String());
      await _repo.removeSetting(SettingKeys.lastBackupError);
    } on PlatformException catch (e) {
      await _repo.setSetting(
        SettingKeys.lastBackupError,
        e.message ?? 'Backup failed (${e.code})',
      );
    } on MissingPluginException {
      await _repo.setSetting(
        SettingKeys.lastBackupError,
        'Backup is not available on this device',
      );
    }
    await load();
  }

  // Loading and changing the log.

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
    await _rememberFill(entry);
    await _changed();
  }

  /// Puts a forgotten refuel inside [chain], in date order.
  Future<void> addMissedRefuel(Chain chain, RefuelEntry entry) async {
    await _repo.insertEntry(
      entry,
      index: missedRefuelIndex(log, chain, entry.date),
    );
    await _changed();
  }

  Future<void> addService(ServiceEvent service) async {
    await _repo.insertEntry(service);
    await _changed();
  }

  Future<void> updateEntry(LogEntry entry) async {
    await _repo.updateEntry(entry);
    if (entry is RefuelEntry) await _rememberFill(entry);
    await _changed();
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    await _changed();
  }

  Future<void> decide(Chain chain, ChainDecisionKind kind) async {
    await _repo.saveDecision(
      ChainDecision(
        startEntryId: chain.start.id,
        endEntryId: chain.end!.id,
        kind: kind,
      ),
    );
    await _changed();
  }

  Future<void> undoDecision(Chain chain) async {
    await _repo.clearDecision(chain.start.id, chain.end!.id);
    await _changed();
  }

  Future<void> saveBike(Bike bike) async {
    await _repo.saveBike(bike);
    await _changed();
  }

  Future<void> finishOnboarding() async {
    await _repo.setSetting(SettingKeys.onboardingDone, 'true');
    await load();
  }

  /// Everything except this phone's backup-folder permission, which would
  /// be meaningless on another device.
  String exportJson(DateTime now) => encodeBackup(
    Backup(
      bike: bike,
      log: log,
      decisions: _data.decisions,
      settings: _portableSettings(_data.settings),
    ),
    exportedAt: now,
  );

  /// Replaces all data with the backup, keeping this phone's backup folder.
  /// Throws [FormatException] (and changes nothing) if the file is not a
  /// valid backup.
  Future<void> importJson(String text) async {
    final backup = decodeBackup(text);
    final thisPhone = {
      for (final key in SettingKeys.deviceOnly) key: ?_setting(key),
    };
    await _repo.replaceAll(
      Backup(
        bike: backup.bike,
        log: backup.log,
        decisions: backup.decisions,
        settings: {..._portableSettings(backup.settings), ...thisPhone},
      ),
    );
    await _changed();
  }

  Future<void> _changed() async {
    await load();
    await backupNow();
  }

  Future<void> _rememberFill(RefuelEntry entry) async {
    await _repo.setSetting(
      SettingKeys.lastPricePerLitre,
      '${entry.pricePerLitre}',
    );
    final grade = entry.grade;
    if (grade != null) {
      await _repo.setSetting(SettingKeys.lastFuelGrade, grade.name);
    }
  }

  Future<void> _put(String key, String? value) =>
      value == null ? _repo.removeSetting(key) : _repo.setSetting(key, value);
}

Map<String, String> _portableSettings(Map<String, String> settings) => {
  for (final MapEntry(:key, :value) in settings.entries)
    if (!SettingKeys.deviceOnly.contains(key)) key: value,
};

String? _isoDay(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

/// Makes the [AppState] available to every screen.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  /// Rebuilds the caller when the state changes.
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// For callbacks and lifecycle methods: no rebuild dependency.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
