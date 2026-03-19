// lib/views/stats/stats_bar_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StatsBarChart extends StatelessWidget {
  const StatsBarChart({super.key, required this.data});

  /// dhikrId (as string) -> count
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data for this period'));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final entries = data.entries.toList();
    final maxY = (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2)
        .toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${entries[groupIndex].key}\n${rod.toY.toInt()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                final name = entries[index].key;
                // Truncate long names
                final label = name.length > 10 ? '${name.substring(0, 10)}\u2026' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Tooltip(
                    message: name,
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
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
        barGroups: entries.asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final count = mapEntry.value.value.toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count,
                color: colorScheme.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
