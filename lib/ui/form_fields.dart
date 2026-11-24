import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

double? parseDecimal(String text) => double.tryParse(text.trim());

int? parseWhole(String text) => int.tryParse(text.trim());

/// A labelled number field. Every number in the app goes through one of
/// these, so nothing is ever entered without a label and a unit.
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.unit,
    this.prefix,
    this.helper,
    this.decimal = false,
    this.validator,
    this.focusNode,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? unit;
  final String? prefix;
  final String? helper;
  final bool decimal;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    focusNode: focusNode,
    keyboardType: TextInputType.numberWithOptions(decimal: decimal),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.]' : r'[0-9]')),
    ],
    decoration: InputDecoration(
      labelText: label,
      suffixText: unit,
      prefixText: prefix,
      helperText: helper,
      helperMaxLines: 3,
      border: const OutlineInputBorder(),
    ),
    validator: validator,
    onChanged: onChanged,
  );
}

/// Amount paid, with ₹100/200/300/500 chips that fill it in.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.pricePerLitre,
    required this.onChanged,
  });

  static const quickAmounts = [100, 200, 300, 500];

  final TextEditingController controller;
  final double? pricePerLitre;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final amount = parseDecimal(controller.text);
    final price = pricePerLitre;
    final litres = amount != null && price != null && price > 0
        ? ' ≈ ${(amount / price).toStringAsFixed(2)} L'
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final value in quickAmounts)
              ActionChip(
                label: Text('₹$value'),
                onPressed: () {
                  controller.text = '$value';
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        NumberField(
          controller: controller,
          label: 'Amount paid',
          prefix: '₹ ',
          decimal: true,
          helper: 'Tap a chip or type any amount.$litres',
          onChanged: (_) => onChanged(),
          validator: (text) {
            final value = parseDecimal(text ?? '');
            if (value == null || value <= 0) return 'Enter the amount paid';
            return null;
          },
        ),
      ],
    );
  }
}

/// The price field, shared by the refuel forms.
class PriceField extends StatelessWidget {
  const PriceField({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => NumberField(
    controller: controller,
    label: 'Petrol price',
    prefix: '₹ ',
    unit: 'per litre',
    decimal: true,
    helper: 'Remembers the last price you entered.',
    onChanged: (_) => onChanged?.call(),
    validator: (text) {
      final value = parseDecimal(text ?? '');
      if (value == null || value <= 0) return 'Enter the price per litre';
      return null;
    },
  );
}

/// A row for picking a date, labelled like a field.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.text,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      child: Text(text),
    ),
  );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
