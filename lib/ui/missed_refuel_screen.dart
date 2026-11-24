import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'form_fields.dart';
import 'format.dart';

/// Add a refuel you forgot to log: amount and date only. It goes inside the
/// chain you pick (by default the one covering that date).
class MissedRefuelScreen extends StatefulWidget {
  const MissedRefuelScreen({super.key, this.chainId});

  /// Opened from a chain: put it there.
  final String? chainId;

  @override
  State<MissedRefuelScreen> createState() => _MissedRefuelScreenState();
}

class _MissedRefuelScreenState extends State<MissedRefuelScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _price = TextEditingController();
  String? _chainId;
  DateTime? _date;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chainId != null) return;
    final chains = AppScope.of(context).analysis?.chains ?? const [];
    final chain =
        chains.where((c) => c.id == widget.chainId).firstOrNull ??
        chainForDate(chains, DateTime.now());
    if (chain != null) _choose(chain);
  }

  @override
  void dispose() {
    _amount.dispose();
    _price.dispose();
    super.dispose();
  }

  /// First and last day a refuel in [chain] can have.
  (DateTime, DateTime) _span(Chain chain) {
    final last = (chain.end ?? chain.brokenBy)?.date ?? DateTime.now();
    return (_day(chain.start.date), _day(last));
  }

  void _choose(Chain chain) {
    _chainId = chain.id;
    _price.text = chain.start.pricePerLitre.toString();
    final (first, last) = _span(chain);
    final current = _date ?? last;
    _date = current.isBefore(first)
        ? first
        : current.isAfter(last)
        ? last
        : current;
  }

  @override
  Widget build(BuildContext context) {
    final chains = AppScope.of(context).analysis?.chains ?? const <Chain>[];
    final chain = chains.where((c) => c.id == _chainId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Add missed refuel')),
      body: chain == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'There are no chains yet. Log your refuels normally; a '
                'missed refuel only matters inside a chain.',
              ),
            )
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  AmountField(
                    controller: _amount,
                    pricePerLitre: parseDecimal(_price.text),
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    label: 'Date of the refuel',
                    value: _date!,
                    text: date(context, _date!),
                    onTap: () => _pickDate(chain),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: chain.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Goes into chain',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in chains.reversed)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            chainLabel(context, c),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (id) => setState(
                      () => _choose(chains.firstWhere((c) => c.id == id)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PriceField(
                    controller: _price,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _save(chain),
                    icon: const Icon(Icons.check),
                    label: const Text('Add to chain'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickDate(Chain chain) async {
    final (first, last) = _span(chain);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date!,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save(Chain chain) async {
    if (!_form.currentState!.validate()) return;
    final entry = RefuelEntry(
      id: 'new',
      date: DateTime(_date!.year, _date!.month, _date!.day, 12),
      amount: parseDecimal(_amount.text)!,
      pricePerLitre: parseDecimal(_price.text)!,
      note: 'Added later as a missed refuel',
    );
    await AppScope.of(context).addMissedRefuel(chain, entry);
    if (mounted) Navigator.pop(context);
  }
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
