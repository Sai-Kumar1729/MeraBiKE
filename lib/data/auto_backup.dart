/// Naming and pruning for automatic backups: one file per day in the folder
/// the owner picked, the newest [autoBackupsKept] kept.
library;

const autoBackupsKept = 7;

final _ours = RegExp(r'^merabike-auto-\d{4}-\d{2}-\d{2}\.json$');

/// For example `merabike-auto-2026-11-24.json`. Later saves on the same day
/// replace that day's file.
String autoBackupFileName(DateTime day) =>
    'merabike-auto-${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}.json';

/// Our automatic backups in [names] beyond the newest [keep], oldest first.
/// Any other file in the folder is never touched.
List<String> autoBackupsToDelete(
  Iterable<String> names, {
  int keep = autoBackupsKept,
}) {
  final ours = names.where(_ours.hasMatch).toList()..sort();
  return ours.length <= keep ? const [] : ours.sublist(0, ours.length - keep);
}
