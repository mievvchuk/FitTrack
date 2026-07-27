import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/analytics_dashboard_model.dart';

class AnalyticsLineChart extends StatelessWidget {
  const AnalyticsLineChart({
    required this.title,
    required this.points,
    required this.color,
    this.unit = '',
    super.key,
  });

  final String title;
  final List<AnalyticsPointModel> points;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: title,
      child: points.isEmpty
          ? const _EmptyChart()
          : CustomPaint(
              painter: _LineChartPainter(points: points, color: color),
              child: const SizedBox(height: 180),
            ),
      footer: points.isEmpty ? null : _RangeFooter(points: points, unit: unit),
    );
  }
}

class AnalyticsBarChart extends StatelessWidget {
  const AnalyticsBarChart({
    required this.title,
    required this.points,
    required this.color,
    super.key,
  });

  final String title;
  final List<AnalyticsPointModel> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      title: title,
      child: CustomPaint(
        painter: _BarChartPainter(points: points, color: color),
        child: const SizedBox(height: 180),
      ),
    );
  }
}

class AnalyticsCaloriesChart extends StatelessWidget {
  const AnalyticsCaloriesChart({
    required this.points,
    super.key,
  });

  final List<AnalyticsCaloriesPointModel> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return _ChartCard(
      title: l10n.calories,
      child: CustomPaint(
        painter: _CaloriesChartPainter(
          points: points,
          consumedColor: scheme.primary,
          burnedColor: scheme.tertiary,
        ),
        child: const SizedBox(height: 180),
      ),
      footer: Row(
        children: <Widget>[
          _LegendDot(color: scheme.primary, label: l10n.consumed),
          const SizedBox(width: 16),
          _LegendDot(color: scheme.tertiary, label: l10n.burned),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
            if (footer != null) ...<Widget>[
              const SizedBox(height: 8),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Text(
          AppLocalizations.of(context).noDataYet,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _RangeFooter extends StatelessWidget {
  const _RangeFooter({
    required this.points,
    required this.unit,
  });

  final List<AnalyticsPointModel> points;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final values = points.map((point) => point.value);
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);

    return Text(
      'Range ${min.toStringAsFixed(1)}$unit - ${max.toStringAsFixed(1)}$unit',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox(width: 8, height: 8),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.points,
    required this.color,
  });

  final List<AnalyticsPointModel> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((point) => point.value).toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = math.max(maxValue - minValue, 1.0);
    const padding = EdgeInsets.fromLTRB(4, 8, 4, 16);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = color;

    for (var i = 0; i < 4; i += 1) {
      final y = padding.top + (chartHeight / 3) * i;
      canvas.drawLine(Offset(padding.left, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    for (var i = 0; i < points.length; i += 1) {
      final x = padding.left +
          (points.length == 1 ? chartWidth : chartWidth * (i / (points.length - 1)));
      final normalized = (points[i].value - minValue) / range;
      final y = padding.top + chartHeight - (normalized * chartHeight);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (var i = 0; i < points.length; i += 1) {
      final x = padding.left +
          (points.length == 1 ? chartWidth : chartWidth * (i / (points.length - 1)));
      final normalized = (points[i].value - minValue) / range;
      final y = padding.top + chartHeight - (normalized * chartHeight);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _BarChartPainter extends CustomPainter {
  const _BarChartPainter({
    required this.points,
    required this.color,
  });

  final List<AnalyticsPointModel> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final maxValue = math.max(
      points.map((point) => point.value).reduce(math.max),
      1.0,
    );
    const padding = EdgeInsets.fromLTRB(4, 8, 4, 16);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;
    final barWidth = math.max(4.0, chartWidth / points.length * 0.55);
    final paint = Paint()..color = color;
    final mutedPaint = Paint()..color = color.withValues(alpha: 0.18);

    for (var i = 0; i < points.length; i += 1) {
      final x = padding.left + (chartWidth / points.length) * i;
      final height = (points[i].value / maxValue) * chartHeight;
      final rect = Rect.fromLTWH(
        x + (chartWidth / points.length - barWidth) / 2,
        padding.top + chartHeight - height,
        barWidth,
        height,
      );
      final baseline = Rect.fromLTWH(
        rect.left,
        padding.top,
        barWidth,
        chartHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(baseline, const Radius.circular(4)),
        mutedPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _CaloriesChartPainter extends CustomPainter {
  const _CaloriesChartPainter({
    required this.points,
    required this.consumedColor,
    required this.burnedColor,
  });

  final List<AnalyticsCaloriesPointModel> points;
  final Color consumedColor;
  final Color burnedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final maxConsumed = points.map((point) => point.consumed).reduce(math.max);
    final maxBurned = points.map((point) => point.burned).reduce(math.max);
    final maxValue = math.max(math.max(maxConsumed, maxBurned), 1).toDouble();
    const padding = EdgeInsets.fromLTRB(4, 8, 4, 16);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;
    final groupWidth = chartWidth / points.length;
    final barWidth = math.max(3.0, groupWidth * 0.25);
    final consumedPaint = Paint()..color = consumedColor;
    final burnedPaint = Paint()..color = burnedColor;

    for (var i = 0; i < points.length; i += 1) {
      final baseX = padding.left + groupWidth * i + groupWidth * 0.25;
      _drawBar(
        canvas,
        x: baseX,
        value: points[i].consumed,
        maxValue: maxValue,
        chartHeight: chartHeight,
        padding: padding,
        width: barWidth,
        paint: consumedPaint,
      );
      _drawBar(
        canvas,
        x: baseX + barWidth + 2,
        value: points[i].burned,
        maxValue: maxValue,
        chartHeight: chartHeight,
        padding: padding,
        width: barWidth,
        paint: burnedPaint,
      );
    }
  }

  void _drawBar(
    Canvas canvas, {
    required double x,
    required int value,
    required double maxValue,
    required double chartHeight,
    required EdgeInsets padding,
    required double width,
    required Paint paint,
  }) {
    final height = (value / maxValue) * chartHeight;
    final rect = Rect.fromLTWH(
      x,
      padding.top + chartHeight - height,
      width,
      height,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CaloriesChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.consumedColor != consumedColor ||
        oldDelegate.burnedColor != burnedColor;
  }
}
