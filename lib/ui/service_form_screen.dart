import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'form_fields.dart';
import 'format.dart';

/// Log a service, or edit one when [editing] is set. A service ends the open
/// chain without a result and starts a new estimate period.
class ServiceFormScreen extends StatefulWidget {
  const ServiceFormScreen({super.key, this.editing});

  final ServiceEvent? editing;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _form = GlobalKey<FormState>();
  final _odometer = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final service = widget.editing;
    _date = service?.date ?? DateTime.now();
    _odometer.text = service?.odometer.toString() ?? '';
    _note.text = service?.note ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.editing == null && _odometer.text.isEmpty) {
      _odometer.text = AppScope.of(context).lastOdometer?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _odometer.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final bike = state.bike!;
    final editing = widget.editing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit service' : 'Log service'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Delete service',
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
            if (!editing && state.analysis?.openChain != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'This ends your open chain without a result. Results '
                  'before and after a service are never averaged together.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            NumberField(
              controller: _odometer,
              label: 'Odometer at the service',
              unit: 'km',
              validator: (text) {
                final value = parseWhole(text ?? '');
                if (value == null) return 'Enter the odometer reading';
                if (value > bike.odometerMax) {
                  return 'Up to ${bike.odometerDigits} digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What was done',
                hintText: 'Oil change, air filter, carburettor tuning…',
                border: OutlineInputBorder(),
              ),
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
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(editing ? 'Save changes' : 'Save service'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final state = AppScope.of(context);
    final service = ServiceEvent(
      id: widget.editing?.id ?? 'new',
      date: _date,
      odometer: parseWhole(_odometer.text)!,
      note: _note.text.trim(),
    );
    if (widget.editing != null) {
      await state.updateEntry(service);
    } else {
      await state.addService(service);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final go = await confirm(
      context,
      title: 'Delete this service?',
      message: 'The chains around it are recalculated as if it never happened.',
      action: 'Delete',
    );
    if (!go || !mounted) return;
    await AppScope.of(context).deleteEntry(widget.editing!.id);
    if (mounted) Navigator.pop(context);
  }
}
