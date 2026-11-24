import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'form_fields.dart';
import 'format.dart';
import 'onboarding_screen.dart';

/// Bike setup (model from bikes.json, with overrides), reminders, backups.
class BikeScreen extends StatefulWidget {
  const BikeScreen({super.key});

  @override
  State<BikeScreen> createState() => _BikeScreenState();
}

class _BikeScreenState extends State<BikeScreen> {
  final _bikeForm = GlobalKey<FormState>();
  final _reminderForm = GlobalKey<FormState>();
  final _tank = TextEditingController();
  final _bars = TextEditingController();
  final _u = TextEditingController();
  final _digits = TextEditingController();
  final _serviceKm = TextEditingController();
  final _serviceDays = TextEditingController();
  DateTime? _insurance;
  DateTime? _puc;
  BikeModel? _model;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadFromState();
  }

  /// Fills the forms from what is saved (or the first catalog model).
  void _loadFromState() {
    final state = AppScope.read(context);
    final bike = state.bike;
    _model = state.bikeModel ?? state.catalog.firstOrNull;
    _fill(
      tank: bike?.tankLitres ?? _model?.tankLitres,
      bars: bike?.gaugeBars ?? _model?.gaugeBars,
      u: bike?.prefillUncertaintyLitres ?? Bike.defaultPrefillUncertaintyLitres,
      digits: bike?.odometerDigits ?? Bike.defaultOdometerDigits,
    );
    final reminders = state.reminderSettings;
    _serviceKm.text = reminders.serviceEveryKm?.toString() ?? '';
    _serviceDays.text = reminders.serviceEveryDays?.toString() ?? '';
    _insurance = reminders.insuranceExpiry;
    _puc = reminders.pucExpiry;
  }

  void _fill({double? tank, int? bars, double? u, int? digits}) {
    if (tank != null) _tank.text = '$tank';
    if (bars != null) _bars.text = '$bars';
    if (u != null) _u.text = '$u';
    if (digits != null) _digits.text = '$digits';
  }

  @override
  void dispose() {
    for (final c in [_tank, _bars, _u, _digits, _serviceKm, _serviceDays]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final model = _model;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Form(
          key: _bikeForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bike setup', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<BikeModel>(
                // Rebuilt when an import changes the model.
                key: ValueKey(model),
                initialValue: model,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final m in state.catalog)
                    DropdownMenuItem(
                      value: m,
                      child: Text(
                        m.verified ? m.model : '${m.model} (unverified)',
                      ),
                    ),
                ],
                onChanged: (m) => setState(() {
                  _model = m;
                  _fill(tank: m?.tankLitres, bars: m?.gaugeBars);
                }),
              ),
              if (model != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                  child: Text(
                    'Expected range ${model.expectedKmplMin.toStringAsFixed(0)}–'
                    '${model.expectedKmplMax.toStringAsFixed(0)} km/L, from '
                    'bikes.json${model.verified ? '' : ' (placeholder, unverified)'}. '
                    'Chains outside it are flagged for your review.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              NumberField(
                controller: _tank,
                label: 'Tank capacity',
                unit: 'litres',
                decimal: true,
                validator: _positive,
              ),
              const SizedBox(height: 16),
              NumberField(
                controller: _bars,
                label: 'Fuel gauge bars when full',
                unit: 'bars',
                validator: (text) =>
                    (parseWhole(text ?? '') ?? 0) > 0 ? null : 'At least 1',
              ),
              const SizedBox(height: 16),
              NumberField(
                controller: _u,
                label: 'Gauge reading uncertainty (U)',
                prefix: '± ',
                unit: 'litres per reading',
                decimal: true,
                helper:
                    'How far off one gauge reading can be. A chain has two '
                    'readings, so its band uses √2 × U. Default 0.5 L.',
                validator: (text) {
                  final value = parseDecimal(text ?? '');
                  return value == null || value < 0 ? 'Enter 0 or more' : null;
                },
              ),
              const SizedBox(height: 16),
              NumberField(
                controller: _digits,
                label: 'Odometer digits',
                unit: 'digits',
                helper:
                    'Count the digits on your odometer. 5 digits rolls over '
                    'after 99,999 km; the app treats that as a rollover, not '
                    'an error.',
                validator: (text) {
                  final value = parseWhole(text ?? '');
                  return value == null || value < 4 || value > 7
                      ? 'Between 4 and 7'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saveBike,
                icon: const Icon(Icons.check),
                label: const Text('Save bike'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Form(
          key: _reminderForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Reminders', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Shown on Home when due. Leave a field empty to skip it.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              NumberField(
                controller: _serviceKm,
                label: 'Service every',
                unit: 'km',
                helper: 'Counted from your last logged service.',
                validator: _emptyOrPositive,
              ),
              const SizedBox(height: 16),
              NumberField(
                controller: _serviceDays,
                label: 'Service every',
                unit: 'days',
                validator: _emptyOrPositive,
              ),
              const SizedBox(height: 16),
              _OptionalDateField(
                label: 'Insurance expires on',
                value: _insurance,
                onChanged: (d) => setState(() => _insurance = d),
              ),
              const SizedBox(height: 16),
              _OptionalDateField(
                label: 'PUC certificate expires on',
                value: _puc,
                onChanged: (d) => setState(() => _puc = d),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: _saveReminders,
                icon: const Icon(Icons.check),
                label: const Text('Save reminders'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text('Backup', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        _AutoBackupStatus(state: state),
        const SizedBox(height: 16),
        Text(
          'Or save a single file anywhere, such as Google Drive. Data inside '
          'the app is deleted if you uninstall it; files are not.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _export,
              icon: const Icon(Icons.upload_file),
              label: const Text('Export backup'),
            ),
            OutlinedButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.download),
              label: const Text('Import backup'),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const OnboardingScreen(reviewing: true),
              ),
            ),
            icon: const Icon(Icons.help_outline),
            label: const Text('How anchors work'),
          ),
        ),
      ],
    );
  }

  String? _positive(String? text) =>
      (parseDecimal(text ?? '') ?? 0) > 0 ? null : 'Enter a number above 0';

  String? _emptyOrPositive(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return (parseWhole(text) ?? 0) > 0 ? null : 'A whole number above 0';
  }

  Future<void> _saveBike() async {
    final model = _model;
    if (model == null || !_bikeForm.currentState!.validate()) return;
    final Bike bike;
    try {
      bike = model.toBike(
        tankLitres: parseDecimal(_tank.text),
        gaugeBars: parseWhole(_bars.text),
        prefillUncertaintyLitres: parseDecimal(_u.text),
        odometerDigits: parseWhole(_digits.text),
      );
    } on ArgumentError catch (e) {
      _snack('${e.message}');
      return;
    }
    await AppScope.read(context).saveBike(bike);
    _snack('Bike saved');
  }

  Future<void> _saveReminders() async {
    if (!_reminderForm.currentState!.validate()) return;
    await AppScope.read(context).saveReminders(
      ReminderSettings(
        serviceEveryKm: parseWhole(_serviceKm.text),
        serviceEveryDays: parseWhole(_serviceDays.text),
        insuranceExpiry: _insurance,
        pucExpiry: _puc,
      ),
    );
    _snack('Reminders saved');
  }

  Future<void> _export() async {
    final state = AppScope.read(context);
    final now = DateTime.now();
    final stamp = '${now.year}-${_two(now.month)}-${_two(now.day)}';
    try {
      final saved = await state.bridge.saveAs(
        'merabike-backup-$stamp.json',
        state.exportJson(now),
      );
      if (saved) _snack('Backup saved');
    } on PlatformException catch (e) {
      _snack('Could not save: ${e.message ?? e.code}');
    }
  }

  Future<void> _import() async {
    final state = AppScope.read(context);
    final String? text;
    try {
      text = await state.bridge.open();
    } on PlatformException catch (e) {
      _snack('Could not open: ${e.message ?? e.code}');
      return;
    }
    if (text == null || !mounted) return;
    final go = await confirm(
      context,
      title: 'Replace all data?',
      message:
          'Everything in the app is replaced by the backup. Export first '
          'if you want to keep the current data.',
      action: 'Replace',
    );
    if (!go) return;
    try {
      await state.importJson(text);
      if (!mounted) return;
      setState(_loadFromState);
      _snack('Backup imported');
    } on FormatException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Where automatic backups go, when the last one ran, and the controls.
class _AutoBackupStatus extends StatelessWidget {
  const _AutoBackupStatus({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at = state.lastBackupAt;
    final error = state.lastBackupError;
    if (!state.autoBackupOn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Automatic backup is off. Pick a folder once (for example '
            'Documents/MeraBiKE) and the app saves a backup there after '
            'every change, keeping the last 7 days. It survives an '
            'uninstall.',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: state.chooseBackupFolder,
            icon: const Icon(Icons.folder_open),
            label: const Text('Choose backup folder'),
          ),
        ],
      );
    }
    final localizations = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Automatic backup is on, saving to "${state.backupFolderName}".'),
        Text(
          error != null
              ? 'Last attempt failed: $error'
              : at == null
              ? 'No backup yet.'
              : 'Last backup: ${localizations.formatMediumDate(at)}, '
                    '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(at))}.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: error != null ? theme.colorScheme.error : null,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: state.backupNow,
              icon: const Icon(Icons.backup),
              label: const Text('Back up now'),
            ),
            OutlinedButton(
              onPressed: state.chooseBackupFolder,
              child: const Text('Change folder'),
            ),
            TextButton(
              onPressed: state.turnOffAutoBackup,
              child: const Text('Turn off'),
            ),
          ],
        ),
      ],
    );
  }
}

/// A labelled date that may be empty, with a clear button.
class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final picked = value;
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final chosen = await showDatePicker(
          context: context,
          initialDate: picked ?? now,
          firstDate: DateTime(now.year - 2),
          lastDate: DateTime(now.year + 5),
        );
        if (chosen != null) onChanged(chosen);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: picked == null
              ? const Icon(Icons.calendar_today)
              : IconButton(
                  tooltip: 'Clear $label',
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(picked == null ? 'Not set' : date(context, picked)),
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
