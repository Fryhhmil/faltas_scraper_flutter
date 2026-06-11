import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RingGauge extends StatelessWidget {
  final double? value; // 0..10
  final String caption;
  const RingGauge({super.key, required this.value, this.caption = 'MÉDIA'});

  @override
  Widget build(BuildContext context) {
    final v = value ?? 0;
    final pct = (v / 10).clamp(0.0, 1.0);
    final color = v >= 7
        ? AppColors.success
        : v >= 5
            ? AppColors.warning
            : AppColors.error;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(
          startDegreeOffset: -90,
          sectionsSpace: 0,
          centerSpaceRadius: 42,
          sections: [
            PieChartSectionData(
                value: pct, color: color, radius: 12, showTitle: false),
            PieChartSectionData(
                value: 1 - pct,
                color: AppColors.border,
                radius: 12,
                showTitle: false),
          ],
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value == null ? '—' : v.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          Text(caption,
              style: const TextStyle(fontSize: 9, color: AppColors.text2)),
        ]),
      ]),
    );
  }
}
