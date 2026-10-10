import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED BAR CHART — CustomPainter (No third-party chart library)
// ═══════════════════════════════════════════════════════════════════════════════

class AnimatedBarChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final Color barColor;
  final Color highlightColor;

  const AnimatedBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 180,
    this.barColor = AppColors.primary,
    this.highlightColor = AppColors.accent,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          height: widget.height + 40, // +40 for labels
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarChartPainter(
              values: widget.values,
              labels: widget.labels,
              progress: _animation.value,
              barColor: widget.barColor,
              highlightColor: widget.highlightColor,
            ),
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double progress;
  final Color barColor;
  final Color highlightColor;

  _BarChartPainter({
    required this.values,
    required this.labels,
    required this.progress,
    required this.barColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const labelHeight = 36.0;
    const topPadding = 20.0;
    const sidePadding = 16.0;

    final chartHeight = size.height - labelHeight - topPadding;
    final chartWidth = size.width - sidePadding * 2;

    final maxValue = values.reduce((a, b) => a > b ? a : b);

    // Nếu tất cả values <= 0, vẽ placeholder
    if (maxValue <= 0) {
      _drawEmptyState(canvas, size);
      return;
    }

    // ─── Horizontal guide lines ──────────────────────────────────────────
    final guideLinePaint = Paint()
      ..color = AppColors.glassBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const guideCount = 4;
    for (int i = 0; i <= guideCount; i++) {
      final y = topPadding + chartHeight * (1 - i / guideCount);
      canvas.drawLine(
        Offset(sidePadding, y),
        Offset(size.width - sidePadding, y),
        guideLinePaint,
      );

      // Value labels on left
      final valuePainter = TextPainter(
        text: TextSpan(
          text: CurrencyFormatter.formatVNDShort(maxValue * i / guideCount),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      valuePainter.layout();
      valuePainter.paint(
        canvas,
        Offset(0, y - valuePainter.height / 2),
      );
    }

    // ─── Bars ─────────────────────────────────────────────────────────────
    final barCount = values.length;
    final barAreaWidth = chartWidth / barCount;
    final barWidth = (barAreaWidth * 0.55).clamp(20.0, 60.0);

    // Find max index for highlighting
    int maxIdx = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[maxIdx]) maxIdx = i;
    }

    for (int i = 0; i < barCount; i++) {
      final isHighlight = i == maxIdx;

      // Chiều cao tối thiểu 6px khi có giá trị > 0
      // Giới hạn trên = chartHeight để tránh vọt khỏi vùng vẽ (Curves.elasticOut > 1.0)
      const minBarHeight = 6.0;
      final rawHeight = (values[i] / maxValue) * chartHeight * progress;
      final barHeight = values[i] > 0
          ? math.min(math.max(rawHeight, minBarHeight), chartHeight)
          : 0.0;

      final x = sidePadding + barAreaWidth * i + (barAreaWidth - barWidth) / 2;
      final top = topPadding + chartHeight - barHeight;
      final bottom = topPadding + chartHeight;

      // Bán kính bo góc không được vượt quá nửa chiều cao cột
      final cornerRadius = Radius.circular(
        math.min(barWidth / 2, barHeight / 2),
      );
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        topLeft: cornerRadius,
        topRight: cornerRadius,
      );

      // Glow for highlighted bar
      if (isHighlight && barHeight > 0) {
        final glowPaint = Paint()
          ..color = highlightColor.withAlpha(60)
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              highlightColor.withAlpha(60),
              highlightColor.withAlpha(10),
            ],
          ).createShader(
            Rect.fromLTWH(x - 10, top - 10, barWidth + 20, barHeight + 20),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawRRect(barRect, glowPaint);
      }

      // Bar gradient fill
      if (barHeight > 0) {
        final barPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isHighlight
                ? [
              highlightColor,
              Color.lerp(highlightColor, barColor, 0.5)!,
            ]
                : [
              barColor.withAlpha(200),
              barColor.withAlpha(120),
            ],
          ).createShader(Rect.fromLTWH(x, top, barWidth, barHeight));
        canvas.drawRRect(barRect, barPaint);
      }

      // Value label on top of bar — hiện khi animation đủ xa, không cần barHeight > 16
      if (progress > 0.7 && values[i] > 0) {
        final labelAlpha = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
        final valuePainter = TextPainter(
          text: TextSpan(
            text: CurrencyFormatter.formatVNDShort(values[i] * progress),
            style: TextStyle(
              color: isHighlight
                  ? highlightColor
                  : AppColors.textSecondary
                  .withAlpha((255 * labelAlpha).toInt()),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valuePainter.layout(maxWidth: barWidth + 20);
        valuePainter.paint(
          canvas,
          Offset(
            x + barWidth / 2 - valuePainter.width / 2,
            top - valuePainter.height - 4,
          ),
        );
      }

      // X-axis label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: i < labels.length ? labels[i] : 'W${i + 1}',
          style: TextStyle(
            color: isHighlight ? highlightColor : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout(maxWidth: barAreaWidth);
      labelPainter.paint(
        canvas,
        Offset(
          x + barWidth / 2 - labelPainter.width / 2,
          bottom + 8,
        ),
      );
    }
  }

  void _drawEmptyState(Canvas canvas, Size size) {
    const labelHeight = 36.0;
    const topPadding = 20.0;
    const sidePadding = 16.0;

    final chartHeight = size.height - labelHeight - topPadding;
    final chartWidth = size.width - sidePadding * 2;
    final barCount = labels.length;
    final barAreaWidth = chartWidth / barCount;

    for (int i = 0; i < barCount; i++) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: i < labels.length ? labels[i] : 'W${i + 1}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout(maxWidth: barAreaWidth);
      labelPainter.paint(
        canvas,
        Offset(
          sidePadding +
              barAreaWidth * i +
              barAreaWidth / 2 -
              labelPainter.width / 2,
          topPadding + chartHeight + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}