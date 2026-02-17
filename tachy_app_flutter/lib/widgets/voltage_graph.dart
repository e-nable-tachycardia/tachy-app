//
// VoltageGraph.dart
// tachy_app_flutter
//
// PPG voltage line chart (last 5 seconds) - migrated from Swift VoltageGraphView
//

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../providers/ppg_provider.dart';

class VoltageGraph extends StatelessWidget {
  final List<VoltageDataPoint> voltageHistory;
  static const double peakThreshold = 2.8;

  const VoltageGraph({super.key, required this.voltageHistory});

  double get _minVoltage {
    if (voltageHistory.isEmpty) return 0.0;
    final min = voltageHistory.map((p) => p.voltage).reduce(
          (a, b) => a < b ? a : b,
        );
    return min - (min.abs() * 0.05);
  }

  double get _maxVoltage {
    if (voltageHistory.isEmpty) return 5.0;
    final max = voltageHistory.map((p) => p.voltage).reduce(
          (a, b) => a > b ? a : b,
        );
    return max + (max * 0.05);
  }

  @override
  Widget build(BuildContext context) {
    if (voltageHistory.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Waiting for data...",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final minV = _minVoltage;
    final maxV = _maxVoltage;
    final voltageRange = maxV - minV;

    final spots = voltageHistory
        .asMap()
        .entries
        .map((e) => FlSpot(
              e.key.toDouble(),
              e.value.voltage,
            ))
        .toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.only(left: 20, right: 15, top: 15, bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (voltageHistory.length - 1).toDouble().clamp(1.0, double.infinity),
          minY: minV,
          maxY: maxV,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: voltageRange / 5,
            verticalInterval: (voltageHistory.length - 1) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 0.5,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: voltageRange / 5,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: Colors.blue,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            if (voltageRange > 0 &&
                peakThreshold >= minV &&
                peakThreshold <= maxV)
              LineChartBarData(
                spots: [
                  FlSpot(0, peakThreshold),
                  FlSpot(
                    (voltageHistory.length - 1).toDouble().clamp(1.0, double.infinity),
                    peakThreshold,
                  ),
                ],
                isCurved: false,
                color: Colors.red.withOpacity(0.6),
                barWidth: 1.5,
                dashArray: [5, 5],
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 150),
      ),
    );
  }
}
