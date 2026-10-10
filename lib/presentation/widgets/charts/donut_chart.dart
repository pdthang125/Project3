import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ANIMATED DONUT/PIE CHART — CustomPainter (No third-party chart library)
// ═══════════════════════════════════════════════════════════════════════════════

class AnimatedDonutChart extends StatefulWidget {
  final Map<String, double> data;
  final double size;
  final double strokeWidth;
  final String? centerLabel;
  final double? centerValue;

  const AnimatedDonutChart({
    super.key,
    required this.data,
    this.size = 220,
    this.strokeWidth = 38,
    this.centerLabel,
    this.centerValue,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
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
    // Chiều rộng vùng trong vòng tròn (đường kính trong = size - strokeWidth * 2)
    // Trừ thêm padding để text không chạm viền
    final innerWidth = widget.size - widget.strokeWidth * 2 - 16;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: ClipRect(
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _DonutChartPainter(
                data: widget.data,
                progress: _animation.value,
                strokeWidth: widget.strokeWidth,
              ),
              child: Center(
                child: widget.centerValue != null
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.centerLabel != null)
                      Text(
                        widget.centerLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    // Constrain + FittedBox để số tiền lớn không tràn vòng trong
                    SizedBox(
                      width: innerWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.formatVNDShort(
                            widget.centerValue! * _animation.value,
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double progress;
  final double strokeWidth;

  _DonutChartPainter({
    required this.data,
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = data.values.fold(0.0, (sum, v) => sum + v);
    if (total == 0) return;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.backgroundElevated
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -math.pi / 2; // Start from top
    const gapAngle = 0.03; // Gap between segments (radians)

    for (final entry in data.entries) {
      final sweepFraction = entry.value / total;
      final sweepAngle =
          (2 * math.pi * sweepFraction - gapAngle) * progress;

      if (sweepAngle <= 0) {
        startAngle += 2 * math.pi * sweepFraction * progress;
        continue;
      }

      final color = AppColors.categoryColor(entry.key);

      // Shadow/glow effect
      final glowPaint = Paint()
        ..color = color.withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

      // Main segment
      final segmentPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [
            color,
            Color.lerp(color, Colors.white, 0.15)!,
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, segmentPaint);

      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.data != data;
}

// ─── Legend ───────────────────────────────────────────────────────────────────

class ChartLegend extends StatelessWidget {
  final Map<String, double> data;

  const ChartLegend({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (s, v) => s + v);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Số tiền chiếm tối đa 42% chiều rộng, phần còn lại dành cho tên
        final maxAmountWidth = constraints.maxWidth * 0.42;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: data.entries.map((entry) {
            final pct = total > 0 ? (entry.value / total * 100) : 0.0;
            final color = AppColors.categoryColor(entry.key);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // ── Dot ────────────────────────────────────────────────
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withAlpha(100),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // ── Category name — chiếm phần còn lại ─────────────────
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── Percentage — co chữ trong khung cố định ────────────
                  SizedBox(
                    width: 38,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // ── Amount — co chữ, không cắt bớt ────────────────────
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxAmountWidth),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        CurrencyFormatter.formatVNDShort(entry.value),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}