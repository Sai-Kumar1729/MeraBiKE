import 'package:material_ui/material_ui.dart';

import '../app/app_state.dart';
import '../engine/engine.dart';
import 'charts.dart';
import 'format.dart';

/// Evidence from the log: cost, the trend of results, and fuel comparisons.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cost = state.rupeesPerKm;
    final spend = state.spendLast30Days;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _StatTile(
                label: 'Fuel cost per km',
                value: cost == null ? '—' : costRange(cost),
                caption: cost == null
                    ? 'Appears with your first result'
                    : 'Your current range, at ${rupees(cost.pricePerLitre)}/L',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'Spent on fuel, last 30 days',
                value: rupees(spend),
                caption: 'About ${rupees((spend / 30).roundToDouble())} a day',
              ),
            ),
          ],
        ),
        _TrendCard(state: state),
        _GradeCard(comparison: state.gradeComparison),
        _MonthsCard(months: state.spendByMonth),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(caption, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final series = state.trend;
    final points = series?.points ?? const <Chain>[];
    if (series == null || points.isEmpty) {
      return const _Section(
        title: 'Mileage trend',
        children: [
          Text(
            'Each closed chain adds a point here, with its range. Your '
            'trend starts after your first result.',
          ),
        ],
      );
    }
    return _Section(
      title: 'Mileage trend',
      children: [
        TrendChart(series: series, current: state.analysis?.current),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Show all values'),
          children: [
            for (final chain in points.reversed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${kmpl(chain.kmpl!)} km/L (${bandText(chain.band!)})',
                ),
                subtitle: Text(
                  '${chainLabel(context, chain)} · ${km(chain.distanceKm!)} '
                  'on ${litres(chain.litres)}',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.comparison});

  final GradeComparison? comparison;

  @override
  Widget build(BuildContext context) {
    final c = comparison;
    final rows = c?.byGrade ?? const <GradeEstimate>[];
    final leftOut = [
      if ((c?.mixedChains ?? 0) > 0) '${c!.mixedChains} mixed',
      if ((c?.untaggedChains ?? 0) > 0) '${c!.untaggedChains} untagged',
    ];
    return _Section(
      title: 'Fuel comparison',
      children: [
        if (rows.isEmpty)
          const Text(
            'Pick the fuel type when you log a refuel. A chain counts for a '
            'fuel when every fill in it was that fuel.',
          )
        else ...[
          RangeRows(
            rows: [
              for (final row in rows) (gradeLabel(row.grade), row.estimate),
            ],
          ),
          const SizedBox(height: 4),
          Text(_verdict(rows)),
        ],
        const SizedBox(height: 8),
        Text(
          [
            'Uses chains since your last service only.',
            if (leftOut.isNotEmpty)
              'Left out: ${leftOut.join(', ')} chain'
                  '${(c!.mixedChains + c.untaggedChains) == 1 ? '' : 's'}.',
            'After switching fuel, the first chain still burns a little of '
                'the old fuel.',
          ].join(' '),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Only claims a difference when the ranges don't overlap.
  String _verdict(List<GradeEstimate> rows) {
    if (rows.length < 2) {
      return 'Log chains on another fuel to compare.';
    }
    final sorted = [...rows]
      ..sort((a, b) => b.estimate.kmpl.compareTo(a.estimate.kmpl));
    final best = sorted.first;
    final next = sorted[1];
    final nextTop = next.estimate.band.high;
    if (nextTop != null && best.estimate.band.low > nextTop) {
      return '${gradeLabel(best.grade)} gives clearly more km/L than '
          '${gradeLabel(next.grade)} on your bike.';
    }
    return 'No clear difference yet: the ranges overlap. More litres of each '
        'will narrow them.';
  }
}

class _MonthsCard extends StatelessWidget {
  const _MonthsCard({required this.months});

  final List<MonthSpend> months;

  @override
  Widget build(BuildContext context) {
    final shown = months.take(6).toList();
    final most = shown.fold(0.0, (m, s) => s.rupees > m ? s.rupees : m);
    return _Section(
      title: 'Spend by month',
      children: [
        if (shown.isEmpty)
          const Text('Nothing logged yet.')
        else
          for (final month in shown)
            MeterRow(
              label: monthLabel(month.year, month.month),
              fraction: most == 0 ? 0 : month.rupees / most,
              value: rupees(month.rupees),
            ),
        if (shown.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Every refuel counts here, including ones outside a chain.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
