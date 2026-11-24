import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'form_fields.dart';
import 'format.dart';

const anchorDefinition =
    'An anchor is the moment the second-last bar disappears (1 bar left), '
    'read with the bike upright. Fill right then.';

/// Log a refuel, or edit one when [editing] is set.
class RefuelFormScreen extends StatefulWidget {
  const RefuelFormScreen({super.key, this.editing});

  final RefuelEntry? editing;

  @override
  State<RefuelFormScreen> createState() => _RefuelFormScreenState();
}

class _RefuelFormScreenState extends State<RefuelFormScreen> {
  final _form = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _odometerFocus = FocusNode();
  final _amount = TextEditingController();
  final _price = TextEditingController();
  late DateTime _date;
  int? _bars;
  bool _full = false;
  bool _anchor = false;
  FuelGrade? _grade;
  bool _saving = false;
  bool _prefilled = false;
  int? _prefilledOdometer;

  bool get _editing => widget.editing != null;

  AnchorLevel? get _level => _full
      ? const AnchorLevel.full()
      : (_bars == null ? null : AnchorLevel.bars(_bars!));

  @override
  void initState() {
    super.initState();
    final entry = widget.editing;
    _odometerFocus.addListener(_selectLastDigits);
    if (entry != null) {
      _date = entry.date;
      _odometer.text = entry.odometer?.toString() ?? '';
      _amount.text = _plain(entry.amount);
      _price.text = _plain(entry.pricePerLitre);
      _bars = entry.gaugeBars;
      _full = entry.isFull;
      _anchor = entry.isAnchor;
      _grade = entry.grade;
    } else {
      _date = DateTime.now();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once only: later app-state changes must not overwrite what's typed.
    if (_editing || _prefilled) return;
    _prefilled = true;
    final state = AppScope.read(context);
    _prefilledOdometer = state.lastOdometer;
    _odometer.text = _prefilledOdometer?.toString() ?? '';
    final price = state.lastPricePerLitre;
    if (price != null && _price.text.isEmpty) _price.text = _plain(price);
    _grade = state.lastFuelGrade;
  }

  @override
  void dispose() {
    _odometer.dispose();
    _odometerFocus.dispose();
    _amount.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Selects the last three digits so only they need retyping.
  void _selectLastDigits() {
    if (!_odometerFocus.hasFocus) return;
    final length = _odometer.text.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _odometer.selection = TextSelection(
        baseOffset: length > 3 ? length - 3 : 0,
        extentOffset: length,
      );
    });
  }

