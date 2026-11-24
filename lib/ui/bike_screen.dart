import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../data/file_channel.dart';
import '../engine/engine.dart';
import 'form_fields.dart';
import 'onboarding_screen.dart';

/// Bike setup (model from bikes.json, with overrides) and backups.
class BikeScreen extends StatefulWidget {
  const BikeScreen({super.key, this.files = const SystemFiles()});

  final SystemFiles files;

  @override
  State<BikeScreen> createState() => _BikeScreenState();
}

class _BikeScreenState extends State<BikeScreen> {
  final _form = GlobalKey<FormState>();
  final _tank = TextEditingController();
  final _bars = TextEditingController();
  final _u = TextEditingController();
  final _digits = TextEditingController();
  BikeModel? _model;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadFromState();
  }

  /// Fills the form from the saved bike (or the first catalog model).
  void _loadFromState() {
    final state = AppScope.of(context);
    final bike = state.bike;
    _model = state.bikeModel ?? state.catalog.firstOrNull;
    _fill(
      tank: bike?.tankLitres ?? _model?.tankLitres,
      bars: bike?.gaugeBars ?? _model?.gaugeBars,
      u: bike?.prefillUncertaintyLitres ?? Bike.defaultPrefillUncertaintyLitres,
      digits: bike?.odometerDigits ?? Bike.defaultOdometerDigits,
    );
  }

  void _fill({double? tank, int? bars, double? u, int? digits}) {
    if (tank != null) _tank.text = '$tank';
    if (bars != null) _bars.text = '$bars';
    if (u != null) _u.text = '$u';
    if (digits != null) _digits.text = '$digits';
  }

  @override
  void dispose() {
    _tank.dispose();
    _bars.dispose();
    _u.dispose();
    _digits.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final model = _model;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                  child: Text(m.verified ? m.model : '${m.model} (unverified)'),
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
                'Count the digits on your odometer. 5 digits rolls over after '
                '99,999 km; the app treats that as a rollover, not an error.',
            validator: (text) {
              final value = parseWhole(text ?? '');
              return value == null || value < 4 || value > 7
                  ? 'Between 4 and 7'
                  : null;
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save bike'),
          ),
          const SizedBox(height: 32),
          Text('Backup', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Save a JSON file to Downloads or Google Drive. Data inside the '
            'app is deleted if you uninstall it; the file is not.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
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
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const OnboardingScreen(reviewing: true),
              ),
            ),
            icon: const Icon(Icons.help_outline),
            label: const Text('How anchors work'),
          ),
        ],
      ),
    );
  }

  String? _positive(String? text) =>
      (parseDecimal(text ?? '') ?? 0) > 0 ? null : 'Enter a number above 0';

  Future<void> _save() async {
    final model = _model;
    if (model == null || !_form.currentState!.validate()) return;
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
    await AppScope.of(context).saveBike(bike);
    _snack('Bike saved');
  }

  Future<void> _export() async {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final stamp = '${now.year}-${_two(now.month)}-${_two(now.day)}';
    try {
      final saved = await widget.files.saveAs(
        'merabike-backup-$stamp.json',
        state.exportJson(now),
      );
      if (saved) _snack('Backup saved');
    } on Exception catch (e) {
      _snack('Could not save: $e');
    }
  }

  Future<void> _import() async {
    final state = AppScope.of(context);
    final String? text;
    try {
      text = await widget.files.open();
    } on Exception catch (e) {
      _snack('Could not open: $e');
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

String _two(int n) => n.toString().padLeft(2, '0');
