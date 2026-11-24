import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'format.dart';
import 'missed_refuel_screen.dart';
import 'refuel_form_screen.dart';
import 'service_form_screen.dart';

/// One block in the history: a chain, a run of unchained refuels, or a
/// service.
sealed class _Block {}

class _ChainBlock extends _Block {
  _ChainBlock(this.chain);
  final Chain chain;
}

class _UnchainedBlock extends _Block {
  final List<RefuelEntry> refuels = [];
}

class _ServiceBlock extends _Block {
  _ServiceBlock(this.service);
  final ServiceEvent service;
}

/// Groups the log in order. Each entry appears once: a closing anchor is
/// shown as the start of the chain it opens.
List<_Block> _blocks(List<LogEntry> log, LogAnalysis analysis) {
  final chainOf = <String, Chain>{};
  for (final chain in analysis.chains) {
    for (final refuel in chain.refuels) {
      if (refuel != chain.end) chainOf[refuel.id] = chain;
    }
  }
  final blocks = <_Block>[];
  for (final entry in log) {
    switch (entry) {
      case final ServiceEvent service:
        blocks.add(_ServiceBlock(service));
      case final RefuelEntry refuel:
        final chain = chainOf[refuel.id];
        if (chain == null) {
          final last = blocks.lastOrNull;
          final group = last is _UnchainedBlock ? last : _UnchainedBlock();
          if (group != last) blocks.add(group);
          group.refuels.add(refuel);
        } else if (chain.start == refuel) {
          blocks.add(_ChainBlock(chain));
        }
    }
  }
  return blocks;
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final analysis = state.analysis!;
    final blocks = _blocks(state.log, analysis).reversed.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        if (analysis.issues.isNotEmpty) _IssuesCard(issues: analysis.issues),
        if (blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nothing logged yet.'),
          ),
        for (final block in blocks)
          switch (block) {
            _ChainBlock(:final chain) => _ChainCard(chain: chain),
            _UnchainedBlock(:final refuels) => _UnchainedCard(refuels: refuels),
            _ServiceBlock(:final service) => _ServiceTile(service: service),
          },
      ],
    );
  }
}

class _ChainCard extends StatelessWidget {
  const _ChainCard({required this.chain});

  final Chain chain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kmplValue = chain.kmpl;
    final band = chain.band;
    final shown = chain.refuels.where((r) => r != chain.end).toList().reversed;
    final endsAt = chain.end;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(chain: chain),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chain at ${chain.level}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _ChainMenu(chain: chain),
              ],
            ),
            const SizedBox(height: 8),
            if (kmplValue != null && band != null)
              Text(
                '${bandText(band)} · ${confidenceLabel(chain.confidence)} '
                'confidence',
                style: theme.textTheme.titleLarge,
              ),
            Text(
              [
                if (kmplValue != null) 'Midpoint ${kmpl(kmplValue)} km/L',
                if (chain.distanceKm != null)
                  chain.status == ChainStatus.open
                      ? '${km(chain.distanceKm!)} so far'
                      : km(chain.distanceKm!),
                '${litres(chain.litres)} counted',
              ].join(' · '),
            ),
            if (chain.status == ChainStatus.open)
              Text(_openProgress(chain), style: theme.textTheme.bodySmall),
            if (chain.breakReason case final reason?)
              Text(breakReasonText(reason), style: theme.textTheme.bodySmall),
            if (endsAt != null)
              Text(
                'Closed by the ${km(endsAt.odometer!)} anchor on '
                '${date(context, endsAt.date)} (shown in the next chain).',
                style: theme.textTheme.bodySmall,
              ),
            if (chain.status == ChainStatus.flagged) _FlagPanel(chain: chain),
            const Divider(),
            for (final refuel in shown)
              _RefuelTile(
                refuel: refuel,
                counted: chain.countedFills.contains(refuel),
              ),
          ],
        ),
      ),
    );
  }

  String _openProgress(Chain chain) {
    final more = Confidence.litresToNextLevel(chain.litres);
    if (more == null) return 'High confidence once it closes.';
    final next = chain.confidence == Confidence.low ? 'Medium' : 'High';
    return '~${more.ceil()} L more to reach $next.';
  }
}

/// The direction-dependent questions for a flagged chain.
class _FlagPanel extends StatelessWidget {
  const _FlagPanel({required this.chain});

