# MeraBiKE

Personal Android app (Flutter) that estimates a motorcycle's real fuel mileage
from partial refuels, without full-tank tests. One user. Fully offline: no
backend, no login, no GPS, no analytics, no ads.

## Working agreement

- Build in phases and STOP after each phase for the owner's review.
  - Phase 1: engine + unit tests, pure Dart. (Built; awaiting review.)
  - Phase 2: Drift storage, minimal Material 3 UI with dark mode, JSON
    export/import, pre-load the owner's 5 real entries.
- Ask before adding any package beyond `drift`, `path_provider` and the
  standard Flutter packages.
- Material widgets come from `package:material_ui/material_ui.dart`: the
  official first-party package that the Flutter 3.50 template adds.
- `lib/engine/` is pure Dart: no Flutter imports, no I/O.
  `test/engine/engine_purity_test.dart` enforces this.
- In the UI every number field is labelled. Never accept an unlabelled value.
- Raise gaps and doubts with the owner instead of guessing silently.

## Anchor rules (the core of the product; change only with the owner)

- Mileage = distance ÷ fuel consumed. Fuel added equals fuel consumed only
  between two moments when the tank is at the same known level: anchors.
- A CHAIN runs from one anchor to the next anchor at the SAME level.
  - Distance = odometer at end anchor − odometer at start anchor.
  - Litres = sum of the counted fills, each amount ₹ ÷ price ₹/L.
- Intermediate refuels need only amount and date. Odometer and gauge are optional.
- PRE-FILL anchor (gauge bars read BEFORE filling): the start anchor's fill IS
  counted; the end anchor's fill is NOT (it starts the next chain).
- FULL anchor (filled to the neck): the start anchor's fill is NOT counted;
  the end anchor's fill IS counted.
- Uncertainty U (litres): pre-fill default 0.5 L, configurable per bike; FULL 0.15 L.
  Band: low = d ÷ (L + U), estimate = d ÷ L, high = d ÷ (L − U).
- Confidence comes from total litres in the chain, not the number of refuels:
  < 4 L Low, 4–8 L Medium, > 8 L High.
- Plausibility fence: a closed chain outside the bike model's expected km/L
  range is FLAGGED. The user picks "Missed a refuel?" (add amounts),
  "Bike may need service" (accept) or "Discard chain".
- A SERVICE entry (date + odometer + note) ends any open chain without a
  result. Pre-service and post-service results are never averaged together.
- Overall estimate = litres-weighted average of accepted chains since the last
  service, which equals Σdistance ÷ Σlitres.

## Engine decisions (made in Phase 1, pending the owner's review)

- `analyzeLog(log, bike, decisions:)` reads the log in list order; storage
  owns the ordering. Dates and odometers are only checked for mistakes.
- `isAnchor` is explicit. An anchor needs an odometer and a level (bars or
  Full); bars and Full are mutually exclusive. A gauge reading on a non-anchor
  is informational only.
- One chain at a time. An anchor at a different level from the open chain
  ends that chain as BROKEN (no result) and starts a new chain at its own level.
- Statuses: open; closed (counts, including out-of-range chains the user
  accepted); flagged; discarded; broken (ended with no result: service, level
  change, odometer not increasing, or no fuel counted).
- Accept/discard decisions are keyed by (start anchor id, end anchor id) and
  ignored once the chain's anchors change. The latest decision wins.
- A flag keeps its direction: aboveRange usually means a missed refuel;
  belowRange means a double-logged or wrong amount, mismatched anchor
  readings, or a genuinely thirsty bike.
- Overall band: back-to-back accepted chains share anchors, so their inner
  anchor errors cancel. Each unbroken run adds one U; separate runs combine as
  √ΣU². Overall confidence uses total litres.
- Band high is null (unbounded) when L ≤ U.
- Warnings, not errors: odometer or date going backwards, gauge bars above the
  bike's bar count, a single fill larger than the tank.

## Layout

- `lib/engine/models.dart`: inputs (Bike, RefuelEntry, ServiceEvent, ChainDecision)
- `lib/engine/chain.dart`: outputs (Chain, status, band, confidence)
- `lib/engine/analysis.dart`: `analyzeLog`, service periods, data warnings
- `lib/engine/estimate.dart`: overall estimate
- `lib/engine/bike_catalog.dart`: parses `assets/bikes.json`
- `assets/bikes.json`: UNVERIFIED placeholder specs and km/L fences
- `test/engine/`: unit tests, including the owner's real data (`real_data_test.dart`)

## Commands

- `flutter test`: all tests
- `flutter analyze`: lints
- Flutter SDK lives at `D:\dev\flutter` (stable channel).
