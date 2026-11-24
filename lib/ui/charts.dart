import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../engine/engine.dart';
import 'format.dart';

/// Chart colours from the validated reference palette (dataviz skill),
/// checked against this app's card surfaces (#eff5f2 light, #171d1b dark).
/// Text never uses these: labels use the theme's text colours.
class ChartColors {
  const ChartColors._({
    required this.series,
    required this.flagged,
    required this.muted,
    required this.grid,
    required this.axis,
    required this.track,
  });

  /// Single series (categorical slot 1, blue).
  final Color series;

  /// Status "serious": flagged results. Always paired with a hollow shape
  /// and a label, never colour alone.
  final Color flagged;

  /// De-emphasis grey: discarded results.
  final Color muted;
  final Color grid;
  final Color axis;

  /// Meter track: a lighter step of the series ramp.
  final Color track;

  Color get wash => series.withValues(alpha: 0.10);

  static ChartColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  static const _light = ChartColors._(
    series: Color(0xFF2A78D6),
    flagged: Color(0xFFEC835A),
    muted: Color(0xFF898781),
    grid: Color(0xFFE1E0D9),
    axis: Color(0xFFC3C2B7),
    track: Color(0xFFCDE2FB),
  );

  static const _dark = ChartColors._(
    series: Color(0xFF3987E5),
    flagged: Color(0xFFEC835A),
    muted: Color(0xFF898781),
    grid: Color(0xFF2C2C2A),
    axis: Color(0xFF383835),
    track: Color(0xFF104281),
  );
}

/// How a chain result is drawn: filled (counts), hollow (flagged), grey
/// (discarded). Shape plus the key carry the state, not colour alone.
enum _Mark { counts, flagged, discarded }

_Mark _markOf(Chain chain) => switch (chain.status) {
  ChainStatus.flagged => _Mark.flagged,
  ChainStatus.discarded => _Mark.discarded,
  _ => _Mark.counts,
};

/// Clean axis bounds and step for [min]..[max] (about four steps).
({double low, double high, double step}) niceScale(double min, double max) {
  if (max - min < 2) {
    min -= 1;
    max += 1;
  }
  final raw = (max - min) / 4;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floorToDouble())
      .toDouble();
  final normal = raw / magnitude;
  final step =
      (normal <= 1
          ? 1
          : normal <= 2
          ? 2
          : normal <= 5
          ? 5
          : 10) *
      magnitude;
  return (
    low: (min / step).floorToDouble() * step,
    high: (max / step).ceilToDouble() * step,
    step: step,
  );
}

/// km/L per chain, each with its range, on one axis; the current range as a
/// wash; services as dividers. Tap a point to read it below the chart.
class TrendChart extends StatefulWidget {
  const TrendChart({super.key, required this.series, required this.current});

  final TrendSeries series;
  final OverallEstimate? current;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final points = widget.series.points;
    final selected = (_selected ?? points.length - 1).clamp(
      0,
      points.length - 1,
    );
    final colors = ChartColors.of(context);
    final theme = Theme.of(context);
    final marks = {for (final p in points) _markOf(p)};
    final chain = points[selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final layout = _TrendLayout(
              points: points,
              current: widget.current,
              width: constraints.maxWidth,
            );
            return Semantics(
              label:
                  'Mileage trend: ${points.length} results. '
                  'Tap a point to read it.',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => setState(
                  () => _selected = layout.indexAt(details.localPosition.dx),
                ),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, _TrendLayout.height),
                  painter: _TrendPainter(
                    layout: layout,
                    servicesBefore: widget.series.servicesBefore,
                    selected: selected,
                    colors: colors,
                    surface: theme.colorScheme.surfaceContainerLow,
                    text: theme.textTheme.labelSmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textDirection: Directionality.of(context),
                    dateLabel: (d) => date(context, d),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '${date(context, chain.end!.date)} · ${kmpl(chain.kmpl!)} km/L '
          '(${bandText(chain.band!)}) · ${litres(chain.litres)} · '
          '${statusLabel(chain)}',
          style: theme.textTheme.bodyMedium,
        ),
        if (marks.length > 1) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (final mark in _Mark.values)
                if (marks.contains(mark)) _Key(mark: mark, colors: colors),
            ],
          ),
        ],
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.mark, required this.colors});

  final _Mark mark;
  final ChartColors colors;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surfaceContainerLow;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(14, 14),
          painter: _KeyPainter(mark, colors, surface),
        ),
        const SizedBox(width: 6),
        Text(switch (mark) {
          _Mark.counts => 'Counts toward your mileage',
          _Mark.flagged => 'Flagged',
          _Mark.discarded => 'Discarded',
        }, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _KeyPainter extends CustomPainter {
  _KeyPainter(this.mark, this.colors, this.surface);

  final _Mark mark;
  final ChartColors colors;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) =>
      _paintDot(canvas, size.center(Offset.zero), mark, colors, surface);

  @override
  bool shouldRepaint(_KeyPainter old) =>
      old.mark != mark || old.colors != colors || old.surface != surface;
}

