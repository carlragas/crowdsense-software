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

  // --- Notification State ---
  late List<AppNotification> _notifications;

  @override
  void initState() {
    super.initState();

    // Define the sample notifications
    _notifications = [
      AppNotification(
        id: 'u1',
        title: 'Flame Sensor - Main Entrance',
        body: 'FIRE ALERT: Flame detected at Block A, Floor 1. Relay triggered. Evacuation protocol initiated.',
        icon: Icons.local_fire_department,
        iconColor: AppColors.statusDanger,
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        isUrgent: true,
      ),
      AppNotification(
        id: 'u2',
        title: 'Temp Sensor - Server Room',
        body: 'CRITICAL: Temperature reached 42°C (Limit: 38°C). Cooling system engaged.',
        icon: Icons.thermostat,
        iconColor: AppColors.statusDanger,
        time: DateTime.now().subtract(const Duration(minutes: 20)),
        isUrgent: true,
      ),
      AppNotification(
        id: 's1',
        title: 'Smoke Sensor - Hallway A',
        body: 'Smoke detected (410 ppm). Investigating — possible false positive.',
        icon: Icons.smoking_rooms,
        iconColor: AppColors.statusWarning,
        time: DateTime.now().subtract(const Duration(minutes: 45)),
        isUrgent: false,
      ),
      AppNotification(
        id: 's2',
        title: 'ToF - Parking Entrance',
        body: 'Device offline. Connection lost to gateway. Reboot attempt in progress.',
        icon: Icons.radar,
        iconColor: AppColors.statusWarning,
        time: DateTime.now().subtract(const Duration(hours: 2)),
        isUrgent: false,
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
  bool get _hasUrgentNotification =>
      _notifications.any((n) => n.isUrgent && !n.isResolved);

  bool get _hasAnyNotification =>
      _notifications.any((n) => (!n.isUrgent && !n.isRead) || (n.isUrgent && !n.isResolved));

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = true;
      }
    });
  }

  void _resolveUrgent(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isResolved = true;
      }
    });
  }

  // --- Device data ---
  final List<Map<String, dynamic>> _deviceData = [
    {"location": "Main Entrance", "count": 101, "entries": 101, "exits": 0, "isOnline": true},
    {"location": "Central Stairs", "count": 45, "entries": 0, "exits": 87, "isOnline": true},
    {"location": "Parking Entrance", "count": 15, "entries": 35, "exits": 69, "isOnline": false},
    {"location": "Parking Side", "count": 60, "entries": 64, "exits": 140, "isOnline": true},
  ];
  String _selectedLocation = "Main Entrance";

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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      _buildCrowdCountList(),
                      const SizedBox(height: 16),
                      _buildQuickAccessButtons(context),
                    ],
                  ),
                  const AnalyticsScreen(),
                  const DevicesScreen(),
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

  Widget _buildQuickAccessButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAccessCard(
            context,
            title: "Analytics",
            icon: Icons.analytics_outlined,
            color: AppColors.primaryBlue,
            onTap: () => setState(() => _currentIndex = 1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickAccessCard(
            context,
            title: "Devices",
            icon: Icons.devices_other,
            color: AppColors.statusWarning,
            onTap: () => setState(() => _currentIndex = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return _BouncingCard(
      title: title,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }
}

class _BouncingCard extends StatefulWidget {
  final VoidCallback onTap;
  final String title;
  final IconData icon;
  final Color color;

  const _BouncingCard({
    required this.onTap,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  State<_BouncingCard> createState() => _BouncingCardState();
}

class _BouncingCardState extends State<_BouncingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isPressed
                ? colorScheme.surface.withOpacity(0.6)
                : colorScheme.surface,
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "View details",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
