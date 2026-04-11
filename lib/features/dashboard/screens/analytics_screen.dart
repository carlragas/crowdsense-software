import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/providers/settings_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle(title: "Analytics"),
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
                child: _buildTemperatureChart(settings.temperatureThreshold),
              ),
              const SizedBox(width: 16),
              _buildChartCard(
                context: context,
                title: "Smoke Concentration",
                subtitle: "Current PPM vs threshold",
                icon: Icons.cloud_outlined,
                color: AppColors.primaryBlue,
                child: _buildSmokeGauge(context, settings.smokeThreshold),
              ),
              const SizedBox(width: 16),
              _buildChartCard(
                context: context,
                title: "Flame Sensor PPM",
                subtitle: "IR analog reading vs threshold",
                icon: Icons.local_fire_department_outlined,
                color: AppColors.statusDanger,
                child: _buildFlameGauge(context, settings.flameThreshold),
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
        
        const SizedBox(height: 16),
        
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

  Widget _buildTemperatureChart(double threshold) {
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
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: threshold,
              color: AppColors.statusDanger,
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 5),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.statusDanger,
                ),
                labelResolver: (line) => 'Limit: ${threshold.toStringAsFixed(1)}°C',
              ),
            ),
          ],
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
        maxY: threshold > 40 ? threshold + 5 : 45,
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

  // Mock current readings
  static const double _mockSmokePPM = 290.0;   // current smoke sensor reading
  static const double _mockFlamePPM = 185.0;    // current flame IR sensor reading
  static const double _gaugeMaxPPM  = 500.0;

  Widget _buildSmokeGauge(BuildContext context, double threshold) {
    return _PpmGauge(
      value: _mockSmokePPM,
      maxValue: _gaugeMaxPPM,
      threshold: threshold,
      unit: 'PPM',
      label: 'Smoke',
      baseColor: AppColors.primaryBlue,
    );
  }

  Widget _buildFlameGauge(BuildContext context, double threshold) {
    return _PpmGauge(
      value: _mockFlamePPM,
      maxValue: _gaugeMaxPPM,
      threshold: threshold,
      unit: 'PPM',
      label: 'Flame IR',
      baseColor: AppColors.statusDanger,
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


  

}

// ---------------------------------------------------------------------------
// PPM Arc Gauge Meter
// ---------------------------------------------------------------------------

class _PpmGauge extends StatelessWidget {
  final double value;
  final double maxValue;
  final double threshold;
  final String unit;
  final String label;
  final Color baseColor;

  const _PpmGauge({
    required this.value,
    required this.maxValue,
    required this.threshold,
    required this.unit,
    required this.label,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    final thresholdRatio = (threshold / maxValue).clamp(0.0, 1.0);

    Color valueColor;
    if (ratio >= thresholdRatio) {
      valueColor = AppColors.statusDanger;
    } else if (ratio >= thresholdRatio * 0.75) {
      valueColor = AppColors.statusWarning;
    } else {
      valueColor = baseColor;
    }

    final statusLabel = ratio >= thresholdRatio
        ? 'ABOVE LIMIT'
        : ratio >= thresholdRatio * 0.75
            ? 'WARNING'
            : 'NORMAL';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: CustomPaint(
            painter: _GaugePainter(
              ratio: ratio,
              maxValue: maxValue,
              thresholdRatio: thresholdRatio,
              baseColor: baseColor,
              valueColor: valueColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 28),
                  Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: valueColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: valueColor.withOpacity(0.35)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Limit: ${threshold.toStringAsFixed(0)} PPM',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.statusDanger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double ratio;
  final double maxValue;
  final double thresholdRatio;
  final Color baseColor;
  final Color valueColor;

  static const double _startDeg = 145.0;
  static const double _sweepDeg = 250.0;

  const _GaugePainter({
    required this.ratio,
    required this.maxValue,
    required this.thresholdRatio,
    required this.baseColor,
    required this.valueColor,
  });

  double _rad(double deg) => deg * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.54);
    final radius = math.min(size.width, size.height) * 0.40;
    final strokeW = radius * 0.20;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    canvas.drawArc(
      rect,
      _rad(_startDeg),
      _rad(_sweepDeg),
      false,
      Paint()
        ..color = Colors.grey.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    // Safe zone tint up to threshold
    if (thresholdRatio > 0) {
      canvas.drawArc(
        rect,
        _rad(_startDeg),
        _rad(_sweepDeg * thresholdRatio),
        false,
        Paint()
          ..color = baseColor.withOpacity(0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // Gradient value arc drawn in 60 segments
    if (ratio > 0) {
      final valueSweep = _sweepDeg * ratio;
      const segments = 60;
      final segSweep = valueSweep / segments;
      for (int i = 0; i < segments; i++) {
        final t = (i / (segments - 1)).clamp(0.0, 1.0);
        Color segColor;
        if (t < thresholdRatio * 0.70) {
          segColor = baseColor;
        } else if (t < thresholdRatio) {
          segColor = Color.lerp(
            baseColor,
            AppColors.statusWarning,
            (t - thresholdRatio * 0.70) / (thresholdRatio * 0.30),
          )!;
        } else {
          segColor = Color.lerp(
            AppColors.statusWarning,
            AppColors.statusDanger,
            ((t - thresholdRatio) / (1.0 - thresholdRatio)).clamp(0.0, 1.0),
          )!;
        }
        canvas.drawArc(
          rect,
          _rad(_startDeg + segSweep * i),
          _rad(segSweep + 0.6),
          false,
          Paint()
            ..color = segColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = i == 0 ? StrokeCap.round : StrokeCap.butt,
        );
      }
    }

    // Threshold tick
    final thAngle = _rad(_startDeg + _sweepDeg * thresholdRatio);
    canvas.drawLine(
      center + Offset((radius - strokeW * 0.6) * math.cos(thAngle), (radius - strokeW * 0.6) * math.sin(thAngle)),
      center + Offset((radius + strokeW * 0.6) * math.cos(thAngle), (radius + strokeW * 0.6) * math.sin(thAngle)),
      Paint()
        ..color = AppColors.statusDanger
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Needle glow + dot
    final needleAngle = _rad(_startDeg + _sweepDeg * ratio);
    final tipX = radius * math.cos(needleAngle);
    final tipY = radius * math.sin(needleAngle);
    final tip = center + Offset(tipX, tipY);

    canvas.drawCircle(
      tip, strokeW * 0.50,
      Paint()
        ..color = valueColor.withOpacity(0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(tip, strokeW * 0.38, Paint()..color = valueColor);
    canvas.drawCircle(tip, strokeW * 0.16, Paint()..color = Colors.white);

    // Scale ticks at 0%, 25%, 50%, 75%, 100%
    for (int i = 0; i <= 4; i++) {
      final t = i / 4.0;
      final a = _rad(_startDeg + _sweepDeg * t);
      canvas.drawLine(
        center + Offset((radius - strokeW) * math.cos(a), (radius - strokeW) * math.sin(a)),
        center + Offset((radius - strokeW * 0.45) * math.cos(a), (radius - strokeW * 0.45) * math.sin(a)),
        Paint()
          ..color = Colors.grey.withOpacity(0.45)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Min/Max Scale Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw "0"
    textPainter.text = TextSpan(
      text: '0',
      style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    final startAngle = _rad(_startDeg);
    final zeroOffset = center +
        Offset(
          (radius + strokeW * 1.5) * math.cos(startAngle) - textPainter.width / 2,
          (radius + strokeW * 1.5) * math.sin(startAngle) - textPainter.height / 2,
        );
    textPainter.paint(canvas, zeroOffset);

    // Draw maxValue
    textPainter.text = TextSpan(
      text: maxValue.toStringAsFixed(0),
      style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    final endAngle = _rad(_startDeg + _sweepDeg);
    final maxOffset = center +
        Offset(
          (radius + strokeW * 1.5) * math.cos(endAngle) - textPainter.width / 2,
          (radius + strokeW * 1.5) * math.sin(endAngle) - textPainter.height / 2,
        );
    textPainter.paint(canvas, maxOffset);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.ratio != ratio || old.thresholdRatio != thresholdRatio;
}
