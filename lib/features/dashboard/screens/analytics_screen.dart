import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Analytics",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 24),
        
        // --- SECTION 1: Emergency Sensor Trends ---
        Text(
          "Emergency Sensor Trends",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
              },
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              children: [
              _buildChartCard(
                context: context,
                title: "Temperature Trend (24h)",
                subtitle: "Continuous environmental monitoring",
                icon: Icons.device_thermostat,
                color: AppColors.statusWarning,
                child: _buildTemperatureChart(),
              ),
              const SizedBox(width: 16),
              _buildChartCard(
                context: context,
                title: "Smoke Concentration",
                subtitle: "Analog particle detection (PPM)",
                icon: Icons.cloud_outlined,
                color: AppColors.primaryBlue,
                child: _buildSmokeChart(),
              ),
              const SizedBox(width: 16),
              _buildChartCard(
                context: context,
                title: "Flame / Fire Events",
                subtitle: "Digital trigger frequency per zone",
                icon: Icons.local_fire_department_outlined,
                color: AppColors.statusDanger,
                child: _buildFlameEventsChart(context),
              ),
            ],
          ),
        ),
        ),
        
        const SizedBox(height: 32),
        
        // --- SECTION 2: Hardware Health & System Performance ---
        Text(
          "Hardware & System Health",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // System Latency KPI Card
        _buildMetricCard(
          context: context,
          title: "System Latency",
          value: "1.2s",
          unit: "avg response",
          subtitle: "Time from sensor threshold to 115dB siren trigger.",
          icon: Icons.bolt,
          color: AppColors.statusWarning,
        ),
        const SizedBox(height: 16),
        
        // Power Stability Pie Chart
        _buildHardwareCard(
           context: context,
           title: "Power Stability",
           subtitle: "Mains vs Battery Backup Usage",
           icon: Icons.power,
           color: AppColors.statusSafe,
           child: SizedBox(
             height: 200,
             child: _buildPowerStabilityChart(context),
           )
        ),
        const SizedBox(height: 16),
        
        // Battery Curve Line Chart
        _buildHardwareCard(
           context: context,
           title: "Battery Discharge Curve",
           subtitle: "UPS percentage during simulated outage",
           icon: Icons.battery_charging_full,
           color: AppColors.primaryBlue,
           child: SizedBox(
             height: 220,
             child: _buildBatteryChart(),
           )
        ),
        
        const SizedBox(height: 40), // Bottom padding
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildChartCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
  
  Widget _buildHardwareCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
             children: [
               Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                     ),
                     const SizedBox(height: 2),
                     Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                     ),
                   ],
                 ),
               ),
             ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
  
    Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String unit,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: color.withOpacity(0.2),
               shape: BoxShape.circle,
             ),
             child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   title,
                   style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                     color: colorScheme.onSurface,
                   ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // --- MOCK DATA CHARTS ---

  Widget _buildTemperatureChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 6,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}h', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 10,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}°C', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 24,
        minY: 10,
        maxY: 45,
        lineBarsData: [
          LineChartBarData(
            spots: _getMockTempData(),
            isCurved: true,
            color: AppColors.statusWarning,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.statusWarning.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmokeChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}m', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 150,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                 if(value == 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 30,
        minY: 0,
        maxY: 500,
        lineBarsData: [
          LineChartBarData(
            spots: _getMockSmokeData(),
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryBlue.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlameEventsChart(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 15,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10);
                Widget text;
                switch (value.toInt()) {
                  case 0: text = const Text('Z1', style: style); break;
                  case 1: text = const Text('Z2', style: style); break;
                  case 2: text = const Text('Z3', style: style); break;
                  case 3: text = const Text('Z4', style: style); break;
                  default: text = const Text('', style: style); break;
                }
                return SideTitleWidget(meta: meta, child: text);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _getMockFlameEvents(),
      ),
    );
  }
  
  Widget _buildPowerStabilityChart(BuildContext context) {
     final colorScheme = Theme.of(context).colorScheme;
     
     return Row(
       children: [
         Expanded(
           child: PieChart(
             PieChartData(
               sectionsSpace: 2,
               centerSpaceRadius: 40,
               sections: [
                 PieChartSectionData(
                   color: AppColors.statusSafe,
                   value: 95,
                   title: '95%',
                   radius: 50,
                   titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                 ),
                 PieChartSectionData(
                   color: AppColors.statusWarning,
                   value: 5,
                   title: '5%',
                   radius: 40,
                   titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                 ),
               ],
             ),
           ),
         ),
         Column(
           mainAxisAlignment: MainAxisAlignment.center,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             _buildLegendItem("Mains Power", AppColors.statusSafe, colorScheme),
             const SizedBox(height: 8),
             _buildLegendItem("Battery Backup", AppColors.statusWarning, colorScheme),
           ],
         ),
       ],
     );
  }
  
  Widget _buildLegendItem(String title, Color color, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBatteryChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 10,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}m', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                 if(value == 0) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 60,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: _getMockBatteryData(),
            isCurved: true,
            color: AppColors.statusSafe,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.statusSafe.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }


  // --- MOCK DATA GENERATORS ---

  List<FlSpot> _getMockTempData() {
    return const [
      FlSpot(0, 22.5),
      FlSpot(4, 21.0),
      FlSpot(8, 23.5),
      FlSpot(12, 28.0),
      FlSpot(14, 32.5), // Peak afternoon
      FlSpot(16, 30.0),
      FlSpot(20, 25.5),
      FlSpot(24, 23.0),
    ];
  }

  List<FlSpot> _getMockSmokeData() {
    return const [
      FlSpot(0, 50),
      FlSpot(5, 65),
      FlSpot(10, 45),
      FlSpot(15, 120), // Minor spike
      FlSpot(20, 80),
      FlSpot(25, 290), // High warning
      FlSpot(30, 60),
    ];
  }

  List<BarChartGroupData> _getMockFlameEvents() {
    return [
      BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 2, color: AppColors.statusDanger, width: 20, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 8, color: AppColors.statusDanger, width: 20, borderRadius: BorderRadius.circular(4))]), // Triggered more here
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1, color: AppColors.statusDanger, width: 20, borderRadius: BorderRadius.circular(4))]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 0, color: AppColors.statusDanger, width: 20, borderRadius: BorderRadius.circular(4))]),
    ];
  }
  
  List<FlSpot> _getMockBatteryData() {
    return const [
      FlSpot(0, 100),
      FlSpot(10, 100), // Power lost at 10m
      FlSpot(20, 85),
      FlSpot(30, 70),
      FlSpot(40, 52),
      FlSpot(50, 35),
      FlSpot(60, 18), // 60 mins later
    ];
  }
}
