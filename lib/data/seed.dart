import '../engine/engine.dart';
import 'repository.dart';

const placeholderDateNote = 'Placeholder date: update from UPI history';

/// The owner's first five refuels (Hero Glamour, ₹116/L). The dates are
/// placeholders until the owner sends the real ones.
List<RefuelEntry> ownerStartingLog() {
  RefuelEntry refuel(
    int day,
    double amount, {
    int? odometer,
    int? bars,
    bool anchor = false,
  }) => RefuelEntry(
    id: 'seed',
    date: DateTime(2026, 11, day, 9),
    odometer: odometer,
    amount: amount,
    pricePerLitre: 116,
    gaugeBars: bars,
    isAnchor: anchor,
    note: placeholderDateNote,
  );

  return [
    refuel(1, 116, odometer: 83050, bars: 1, anchor: true),
    refuel(4, 416),
    refuel(8, 400),
    refuel(12, 116, odometer: 83308, bars: 1, anchor: true),
    refuel(14, 160, odometer: 83336),
  ];
}

/// Runs once, on the very first launch: sets up the Hero Glamour from the
/// catalog and loads the owner's five entries.
Future<void> seedOnFirstLaunch(
  MileageRepository repo,
  List<BikeModel> catalog,
) async {
  final data = await repo.load();
  if (data.settings.containsKey(SettingKeys.seeded)) return;
  if (data.bike == null) {
    final glamour = catalog.where((m) => m.model == 'Hero Glamour');
    if (glamour.isNotEmpty) await repo.saveBike(glamour.first.toBike());
  }
  if (data.log.isEmpty) {
    for (final entry in ownerStartingLog()) {
      await repo.insertEntry(entry);
    }
    await repo.setSetting(SettingKeys.lastPricePerLitre, '116');
  }
  await repo.setSetting(SettingKeys.seeded, 'true');
}
