import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/widgets/custom_notification_modal.dart';

class DeviceManagementModal extends StatefulWidget {
  const DeviceManagementModal({super.key});

  @override
  State<DeviceManagementModal> createState() => _DeviceManagementModalState();
}

class _DeviceManagementModalState extends State<DeviceManagementModal> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  StreamSubscription? _devicesSubscription;
  List<Map<String, dynamic>> _devices = [];

  final TextEditingController _macController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _listenToDevices();
  }

  void _listenToDevices() {
    _devicesSubscription = _dbRef.child('prototype_units').onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final Map<dynamic, dynamic> devicesMap = event.snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> loadedDevices = [];
        
        devicesMap.forEach((key, value) {
          if (value is Map) {
            final device = <String, dynamic>{};
            value.forEach((k, v) => device[k.toString()] = v);
            device['macAddress'] = key.toString();
            
            if (!device.containsKey('sensors') && device.containsKey('config') && device['config'] is Map) {
               final configMap = device['config'] as Map;
               final sensorsStrMap = <String, dynamic>{};
               configMap.forEach((k, v) => sensorsStrMap[k.toString()] = v);
               device['sensors'] = sensorsStrMap;
            } else if (!device.containsKey('sensors')) {
               device['sensors'] = <String, dynamic>{
                  "temp_threshold": 35.0,
                  "smoke_threshold": 300.0,
                  "flame_threshold": 200.0
               };
            }

            // Ensure status has a string representation
            if (!device.containsKey('status') || device['status'] == null) {
              device['status'] = 'offline';
            } else {
              device['status'] = device['status'].toString();
            }

            // Extract heartbeat data
            if (device.containsKey('heartbeat') && device['heartbeat'] is Map) {
              final hbMap = device['heartbeat'] as Map;
              device['heartbeat_status'] = hbMap['connection_state']?.toString() ?? 'NEVER SEEN';
              device['heartbeat_last_seen'] = hbMap['last_seen'];
              device['heartbeat_ip'] = hbMap['ip_address']?.toString();
              device['heartbeat_firmware'] = hbMap['firmware_version']?.toString();
            } else {
              device['heartbeat_status'] = 'NEVER SEEN';
              device['heartbeat_last_seen'] = null;
            }

            loadedDevices.add(device);
          }
        });

        // Sort by priority if available
        loadedDevices.sort((a, b) {
          final pA = a['priority'] ?? 999;
          final pB = b['priority'] ?? 999;
          return pA.compareTo(pB);
        });

        if (mounted) {
          setState(() {
            _devices = loadedDevices;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _devices = [];
          });
        }
      }
    }, onError: (error) {
      debugPrint("Error listening to devices stream: $error");
    });
  }

  void _addDeviceToFirebase(String mac, String name) async {
    try {
      await _dbRef.child('prototype_units').child(mac).set({
        "name": name,
        "status": "online",
        "config": {
          "temp_threshold": 35.0,
          "smoke_threshold": 300.0,
          "flame_threshold": 200.0,
          "priority": _devices.length,
        }
      });
      // Pre-initialize sensor data logic
      await _dbRef.child('sensor_data').child(mac).set({
        "people_inside": 0,
        "total_entries": 0,
        "total_exits": 0,
        "temperature": 0.0,
        "gas": 0,
        "flame": 0,
        "last_updated": DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint("Error adding device: $e");
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    
    setState(() {
      final device = _devices.removeAt(oldIndex);
      _devices.insert(newIndex, device);
    });

    // Batch update priorities in Firebase
    for (int i = 0; i < _devices.length; i++) {
        _dbRef.child('prototype_units').child(_devices[i]['macAddress']).update({
            'priority': i,
        });
    }
  }

  void _updateDeviceConfig(String mac, Map<String, dynamic> newSensors) async {
    try {
      await _dbRef.child('prototype_units').child(mac).child('config').set(newSensors);
    } catch (e) {
      debugPrint("Error updating config: $e");
    }
  }

  void _updateDeviceStatus(String mac, String newStatus) async {
    try {
      await _dbRef.child('prototype_units').child(mac).update({"status": newStatus});
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
  }

  void _removeDeviceFromFirebase(String mac) async {
    try {
      await _dbRef.child('prototype_units').child(mac).remove();
      await _dbRef.child('sensor_data').child(mac).remove();
    } catch (e) {
      debugPrint("Error removing device: $e");
    }
  }

  void _handleAddDevice() {
    if (_macController.text.trim().isEmpty || _nameController.text.trim().isEmpty) {
      CustomNotificationModal.show(
        context: context,
        title: "Missing Fields",
        message: "Please fill in both MAC Address and Node Name.",
        isSuccess: false,
      );
      return;
    }

    final String mac = _macController.text.trim();
    final String name = _nameController.text.trim();

    _addDeviceToFirebase(mac, name);

    _macController.clear();
    _nameController.clear();

    FocusScope.of(context).unfocus();
    
    CustomNotificationModal.show(
      context: context,
      title: "Device Added",
      message: "Device '$name' has been added successfully.",
      isSuccess: true,
    );
  }

  void _promptRemoveDevice(String mac, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.statusDanger, size: 28),
              const SizedBox(width: 12),
              const Text("Remove Device", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text("Are you sure you want to permanently remove '$name'?\n\nThis will disconnect the hardware node and stop incoming sensor data."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _executeRemoveDevice(mac, name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusDanger,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _executeRemoveDevice(String mac, String name) {
    _removeDeviceFromFirebase(mac);
    
    CustomNotificationModal.show(
      context: context,
      title: "Device Removed",
      message: "Device '$name' has been permanently removed.",
      isSuccess: true,
      isDestructive: true,
    );
  }

  void _executeEditDevice(String oldMac, String newMac, String newName, Map<String, dynamic> newSensors) async {
    try {
      if (oldMac == newMac) {
        await _dbRef.child('prototype_units').child(oldMac).update({
          "name": newName,
          "config": newSensors,
        });
      } else {
        final protoSnapshot = await _dbRef.child('prototype_units').child(oldMac).get();
        final sensorSnapshot = await _dbRef.child('sensor_data').child(oldMac).get();

        if (protoSnapshot.exists) {
           final baseData = Map<String, dynamic>.from(protoSnapshot.value as Map);
           baseData["name"] = newName;
           baseData["config"] = newSensors;
           await _dbRef.child('prototype_units').child(newMac).set(baseData);
        }

        if (sensorSnapshot.exists) {
           await _dbRef.child('sensor_data').child(newMac).set(sensorSnapshot.value);
        }

        await _dbRef.child('prototype_units').child(oldMac).remove();
        await _dbRef.child('sensor_data').child(oldMac).remove();
      }

      if (mounted) {
        CustomNotificationModal.show(
          context: context,
          title: "Device Updated",
          message: "Device settings have been successfully saved.",
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint("Error editing device: $e");
    }
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _macController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
              blurRadius: isDark ? 20 : 30,
              offset: Offset(0, isDark ? -10 : -15),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Add New Device"),
                    const SizedBox(height: 16),
                    _buildAddDeviceForm(isDark),
                    
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("Configured Devices"),
                        if (_devices.length > 1)
                          IconButton(
                            icon: Icon(
                              _isReordering ? Icons.check_circle : Icons.reorder_rounded,
                              color: _isReordering ? AppColors.statusSafe : AppColors.primaryBlue,
                            ),
                            tooltip: _isReordering ? "Save Order" : "Reorder Devices",
                            onPressed: () => setState(() => _isReordering = !_isReordering),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDeviceList(isDark),
                    
                    const SizedBox(height: 48), // Padding at bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Device Management",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAddDeviceForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _macController,
            decoration: InputDecoration(
              labelText: "MAC Address",
              hintText: "e.g. 00:1B:44:11:3A:B7",
              prefixIcon: const Icon(Icons.memory),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Location/Node Name",
              hintText: "e.g. CEA 3rd Floor",
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleAddDevice,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add Device", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(bool isDark) {
    if (_devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.devices_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                "No devices configured yet.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    if (_isReordering) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return Padding(
            key: ValueKey(device["macAddress"]),
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _EditableDeviceTile(
              key: ValueKey(device["macAddress"]),
              device: device,
              isDark: isDark,
              isReordering: _isReordering,
              index: index,
              onSave: _executeEditDevice,
              onRemove: _promptRemoveDevice,
              onStatusToggle: _updateDeviceStatus,
            ),
          );
        },
        onReorder: _handleReorder,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _buildDeviceTile(device, isDark, index: index);
      },
    );
  }

  Widget _buildDeviceTile(Map<String, dynamic> device, bool isDark, {int index = 0}) {
    return _EditableDeviceTile(
      key: ValueKey(device["macAddress"]),
      device: device,
      isDark: isDark,
      isReordering: _isReordering,
      index: index,
      onSave: _executeEditDevice,
      onRemove: _promptRemoveDevice,
      onStatusToggle: _updateDeviceStatus,
    );
  }
}

class _EditableDeviceTile extends StatefulWidget {
  final Map<String, dynamic> device;
  final bool isDark;
  final bool isReordering;
  final int index;
  final Function(String, String, String, Map<String, dynamic>) onSave;
  final Function(String, String) onRemove;
  final Function(String, String) onStatusToggle;

  const _EditableDeviceTile({
    super.key,
    required this.device,
    required this.isDark,
    this.isReordering = false,
    this.index = 0,
    required this.onSave,
    required this.onRemove,
    required this.onStatusToggle,
  });

  @override
  State<_EditableDeviceTile> createState() => _EditableDeviceTileState();
}

class _EditableDeviceTileState extends State<_EditableDeviceTile> {
  late TextEditingController _macCtrl;
  late TextEditingController _nameCtrl;
  late double _tempThresh;
  Timer? _heartbeatTimer;
  late double _smokeThresh;
  late double _flameThresh;

  @override
  void initState() {
    super.initState();
    _macCtrl = TextEditingController(text: widget.device["macAddress"]);
    _nameCtrl = TextEditingController(text: widget.device["name"]);
    final sensors = widget.device["sensors"] as Map<String, dynamic>;
    _tempThresh = (sensors["temp_threshold"] ?? 35.0).toDouble();
    _smokeThresh = (sensors["smoke_threshold"] ?? 300.0).toDouble();
    _flameThresh = (sensors["flame_threshold"] ?? 200.0).toDouble();

    // Refresh the "ago" text every 10 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _macCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // --- Heartbeat helpers ---
  String get _hardwareState {
    final hwStatus = widget.device['heartbeat_status']?.toString() ?? 'NEVER SEEN';
    if (hwStatus == 'CONNECTED' || hwStatus == 'DISCONNECTED') {
        return hwStatus;
    }
    
    final lastSeen = widget.device['heartbeat_last_seen'];
    if (lastSeen != null) {
        final ts = DateTime.fromMillisecondsSinceEpoch((lastSeen is int) ? lastSeen : (lastSeen as num).toInt());
        return DateTime.now().difference(ts).inSeconds < 60 ? 'CONNECTED' : 'DISCONNECTED';
    }
    return 'NEVER SEEN';
  }

  bool get _isHardwareLive {
    return _hardwareState == 'CONNECTED';
  }

  String get _lastSeenText {
    final lastSeen = widget.device['heartbeat_last_seen'];
    if (lastSeen == null) return 'Never connected';
    final ts = DateTime.fromMillisecondsSinceEpoch((lastSeen is int) ? lastSeen : (lastSeen as num).toInt());
    final diff = DateTime.now().difference(ts);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.device["status"] == "online";
    final isDark = widget.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
            ),
            child: Stack(
              children: [
                Icon(Icons.router, color: isOnline ? AppColors.primaryBlue : AppColors.textGrey, size: 24),
                // Pulsing hardware-live dot
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isHardwareLive ? AppColors.statusSafe : AppColors.textGrey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                      boxShadow: _isHardwareLive
                        ? [BoxShadow(color: AppColors.statusSafe.withOpacity(0.6), blurRadius: 4)]
                        : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            widget.device["name"],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.device["macAddress"],
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    _isHardwareLive ? Icons.sensors : Icons.sensors_off,
                    size: 12,
                    color: _isHardwareLive ? AppColors.statusSafe : AppColors.textGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isHardwareLive ? 'ESP32 Live · $_lastSeenText' : 'ESP32 Offline · $_lastSeenText',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isHardwareLive ? AppColors.statusSafe : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: widget.isReordering 
            ? ReorderableDragStartListener(
                index: widget.index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.drag_handle_rounded, color: AppColors.textGrey, size: 28),
                ),
              )
            : _buildStatusBadge(isOnline),
          children: widget.isReordering ? [] : [
            const Divider(),
            const SizedBox(height: 12),
            _buildHeartbeatCard(),
            const SizedBox(height: 12),
            _buildStatusToggle(isOnline),
            const SizedBox(height: 16),
            TextField(
               controller: _macCtrl,
               decoration: const InputDecoration(labelText: "MAC Address", border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
               controller: _nameCtrl,
               decoration: const InputDecoration(labelText: "Location/Node Name", border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Temperature Alert", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text("${_tempThresh.toStringAsFixed(1)} °C", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusDanger, fontSize: 13)),
              ],
            ),
            Slider(
              value: _tempThresh,
              min: 30.0,
              max: 60.0,
              divisions: 60,
              activeColor: AppColors.statusDanger,
              onChanged: (val) => setState(() => _tempThresh = val),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Smoke Alert", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text("${_smokeThresh.toStringAsFixed(0)} PPM", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 13)),
              ],
            ),
            Slider(
              value: _smokeThresh,
              min: 100.0,
              max: 500.0,
              divisions: 40,
              activeColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _smokeThresh = val),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Flame Alert", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text("${_flameThresh.toStringAsFixed(0)} PPM", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusWarning, fontSize: 13)),
              ],
            ),
            Slider(
              value: _flameThresh,
              min: 50.0,
              max: 500.0,
              divisions: 45,
              activeColor: AppColors.statusWarning,
              onChanged: (val) => setState(() => _flameThresh = val),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onSave(
                         widget.device["macAddress"], 
                         _macCtrl.text.trim(), 
                         _nameCtrl.text.trim(), 
                         {
                            "temp_threshold": _tempThresh,
                            "smoke_threshold": _smokeThresh,
                            "flame_threshold": _flameThresh,
                         }
                      );
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onRemove(widget.device["macAddress"], widget.device["name"]),
                    icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger),
                    label: const Text("Remove", style: TextStyle(color: AppColors.statusDanger, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.statusDanger.withOpacity(0.5), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isOnline) {
    final color = isOnline ? AppColors.statusSafe : AppColors.textGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isOnline ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)] : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? "ONLINE" : "OFFLINE",
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartbeatCard() {
    final hwState = _hardwareState;
    final ip = widget.device['heartbeat_ip'];
    final firmware = widget.device['heartbeat_firmware'];
    // We are now trusting the RTDB explicit string
    final isLive = hwState == 'CONNECTED';
    final color = isLive ? AppColors.statusSafe : (hwState == 'DISCONNECTED' ? AppColors.statusDanger : AppColors.textGrey);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLive ? Icons.sensors : Icons.sensors_off,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                "ESP32 Hardware",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hwState.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _heartbeatDetail(Icons.access_time, 'Last Seen', _lastSeenText),
              if (ip != null) ...[const SizedBox(width: 16), _heartbeatDetail(Icons.lan, 'IP', ip)],
              if (firmware != null) ...[const SizedBox(width: 16), _heartbeatDetail(Icons.memory, 'FW', firmware)],
            ],
          ),
        ],
      ),
    );
  }

  Widget _heartbeatDetail(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7)),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(bool isOnline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                size: 22,
                color: isOnline ? AppColors.statusSafe : AppColors.statusDanger,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hardware Connectivity", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    isOnline ? "Node is active and sending data" : "Node is physically disconnected",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              widget.onStatusToggle(widget.device["macAddress"], isOnline ? "offline" : "online");
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 68,
              height: 34,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isOnline ? AppColors.statusSafe.withOpacity(0.15) : AppColors.statusDanger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isOnline ? AppColors.statusSafe.withOpacity(0.3) : AppColors.statusDanger.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                alignment: isOnline ? Alignment.centerRight : Alignment.centerLeft,
                curve: Curves.easeOutBack,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.statusSafe : AppColors.statusDanger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline ? AppColors.statusSafe : AppColors.statusDanger).withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.power_settings_new,
                    size: 15,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
