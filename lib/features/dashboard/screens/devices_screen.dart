import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart'; // Added for date formatting later
import '../../../../core/theme/app_colors.dart';

class DeviceLog {
  final IconData icon;
  final String title;
  final String message;
  final DateTime dateTime;
  final Color iconColor;
  final bool isUnread;
  final String sensorType; // 'ToF', 'Flame', 'Smoke', 'Temp'
  final String priority; // 'High', 'Mid', 'Low'

  DeviceLog({
    required this.icon,
    required this.title,
    required this.message,
    required this.dateTime,
    required this.iconColor,
    required this.isUnread,
    required this.sensorType,
    required this.priority,
  });
}

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  // Filter State
  DateTime? selectedFilterDate;
  List<String> selectedSensorTypes = [];
  List<String> selectedPriorities = [];
  
  // Dummy Data (Matching the original hardcoded logs)
  late List<DeviceLog> allLogs;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    
    allLogs = [
      // TODAY
      DeviceLog(
        icon: Icons.local_fire_department,
        title: "Flame Sensor - Main Entrance",
        message: "Triggered - Possible fire detected. Evacuation protocol standing by.",
        dateTime: now.subtract(const Duration(minutes: 5)),
        iconColor: AppColors.statusDanger,
        isUnread: true,
        sensorType: 'Flame',
        priority: 'High',
      ),
      DeviceLog(
        icon: Icons.thermostat,
        title: "Temp Sensor - Server Room",
        message: "High temperature detected (38°C). Cooling system engaged automatically.",
        dateTime: now.subtract(const Duration(minutes: 20)),
        iconColor: AppColors.statusDanger,
        isUnread: true,
        sensorType: 'Temp',
        priority: 'High',
      ),
      DeviceLog(
        icon: Icons.smoking_rooms,
        title: "Smoke Sensor - Hallway A",
        message: "Smoke detected in proximity. Investigating false positive potential.",
        dateTime: now.subtract(const Duration(minutes: 45)),
        iconColor: AppColors.statusWarning,
        isUnread: false,
        sensorType: 'Smoke',
        priority: 'Mid',
      ),
      DeviceLog(
        icon: Icons.center_focus_strong,
        title: "ToF - Parking Entrance",
        message: "Device offline - Connection lost to gateway. Attempting automated reboot.",
        dateTime: now.subtract(const Duration(hours: 2, minutes: 15)),
        iconColor: AppColors.statusWarning,
        isUnread: false,
        sensorType: 'ToF',
        priority: 'Mid',
      ),
      DeviceLog(
        icon: Icons.center_focus_strong,
        title: "ToF - Main Entrance 1",
        message: "Crowd density threshold exceeded. 120 pax / min entering.",
        dateTime: now.subtract(const Duration(hours: 5)),
        iconColor: AppColors.accentBlue,
        isUnread: false,
        sensorType: 'ToF',
        priority: 'High',
      ),

      // YESTERDAY
      DeviceLog(
        icon: Icons.local_fire_department,
        title: "Flame Sensor - Kitchen",
        message: "Routine self-diagnostic completed. All systems functional.",
        dateTime: now.subtract(const Duration(days: 1, hours: 2)),
        iconColor: AppColors.statusSafe,
        isUnread: false,
        sensorType: 'Flame',
        priority: 'Low',
      ),
      DeviceLog(
        icon: Icons.center_focus_strong,
        title: "ToF - Central Stairs",
        message: "Heavy traffic detected. 45 pax / min exiting.",
        dateTime: now.subtract(const Duration(days: 1, hours: 6)),
        iconColor: AppColors.accentBlue,
        isUnread: false,
        sensorType: 'ToF',
        priority: 'Low',
      ),
      DeviceLog(
        icon: Icons.thermostat,
        title: "Temp Sensor - Room 302",
        message: "Temperature anomaly detected (32°C). HVAC adjusted.",
        dateTime: now.subtract(const Duration(days: 1, hours: 10)),
        iconColor: AppColors.statusWarning,
        isUnread: false,
        sensorType: 'Temp',
        priority: 'Mid',
      ),
      DeviceLog(
        icon: Icons.center_focus_strong,
        title: "ToF - Parking Side",
        message: "Device rebooted successfully. Connection restored.",
        dateTime: now.subtract(const Duration(days: 1, hours: 14)),
        iconColor: AppColors.statusSafe,
        isUnread: false,
        sensorType: 'ToF',
        priority: 'Low',
      ),

      // TWO DAYS AGO / LAST TUESDAY
      DeviceLog(
        icon: Icons.smoking_rooms,
        title: "Smoke Sensor - Bathroom B",
        message: "Vaping detected. Alert sent to local administration.",
        dateTime: now.subtract(const Duration(days: 2, hours: 4)),
        iconColor: AppColors.statusDanger,
        isUnread: false,
        sensorType: 'Smoke',
        priority: 'High',
      ),
      DeviceLog(
        icon: Icons.thermostat,
        title: "Temp Sensor - Main Lobby",
        message: "Routine self-diagnostic completed. All systems functional.",
        dateTime: now.subtract(const Duration(days: 2, hours: 8)),
        iconColor: AppColors.statusSafe,
        isUnread: false,
        sensorType: 'Temp',
        priority: 'Low',
      ),
      DeviceLog(
        icon: Icons.center_focus_strong,
        title: "ToF - Main Entrance 2",
        message: "Firmware update applied. System running version v3.14.",
        dateTime: now.subtract(const Duration(days: 2, hours: 18)),
        iconColor: AppColors.accentBlue,
        isUnread: false,
        sensorType: 'ToF',
        priority: 'Low',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Devices",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Online / Offline count
        Row(
          children: [
            Expanded(
              child: _GlowingStatusCard(title: "Online Devices", count: 10, color: AppColors.statusSafe),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GlowingStatusCard(title: "Offline Devices", count: 2, color: AppColors.statusDanger),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Device types horizontal list
        SizedBox(
          height: 140,
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
                _AnimatedBouncingDeviceCard(title: "Time-of-Flight\nDevices", icon: Icons.center_focus_strong, iconColor: AppColors.accentBlue, onTap: () => _showDeviceDetailsModal(context, "Time-of-Flight\nDevices")),
                _AnimatedBouncingDeviceCard(title: "Flame Sensor\nDevices", icon: Icons.local_fire_department, iconColor: AppColors.statusWarning, onTap: () => _showDeviceDetailsModal(context, "Flame Sensor\nDevices")),
                _AnimatedBouncingDeviceCard(title: "Smoke Sensor\nDevices", icon: Icons.smoking_rooms, iconColor: AppColors.textGrey, onTap: () => _showDeviceDetailsModal(context, "Smoke Sensor\nDevices")),
                _AnimatedBouncingDeviceCard(title: "Temperature\nSensor Devices", icon: Icons.thermostat, iconColor: AppColors.statusDanger, onTap: () => _showDeviceDetailsModal(context, "Temperature\nSensor Devices")),
                _AnimatedBouncingDeviceCard(title: "Power\nManagement", icon: Icons.power, iconColor: AppColors.statusSafe, onTap: () => _showDeviceDetailsModal(context, "Power\nManagement")),
                const SizedBox(width: 4), // extra trailing space
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Device Management Button
        InkWell(
          onTap: () {
            // Placeholder: Navigate to settings/maintenance
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
                  child: const Icon(Icons.settings_suggest, color: AppColors.accentBlue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Device Management",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Add, remove, or configure sensors",
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
        ),
        const SizedBox(height: 32),
        // Logs Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.list_alt, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Device Activity Logs",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            _BouncingFilterButton(onTap: _openFilterModal),
          ],
        ),
        const SizedBox(height: 12),
        
        ..._buildFilteredLogWidgets(),
      ],
    );
  }

  void _openFilterModal() {
    // Temporary variables for modal's local state before applying
    DateTime? tempDate = selectedFilterDate;
    List<String> tempSensors = List.from(selectedSensorTypes);
    List<String> tempPriorities = List.from(selectedPriorities);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.1),
                      blurRadius: Theme.of(context).brightness == Brightness.dark ? 20 : 30,
                      offset: Offset(0, Theme.of(context).brightness == Brightness.dark ? 10 : 15),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Filter Logs",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    tempDate = null;
                                    tempSensors.clear();
                                    tempPriorities.clear();
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text("Clear All", style: TextStyle(color: AppColors.statusDanger)),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, color: AppColors.textGrey),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // 1. DATE FILTER
                      Text("Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: tempDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppColors.primaryBlue,
                                    onPrimary: Colors.white,
                                    surface: AppColors.surfaceDark,
                                    onSurface: AppColors.textLight,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setModalState(() {
                              tempDate = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tempDate != null ? DateFormat('MMMM d, yyyy').format(tempDate!) : "Select Date",
                                style: TextStyle(color: tempDate != null ? AppColors.textLight : AppColors.textGrey),
                              ),
                              const Icon(Icons.calendar_today, color: AppColors.textGrey, size: 20),
                            ],
                          ),
                        ),
                      ),
                      if (tempDate != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setModalState(() => tempDate = null),
                            child: Text("Clear Date", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                          ),
                        )
                      else
                        const SizedBox(height: 24),

                      // 2. SENSOR TYPE FILTER
                      Text("Sensor Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['ToF', 'Flame', 'Smoke', 'Temp'].map((sensor) {
                          final isSelected = tempSensors.contains(sensor);
                          return FilterChip(
                            label: Text(sensor),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (selected) {
                                  tempSensors.add(sensor);
                                } else {
                                  tempSensors.remove(sensor);
                                }
                              });
                            },
                            selectedColor: AppColors.primaryBlue.withOpacity(0.3),
                            checkmarkColor: AppColors.primaryBlue,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? AppColors.primaryBlue : Colors.white24),
                            ),
                            labelStyle: TextStyle(color: isSelected ? AppColors.primaryBlue : Theme.of(context).colorScheme.onSurfaceVariant),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 3. PRIORITY FILTER
                      Text("Emergency Priority", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: ['High', 'Mid', 'Low'].map((priority) {
                          final isSelected = tempPriorities.contains(priority);
                          Color pColor;
                          if (priority == 'High') pColor = AppColors.statusDanger;
                          else if (priority == 'Mid') pColor = AppColors.statusWarning;
                          else pColor = AppColors.statusSafe;

                          return FilterChip(
                            label: Text(priority),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (selected) {
                                  tempPriorities.add(priority);
                                } else {
                                  tempPriorities.remove(priority);
                                }
                              });
                            },
                            selectedColor: pColor.withOpacity(0.2),
                            checkmarkColor: pColor,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? pColor : Colors.white24),
                            ),
                            labelStyle: TextStyle(color: isSelected ? pColor : Theme.of(context).colorScheme.onSurfaceVariant),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),
                      
                      // Apply Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedFilterDate = tempDate;
                              selectedSensorTypes = List.from(tempSensors);
                              selectedPriorities = List.from(tempPriorities);
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            "Apply Filters",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildFilteredLogWidgets() {
    // 1. Filter Logs
    List<DeviceLog> filteredLogs = allLogs.where((log) {
      bool matchesDate = true;
      if (selectedFilterDate != null) {
        matchesDate = log.dateTime.year == selectedFilterDate!.year &&
                      log.dateTime.month == selectedFilterDate!.month &&
                      log.dateTime.day == selectedFilterDate!.day;
      }
      
      bool matchesSensor = true;
      if (selectedSensorTypes.isNotEmpty) {
        matchesSensor = selectedSensorTypes.contains(log.sensorType);
      }

      bool matchesPriority = true;
      if (selectedPriorities.isNotEmpty) {
        matchesPriority = selectedPriorities.contains(log.priority);
      }

      return matchesDate && matchesSensor && matchesPriority;
    }).toList();

    if (filteredLogs.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              "No logs match the current filters.",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
            ),
          ),
        ),
      ];
    }

    // 2. Group by Date
    Map<String, List<DeviceLog>> groupedLogs = {};
    for (var log in filteredLogs) {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final logDate = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day);
      final difference = todayDate.difference(logDate).inDays;
      
      String relativeTimeStr;

      if (difference == 0) {
        relativeTimeStr = "TODAY";
      } else if (difference == 1) {
        relativeTimeStr = "YESTERDAY";
      } else if (difference < 7) {
        relativeTimeStr = "${difference}D AGO";
      } else if (difference < 30) {
        final weeks = difference ~/ 7;
        relativeTimeStr = "${weeks}W AGO";
      } else if (difference < 365) {
        final months = difference ~/ 30;
        relativeTimeStr = "${months}M AGO";
      } else {
        final years = difference ~/ 365;
        relativeTimeStr = "${years}Y AGO";
      }

      String dateKey = "${DateFormat('MMM d, yyyy').format(log.dateTime)} // $relativeTimeStr";

      if (!groupedLogs.containsKey(dateKey)) {
        groupedLogs[dateKey] = [];
      }
      groupedLogs[dateKey]!.add(log);
    }

    // 3. Build Widgets
    List<Widget> widgets = [];
    groupedLogs.forEach((dateKey, logs) {
      widgets.add(_buildDateHeader(dateKey, logs.length));
      for (var log in logs) {
        widgets.add(_buildLogItem(
          icon: log.icon,
          title: log.title,
          message: log.message,
          time: DateFormat('h:mm a').format(log.dateTime),
          iconColor: log.iconColor,
          isUnread: log.isUnread,
        ));
      }
      widgets.add(const SizedBox(height: 16));
    });

    return widgets;
  }


  Widget _buildLogItem({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required Color iconColor,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
            blurRadius: Theme.of(context).brightness == Brightness.dark ? 10 : 20,
            offset: Offset(0, Theme.of(context).brightness == Brightness.dark ? 4 : 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color indicator strip (like Valorant match history)
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: iconColor,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 16, bottom: 16, right: 16),
                  child: Row(
                    children: [
                      // Sensor Icon (replacing text initials)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time and unread dot
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.statusSafe, // Green for unread/active like match history
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.statusSafe.withOpacity(0.4),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceDetailsModal(BuildContext context, String title) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black45, // Translucent underlying barrier
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0 * animation.value, sigmaY: 8.0 * animation.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curve),
            child: FadeTransition(
              opacity: animation,
              child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.1),
                    blurRadius: Theme.of(context).brightness == Brightness.dark ? 20 : 30,
                    offset: Offset(0, Theme.of(context).brightness == Brightness.dark ? 10 : 15),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title.replaceAll('\n', ' '),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        Text("Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    Divider(height: 32, thickness: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                    if (title.toLowerCase().contains('power')) ...[
                      _buildPowerStatusRow("Main Entrance", true),
                      const SizedBox(height: 16),
                      _buildPowerStatusRow("Central Stairs", false),
                      const SizedBox(height: 16),
                      _buildPowerStatusRow("Parking Entrance", true),
                      const SizedBox(height: 16),
                      _buildPowerStatusRow("Parking Side", false),
                    ] else ...[
                      _buildDeviceStatusRow("Main Entrance", true),
                      const SizedBox(height: 16),
                      _buildDeviceStatusRow("Central Stairs", true),
                      const SizedBox(height: 16),
                      _buildDeviceStatusRow("Parking Entrance", true),
                      const SizedBox(height: 16),
                      _buildDeviceStatusRow("Parking Side", false),
                    ],

                    if (title.toLowerCase().contains('power')) ...[
                      const SizedBox(height: 48),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          Text("Battery %", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      Divider(height: 32, thickness: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                      _buildDeviceBatteryRow("Main Entrance", "87%"),
                      const SizedBox(height: 16),
                      _buildDeviceBatteryRow("Central Stairs", "20%"),
                      const SizedBox(height: 16),
                      _buildDeviceBatteryRow("Parking Entrance", "41%"),
                      const SizedBox(height: 16),
                      _buildDeviceBatteryRow("Parking Side", "N/A"),
                    ],
                    
                    const SizedBox(height: 32),
                    Center(
                      child: Text(
                        "Last sync: 2026/02/24 00:20",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceStatusRow(String location, bool isConnected) {
    final statusColor = isConnected ? AppColors.statusSafe : AppColors.statusDanger;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(location, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(
          width: 90, // Fixed width for alignment
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.25),
                  statusColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedPulsingDot(color: statusColor, size: 6.0),
                const SizedBox(width: 8),
                Text(
                  isConnected ? "ONLINE" : "OFFLINE",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: statusColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPowerStatusRow(String location, bool isMainPower) {
    final statusColor = isMainPower ? Colors.green[700]! : Colors.amber[700]!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(location, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
        SizedBox(
          width: 142, // Fixed width for alignment
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.25),
                  statusColor.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.4), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMainPower ? Icons.check_circle : Icons.warning_rounded,
                  color: statusColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  isMainPower ? "MAIN POWER" : "BACKUP POWER",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: statusColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceBatteryRow(String location, String battery) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(location, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
        Text(
          battery,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildDateHeader(String date, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            date,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingStatusCard extends StatefulWidget {
  final String title;
  final int count;
  final Color color;

  const _GlowingStatusCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  State<_GlowingStatusCard> createState() => _GlowingStatusCardState();
}

class _GlowingStatusCardState extends State<_GlowingStatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 4.0, end: 12.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Fallback underlying color
        gradient: LinearGradient(
          colors: [
            widget.color.withOpacity(0.25),
            widget.color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.8),
                      blurRadius: _glowAnimation.value,
                      spreadRadius: _glowAnimation.value / 3,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.color.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.count.toString(),
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.w900,
              fontSize: 32,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingFilterButton extends StatefulWidget {
  final VoidCallback onTap;

  const _BouncingFilterButton({required this.onTap});

  @override
  State<_BouncingFilterButton> createState() => _BouncingFilterButtonState();
}

class _BouncingFilterButtonState extends State<_BouncingFilterButton> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.90).animate(
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isPressed ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt, color: Theme.of(context).colorScheme.onSurface, size: 16),
              const SizedBox(width: 6),
              Text(
                "Filter",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBouncingDeviceCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _AnimatedBouncingDeviceCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_AnimatedBouncingDeviceCard> createState() => _AnimatedBouncingDeviceCardState();
}

class _AnimatedBouncingDeviceCardState extends State<_AnimatedBouncingDeviceCard> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
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
        child: Container(
          width: 135,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: _isPressed 
                ? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03))
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            boxShadow: [
              if (!_isPressed)
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.02),
                  blurRadius: Theme.of(context).brightness == Brightness.dark ? 10 : 15,
                  offset: Offset(0, Theme.of(context).brightness == Brightness.dark ? 4 : 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.iconColor, size: 24),
              const Spacer(),
              Text(
                widget.title.replaceAll('\n', ' '), 
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                "Tap to manage",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedPulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedPulsingDot({required this.color, this.size = 8.0});

  @override
  State<_AnimatedPulsingDot> createState() => _AnimatedPulsingDotState();
}

class _AnimatedPulsingDotState extends State<_AnimatedPulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: widget.size * 0.5, end: widget.size * 1.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.8),
                blurRadius: _glowAnimation.value,
                spreadRadius: _glowAnimation.value / 3,
              ),
            ],
          ),
        );
      },
    );
  }
}
