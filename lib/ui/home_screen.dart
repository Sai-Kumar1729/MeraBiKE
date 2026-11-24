import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'format.dart';
import 'missed_refuel_screen.dart';
import 'service_form_screen.dart';
import 'share_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenHistory,
    required this.onOpenBike,
  });

  final VoidCallback onOpenHistory;
  final VoidCallback onOpenBike;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final analysis = state.analysis!;
    final bike = state.bike!;
    final scheme = Theme.of(context).colorScheme;
    final flagged = analysis.chains
        .where((c) => c.status == ChainStatus.flagged)
        .length;
    final due = state.reminders
        .where((r) => r.state != DueState.ok || r.needsLastService)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        if (flagged > 0)
          Card(
            color: scheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.flag),
              title: Text(
                '$flagged chain${flagged == 1 ? ' needs' : 's need'} your '
                'review',
              ),
              subtitle: const Text('Outside the expected range for this bike.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenHistory,
            ),
          ),
        if (state.lastBackupError case final error?)
          Card(
            color: scheme.errorContainer,
            child: ListTile(
              leading: const Icon(Icons.cloud_off),
              title: const Text('Backup failed'),
              subtitle: Text(error),
              trailing: TextButton(
                onPressed: state.chooseBackupFolder,
                child: const Text('Pick folder'),
              ),
            ),
          )
        else if (!state.autoBackupOn)
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Your data lives only on this phone'),
              subtitle: const Text(
                'Pick a folder once; MeraBiKE saves a backup there after '
                'every change.',
              ),
              trailing: TextButton(
                onPressed: state.chooseBackupFolder,
                child: const Text('Turn on'),
              ),
            ),
          ),
        for (final reminder in due)
          Card(
            color: reminder.state == DueState.overdue
                ? scheme.errorContainer
                : null,
            child: ListTile(
              leading: Icon(
                reminder.state == DueState.overdue
                    ? Icons.warning_amber
                    : Icons.event,
              ),
              title: Text(reminderTitle(reminder.kind)),
              subtitle: Text(reminderDetail(context, reminder)),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenBike,
            ),
          ),
        _EstimateCard(analysis: analysis, bike: bike, cost: state.rupeesPerKm),
        _OpenChainCard(chain: analysis.openChain),
        _KmLeftCard(estimate: estimateKmLeft(analysis, bike), bike: bike),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.playlist_add),
              label: const Text('Add missed refuel'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const MissedRefuelScreen(),
                ),
              ),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.build),
              label: const Text('Log service'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ServiceFormScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({
    required this.analysis,
    required this.bike,
    required this.cost,
  });

  final LogAnalysis analysis;
  final Bike bike;
  final CostPerKm? cost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = analysis.current;
    final sinceService = analysis.periods.last.startedBy != null;
    final cost = this.cost;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your mileage',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (current != null)
                  IconButton(
                    tooltip: 'Share your mileage',
                    icon: const Icon(Icons.share),
                    onPressed: () => showShareCard(context),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (current == null) ...[
              Text('No result yet', style: theme.textTheme.headlineMedium),
              Text(
                'A result appears when a chain closes at the same anchor '
                'level. Expected for a ${bike.model}: '
                '${kmpl(bike.expectedKmplMin)}–${kmpl(bike.expectedKmplMax)} '
                'km/L (unverified).',
              ),
            ] else ...[
              Text(
                '${bandText(current.band)}, '
                '${confidenceLabel(current.confidence)}',
                style: theme.textTheme.headlineMedium,
              ),
              Text(
                'Midpoint ${kmpl(current.kmpl)} km/L from '
                '${km(current.distanceKm)} on ${litres(current.litres)} '
                '(${current.chains.length} '
                'chain${current.chains.length == 1 ? '' : 's'}'
                '${sinceService ? ', since your last service' : ''}).',
              ),
              if (cost != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${costPerKmText(cost)} at ${rupees(cost.pricePerLitre)}/L',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _OpenChainCard extends StatelessWidget {
  const _OpenChainCard({required this.chain});

  final Chain? chain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = chain;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current chain', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (open == null)
              const Text(
                'No chain is open. Log a refuel as an anchor (gauge at your '
                'anchor level) to start one.',
              )
            else ...[
              Text(_progressText(open), style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (open.litres / Confidence.highAboveLitres).clamp(0, 1),
              ),
              const SizedBox(height: 4),
              Text(
                'Started at ${open.level} on ${date(context, open.start.date)} '
                '(${km(open.start.odometer!)}). It closes at your next '
                '${open.level} anchor.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _progressText(Chain open) {
    final logged = '${open.litres.toStringAsFixed(1)} L logged';
    final more = Confidence.litresToNextLevel(open.litres);
    if (more == null) return '$logged: enough for High confidence.';
    final next = open.confidence == Confidence.low ? 'Medium' : 'High';
    return '$logged, ~${more.ceil()} L more to reach $next';
  }
}

class _KmLeftCard extends StatelessWidget {
  const _KmLeftCard({required this.estimate, required this.bike});

  final KmLeftEstimate? estimate;
  final Bike bike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = estimate;
    if (e == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Km left (rough estimate)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '≈ ${(e.kmLeft / 10).round() * 10} km',
              style: theme.textTheme.headlineSmall,
            ),
            Text(
              'Approximate. Assumes the anchor held '
              '${e.litresAtAnchor.toStringAsFixed(1)} L (gauge treated as '
              'linear) and ${kmpl(e.kmplUsed)} km/L'
              '${e.kmplIsModelGuess ? ' (typical for the model, not yet yours)' : ''}'
              ', as of ${km(e.asOfOdometer)}. Not a reason to skip the pump.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