  void _pickGauge({int? bars, bool full = false}) {
    setState(() {
      _bars = bars;
      _full = full;
      final level = _level;
      if (level == null) {
        _anchor = false;
      } else if (!_editing) {
        final open = AppScope.of(context).analysis?.openChain;
        _anchor = anchorOnByDefault(anchorEffect(open, level));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final bike = state.bike!;
    final open = state.analysis?.openChain;
    final effect = anchorEffect(_editing ? null : open, _level);
    final prefilled = _prefilledOdometer;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Edit refuel' : 'Log refuel'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Delete refuel',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NumberField(
              controller: _odometer,
              focusNode: _odometerFocus,
              label: 'Odometer',
              unit: 'km',
              helper: _editing
                  ? 'Optional unless this is an anchor.'
                  : prefilled == null
                  ? 'Optional unless this is an anchor.'
                  : 'Pre-filled with your last reading (${km(prefilled)}). '
                        'Edit the last digits, or leave it unchanged if you '
                        "didn't read it.",
              validator: (text) {
                if (text == null || text.trim().isEmpty) return null;
                final value = parseWhole(text);
                if (value == null || value > bike.odometerMax) {
                  return 'Up to ${bike.odometerDigits} digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AmountField(
              controller: _amount,
              pricePerLitre: parseDecimal(_price.text),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            PriceField(controller: _price, onChanged: () => setState(() {})),
            const SizedBox(height: 16),
            FuelGradeField(
              value: _grade,
              onChanged: (grade) => setState(() => _grade = grade),
            ),
            const SizedBox(height: 16),
            Text(
              'Gauge before filling',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text("I don't know"),
                  selected: _level == null,
                  onSelected: (_) => _pickGauge(),
                ),
                for (var bars = 0; bars <= bike.gaugeBars; bars++)
                  ChoiceChip(
                    label: Text(bars == 1 ? '1 bar' : '$bars bars'),
                    selected: !_full && _bars == bars,
                    onSelected: (_) => _pickGauge(bars: bars),
                  ),
                ChoiceChip(
                  label: const Text('Filled to full'),
                  selected: _full,
                  onSelected: (_) => _pickGauge(full: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use as anchor'),
              subtitle: Text(_anchorHint(effect, open)),
              value: _anchor,
              onChanged: _level == null
                  ? null
                  : (value) => setState(() => _anchor = value),
            ),
            Text(
              anchorDefinition,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DateField(
              label: 'Date',
              value: _date,
              text: date(context, _date),
              onTap: _pickDate,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_editing ? 'Save changes' : 'Save refuel'),
            ),
          ],
        ),
      ),
    );
  }

  String _anchorHint(AnchorEffect effect, Chain? open) {
    if (_editing) {
      return _level == null
          ? 'Pick the gauge level to use this as an anchor.'
          : 'Anchors start and close chains.';
    }
    return switch (effect) {
      AnchorEffect.notPossible =>
        'Pick the gauge level to use this as an anchor.',
      AnchorEffect.startsChain => 'Starts a new chain.',
      AnchorEffect.closesChain =>
        'Closes your ${open!.level} chain and gives a result.',
      AnchorEffect.breaksChain =>
        'Warning: your open chain is at ${open!.level}. Turning this on ends '
            'it with no result and starts a new one.',
    };
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final state = AppScope.of(context);
    var odometer = parseWhole(_odometer.text);
    final unchanged = !_editing && odometer == _prefilledOdometer;
    if (_anchor && (odometer == null || unchanged)) {
      _snack(
        'An anchor needs the odometer reading from right now. '
        'Update the odometer.',
      );
      return;
    }
    // A pre-filled reading left as it was means "not read".
    if (unchanged) odometer = null;

    final RefuelEntry entry;
    try {
      entry = RefuelEntry(
        id: widget.editing?.id ?? 'new',
        date: _date,
        odometer: odometer,
        amount: parseDecimal(_amount.text)!,
        pricePerLitre: parseDecimal(_price.text)!,
        gaugeBars: _full ? null : _bars,
        isFull: _full,
        isAnchor: _anchor,
        grade: _grade,
        note: widget.editing?.note ?? '',
      );
    } on ArgumentError catch (e) {
      _snack('${e.message}');
      return;
    }

    final open = state.analysis?.openChain;
    if (!_editing &&
        _anchor &&
        anchorEffect(open, _level) == AnchorEffect.breaksChain) {
      final go = await confirm(
        context,
        title: 'End the open chain?',
        message:
            'Your open ${open!.level} chain has ${litres(open.litres)} logged. '
            'This anchor ends it with no result and starts a new chain at '
            '$_level.',
        action: 'End it',
      );
      if (!go) return;
    }

    setState(() => _saving = true);
    if (_editing) {
      await state.updateEntry(entry);
    } else {
      await state.addRefuel(entry);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final go = await confirm(
      context,
      title: 'Delete this refuel?',
      message: 'Its fuel leaves the chain, and the chain is recalculated.',
      action: 'Delete',
    );
    if (!go || !mounted) return;
    await AppScope.of(context).deleteEntry(widget.editing!.id);
    if (mounted) Navigator.pop(context);
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
}

/// 116.0 → "116", 116.5 → "116.5".
String _plain(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toString();
