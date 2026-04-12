import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

class PageTitle extends StatefulWidget {
  final String title;

  const PageTitle({super.key, required this.title});

  @override
  State<PageTitle> createState() => _PageTitleState();
}

class _PageTitleState extends State<PageTitle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    // Add a slight ease-out curve for a natural stopping motion
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    
    // Start animation on load
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.title.toUpperCase(),
          style: GoogleFonts.rajdhani(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: colorScheme.onSurface,
            shadows: [
              // Soothing, soft ambient drop shadow
              Shadow(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 48,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _HeartbeatPainter(
                    color: const Color(0xFFFF3B30),
                    progress: _animation.value,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  final Color color;
  final double progress;

  _HeartbeatPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ambientGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0);

    // Delay the fade-out significantly so it doesn't fade too early
    final gradientStops = [0.0, 0.7, 1.0];
    final gradientColors = [color, color, color.withValues(alpha: 0.0)];
    final glowColors = [
      color.withValues(alpha: 0.4),
      color.withValues(alpha: 0.4),
      color.withValues(alpha: 0.0)
    ];

    paint.shader = ui.Gradient.linear(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gradientColors,
      gradientStops,
    );

    glowPaint.shader = ui.Gradient.linear(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      glowColors,
      gradientStops,
    );

    ambientGlowPaint.shader = glowPaint.shader;

    final path = Path();
    double startY = size.height / 2;
    path.moveTo(0, startY);

    // Initial flat line
    double x = size.width * 0.12;
    path.lineTo(x, startY);

    // First small dip
    x += 10;
    path.lineTo(x, startY + 8);

    // High peak
    x += 16;
    path.lineTo(x, startY - 20);

    // Deep dip
    x += 18;
    path.lineTo(x, startY + 20);

    // Rebound up
    x += 12;
    path.lineTo(x, startY - 8);

    // Small stabilization wave
    x += 8;
    path.lineTo(x, startY + 4);

    // Return to flat line
    x += 10;
    path.lineTo(x, startY);

    // Extended flat line fading out late
    path.lineTo(size.width, startY);

    // Compute metrics to only draw up to the current progress
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    
    final metric = metrics.first;
    final extractPath = metric.extractPath(0.0, metric.length * progress);

    canvas.drawPath(extractPath, ambientGlowPaint);
    canvas.drawPath(extractPath, glowPaint);
    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
