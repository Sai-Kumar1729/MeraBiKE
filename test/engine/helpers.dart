import 'package:mera_bike/engine/engine.dart';

/// A test bike whose fence (40–70 km/L) the scenarios below are built around.
final testBike = Bike(
  model: 'Test bike',
  tankLitres: 10,
  gaugeBars: 6,
  expectedKmplMin: 40,
  expectedKmplMax: 70,
);

/// Builds a log in order, one day per entry. Default price ₹100/L, so
/// ₹100 = 1 L.
class LogBuilder {
  LogBuilder({this.price = 100});

  final double price;
  final List<LogEntry> entries = [];
  DateTime _date = DateTime(2026, 1, 1);

  DateTime _nextDate() => _date = _date.add(const Duration(days: 1));

  /// An intermediate refuel: just an amount, odometer optional.
  void fill(
    String id,
    double amount, {
    int? odo,
    int? bars,
    FuelGrade? grade,
  }) => entries.add(
    RefuelEntry(
      id: id,
      date: _nextDate(),
      odometer: odo,
      amount: amount,
      pricePerLitre: price,
      gaugeBars: bars,
      grade: grade,
    ),
  );

  /// A pre-fill anchor: [bars] read before filling.
  void barsAnchor(
    String id, {
    required int odo,
    required int bars,
    required double amount,
    FuelGrade? grade,
  }) => entries.add(
    RefuelEntry(
      id: id,
      date: _nextDate(),
      odometer: odo,
      amount: amount,
      pricePerLitre: price,
      gaugeBars: bars,
      isAnchor: true,
      grade: grade,
    ),
  );

  /// A FULL anchor: filled to the neck.
  void fullAnchor(String id, {required int odo, required double amount}) =>
      entries.add(
        RefuelEntry(
          id: id,
          date: _nextDate(),
          odometer: odo,
          amount: amount,
          pricePerLitre: price,
          isFull: true,
          isAnchor: true,
        ),
      );

  void service(String id, {required int odo, String note = ''}) => entries.add(
    ServiceEvent(id: id, date: _nextDate(), odometer: odo, note: note),
  );
}

List<String> ids(Iterable<LogEntry> entries) => [for (final e in entries) e.id];
