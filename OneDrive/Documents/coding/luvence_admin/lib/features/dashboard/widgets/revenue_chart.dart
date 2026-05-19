import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/colors.dart';

class RevenueChart extends StatelessWidget {
  final Map<String, int> dailyRevenue;

  const RevenueChart({super.key, required this.dailyRevenue});

  @override
  Widget build(BuildContext context) {
    if (dailyRevenue.isEmpty) {
      return Center(child: Text('Belum ada data revenue', style: TextStyle(fontSize: 12, color: LuvColors.textMuted)));
    }

    final sortedKeys = dailyRevenue.keys.toList()..sort();
    final last7 = sortedKeys.length > 7 ? sortedKeys.sublist(sortedKeys.length - 7) : sortedKeys;
    final maxY = last7.map((k) => dailyRevenue[k] ?? 0).reduce((a, b) => a > b ? a : b).toDouble();

    final spots = last7.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (dailyRevenue[e.value] ?? 0).toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 4 : 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.03),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= last7.length) return const SizedBox();
                // Show only first, middle, and last labels to prevent overlap
                final showLabel = idx == 0 || idx == last7.length - 1 || idx == last7.length ~/ 2;
                if (!showLabel) return const SizedBox();
                final parts = last7[idx].split('-');
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${parts.last}/${parts[1]}', style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: LuvColors.accent,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: LuvColors.accent,
                strokeWidth: 1.5,
                strokeColor: LuvColors.background,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [LuvColors.accent.withValues(alpha: 0.2), LuvColors.accent.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => LuvColors.surface,
            getTooltipItems: (spots) => spots.map((s) {
              final v = s.y.toInt();
              final formatted = v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}M' : v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}K' : '$v';
              return LineTooltipItem('Rp $formatted', const TextStyle(color: LuvColors.accent, fontSize: 11, fontWeight: FontWeight.w700));
            }).toList(),
          ),
        ),
      ),
    );
  }
}