/// The dot for one result: an 8px mark inside a 2px ring of the surface.
void _paintDot(
  Canvas canvas,
  Offset at,
  _Mark mark,
  ChartColors colors,
  Color surface,
) {
  canvas.drawCircle(at, 6, Paint()..color = surface);
  switch (mark) {
    case _Mark.counts:
      canvas.drawCircle(at, 4, Paint()..color = colors.series);
    case _Mark.flagged:
      canvas.drawCircle(
        at,
        3.5,
        Paint()
          ..color = colors.flagged
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    case _Mark.discarded:
      canvas.drawCircle(at, 4, Paint()..color = colors.muted);
  }
}

class _TrendLayout {
  _TrendLayout({
    required this.points,
    required this.current,
    required double width,
  }) : plot = Rect.fromLTRB(40, 20, width - 8, height - 26) {
    final values = <double>[
      for (final p in points) ...[p.band!.low, p.band!.high ?? p.kmpl! * 1.2],
      if (current case final c?) ...[c.band.low, c.band.high ?? c.kmpl * 1.2],
    ];
    scale = niceScale(values.reduce(math.min), values.reduce(math.max));
  }

  /// Plot plus the x-axis label band, so nothing is clipped.
  static const height = 240.0;

  final List<Chain> points;
  final OverallEstimate? current;
  final Rect plot;
  late final ({double low, double high, double step}) scale;

  double get slot => plot.width / points.length;
  double xOf(int i) => plot.left + slot * (i + 0.5);
  double yOf(double kmpl) =>
      plot.bottom - (kmpl - scale.low) / (scale.high - scale.low) * plot.height;

  /// The whole slot is the hit target (always wider than 24px here).
  int indexAt(double x) =>
      ((x - plot.left) / slot).floor().clamp(0, points.length - 1);
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.layout,
    required this.servicesBefore,
    required this.selected,
    required this.colors,
    required this.surface,
    required this.text,
    required this.textDirection,
    required this.dateLabel,
  });

  final _TrendLayout layout;
  final List<int> servicesBefore;
  final int selected;
  final ChartColors colors;
  final Color surface;
  final TextStyle text;
  final TextDirection textDirection;
  final String Function(DateTime) dateLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = layout.plot;
    final hairline = Paint()
      ..color = colors.grid
      ..strokeWidth = 1;

    // Gridlines and y ticks (km/L).
    final scale = layout.scale;
    for (var v = scale.low; v <= scale.high + 1e-9; v += scale.step) {
      final y = layout.yOf(v);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), hairline);
      _label(canvas, v.toStringAsFixed(0), Offset(plot.left - 6, y), 1, 0.5);
    }
    _label(canvas, 'km/L', Offset(plot.left - 6, plot.top - 18), 1, 0);

    // The current range: a wash, a 2px line, and a direct label.
    final current = layout.current;
    if (current != null) {
      final top = layout.yOf(current.band.high ?? scale.high);
      final bottom = layout.yOf(current.band.low);
      canvas.drawRect(
        Rect.fromLTRB(plot.left, top, plot.right, bottom),
        Paint()..color = colors.wash,
      );
      final y = layout.yOf(current.kmpl);
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()
          ..color = colors.series
          ..strokeWidth = 2,
      );
      _label(
        canvas,
        'Now ${kmpl(current.kmpl)}',
        Offset(plot.right, top - 2),
        1,
        1,
      );
    }

    // Services: a divider between the results before and after.
    final divider = Paint()
      ..color = colors.axis
      ..strokeWidth = 1;
    for (final index in servicesBefore) {
      final x = plot.left + layout.slot * index;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), divider);
      _label(canvas, 'Service', Offset(x + 3, plot.top), 0, 0);
    }

    // Results: the range as a 2px bar, the estimate as a dot.
    for (var i = 0; i < layout.points.length; i++) {
      final chain = layout.points[i];
      final mark = _markOf(chain);
      final x = layout.xOf(i);
      final band = chain.band!;
      canvas.drawLine(
        Offset(x, layout.yOf(band.high ?? scale.high)),
        Offset(x, layout.yOf(band.low)),
        Paint()
          ..color = switch (mark) {
            _Mark.counts => colors.series,
            _Mark.flagged => colors.flagged,
            _Mark.discarded => colors.muted,
          }
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      final at = Offset(x, layout.yOf(chain.kmpl!));
      if (i == selected) {
        canvas.drawCircle(
          at,
          9,
          Paint()
            ..color = text.color!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      _paintDot(canvas, at, mark, colors, surface);
    }

    // Baseline and dates: first, last and the selected one.
    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      Paint()
        ..color = colors.axis
        ..strokeWidth = 1,
    );
    final n = layout.points.length;
    final shown = n <= 4
        ? {for (var i = 0; i < n; i++) i}
        : {0, n - 1, selected};
    for (final i in shown) {
      final x = layout.xOf(i);
      final anchor = n == 1
          ? 0.5
          : i == 0
          ? 0.0
          : i == n - 1
          ? 1.0
          : 0.5;
      _label(
        canvas,
        dateLabel(layout.points[i].end!.date),
        Offset(x, plot.bottom + 6),
        anchor,
        0,
      );
    }
  }

  /// Draws [value] with its anchor point (ax, ay in 0..1 of the text box)
  /// at [at].
  void _label(Canvas canvas, String value, Offset at, double ax, double ay) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: text),
      textDirection: textDirection,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width * ax, painter.height * ay));
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.layout != layout ||
      old.selected != selected ||
      old.colors != colors ||
      old.surface != surface ||
      old.text != text;
}

