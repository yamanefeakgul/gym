import 'dart:math';
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

class MiniProgressChart extends StatelessWidget {
  final List<WeightLogEntry> history;
  final String exerciseName;

  const MiniProgressChart({
    super.key,
    required this.history,
    required this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: const Center(
          child: Text(
            'Henüz kaydedilmiş ağırlık verisi yok.\nAğırlık girerek gelişim grafiğinizi başlatın!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final sorted = List<WeightLogEntry>.from(history)..sort((a, b) => a.date.compareTo(b.date));
    final weights = sorted.map((e) => e.weightKg).toList();
    final minW = weights.reduce(min);
    final maxW = weights.reduce(max);
    final startW = weights.first;
    final lastW = weights.last;
    final diff = lastW - startW;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AĞIRLIK GELİŞİM GRAFİĞİ',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${lastW.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: diff >= 0 ? AppTheme.primaryNeon.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: diff >= 0 ? AppTheme.primaryNeon : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Tahmini 1RM',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  Text(
                    '${sorted.last.estimated1RM.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Canvas Chart
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(
                entries: sorted,
                minWeight: minW == maxW ? minW - 5 : minW - 2,
                maxWeight: minW == maxW ? maxW + 5 : maxW + 5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // History Log Table Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: sorted.take(4).map((entry) {
              final dateStr = '${entry.date.day}/${entry.date.month}';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(dateStr, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.weightKg}kg × ${entry.reps}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<WeightLogEntry> entries;
  final double minWeight;
  final double maxWeight;

  _LineChartPainter({
    required this.entries,
    required this.minWeight,
    required this.maxWeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final paintLine = Paint()
      ..color = AppTheme.primaryNeon
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryNeon.withOpacity(0.35),
          AppTheme.primaryNeon.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = AppTheme.surfaceBorder.withOpacity(0.5)
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i <= 2; i++) {
      final y = size.height * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    final weightSpan = (maxWeight - minWeight).clamp(1.0, 1000.0);
    final count = entries.length;

    for (int i = 0; i < count; i++) {
      final x = count == 1 ? size.width / 2 : (i / (count - 1)) * size.width;
      final normalizedY = (entries[i].weightKg - minWeight) / weightSpan;
      final y = size.height - (normalizedY * size.height).clamp(0.0, size.height);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Draw gradient area under line
    canvas.drawPath(fillPath, paintFill);
    // Draw the main line
    canvas.drawPath(path, paintLine);

    // Draw dots and glow
    final dotPaint = Paint()..color = AppTheme.background;
    final dotBorderPaint = Paint()
      ..color = AppTheme.primaryNeon
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}
