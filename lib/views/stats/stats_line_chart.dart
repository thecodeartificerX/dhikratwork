// lib/views/stats/stats_line_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatsLineChart extends StatelessWidget {
  const StatsLineChart({super.key, required this.data});

  /// Ordered list of date string -> count
  final List<MapEntry<String, int>> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data for this period'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final maxY = (data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2)
        .toDouble();

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final index = spot.x.toInt();
              final label = index < data.length ? data[index].key : '';
              return LineTooltipItem(
                '$label\n${spot.y.toInt()}',
                const TextStyle(color: Colors.white),
              );
            }).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (data.length / 5).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox.shrink();
                // Show only day portion: YYYY-MM-DD -> DD
                final parts = data[index].key.split('-');
                final label = parts.length == 3 ? parts[2] : data[index].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outlineVariant,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.secondary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.secondary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
