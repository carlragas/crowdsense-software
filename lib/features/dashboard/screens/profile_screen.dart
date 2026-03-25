import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  bool hasChanges = false;

  final String initialName = "Dr. Admin User";
  final String initialEmail = "admin@crowdsense.network";
  final String initialDept = "System Operations";

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController deptController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: initialName);
    emailController = TextEditingController(text: initialEmail);
    deptController = TextEditingController(text: initialDept);

    nameController.addListener(_checkForChanges);
    emailController.addListener(_checkForChanges);
    deptController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    bool changed = nameController.text != initialName ||
        emailController.text != initialEmail ||
        deptController.text != initialDept;
    if (hasChanges != changed) {
      setState(() {
        hasChanges = changed;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    deptController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (isEditing) {
        // Cancel logic: restore initial values
        nameController.text = initialName;
        emailController.text = initialEmail;
        deptController.text = initialDept;
      }
      isEditing = !isEditing;
    });
  }

  void _saveChanges() {
    // Save logic
    setState(() {
      isEditing = false;
      hasChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sensorBlue = const Color(0xFF0056D2); // Deep Sensor Blue

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('User Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!isEditing)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: _toggleEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("Edit Profile"),
                style: TextButton.styleFrom(
                  foregroundColor: sensorBlue,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Avatar and Name/Designation
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: sensorBlue.withOpacity(0.3), width: 3),
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                    ),
                    if (isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: sensorBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nameController.text.isEmpty ? initialName : nameController.text,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sensorBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "System Administrator",
                          style: TextStyle(
                            color: isDark ? Colors.blue.shade300 : sensorBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Primary Section
            _buildSectionHeader("Personal & Professional Info"),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
              ),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildField("Full Name", nameController, isEditing, sensorBlue),
                    const Divider(height: 32),
                    _buildField("Verified Email", emailController, isEditing, sensorBlue),
                    const Divider(height: 32),
                    _buildField("Department Affiliation", deptController, isEditing, sensorBlue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Final Section (System Metadata)
            _buildSectionHeader("System Metadata & Security"),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.onSurface.withOpacity(0.1)),
              ),
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStaticField("User ID", "USR-99281-SYS"),
                    const Divider(height: 32),
                    _buildStaticField("Assigned Hardware Clusters", "Alpha ESP32-CAM (Sector 4)\nBeta NodeMCU (Sector 7)\nMain Access Gateway - PUP-CEA"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isEditing
          ? Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _toggleEdit,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: hasChanges ? _saveChanges : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sensorBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: sensorBlue.withOpacity(0.3),
                          disabledForegroundColor: Colors.white.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool editable, Color focusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (!editable)
          Text(
            controller.text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          )
        else
          TextField(
            controller: controller,
            cursorColor: focusColor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.grey.shade100,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: focusColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStaticField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
