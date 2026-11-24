import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import 'format.dart';

/// Shows the "honest mileage" card and shares it as an image: the range,
/// how much fuel it rests on, and the cost per km. No location, no log.
Future<void> showShareCard(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _ShareDialog());

class _ShareDialog extends StatefulWidget {
  const _ShareDialog();

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _card = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final current = state.analysis?.current;
    if (current == null) {
      return AlertDialog(
        title: const Text('Nothing to share yet'),
        content: const Text('Your card appears with your first result.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      );
    }
    return AlertDialog(
      title: const Text('Share your mileage'),
      content: RepaintBoundary(
        key: _card,
        child: _MileageCard(state: state),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _sharing ? null : () => _share(state),
          icon: const Icon(Icons.share),
          label: const Text('Share'),
        ),
      ],
    );
  }

  Future<void> _share(AppState state) async {
    setState(() => _sharing = true);
    final current = state.analysis!.current!;
    try {
      final boundary =
          _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await state.bridge.shareImage(
        png!.buffer.asUint8List(),
        'My ${state.bike!.model} does ${bandText(current.band)} '
        '(${confidenceLabel(current.confidence)} confidence), measured from '
        '${litres(current.litres)} of real fills. No full tank needed.',
      );
      if (mounted) Navigator.pop(context);
    } on PlatformException catch (e) {
      _failed(e.message ?? e.code);
    } on MissingPluginException {
      _failed('Sharing is not available here');
    }
  }

  void _failed(String why) {
    if (!mounted) return;
    setState(() => _sharing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Could not share: $why')));
  }
}

class _MileageCard extends StatelessWidget {
  const _MileageCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = state.analysis!.current!;
    final cost = state.rupeesPerKm;
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.bike!.model,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              bandText(current.band),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${confidenceLabel(current.confidence)} confidence · measured '
              'from ${litres(current.litres)} of real fills',
            ),
            if (cost != null) ...[
              const SizedBox(height: 8),
              Text(costPerKmText(cost)),
            ],
            const SizedBox(height: 16),
            Text(
              'MeraBiKE · no full tank needed · an honest range',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
