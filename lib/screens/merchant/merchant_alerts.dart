import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:bhart/theme/app_theme.dart';

/// Port of merchant/alerts/page.tsx — same mock demand data, recharts
/// BarChart replaced with fl_chart's BarChart.
///
/// NOTE: the numbers below are hardcoded sample data, and the UI says so.
class MerchantAlerts extends StatelessWidget {
  const MerchantAlerts({super.key});

  static const _mockData = [
    (month: 'Aug', demand: 40.0),
    (month: 'Sep', demand: 65.0),
    (month: 'Oct', demand: 100.0), // Diwali Peak
    (month: 'Nov', demand: 85.0),
    (month: 'Dec', demand: 50.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.khadi,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('बाज़ार अलर्ट',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.weaverBlue)),
                    TextButton(
                      onPressed: () => context.go('/merchant'),
                      style: TextButton.styleFrom(backgroundColor: const Color(0xFFFFF7ED)),
                      child: const Text('वापस (Back)', style: TextStyle(color: AppColors.terracotta, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Alert card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.blue600, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Diwali Demand Spike',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
                            SizedBox(height: 4),
                            Text(
                              'Terracotta and Diyas demand is predicted to increase by 150% in October. Increase production now.',
                              style: TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Chart card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.trending_up, color: AppColors.terracotta, size: 22),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Terracotta Demand Forecast',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.weaverBlue)),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 240,
                        child: BarChart(
                          BarChartData(
                            maxY: 120,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(color: AppColors.gray500, fontSize: 12),
                                  ),
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= _mockData.length) return const SizedBox.shrink();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(_mockData[idx].month,
                                          style: const TextStyle(color: AppColors.gray500, fontSize: 12)),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < _mockData.length; i++)
                                BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(
                                    toY: _mockData[i].demand,
                                    color: AppColors.terracotta,
                                    width: 28,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ]),
                            ],
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                                  rod.toY.round().toString(),
                                  const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sample data for demonstration — not a live forecast.',
                        style: TextStyle(fontSize: 12, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}