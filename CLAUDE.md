# MeraBiKE

Personal Android app (Flutter) that estimates a motorcycle's real fuel mileage
from partial refuels, without full-tank tests. One user. Fully offline: no
backend, no login, no GPS, no analytics, no ads.

## Working agreement

- Build in phases and STOP after each phase for the owner's review.
  - Phase 1: engine + unit tests, pure Dart. (Approved.)
  - Phase 2: Drift storage, minimal Material 3 UI with dark mode, JSON
    export/import, pre-load the owner's 5 real entries. (Built; awaiting review.)
- NEVER run `git commit` or `git push`. The owner commits and pushes
  themselves. Read-only git commands are fine.
- Ask before adding any package. Approved so far: `drift`, `drift_dev`,
  `build_runner`, `path_provider`, plus the standard Flutter packages.
  SQLite for Android comes from `sqlite3` 3.x (a Drift dependency; its build
  hook bundles SQLite). `sqlite3_flutter_libs` is end-of-life: don't add it.
- Material widgets come from `package:material_ui/material_ui.dart`: the
  official first-party package that the Flutter 3.50 template adds.
- `lib/engine/` is pure Dart: no Flutter imports, no I/O.
  `test/engine/engine_purity_test.dart` enforces this.
- In the UI every number field is labelled (use `NumberField` in
  `lib/ui/form_fields.dart`). Never accept an unlabelled value.
  `test/ui/app_flow_test.dart` checks every form.
- Raise gaps and doubts with the owner instead of guessing silently.
- Not yet: the mileage-drop diagnostic checklist and per-pump comparison
  (owner said wait).

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
- The owner's anchor: "the moment the second-last bar disappears (1 bar left),
  bike upright." Onboarding teaches exactly this.
- U is the error of ONE gauge reading: pre-fill default 0.5 L (configurable per
  bike), FULL 0.15 L. A chain has two readings, so chain U = √2 × U.
  Band: low = d ÷ (L + chain U), estimate = d ÷ L, high = d ÷ (L − chain U).
- Confidence comes from total litres in the chain, not the number of refuels:
  < 4 L Low, 4–8 L Medium, > 8 L High.
- Plausibility fence: a closed chain outside the bike model's expected km/L
  range is FLAGGED. Prompts depend on direction:
  - too high → "Missed a refuel?" (add amounts)
  - too low → "Logged a fill twice or a wrong amount?" (edit/delete entries)
  - both also offer "Bike may need attention" (accept) and "Discard chain".
- A SERVICE entry (date + odometer + note) ends any open chain without a
  result. Pre-service and post-service results are never averaged together.
- Overall estimate = litres-weighted average of accepted chains since the last
  service, which equals Σdistance ÷ Σlitres.
- Odometer rollover: a drop of more than 90% of the odometer's maximum
  (from its digit count, default 5) is a rollover, not an error.

## Engine decisions (approved in the Phase 1 review)

- `analyzeLog(log, bike, decisions:)` reads the log in list order; storage
  owns the ordering. Dates and odometers are only checked for mistakes.
- `isAnchor` is explicit. An anchor needs an odometer and a level (bars or
  Full); bars and Full are mutually exclusive. A gauge reading on a non-anchor
  is informational only.
- One chain at a time. An anchor at a different level from the open chain
  ends that chain as BROKEN (no result) and starts a new chain at its level.
- Statuses: open; closed (counts, including out-of-range chains the user
  accepted); flagged; discarded; broken (ended with no result: service, level
  change, odometer not increasing, or no fuel counted).
- Accept/discard decisions are keyed by (start anchor id, end anchor id) and
  ignored once the chain's anchors change. The latest decision wins.
- Overall band: back-to-back accepted chains share anchors, so their inner
  reading errors cancel; each unbroken run keeps one chain U (its two outer
  readings). Separate runs combine as √ΣU². Overall confidence uses total litres.
- Band high is null (unbounded) when L ≤ chain U.
- Warnings, not errors: odometer or date going backwards, a reading with more
  digits than the odometer, gauge bars above the bike's count, a fill larger
  than the tank. A rollover is reported as information.

## App decisions (Phase 2, pending the owner's review)

- Anchor toggle defaults ON when the gauge matches the open chain's level (or
  no chain is open), OFF when it would break the open chain (with a warning
  and a confirmation).
- The odometer is pre-filled with the last reading. Left unchanged, it is
  saved as "not read"; an anchor must have a changed reading.
- A missed refuel goes inside the chosen chain (default: the chain that
  started on or before its date), after that chain's entries on or before its
  date, never after the closing anchor.
- Km left (approximate): fuel at anchor (bars × tank ÷ bars, or the full tank)
  + litres counted since − distance ÷ km/L, at the current estimate (or the
  middle of the fence before there is one), as of the latest odometer reading.
- Export/import: JSON via Android's own Save as / Open dialogs (Kotlin
  MethodChannel `merabike/files` in MainActivity.kt). Import replaces all data
  after confirmation and keeps entry ids so decisions still apply.
- First launch seeds the Hero Glamour from bikes.json and the owner's five
  entries, with placeholder dates (note on each entry) until the owner sends
  real dates from UPI history.

## Layout

- `lib/engine/`: models (inputs), chain (outputs), analysis (`analyzeLog`,
  rollover, warnings), estimate, logging_rules (anchor default, missed-refuel
  placement, km left), bike_catalog
- `lib/data/`: Drift database (`database.dart` + generated `.g.dart`),
  repository, JSON backup codec, seed, file channel
- `lib/app/app_state.dart`: `AppState` (ChangeNotifier) + `AppScope`
- `lib/ui/`: screens (home, refuel form, missed refuel, history, service form,
  bike setup + backup, onboarding) and shared form fields
- `android/.../MainActivity.kt`: Save as / Open bridge
- `assets/bikes.json`: UNVERIFIED placeholder specs and km/L fences
- `test/engine/`, `test/data/`, `test/ui/`

## Commands

- `flutter test`: all tests. `flutter analyze`: lints.
- `dart run build_runner build`: regenerate Drift code after editing tables.
- `flutter build apk --debug`, or `flutter run` with the phone on USB.
- Toolchain: Flutter `D:\dev\flutter`, JDK 17 `D:\dev\jdk-17`, Android SDK
  `D:\dev\android-sdk` (set via `flutter config`). NDK 28.2, build-tools 36.1.
- If a build fails within seconds on "Could not GET ... storage.googleapis.com"
  (Flutter engine jars), the Gradle daemon survived a network drop in a bad
  state: run `android\gradlew.bat --stop` (with `JAVA_HOME=D:\dev\jdk-17`) and
  build again. The debug engine jars are ~110–180 MB each, so the first build
  per ABI is slow on this connection.
