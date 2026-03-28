import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SecondaryGeometricBackground extends StatelessWidget {
  final Widget child;

  const SecondaryGeometricBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Gradient
        Container(
          decoration: BoxDecoration(
            gradient: isDark 
                ? const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E1E2C)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : const LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        
        // Geometric Shapes
        CustomPaint(
          painter: _SecondaryGeometricPainter(isDark: isDark),
          size: Size.infinite,
        ),
        
        // Content
        child,
      ],
    );
  }
}

class _SecondaryGeometricPainter extends CustomPainter {
  final bool isDark;

  _SecondaryGeometricPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Large Polygon (Bottom Right focused)
    // Red/Orange geometric slice
    final path1 = Path();
    path1.moveTo(0, size.height); // Bottom left
    path1.lineTo(size.width, size.height * 0.4); // Angle up towards right
    path1.lineTo(size.width, size.height); // Bottom right corner
    path1.close();

    paint.shader = LinearGradient(
      colors: [
        AppColors.statusDanger.withOpacity(isDark ? 0.15 : 0.08),
        AppColors.statusWarning.withOpacity(isDark ? 0.05 : 0.05),
      ],
      begin: Alignment.bottomRight,
      end: Alignment.topLeft,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path1, paint);

    // 2. Secondary Polygon (Top Left)
    // Deep purple / blue angular slice
    final path2 = Path();
    path2.moveTo(0, 0); // Top left
    path2.lineTo(size.width * 0.6, 0); // Angle across top
    path2.lineTo(0, size.height * 0.5); // Angle down left
    path2.close();

    paint.shader = LinearGradient(
      colors: [
        Colors.deepPurpleAccent.withOpacity(isDark ? 0.12 : 0.1),
        AppColors.primaryBlue.withOpacity(isDark ? 0.05 : 0.05),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path2, paint);

    // We removed the glowing circles and rely purely on geometric angular layers.
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _SecondaryGeometricPainter) {
      return oldDelegate.isDark != isDark;
    }
    return true;
  }
}