  final Chain chain;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final bike = state.bike!;
    final high = chain.plausibility == Plausibility.aboveRange;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            high
                ? '${kmpl(chain.kmpl!)} km/L is above the expected '
                      '${kmpl(bike.expectedKmplMin)}–'
                      '${kmpl(bike.expectedKmplMax)} km/L for this bike.'
                : '${kmpl(chain.kmpl!)} km/L is below the expected '
                      '${kmpl(bike.expectedKmplMin)}–'
                      '${kmpl(bike.expectedKmplMax)} km/L for this bike.',
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (high)
                FilledButton.tonal(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => MissedRefuelScreen(chainId: chain.id),
                    ),
                  ),
                  child: const Text('Missed a refuel?'),
                )
              else
                FilledButton.tonal(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tap a refuel in this chain to fix its amount, or '
                        'delete it if it was logged twice.',
                      ),
                    ),
                  ),
                  child: const Text('Logged a fill twice or a wrong amount?'),
                ),
              OutlinedButton(
                onPressed: () => state.decide(chain, ChainDecisionKind.accept),
                child: const Text('Bike may need attention'),
              ),
              TextButton(
                onPressed: () => state.decide(chain, ChainDecisionKind.discard),
                child: const Text('Discard chain'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChainMenu extends StatelessWidget {
  const _ChainMenu({required this.chain});

  final Chain chain;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hasResult = chain.kmpl != null;
    return PopupMenuButton<String>(
      tooltip: 'Chain actions',
      onSelected: (action) => switch (action) {
        'missed' => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => MissedRefuelScreen(chainId: chain.id),
          ),
        ),
        'discard' => state.decide(chain, ChainDecisionKind.discard),
        'undo' => state.undoDecision(chain),
        _ => null,
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'missed', child: Text('Add missed refuel')),
        if (hasResult && chain.decision != null)
          const PopupMenuItem(value: 'undo', child: Text('Undo my decision')),
        if (hasResult && chain.status == ChainStatus.closed)
          const PopupMenuItem(value: 'discard', child: Text('Discard chain')),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.chain});

  final Chain chain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (chain.status) {
      ChainStatus.open => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      ChainStatus.closed => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      ChainStatus.flagged => (scheme.errorContainer, scheme.onErrorContainer),
      ChainStatus.discarded || ChainStatus.broken => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusLabel(chain),
        style: TextStyle(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RefuelTile extends StatelessWidget {
  const _RefuelTile({required this.refuel, this.counted});

  final RefuelEntry refuel;

  /// Null outside a chain.
  final bool? counted;

  @override
  Widget build(BuildContext context) {
    final gauge = refuel.isFull
        ? 'filled to full'
        : refuel.gaugeBars == null
        ? 'gauge unknown'
        : '${refuel.gaugeBars} bar${refuel.gaugeBars == 1 ? '' : 's'} before';
    final details = [
      date(context, refuel.date),
      if (refuel.odometer != null) km(refuel.odometer!),
      gauge,
      if (counted == false) 'not counted here',
    ];
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(right: 8),
      leading: Icon(refuel.isAnchor ? Icons.flag : Icons.local_gas_station),
      title: Text(
        '${rupees(refuel.amount)} · ${litres(refuel.litres)}'
        '${refuel.isAnchor ? ' · anchor' : ''}',
      ),
      subtitle: Text(
        [
          details.join(' · '),
          if (refuel.note.isNotEmpty) refuel.note,
        ].join('\n'),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => RefuelFormScreen(editing: refuel),
        ),
      ),
    );
  }
}

class _UnchainedCard extends StatelessWidget {
  const _UnchainedCard({required this.refuels});

  final List<RefuelEntry> refuels;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Not in a chain',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Logged before the first anchor (or after a service). They '
            "don't affect the estimate.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (final refuel in refuels.reversed) _RefuelTile(refuel: refuel),
        ],
      ),
    ),
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final ServiceEvent service;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: Theme.of(context).colorScheme.tertiaryContainer,
    child: ListTile(
      leading: const Icon(Icons.build),
      title: Text('Service at ${km(service.odometer)}'),
      subtitle: Text(
        [
          date(context, service.date),
          if (service.note.isNotEmpty) service.note,
          'Results before and after are kept apart.',
        ].join('\n'),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ServiceFormScreen(editing: service),
        ),
      ),
    ),
  );
}

class _IssuesCard extends StatelessWidget {
  const _IssuesCard({required this.issues});

  final List<LogIssue> issues;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      leading: const Icon(Icons.info_outline),
      title: Text(
        '${issues.length} thing${issues.length == 1 ? '' : 's'} to check',
      ),
      children: [
        for (final issue in issues)
          ListTile(dense: true, title: Text(issue.message)),
      ],
    ),
  );
}
