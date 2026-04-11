import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/people_counter_card.dart';
import 'users_management_screen.dart';

import '../../../../core/widgets/custom_notification_modal.dart';
import '../../../../core/widgets/geometric_background.dart';
import '../../../../core/widgets/page_title.dart';
import 'analytics_screen.dart';
import 'devices_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
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
  int _currentIndex = 2;
  PageController? _pageController;
  bool _showNotificationsPanel = false;

  // --- Log State ---
  late List<DeviceLog> _deviceLogs;
  int _hazardLevel = 0; // 0 = Nominal, 1 = Caution, 2 = Critical (Mock ESP32 data)
  Timer? _heartbeatTimer;

  int get _onlineCount => _deviceData.where((d) => d['isOnline'] == true).length;
  int get _offlineCount => _deviceData.where((d) => d['isOnline'] == false).length;

  @override
  void initState() {
    super.initState();
    _listenToDeviceStreams();

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

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {
          _syncDeviceDataList();
        });
      }
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _prototypeUnitsSubscription?.cancel();
    _sensorDataSubscription?.cancel();
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
      _currentIndex = 3; // Navigate to Devices tab
      _showNotificationsPanel = false;
      _highlightedLogId = id;
      _highlightedItemKey = GlobalKey(); // Fresh key each tap
    });

    // Give the UI a brief moment to render the newly selected tab
    // and measure the layouts before attempting to scroll.
    Future.delayed(const Duration(milliseconds: 150), () {
      final keyContext = _highlightedItemKey?.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.5, // 0.5 = dead center
        );
      }
    });

    // Clear highlight after 3 seconds
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
  GlobalKey? _highlightedItemKey;

  // --- Device data ---
  final Map<String, Map<String, dynamic>> _deviceDataMap = {};
  List<Map<String, dynamic>> _deviceData = [];
  String _selectedLocation = "";
  StreamSubscription? _prototypeUnitsSubscription;
  StreamSubscription? _sensorDataSubscription;

  void _listenToDeviceStreams() {
    final dbRef = FirebaseDatabase.instance.ref();
    
    _prototypeUnitsSubscription = dbRef.child('prototype_units').onValue.listen((event) {
      if (event.snapshot.value is Map) {
         final map = event.snapshot.value as Map;
         setState(() {
            map.forEach((key, val) {
               final mac = key.toString();
               final data = val as Map;
               _deviceDataMap.putIfAbsent(mac, () => {});
               _deviceDataMap[mac]!['location'] = data['name']?.toString() ?? 'Unknown';
               
               if (data.containsKey('heartbeat') && data['heartbeat'] is Map) {
                   final hbMap = data['heartbeat'] as Map;
                   _deviceDataMap[mac]!['last_seen'] = hbMap['last_seen'];
               } else {
                   _deviceDataMap[mac]!['last_seen'] = null;
               }
            });
            _syncDeviceDataList();
         });
      } else {
        setState(() {
          _deviceDataMap.clear();
          _syncDeviceDataList();
        });
      }
    });

    _sensorDataSubscription = dbRef.child('sensor_data').onValue.listen((event) {
      if (event.snapshot.value is Map) {
         final map = event.snapshot.value as Map;
         setState(() {
            map.forEach((key, val) {
               final mac = key.toString();
               final data = val as Map;
               _deviceDataMap.putIfAbsent(mac, () => {});
               _deviceDataMap[mac]!['count'] = data['people_inside'] ?? 0;
               _deviceDataMap[mac]!['entries'] = data['total_entries'] ?? 0;
               _deviceDataMap[mac]!['exits'] = data['total_exits'] ?? 0;
            });
            _syncDeviceDataList();
         });
      }
    });
  }

  void _syncDeviceDataList() {
    _deviceData = _deviceDataMap.values.map((v) {
        String connState = v['connection_state']?.toString() ?? "NEVER SEEN";
        bool isLive = false;

        if (connState == "CONNECTED") {
            isLive = true;
        } else if (connState == "DISCONNECTED") {
            isLive = false;
        } else {
            // Fallback for older firmware without explicit connection_state
            final lastSeen = v['last_seen'];
            if (lastSeen != null) {
                final ts = DateTime.fromMillisecondsSinceEpoch((lastSeen is int) ? lastSeen : (lastSeen as num).toInt());
                isLive = DateTime.now().difference(ts).inSeconds < 60;
                connState = isLive ? "CONNECTED" : "DISCONNECTED";
            }
        }

        return {
           'location': v['location'] ?? 'Unknown Node',
           'count': v['count'] ?? 0,
           'entries': v['entries'] ?? 0,
           'exits': v['exits'] ?? 0,
           'isOnline': isLive,
           'connectionState': connState,
        };
    }).toList();
    if (_deviceData.isNotEmpty && _selectedLocation.isEmpty) {
       _selectedLocation = _deviceData.first['location'];
    }
  }

  // Computed total across all sensors
  int get _totalEntries => _deviceData.fold(0, (sum, d) => sum + ((d['entries'] as num?)?.toInt() ?? 0));
  int get _totalExits => _deviceData.fold(0, (sum, d) => sum + ((d['exits'] as num?)?.toInt() ?? 0));
  int get _totalPeopleInside => (_totalEntries - _totalExits).clamp(0, 99999);

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/crowdsense_logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                "CrowdSense",
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
          const SizedBox(width: 2),
          PopupMenuButton<String>(
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
              onSelected: (value) async {
                if (value == 'account') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                } else if (value == 'settings') {
                  setState(() => _currentIndex = 4);
                } else if (value == 'logout') {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text("Log Out"),
                        content: const Text("Log out of your account?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(dialogContext).pop();
                              await AuthService().logout();
                              if (context.mounted) {
                                context.read<UserProvider>().clearUser();
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            child: const Text(
                              "Log Out",
                              style: TextStyle(color: AppColors.statusDanger),
                            ),
                          ),
                        ],
                      );
                    },
                  );
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
                        'Welcome, ${userProv.firstName}!',
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
                ],
              ),
            ),
          ),
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
                  // Index 0: Dashboard Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageTitle(title: "Dashboard"),
                      const SizedBox(height: 12),
                      _buildStatsRow(),
                      const SizedBox(height: 12),
                      _deviceData.isEmpty 
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white.withOpacity(0.05) 
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(Icons.sensors_off_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text("No Devices Connected", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                                  const SizedBox(height: 8),
                                  Text("Add your ESP32 prototype units\nin the Device Management tab to see live data.", textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              ]
                            ),
                          )
                        : Builder(builder: (context) {
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildRoleCard(context, "Admins Online", 1, Icons.admin_panel_settings, AppColors.statusDanger)), // Red
                          const SizedBox(width: 12),
                          Expanded(child: _buildRoleCard(context, "Facilitators Online", 0, Icons.support_agent, AppColors.statusWarning)), // Orange
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildShowUsersButton(context),
                    ],
                  ),
                  // Index 1: Analytics
                  const AnalyticsScreen(),
                  // Index 2 (Center): Alerts & Manual Siren Control
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PageTitle(title: "Override Siren"),
                      const SizedBox(height: 12),
                      // Compact occupancy banner
                      _buildOccupancyBanner(),
                      const SizedBox(height: 20),
                      Text(
                        "Emergency Overrides",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tap an action to trigger a building-wide alert.",
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 20),
                      _buildAlarmControlCard(
                        title: "Fire / Evacuation Siren",
                        subtitle: "Trigger all building sirens immediately",
                        icon: Icons.campaign_rounded,
                        color: AppColors.statusDanger,
                      ),
                      const SizedBox(height: 14),
                      _buildAlarmControlCard(
                        title: "Warning Chime",
                        subtitle: "Broadcast a pre-warning alert across all zones",
                        icon: Icons.notifications_active_rounded,
                        color: AppColors.statusWarning,
                      ),
                      const SizedBox(height: 14),
                      _buildAlarmControlCard(
                        title: "Reset All Alarms",
                        subtitle: "Cancel all active sirens and visual alerts",
                        icon: Icons.refresh_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                  // Index 3: Devices
                  DevicesScreen(
                    logs: _deviceLogs,
                    highlightedLogId: _highlightedLogId,
                    highlightedItemKey: _highlightedItemKey,
                    parentScrollController: _scrollController,
                    onlineCount: _onlineCount,
                    offlineCount: _offlineCount,
                  ),
                  // Index 4: Settings
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
        child: Container(
          height: 90,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width - 32, 90),
                painter: _NavBarPainter(context, _currentIndex),
              ),
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(icon: Icons.dashboard_outlined, label: "Dashboard", index: 0),
                    _buildNavItem(icon: Icons.analytics_outlined, label: "Analytics", index: 1),
                    SizedBox(
                      width: 80, 
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 50),
                          Text(
                            "Alerts", 
                            style: TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.w800, 
                              color: _currentIndex == 2 ? AppColors.primaryBlue : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    _buildNavItem(icon: Icons.devices_other, label: "Devices", index: 3),
                    _buildNavItem(icon: Icons.settings_outlined, label: "Settings", index: 4),
                  ],
                ),
              ),
              Positioned(
                top: -10,
                left: MediaQuery.of(context).size.width / 2 - 16 - 32, // Parent is margin 16 left -> Center visually
                child: GestureDetector(
                  onTap: () {
                    setState(() { _currentIndex = 2; _showNotificationsPanel = false; });
                  },
                    child: AnimatedScale(
                      scale: _currentIndex == 2 ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [AppColors.accentBlue, AppColors.primaryBlue],
                            center: Alignment(0, -0.3),
                            radius: 1.0,
                          ),
                          boxShadow: [
                            // Main shadow
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                            // Optional glow when selected
                            if (_currentIndex == 2)
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.6),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primaryBlue : Colors.grey.withOpacity(0.9);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          _showNotificationsPanel = false;
        });
      },
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color hazardColor;
    IconData hazardIcon;
    String hazardLabel;
    bool isPulsing = false;

    // Simulated dynamic hazard logic dependent on ESP32 Firebase inputs
    switch (_hazardLevel) {
      case 2:
        hazardColor = const Color(0xFFFF5252);
        hazardIcon = Icons.error_outline;
        hazardLabel = "CRITICAL ALERT";
        isPulsing = true;
        break;
      case 1:
        hazardColor = Colors.amber;
        hazardIcon = Icons.warning_amber;
        hazardLabel = "CAUTION";
        break;
      case 0:
      default:
        hazardColor = const Color(0xFF00B0FF);
        hazardIcon = Icons.health_and_safety;
        hazardLabel = "SYSTEM NORMAL";
        break;
    }

    // Styled system-notification badge for the Hazard card
    final hazardBadge = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: BoxDecoration(
            color: hazardColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hazardColor.withOpacity(0.45),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              _PulsingDot(color: hazardColor),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  hazardLabel,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: hazardColor,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "SYS ALERT",
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: hazardColor.withOpacity(0.55),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );

    // ── Card 1: Headcount value widget ──────────────────────────────────────
    const headcountColor = Color(0xFF00C853);
    final headcountBadge = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _totalPeopleInside.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'REAL-TIME SYNC',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: headcountColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );

    // ── Card 2: Exits value widget ────────────────────────────────────────
    const exitsColor = Color(0xFFFF5252);
    final exitsBadge = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _totalExits.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'RESETS HOURLY',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: exitsColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildGlassStatCard(
              title: "Live Total\nHeadcount",
              value: '',
              icon: Icons.groups,
              color: headcountColor,
              isDark: isDark,
              valueWidget: headcountBadge,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGlassStatCard(
              title: "Current Hour\nExits",
              value: '',
              icon: Icons.directions_run,
              color: exitsColor,
              isDark: isDark,
              valueWidget: exitsBadge,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGlassStatCard(
              title: "Hazard Status",
              value: '',
              icon: hazardIcon,
              color: hazardColor,
              isDark: isDark,
              isPulsing: isPulsing,
              valueWidget: hazardBadge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isPulsing = false,
    bool isTextSmall = false,
    Widget? valueWidget,
  }) {
    Widget cardChild = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const Spacer(),
          // Use the custom valueWidget (e.g. badge) if provided, else plain text
          valueWidget ?? Text(
            value,
            style: TextStyle(
              fontSize: isTextSmall ? 13 : 24,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    final glassWrapper = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: cardChild,
      ),
    );

    if (isPulsing) {
      return _PulsingWrapper(color: color, child: glassWrapper);
    }
    return glassWrapper;
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

  Widget _buildOccupancyBanner() {
    final int inside = _totalPeopleInside;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_rounded, color: AppColors.primaryBlue, size: 18),
          const SizedBox(width: 8),
          Text(
            '$inside',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryBlue,
            ),
          ),
          Text(
            ' people inside',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant.withOpacity(0.65),
            ),
          ),
          const Spacer(),
          // Entries
          Icon(Icons.login_rounded, size: 13, color: AppColors.statusSafe),
          const SizedBox(width: 3),
          Text(
            '$_totalEntries',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.statusSafe,
            ),
          ),
          const SizedBox(width: 12),
          // Exits
          Icon(Icons.logout_rounded, size: 13, color: AppColors.statusDanger),
          const SizedBox(width: 3),
          Text(
            '$_totalExits',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.statusDanger,
            ),
          ),
          const SizedBox(width: 8),
          _PulsingDot(color: AppColors.statusSafe),
        ],
      ),
    );
  }


  Widget _buildAlarmControlCard({required String title, required String subtitle, required IconData icon, required Color color}) {
    final bool isReset = title.contains("Reset");
    final String actionText = isReset ? "RESET" : "ACTIVATE";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: color, size: 28),
                        const SizedBox(width: 12),
                        const Text("Confirm Action", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    content: Text(
                      "Are you sure you want to $actionText the '$title'?\n\nThis will execute the command immediately across the active zones.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the confirmation dialog
                          
                          if (!isReset) {
                            showDialog(
                              context: context,
                              barrierDismissible: false, // Prevent dismissing by tapping outside
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: color.withOpacity(0.5), width: 2),
                                  ),
                                  title: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(icon, color: color, size: 64),
                                      const SizedBox(height: 16),
                                      Text(
                                        "$title\nis Active & Ringing!",
                                        style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 22, height: 1.2),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "General alarms are currently sounding across the facility. Ensure proper emergency protocols are being followed.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                                  actionsAlignment: MainAxisAlignment.center,
                                  actionsPadding: const EdgeInsets.only(bottom: 24),
                                  actions: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          CustomNotificationModal.show(
                                            context: context,
                                            title: "Alarm Deactivated",
                                            message: "$title DEACTIVATED successfully.",
                                            isSuccess: true,
                                            customColor: AppColors.primaryBlue,
                                            customIcon: Icons.volume_off_rounded,
                                          );
                                        },
                                        icon: const Icon(Icons.stop_circle_rounded, size: 28),
                                        label: const Text("DEACTIVATE ALARM", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.0)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: color.withOpacity(0.1),
                                          foregroundColor: color,
                                          padding: const EdgeInsets.symmetric(vertical: 18),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(color: color.withOpacity(0.5), width: 2),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            CustomNotificationModal.show(
                              context: context,
                              title: "System Update",
                              message: "$title has been ${isReset ? 'RESET' : 'ACTIVATED'}.",
                              isSuccess: true,
                              customColor: color,
                              customIcon: icon,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text("CONFIRM $actionText", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: Text(actionText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  Widget _buildCrowdCountList() {
    if (_deviceData.isEmpty) return const SizedBox.shrink();

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
              Expanded(
                  child: Text("Inside",
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
              final int currentInside = ((data['entries'] ?? 0) as num).toInt() - ((data['exits'] ?? 0) as num).toInt();
              final displayInside = currentInside; // clamped below if desired, but clamping inside calculation is identical
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
                    child: Text(currentInside.clamp(0, 99999).toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface)),
                  ),
                  Expanded(
                    child: Text(data['exits'].toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurface)),
                  ),
                  Expanded(
                    child: Text(displayInside.clamp(0, 99999).toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
            blurRadius: Theme.of(context).brightness == Brightness.dark ? 10 : 20,
            offset: Offset(0, Theme.of(context).brightness == Brightness.dark ? 4 : 8),
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
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "$count",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowUsersButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UsersManagementScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
              blurRadius: Theme.of(context).brightness == Brightness.dark ? 10 : 20,
              offset: Offset(0, Theme.of(context).brightness == Brightness.dark ? 4 : 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.manage_accounts, color: AppColors.accentBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Show Users",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage administrators and facilitators",
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
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

class _NavBarPainter extends CustomPainter {
  final BuildContext context;
  final int currentIndex;
  _NavBarPainter(this.context, this.currentIndex);

  @override
  void paint(Canvas canvas, Size size) {
    // Safely get properties to avoid Null type errors during hot reload transitions
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Safety check: sometimes hot reload can leave fields uninitialized
    // although they are non-nullable in code. We use a fallback to prevent crashes.
    final int safeIndex = currentIndex;
    
    final paint = Paint()
      ..color = isDark ? AppColors.surfaceDark : Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.3 : 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = Path();
    final double w = size.width;
    final double h = size.height;
    
    final double center = w / 2;
    
    // Notch dimensions - expands when Alerts (index 2) is active
    final bool isAlerts = safeIndex == 2;
    final double notchRadius = isAlerts ? 44.0 : 38.0;
    final double notchDepth = isAlerts ? 36.0 : 30.0;

    path.moveTo(0, 24); // Top left radius
    path.quadraticBezierTo(0, 0, 24, 0);

    // Left line to notch
    path.lineTo(center - notchRadius - 15, 0);
    
    // Notch curve (Bezier that mimics a concave well)
    path.cubicTo(
      center - notchRadius + 5, 0, 
      center - notchRadius + 8, notchDepth, 
      center, notchDepth,
    );
    path.cubicTo(
      center + notchRadius - 8, notchDepth, 
      center + notchRadius - 5, 0, 
      center + notchRadius + 15, 0,
    );

    // Right line & top right radius
    path.lineTo(w - 24, 0);
    path.quadraticBezierTo(w, 0, w, 24);

    // Bottom right radius
    path.lineTo(w, h - 24);
    path.quadraticBezierTo(w, h, w - 24, h);

    // Bottom left radius
    path.lineTo(24, h);
    path.quadraticBezierTo(0, h, 0, h - 24);
    path.close();

    // Draw shadow then shape
    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);

    // Subtle inner border for dark themes
    if (isDark) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! _NavBarPainter) return true;
    // Standard safety check for hot reload transitions
    try {
      return oldDelegate.currentIndex != currentIndex;
    } catch (_) {
      return true;
    }
  }
}

class _PulsingWrapper extends StatefulWidget {
  final Widget child;
  final Color color;
  const _PulsingWrapper({required this.child, required this.color});

  @override
  State<_PulsingWrapper> createState() => _PulsingWrapperState();
}

class _PulsingWrapperState extends State<_PulsingWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0)
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
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_anim.value * 0.4),
                blurRadius: 16 * _anim.value,
                spreadRadius: 2 * _anim.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