/// One row of a meter list: name, an aligned bar, and the figure.
class MeterRow extends StatelessWidget {
  const MeterRow({
    super.key,
    required this.label,
    required this.fraction,
    required this.value,
  });

  final String label;
  final double fraction;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = ChartColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 76, child: Text(label, style: textTheme.bodyMedium)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: colors.track),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.series,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ranges on one shared axis, one row each, so overlap is visible.
class RangeRows extends StatelessWidget {
  const RangeRows({super.key, required this.rows});

  /// (label, estimate)
  final List<(String, OverallEstimate)> rows;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final (_, e) in rows) ...[e.band.low, e.band.high ?? e.kmpl * 1.2],
    ];
    final scale = niceScale(values.reduce(math.min), values.reduce(math.max));
    final theme = Theme.of(context);
    final colors = ChartColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (label, estimate) in rows) ...[
          Text(
            '$label: ${kmpl(estimate.kmpl)} km/L (${bandText(estimate.band)}) · '
            '${confidenceLabel(estimate.confidence)} · '
            '${litres(estimate.litres)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          CustomPaint(
            size: const Size(double.infinity, 16),
            painter: _RangePainter(
              estimate: estimate,
              scale: scale,
              colors: colors,
              surface: theme.colorScheme.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${scale.low.toStringAsFixed(0)} km/L',
              style: theme.textTheme.labelSmall,
            ),
            Text(
              '${scale.high.toStringAsFixed(0)} km/L',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _RangePainter extends CustomPainter {
  _RangePainter({
    required this.estimate,
    required this.scale,
    required this.colors,
    required this.surface,
  });

  final OverallEstimate estimate;
  final ({double low, double high, double step}) scale;
  final ChartColors colors;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    double xOf(double v) =>
        (v - scale.low) / (scale.high - scale.low) * (size.width - 12) + 6;
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = colors.grid
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(xOf(estimate.band.low), y),
      Offset(xOf(estimate.band.high ?? scale.high), y),
      Paint()
        ..color = colors.series
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    _paintDot(
      canvas,
      Offset(xOf(estimate.kmpl), y),
      _Mark.counts,
      colors,
      surface,
    );
  }

  @override
  bool shouldRepaint(_RangePainter old) =>
      old.estimate != estimate || old.colors != colors || old.scale != scale;
}
