/// The JSON backup format: everything needed to rebuild the app's data after
/// a reinstall. Pure Dart, so it can be tested without a device.
library;

import 'dart:convert';

import '../engine/engine.dart';

const backupFormat = 'merabike-backup';
const backupVersion = 1;

/// The whole data set. Entry ids are the database ids, as strings.
class Backup {
  const Backup({
    required this.bike,
    required this.log,
    required this.decisions,
    required this.settings,
  });

  final Bike? bike;
  final List<LogEntry> log;
  final List<ChainDecision> decisions;
  final Map<String, String> settings;
}

String encodeBackup(Backup backup, {required DateTime exportedAt}) =>
    const JsonEncoder.withIndent('  ').convert({
      'format': backupFormat,
      'version': backupVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'bike': backup.bike == null ? null : bikeToJson(backup.bike!),
      'entries': [for (final entry in backup.log) _entryToJson(entry)],
      'decisions': [
        for (final d in backup.decisions)
          {
            'startEntryId': int.parse(d.startEntryId),
            'endEntryId': int.parse(d.endEntryId),
            'kind': d.kind.name,
          },
      ],
      'settings': backup.settings,
    });

/// Parses and fully validates a backup. Throws [FormatException] with a
/// readable message; nothing is half-read.
Backup decodeBackup(String text) {
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException {
    throw const FormatException('This file is not valid JSON.');
  }
  if (root is! Map<String, Object?> || root['format'] != backupFormat) {
    throw const FormatException('This is not a MeraBiKE backup file.');
  }
  final version = root['version'];
  if (version is! int || version > backupVersion) {
    throw FormatException(
      'This backup is version $version; this app reads up to $backupVersion.',
    );
  }
  try {
    final bikeJson = root['bike'];
    final entries = _list(root, 'entries');
    final log = [for (final e in entries) _entryFromJson(_map(e))];
    final ids = {for (final e in log) e.id};
    if (ids.length != log.length) {
      throw const FormatException('two entries share the same id');
    }
    return Backup(
      bike: bikeJson == null ? null : bikeFromJson(_map(bikeJson)),
      log: log,
      decisions: [
        for (final d in _list(root, 'decisions'))
          ChainDecision(
            startEntryId: '${_get<int>(_map(d), 'startEntryId')}',
            endEntryId: '${_get<int>(_map(d), 'endEntryId')}',
            kind: ChainDecisionKind.values.byName(
              _get<String>(_map(d), 'kind'),
            ),
          ),
      ],
      settings: {
        for (final MapEntry(:key, :value) in _map(root['settings']).entries)
          key: '$value',
      },
    );
  } on FormatException catch (e) {
    throw FormatException('Backup is damaged: ${e.message}');
  } on ArgumentError catch (e) {
    throw FormatException('Backup has an invalid value: ${e.message}');
  }
}

Map<String, Object?> bikeToJson(Bike bike) => {
  'model': bike.model,
  'tankLitres': bike.tankLitres,
  'gaugeBars': bike.gaugeBars,
  'expectedKmplMin': bike.expectedKmplMin,
  'expectedKmplMax': bike.expectedKmplMax,
  'prefillUncertaintyLitres': bike.prefillUncertaintyLitres,
  'fullUncertaintyLitres': bike.fullUncertaintyLitres,
  'odometerDigits': bike.odometerDigits,
};

Bike bikeFromJson(Map<String, Object?> json) => Bike(
  model: _get<String>(json, 'model'),
  tankLitres: _get<num>(json, 'tankLitres').toDouble(),
  gaugeBars: _get<int>(json, 'gaugeBars'),
  expectedKmplMin: _get<num>(json, 'expectedKmplMin').toDouble(),
  expectedKmplMax: _get<num>(json, 'expectedKmplMax').toDouble(),
  prefillUncertaintyLitres: _get<num>(
    json,
    'prefillUncertaintyLitres',
  ).toDouble(),
  fullUncertaintyLitres: _get<num>(json, 'fullUncertaintyLitres').toDouble(),
  odometerDigits: _get<int>(json, 'odometerDigits'),
);

Map<String, Object?> _entryToJson(LogEntry entry) => switch (entry) {
  RefuelEntry() => {
    'id': int.parse(entry.id),
    'kind': 'refuel',
    'date': entry.date.toIso8601String(),
    'odometer': entry.odometer,
    'amount': entry.amount,
    'pricePerLitre': entry.pricePerLitre,
    'gaugeBars': entry.gaugeBars,
    'isFull': entry.isFull,
    'isAnchor': entry.isAnchor,
    'note': entry.note,
  },
  ServiceEvent() => {
    'id': int.parse(entry.id),
    'kind': 'service',
    'date': entry.date.toIso8601String(),
    'odometer': entry.odometer,
    'note': entry.note,
  },
};

LogEntry _entryFromJson(Map<String, Object?> json) {
  final id = '${_get<int>(json, 'id')}';
  final date = DateTime.tryParse(_get<String>(json, 'date'));
  if (date == null) throw FormatException('entry $id has a bad date');
  return switch (_get<String>(json, 'kind')) {
    'refuel' => RefuelEntry(
      id: id,
      date: date,
      odometer: _opt<int>(json, 'odometer'),
      amount: _get<num>(json, 'amount').toDouble(),
      pricePerLitre: _get<num>(json, 'pricePerLitre').toDouble(),
      gaugeBars: _opt<int>(json, 'gaugeBars'),
      isFull: _get<bool>(json, 'isFull'),
      isAnchor: _get<bool>(json, 'isAnchor'),
      note: _opt<String>(json, 'note') ?? '',
    ),
    'service' => ServiceEvent(
      id: id,
      date: date,
      odometer: _get<int>(json, 'odometer'),
      note: _opt<String>(json, 'note') ?? '',
    ),
    final kind => throw FormatException('entry $id has unknown kind "$kind"'),
  };
}

T _get<T>(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! T) throw FormatException('"$key" must be a $T');
  return value;
}

T? _opt<T>(Map<String, Object?> json, String key) =>
    json[key] == null ? null : _get<T>(json, key);

Map<String, Object?> _map(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('expected an object');
  }
  return value;
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List<Object?>) throw FormatException('"$key" must be a list');
  return value;
}
