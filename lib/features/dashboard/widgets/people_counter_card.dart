import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';

class PeopleCounterCard extends StatelessWidget {
  final List<Map<String, dynamic>> deviceData;
  final int currentIndex;
  final PageController pageController;
  final Function(int) onPageChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PeopleCounterCard({
    super.key,
    required this.deviceData,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final currentData = deviceData[currentIndex];
    final bool isOnline = currentData['isOnline'] ?? true;
    Color statusColor = AppColors.statusSafe;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
              blurRadius: isDark ? 20 : 30,
              offset: Offset(0, isDark ? 10 : 15),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Live Crowd Count",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? statusColor : Colors.redAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isOnline ? statusColor : Colors.redAccent).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: isOnline ? statusColor : Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? "LIVE" : "OFFLINE",
                      style: TextStyle(
                        color: isOnline ? statusColor : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    itemBuilder: (context, index) {
                      final data = deviceData[index % deviceData.length];
                      final String pageLocation = data['location'];
                      final int pageEntries = data['entries'] ?? 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pageLocation,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (pageEntries > 0 ? AppColors.statusWarning : AppColors.statusSafe).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: (pageEntries > 0 ? AppColors.statusWarning : AppColors.statusSafe).withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(pageEntries > 0 ? Icons.error_outline : Icons.check_circle_outline, 
                                         size: 14, 
                                         color: pageEntries > 0 ? AppColors.statusWarning : AppColors.statusSafe),
                                    const SizedBox(width: 4),
                                    Text(
                                      pageEntries > 0 ? "NOT CLEAR" : "CLEAR",
                                      style: TextStyle(
                                        color: pageEntries > 0 ? AppColors.statusWarning : AppColors.statusSafe,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 42),
                            child: SizedBox(
                              height: 160,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildMetricCard("Entries", pageEntries, const [Color(0xFF8BA6FF), Color(0xFF5D7AFF)]),
                                  const SizedBox(width: 16),
                                  _buildMetricCard("Exits", data['exits'] ?? 0, const [Color(0xFFFF9A8B), Color(0xFFFF6A88)]),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          Center(
                            child: Text(
                              "Updated just now",
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: -16,
                  top: 52,
                  height: 160,
                  child: IconButton(
                    onPressed: onPrevious,
                    icon: Icon(Icons.chevron_left, color: colorScheme.onSurface, size: 36),
                  ),
                ),
                Positioned(
                  right: -16,
                  top: 52,
                  height: 160,
                  child: IconButton(
                    onPressed: onNext,
                    icon: Icon(Icons.chevron_right, color: colorScheme.onSurface, size: 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, int value, List<Color> gradientColors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value == 0 ? '0' : value.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
