import 'package:flutter/material.dart';

import '../models/quote.dart';

/// Smooth area/line chart for a symbol's closing price, rendered with a custom
/// painter (no chart dependency), matching the look of the original app.
class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.points,
    required this.color,
  });

  final List<ChartPoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Not enough chart data'),
        ),
      );
    }
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: CustomPaint(
        painter: _PriceChartPainter(points: points, color: color),
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({required this.points, required this.color});

  final List<ChartPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paintRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final firstClose = points.first.close;
    var minY = points.first.close;
    var maxY = points.first.close;
    for (final point in points) {
      if (point.close < minY) minY = point.close;
      if (point.close > maxY) maxY = point.close;
    }
    final span = (maxY - minY).abs();
    if (span == 0) {
      minY -= maxY.abs() * 0.05;
      maxY += maxY.abs() * 0.05;
    } else {
      minY -= span * 0.1;
      maxY += span * 0.1;
    }
    final firstTime = points.first.time.toDouble();
    final lastTime = points.last.time.toDouble();
    final timeSpan = (lastTime - firstTime).abs().clamp(1.0, double.infinity);

    Offset project(ChartPoint point) {
      final dx = ((point.time - firstTime) / timeSpan) * size.width;
      final dy =
          size.height - ((point.close - minY) / (maxY - minY)) * size.height;
      return Offset(dx.toDouble(), dy);
    }

    final offsets = points.map(project).toList();
    final linePath = _smoothPath(offsets);

    final areaPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.45),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(paintRect);
    canvas.drawPath(areaPath, paint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final last = offsets.last;
    canvas.drawCircle(
      last,
      4.2,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      last,
      2.4,
      Paint()..color = color,
    );

    // Baseline marker so flat charts don't look empty.
    if ((firstClose - minY) / (maxY - minY) > 0.9 ||
        (firstClose - minY) / (maxY - minY) < 0.1) {
      final y = size.height -
          ((firstClose - minY) / (maxY - minY)) * size.height;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = color.withValues(alpha: 0.15)
          ..strokeWidth = 1,
      );
    }
  }

  /// Catmull-Rom style smoothing through the points, producing a curve similar
  /// to the cubic connector of the original chart.
  Path _smoothPath(List<Offset> offsets) {
    final path = Path();
    if (offsets.length == 2) {
      path.moveTo(offsets[0].dx, offsets[0].dy);
      path.lineTo(offsets[1].dx, offsets[1].dy);
      return path;
    }
    path.moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i > 0 ? i - 1 : 0];
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final p3 = offsets[i + 2 < offsets.length ? i + 2 : offsets.length - 1];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(_PriceChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
