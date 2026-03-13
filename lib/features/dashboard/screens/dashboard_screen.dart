import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../widgets/people_counter_card.dart';

import '../../../../core/widgets/geometric_background.dart';
import '../../../../core/widgets/page_title.dart';
import 'analytics_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';
import '../widgets/notifications_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isBottomNavVisible = true;
  int _currentIndex = 0;
  PageController? _pageController;
  bool _showNotificationsPanel = false;

  // --- Log State ---
  late List<DeviceLog> _deviceLogs;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _deviceLogs = [
      // TODAY
      DeviceLog(
        id: 'log1',
        icon: Icons.local_fire_department,
        title: "Flame Sensor - Main Entrance",
        message: "Triggered - Possible fire detected. Evacuation protocol standing by.",
        dateTime: now.subtract(const Duration(minutes: 5)),
        iconColor: AppColors.statusDanger,
        isUnread: true,
        sensorType: 'Flame',
        priority: 'High',
        currentStatus: 'Active',
        duration: const Duration(minutes: 5),
        peakSensorReading: 'Flame Detected (Digital HIGH)',
        thresholdLimit: 'Any detection = trigger',
        isMainsPower: true,
        batteryPercentage: 82,
        relayTriggered: true,
        sirenActivated: true,
        networkActions: ['SMS alert dispatched to Security Office', 'Email notification sent to admin@crowdsense.ph'],
        specificZone: 'Block A, Floor 1, Node CS-F-001',
      ),
      DeviceLog(
        id: 'log2',
        icon: Icons.thermostat,
        title: "Temp Sensor - Server Room",
        message: "High temperature detected (42°C). Cooling system engaged automatically.",
        dateTime: now.subtract(const Duration(minutes: 20)),
        iconColor: AppColors.statusDanger,
        isUnread: true,
        sensorType: 'Temp',
        priority: 'High',
        currentStatus: 'Acknowledged',
        duration: const Duration(minutes: 20),
        peakSensorReading: '42°C',
        thresholdLimit: '38°C (critical)',
        isMainsPower: true,
        batteryPercentage: 91,
        relayTriggered: false,
        sirenActivated: false,
        networkActions: ['SMS alert dispatched to IT Department'],
        specificZone: 'Block B, Floor 2, Node CS-T-007',
      ),
      DeviceLog(
        id: 'log3',
        icon: Icons.smoking_rooms,
        title: "Smoke Sensor - Hallway A",
        message: "Smoke detected in proximity. Investigating false positive potential.",
        dateTime: now.subtract(const Duration(minutes: 45)),
        iconColor: AppColors.statusWarning,
        isUnread: false,
        sensorType: 'Smoke',
        priority: 'Mid',
        currentStatus: 'Resolved',
        duration: const Duration(minutes: 12),
        peakSensorReading: '410 ppm (analog)',
        thresholdLimit: '300 ppm threshold',
        isMainsPower: false,
        batteryPercentage: 54,
        relayTriggered: false,
        sirenActivated: false,
        networkActions: [],
        specificZone: 'Block A, Floor 3, Node CS-S-003',
      ),
      DeviceLog(
        id: 'log4',
        icon: Icons.radar,
        title: "ToF - Parking Entrance",
        message: "Device offline - Connection lost to gateway. Attempting automated reboot.",
        dateTime: now.subtract(const Duration(hours: 2, minutes: 15)),
        iconColor: AppColors.statusWarning,
        isUnread: false,
        sensorType: 'ToF',
        priority: 'Mid',
        currentStatus: 'Active',
        peakSensorReading: 'N/A (Offline)',
        thresholdLimit: 'N/A',
        isMainsPower: false,
        batteryPercentage: 18,
        networkActions: ['Automated reboot command sent'],
        specificZone: 'Parking Level 1, Node CS-P-002',
      ),
      DeviceLog(
        id: 'log5',
        icon: Icons.radar,
        title: "ToF - Main Entrance 1",
        message: "Crowd density threshold exceeded. 120 pax / min entering.",
        dateTime: now.subtract(const Duration(hours: 5)),
        iconColor: Colors.cyanAccent,
        isUnread: false,
        sensorType: 'ToF',
        priority: 'High',
        currentStatus: 'Resolved',
        duration: const Duration(minutes: 38),
        peakSensorReading: '120 pax/min',
        thresholdLimit: '80 pax/min',
        isMainsPower: true,
        batteryPercentage: 95,
        networkActions: ['SMS alert dispatched to Security Office'],
        specificZone: 'Main Gate, Floor 1, Node CS-C-001',
      ),
    ];

    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }

      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_isBottomNavVisible) setState(() => _isBottomNavVisible = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_isBottomNavVisible) setState(() => _isBottomNavVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Derived computed properties
  List<AppNotification> get _notifications {
    return _deviceLogs.where((log) => log.isUnread || log.currentStatus == 'Active' || log.currentStatus == 'Acknowledged').map((log) {
      final isUrgent = log.priority == 'High';
      return AppNotification(
        id: log.id,
        title: log.title,
        body: log.message,
        icon: log.icon,
        iconColor: log.iconColor,
        time: log.dateTime,
        isUrgent: isUrgent,
        isRead: !log.isUnread,
        isResolved: log.currentStatus == 'Resolved',
      );
    }).toList();
  }

  bool get _hasUrgentNotification =>
      _notifications.any((n) => n.isUrgent && !n.isResolved);

  bool get _hasAnyNotification =>
      _notifications.any((n) => (!n.isUrgent && !n.isRead) || (n.isUrgent && !n.isResolved));

  void _markAsRead(String id) {
    setState(() {
      final index = _deviceLogs.indexWhere((log) => log.id == id);
      if (index != -1) {
        _deviceLogs[index].isUnread = false;
      }
    });
  }

  void _resolveUrgent(String id) {
    setState(() {
      final index = _deviceLogs.indexWhere((log) => log.id == id);
      if (index != -1) {
        _deviceLogs[index].currentStatus = 'Resolved';
      }
    });
  }

  void _handleNotificationTap(String id) {
    _markAsRead(id);
    _resolveUrgent(id);
    
    setState(() {
      _currentIndex = 2; // Navigate to Devices tab
      _showNotificationsPanel = false;
      _highlightedLogId = id; // Set the highlighted log ID
    });

    // Clear highlight after a short delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          if (_highlightedLogId == id) {
            _highlightedLogId = null;
          }
        });
      }
    });
  }

  String? _highlightedLogId;

  // --- Device data ---
  final List<Map<String, dynamic>> _deviceData = [
    {"location": "Main Entrance", "count": 101, "entries": 101, "exits": 0, "isOnline": true},
    {"location": "Central Stairs", "count": 45, "entries": 0, "exits": 87, "isOnline": true},
    {"location": "Parking Entrance", "count": 15, "entries": 35, "exits": 69, "isOnline": false},
    {"location": "Parking Side", "count": 60, "entries": 64, "exits": 140, "isOnline": true},
  ];
  String _selectedLocation = "Main Entrance";

  // Computed total across all sensors
  int get _totalEntries => _deviceData.fold(0, (sum, d) => sum + (d['entries'] as int));
  int get _totalExits => _deviceData.fold(0, (sum, d) => sum + (d['exits'] as int));
  int get _totalPeopleInside => (_totalEntries - _totalExits).clamp(0, 99999);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/crowdsense_logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 12),
            const Text("CrowdSense"),
          ],
        ),
        backgroundColor: _isScrolled
            ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
            : Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: _isScrolled
            ? ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              )
            : null,
        titleTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20),
        centerTitle: false,
        actions: [
          // --- Notification Bell ---
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: _hasAnyNotification,
              smallSize: 9,
              backgroundColor: _hasUrgentNotification
                  ? AppColors.statusDanger
                  : AppColors.statusWarning,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  key: ValueKey(_hasUrgentNotification),
                  _hasUrgentNotification
                      ? Icons.notifications_active
                      : Icons.notifications_none,
                  color: _hasUrgentNotification
                      ? AppColors.statusDanger
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            onPressed: () {
              setState(() {
                _showNotificationsPanel = !_showNotificationsPanel;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Theme.of(context).colorScheme.surface,
              icon: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: Icon(Icons.person,
                    color: Theme.of(context).colorScheme.primary),
              ),
              onSelected: (value) {
                if (value == 'account') {
                  // Static for now
                } else if (value == 'settings') {
                  setState(() => _currentIndex = 3);
                } else if (value == 'logout') {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  enabled: false,
                  padding: EdgeInsets.zero,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        child: Icon(Icons.person,
                            size: 26,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome, Admin!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Divider(
                          height: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.2)),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'account',
                  height: 40,
                  child: Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 12),
                      Text('Profile Details',
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  height: 40,
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: AppColors.statusDanger),
                      SizedBox(width: 12),
                      Text('Logout',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.statusDanger,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // --- Main body ---
          GeometricBackground(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 10,
                    20,
                    100),
                child: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageTitle(title: "Dashboard"),
                      const SizedBox(height: 12),
                      _buildTotalTallyCard(),
                      const SizedBox(height: 12),
                      Builder(builder: (context) {
                        final int realIndex = _deviceData.indexWhere(
                            (data) => data['location'] == _selectedLocation);
                        _pageController ??= PageController(
                          initialPage: 1000 * _deviceData.length +
                              (realIndex != -1 ? realIndex : 0),
                        );
                        return PeopleCounterCard(
                          deviceData: _deviceData,
                          currentIndex: realIndex != -1 ? realIndex : 0,
                          pageController: _pageController!,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedLocation =
                                  _deviceData[index % _deviceData.length]['location'];
                            });
                          },
                          onPrevious: () {
                            _pageController!.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          onNext: () {
                            _pageController!.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                      _buildCrowdCountList(),
                    ],
                  ),
                  const AnalyticsScreen(),
                  DevicesScreen(logs: _deviceLogs, highlightedLogId: _highlightedLogId),
                  const SettingsScreen(),
                ][_currentIndex],
              ),
            ),
          ),

          // --- Notification Panel Overlay ---
          if (_showNotificationsPanel)
            Positioned.fill(
              top: 0,
              child: NotificationsPanel(
                notifications: _notifications,
                onClose: () => setState(() => _showNotificationsPanel = false),
                onMarkAsRead: (id) {
                  _markAsRead(id);
                  // Auto-close if no more standard notifications
                  final remaining = _notifications
                      .where((n) => !n.isUrgent && !n.isRead)
                      .length;
                  if (remaining == 0 && !_hasUrgentNotification) {
                    setState(() => _showNotificationsPanel = false);
                  }
                },
                onNotificationTap: _handleNotificationTap,
                onResolveUrgent: (id) => _resolveUrgent(id),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.5),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          currentIndex: _currentIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _showNotificationsPanel = false; // close panel on nav
            });
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
            BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined), label: "Analytics"),
            BottomNavigationBarItem(
                icon: Icon(Icons.devices_other), label: "Devices"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined), label: "Settings"),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalTallyCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = _totalPeopleInside;
    const liveColor = Color(0xFF00C853);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: icon + label
          Icon(Icons.groups_rounded, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total Inside Building',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // Center: entries
          _buildCompactStat(
            icon: Icons.login_rounded,
            value: _totalEntries,
            color: const Color(0xFF00C853),
          ),
          const SizedBox(width: 12),
          // Center: exits
          _buildCompactStat(
            icon: Icons.logout_rounded,
            value: _totalExits,
            color: const Color(0xFFFF5252),
          ),
          const SizedBox(width: 16),
          // Right: big count
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                  height: 1.0,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PulsingDot(color: liveColor),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat({required IconData icon, required int value, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTallyStatChip({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdCountList() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Crowd Count",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_outward,
                    color: colorScheme.onSurfaceVariant, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Text("Location",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant))),
              Expanded(
                  child: Text("Entry",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant))),
              Expanded(
                  child: Text("Exit",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant))),
            ],
          ),
          Divider(
              color: isDark ? Colors.white10 : Colors.black12, height: 16),
          ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _deviceData.length,
            separatorBuilder: (context, index) =>
                Divider(color: isDark ? Colors.white10 : Colors.black12, height: 16),
            itemBuilder: (context, index) {
              final data = _deviceData[index];
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(data['location'],
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: Text(data['entries'].toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface)),
                  ),
                  Expanded(
                    child: Text(data['exits'].toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_anim.value * 0.6),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
