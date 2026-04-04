import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/widgets/custom_notification_modal.dart';

class DeviceManagementModal extends StatefulWidget {
  const DeviceManagementModal({super.key});

  @override
  State<DeviceManagementModal> createState() => _DeviceManagementModalState();
}

class _DeviceManagementModalState extends State<DeviceManagementModal> {
  // Mock Data
  final List<Map<String, dynamic>> _mockDevices = [
    {
      "macAddress": "00:1B:44:11:3A:B7",
      "name": "CEA 3rd Floor",
      "status": "online",
      "sensors": {
        "temp_threshold": 35.0,
      }
    },
    {
      "macAddress": "00:1B:44:88:9C:A1",
      "name": "CEA 2nd Floor Landing",
      "status": "online",
      "sensors": {
        "temp_threshold": 40.0,
      }
    },
    {
      "macAddress": "00:1B:44:22:1F:D3",
      "name": "Main Entrance",
      "status": "offline",
      "sensors": {
        "temp_threshold": 30.0,
      }
    },
  ];

  final TextEditingController _macController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  void _addDeviceToFirebase(String mac, String name) {
    // TODO: Implement Firebase connection
    debugPrint("Adding Device to Firebase - MAC: $mac, Name: $name");
  }

  void _updateDeviceConfig(String mac, Map<String, dynamic> newSensors) {
    // TODO: Implement Firebase connection
    debugPrint("Updating Device Config in Firebase - MAC: $mac, Sensors: $newSensors");
  }

  void _updateDeviceStatus(String mac, String newStatus) {
    // TODO: Implement Firebase connection
    debugPrint("Updating Device Status in Firebase - MAC: $mac, Status: $newStatus");
  }

  void _removeDeviceFromFirebase(String mac) {
    // TODO: Implement Firebase connection
    debugPrint("Removing Device from Firebase - MAC: $mac");
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

    final newDevice = {
      "macAddress": _macController.text.trim(),
      "name": _nameController.text.trim(),
      "status": "online", // Mock default state
      "sensors": {
        "temp_threshold": 35.0,
      }
    };

    setState(() {
      _mockDevices.insert(0, newDevice);
    });

    _addDeviceToFirebase(newDevice["macAddress"] as String, newDevice["name"] as String);

    _macController.clear();
    _nameController.clear();

    FocusScope.of(context).unfocus();
    
    CustomNotificationModal.show(
      context: context,
      title: "Device Added",
      message: "Device '${newDevice["name"]}' has been added successfully.",
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
    setState(() {
      _mockDevices.removeWhere((device) => device["macAddress"] == mac);
    });
    _removeDeviceFromFirebase(mac);
    
    CustomNotificationModal.show(
      context: context,
      title: "Device Removed",
      message: "Device '$name' has been permanently removed.",
      isSuccess: true,
      isDestructive: true,
    );
  }

  @override
  void dispose() {
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
                    
                    _buildSectionTitle("Configured Devices"),
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
    if (_mockDevices.isEmpty) {
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mockDevices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final device = _mockDevices[index];
        return _buildDeviceTile(device, isDark);
      },
    );
  }

  Widget _buildDeviceTile(Map<String, dynamic> device, bool isDark) {
    final bool isOnline = device["status"] == "online";
    final sensors = device["sensors"] as Map<String, dynamic>;
    final settings = context.watch<SettingsProvider>();

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
            child: Icon(Icons.router, color: isOnline ? AppColors.primaryBlue : AppColors.textGrey, size: 24),
          ),
          title: Text(
            device["name"],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            device["macAddress"],
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          trailing: _buildStatusBadge(isOnline),
          children: [
            const Divider(),
            const SizedBox(height: 12),
            _buildStatusToggle(device),
            const SizedBox(height: 8),
            const Divider(height: 16),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Temperature Alert Threshold", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text("${settings.temperatureThreshold.toStringAsFixed(1)} °C", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusDanger, fontSize: 14)),
              ],
            ),
            Slider(
              value: settings.temperatureThreshold,
              min: 30.0,
              max: 50.0,
              divisions: 40,
              activeColor: AppColors.statusDanger,
              inactiveColor: AppColors.statusDanger.withOpacity(0.2),
              thumbColor: AppColors.statusDanger,
              label: "${settings.temperatureThreshold.toStringAsFixed(1)} °C",
              onChanged: (val) {
                settings.setTemperatureThreshold(val);
              },
              onChangeEnd: (val) {
                _updateDeviceConfig(device["macAddress"], sensors); // We'd push the new global or local config here
              },
            ),

            // Let's also add the Smoke Threshold Slider since we want both thresholds to be adjustable by admin
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Smoke Alert Threshold", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text("${settings.smokeThreshold.toStringAsFixed(0)} PPM", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 14)),
              ],
            ),
            Slider(
              value: settings.smokeThreshold,
              min: 100.0,
              max: 500.0,
              divisions: 40,
              activeColor: AppColors.primaryBlue,
              inactiveColor: AppColors.primaryBlue.withOpacity(0.2),
              thumbColor: AppColors.primaryBlue,
              label: "${settings.smokeThreshold.toStringAsFixed(0)} PPM",
              onChanged: (val) {
                settings.setSmokeThreshold(val);
              },
              onChangeEnd: (val) {
                _updateDeviceConfig(device["macAddress"], sensors);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Flame Alert Threshold", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text("${settings.flameThreshold.toStringAsFixed(0)} PPM", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusWarning, fontSize: 14)),
              ],
            ),
            Slider(
              value: settings.flameThreshold,
              min: 50.0,
              max: 500.0,
              divisions: 45,
              activeColor: AppColors.statusWarning,
              inactiveColor: AppColors.statusWarning.withOpacity(0.2),
              thumbColor: AppColors.statusWarning,
              label: "${settings.flameThreshold.toStringAsFixed(0)} PPM",
              onChanged: (val) {
                settings.setFlameThreshold(val);
              },
              onChangeEnd: (val) {
                _updateDeviceConfig(device["macAddress"], sensors);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _promptRemoveDevice(device["macAddress"], device["name"]),
                icon: const Icon(Icons.delete_outline, color: AppColors.statusDanger),
                label: const Text("Remove Device", style: TextStyle(color: AppColors.statusDanger, fontWeight: FontWeight.bold, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: AppColors.statusDanger.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
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

  Widget _buildStatusToggle(Map<String, dynamic> device) {
    final bool isOnline = device["status"] == "online";
    
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
              setState(() => device["status"] = isOnline ? "offline" : "online");
              _updateDeviceStatus(device["macAddress"], device["status"]);
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
