import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_title.dart';
import '../../../../core/widgets/secondary_geometric_background.dart';
import '../../auth/services/auth_service.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  // ─── Filter State ───────────────────────────────────────────────────────────
  String _viewType = 'Grid View';
  String _statusFilter = 'All';
  String _roleFilter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();

  // ─── Data State ─────────────────────────────────────────────────────────────
  final GlobalKey _roleDropdownKey = GlobalKey();
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = true;
  int _onlineCount = 0;
  int _offlineCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Firebase Fetch (Using safe SDK instead of REST) ────────────────────────
  Future<void> _fetchUsers() async {
    try {
      final url = Uri.parse('https://crowdsense-db-default-rtdb.asia-southeast1.firebasedatabase.app/users.json');
      final response = await http.get(url);

      if (response.statusCode != 200 || response.body == 'null') {
        setState(() => _isLoading = false);
        return;
      }
      
      final raw = json.decode(response.body) as Map<String, dynamic>;
      final List<Map<String, dynamic>> loaded = [];
      
      raw.forEach((uid, value) {
        if (value is! Map) return;
        final d = Map<String, dynamic>.from(value as Map);
        loaded.add({
          'uid': uid,
          'id': d['customId']?.toString() ?? uid.substring(0, 6).toUpperCase(),
          'name': d['name']?.toString() ?? 'Unknown User',
          'username': d['username']?.toString() ?? '',
          'email': d['email']?.toString() ?? '',
          'phone': d['phone']?.toString() ?? '',
          'role': d['role']?.toString() ?? 'User',
          'designation': d['designation']?.toString() ?? 'N/A',
          // Firebase boolean sometimes saves as digit 1 or 0
          'isOnline': d['isOnline'] == true || d['isOnline'] == 1,
          'createdAt': _parseCreatedAt(d['createdAt']),
        });
      });

      loaded.sort((a, b) => (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime));
      
      // Determine who is currently logged in — they are "Online"
      // The `isOnline` field may not exist in the DB yet; we derive it
      // directly from Firebase Auth's currently authenticated user.
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      loaded.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

      for (final u in loaded) {
        u['isOnline'] = u['uid'] == currentUid;
      }

      setState(() {
        _allUsers = loaded;
        _onlineCount = loaded.where((u) => u['isOnline'] == true).length;
        _offlineCount = loaded.where((u) => u['isOnline'] == false).length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch users error: $e');
      setState(() => _isLoading = false);
    }
  }

  DateTime _parseCreatedAt(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is int || raw is double) {
      int ms = raw is double ? raw.toInt() : raw as int;
      // Convert Unix seconds to ms if necessary
      if (ms < 10000000000) ms = ms * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  bool get _isAdmin {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || _allUsers.isEmpty) return false;
    final user = _allUsers.firstWhere((u) => u['uid'] == currentUid, orElse: () => <String, dynamic>{});
    return user['role']?.toString().toLowerCase() == 'admin';
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final q = _searchCtrl.text.toLowerCase();
    return _allUsers.where((u) {
      final matchSearch = q.isEmpty ||
          u['name'].toString().toLowerCase().contains(q) ||
          u['username'].toString().toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Online' && u['isOnline'] == true) ||
          (_statusFilter == 'Offline' && u['isOnline'] == false);
      final matchRole = _roleFilter == 'All' || u['role'] == _roleFilter;
      return matchSearch && matchStatus && matchRole;
    }).toList();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SecondaryGeometricBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Users Management", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: cs.onSurface,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER SECTION ──────────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageTitle(title: "System Users"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _dotBadge(AppColors.statusSafe, 'Online $_onlineCount'),
                      const SizedBox(width: 16),
                      _dotBadge(cs.onSurfaceVariant.withOpacity(0.5), 'Offline $_offlineCount'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── SEARCH BAR & ADD ACTION ─────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(isDark),
                  if (_isAdmin) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddUserDialog(context),
                      icon: const Icon(Icons.person_add_rounded, size: 20),
                      label: const Text(
                        "ADD USER",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // ── FILTER BAR ──────────────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterDropdown(
                      icon: Icons.grid_view_rounded,
                      label: 'Type: ',
                      selectedValue: _viewType,
                      items: ['Grid View', 'List View'],
                      onChanged: (val) { if (val != null) setState(() => _viewType = val); },
                    ),
                    const SizedBox(width: 12),
                    _buildFilterDropdown(
                      icon: Icons.show_chart_rounded,
                      label: 'Status: ',
                      selectedValue: _statusFilter,
                      items: ['All', 'Online', 'Offline'],
                      onChanged: (val) { if (val != null) setState(() => _statusFilter = val); },
                    ),
                    const SizedBox(width: 12),
                    _buildFilterDropdown(
                      icon: Icons.badge_outlined,
                      label: 'Role: ',
                      selectedValue: _roleFilter,
                      items: ['All', 'Admin', 'Facilitator'],
                      onChanged: (val) { if (val != null) setState(() => _roleFilter = val); },
                    ),
                    const SizedBox(width: 12),
                    _buildAdvanceFilterButton(isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // ── CONTENT AREA ────────────────────────────────────────────────────
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                        ? _buildEmptyState()
                        : _viewType == 'Grid View'
                            ? _buildGridView(isDark)
                            : _buildListView(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LIST VIEW LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildListView(bool isDark) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(isDark ? 0.3 : 1.0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(cs.surfaceVariant.withOpacity(isDark ? 0.4 : 0.8)),
              dataRowMaxHeight: 70,
              columnSpacing: 32,
              headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface, fontSize: 13),
              columns: const [
                DataColumn(label: Text('ID#')),
                DataColumn(label: Text('Full Name')),
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Access Level')),
                DataColumn(label: Text('Designation')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Contact')),
                DataColumn(label: Text('Joined')),
              ],
              rows: _filteredUsers.map((user) {
                final role = user['role'] as String;
                final isOnline = user['isOnline'] as bool;
                final roleColor = role.toLowerCase() == 'admin' ? AppColors.statusDanger : AppColors.statusWarning;
                
                return DataRow(
                  cells: [
                    DataCell(Text('# ${user['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    DataCell(Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: roleColor.withOpacity(0.15),
                          child: Text(user['name'][0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )),
                    DataCell(Text('@${user['username']}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: roleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(role.toUpperCase(), style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    )),
                    DataCell(Text(user['designation'], style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))),
                    DataCell(Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.statusSafe.withOpacity(0.1) : cs.onSurfaceVariant.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: isOnline ? AppColors.statusSafe : cs.onSurfaceVariant),
                          const SizedBox(width: 5),
                          Text(isOnline ? 'Online' : 'Offline', style: TextStyle(color: isOnline ? AppColors.statusSafe : cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )),
                    DataCell(Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email'], style: const TextStyle(fontSize: 12)),
                        if (user['phone'].isNotEmpty) 
                          Text(user['phone'], style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                    )),
                    DataCell(Text('Joined at ${_formatDate(user['createdAt'] as DateTime)}', style: const TextStyle(fontSize: 12))),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GRID VIEW LAYOUT
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildGridView(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On mobile-sized windows (<480px available), go single column
        // so each card is fat enough to fully show all content.
        // On wider screens, show 2 columns.
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = availableWidth < 480 ? 1 : 2;
        final spacing = 20.0;
        final cardWidth = crossAxisCount == 1
            ? availableWidth
            : (availableWidth - spacing) / 2;

        // Narrowing the cards by 25% (adding 12.5% padding on each side)
        // and reducing height by 10% (420 -> 378)
        final horizontalPadding = availableWidth * 0.12;

        return GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 378,
            crossAxisSpacing: spacing,
            mainAxisSpacing: 16,
          ),
          itemCount: _filteredUsers.length,
          itemBuilder: (context, index) {
            // Remap index to achieve vertical-first ordering (1 3, 2 4...) 
            // when we have 2 columns.
            int sourceIndex = index;
            if (crossAxisCount == 2) {
              final int N = _filteredUsers.length;
              final int rows = (N + 1) ~/ 2;
              final int col = index % 2;
              final int row = index ~/ 2;
              
              if (col == 0) {
                sourceIndex = row;
              } else {
                sourceIndex = row + rows;
              }
              
              // Fallback just in case of odd numbers at the end
              if (sourceIndex >= N) sourceIndex = index;
            }

            return _UserGridCard(
              user: _filteredUsers[sourceIndex],
              isDark: isDark,
              formatDate: _formatDate,
            );
          },
        );
      },
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No users found.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── Filter UI Components ───────────────────────────────────────────────────
  Widget _dotBadge(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.2);
    return Container(
      height: 38,
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(hintText: 'Search', hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String label,
    required String selectedValue,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.2);
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 42),
      tooltip: '',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) {
        return items.map((e) => PopupMenuItem(value: e, height: 40, child: Text(e, style: const TextStyle(fontSize: 13)))).toList();
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            Text(selectedValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceFilterButton(bool isDark) {
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = Theme.of(context).colorScheme.outline.withOpacity(0.2);
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_outlined, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          const Text('Advance Filter', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  // ─── Add User Dialog Implementation ─────────────────────────────────────────
  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final designationCtrl = TextEditingController(); // Optional
    String selectedRole = 'Facilitator'; // Default since it's restricted to Admin/Facilitator

    bool isSaving = false;
    final AuthService authService = AuthService();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final textMuted = Theme.of(context).colorScheme.onSurfaceVariant;

    showDialog(
      context: context,
      barrierDismissible: !isSaving,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 500, // Make it wider like the reference image
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Add New User", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor)),
                    IconButton(
                      icon: Icon(Icons.close, color: textMuted),
                      tooltip: '',
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Form Fields wrapped in Expanded scrolling if constrained vertically
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogFieldLabel("Full Name *", isDark),
                        _buildDialogTextInput(nameCtrl, "Enter full name...", isSaving, isDark, icon: Icons.person_outline_rounded),
                        const SizedBox(height: 16),
                        
                        _buildDialogFieldLabel("Username *", isDark),
                        _buildDialogTextInput(usernameCtrl, "Enter username...", isSaving, isDark, icon: Icons.alternate_email_rounded),
                        const SizedBox(height: 16),

                        _buildDialogFieldLabel("Email *", isDark),
                        _buildDialogTextInput(emailCtrl, "Enter email address...", isSaving, isDark, icon: Icons.mail_outline_rounded),
                        const SizedBox(height: 16),

                        _buildDialogFieldLabel("Official Designation (Optional)", isDark),
                        _buildDialogTextInput(designationCtrl, "Enter official designation...", isSaving, isDark, icon: Icons.badge_outlined),
                        const SizedBox(height: 20),

                        // Temporary password notice
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primaryBlue.withOpacity(0.1) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryBlue.withOpacity(isDark ? 0.3 : 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.key_rounded, size: 18, color: AppColors.primaryBlue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(fontSize: 13, color: isDark ? Colors.blue.shade200 : Colors.blue.shade900),
                                    children: const [
                                      TextSpan(text: "A temporary password will be "),
                                      TextSpan(text: "auto-generated", style: TextStyle(fontWeight: FontWeight.bold)),
                                      TextSpan(text: " and emailed to the user."),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildDialogFieldLabel("Role", isDark),
                        _buildDialogRoleDropdown(selectedRole, ['Admin', 'Facilitator'], isSaving, isDark, (val) {
                          if (val != null && !isSaving) setDialogState(() => selectedRole = val);
                        }),
                      ],
                    ),
                  ),
                ),
                
                // Footer actions
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5))),
                      ),
                      child: Text("Cancel", style: TextStyle(color: textMuted, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty && usernameCtrl.text.isNotEmpty) {
                          setDialogState(() => isSaving = true);

                          try {
                            final userData = {
                              'customId': 'U${(1000 + _allUsers.length).toString()}',
                              'name': nameCtrl.text.trim(),
                              'username': usernameCtrl.text.trim(),
                              'email': emailCtrl.text.trim().toLowerCase(),
                              'phone': '',
                              'role': selectedRole.toLowerCase(),
                              'designation': designationCtrl.text.trim().isEmpty ? 'N/A' : designationCtrl.text.trim(),
                              'isOnline': false,
                              'createdAt': DateTime.now().toIso8601String(),
                            };

                            // --- SAVE TO DATABASE ---
                            await authService.createUserRecord(userData);

                            // --- REFRESH LOCAL UI ---
                            setState(() {
                              _allUsers.insert(0, {
                                ...userData,
                                'uid': 'pending_refresh',
                                'createdAt': DateTime.now(),
                              });
                              _offlineCount++;
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text("User '${nameCtrl.text}' saved to database as $selectedRole."),
                                  backgroundColor: Colors.green.shade700,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text("Failed to save: ${e.toString()}"),
                                  backgroundColor: AppColors.statusDanger,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusDanger, // Using the orange/red from reference
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Create User", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogFieldLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildDialogTextInput(TextEditingController ctrl, String hint, bool isSaving, bool isDark, {IconData? icon}) {
    return TextField(
      controller: ctrl,
      enabled: !isSaving,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400) : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDialogRoleDropdown(String selected, List<String> options, bool isSaving, bool isDark, ValueChanged<String?> onChanged) {
    final color = selected.toLowerCase() == 'admin' ? AppColors.statusDanger : AppColors.statusWarning;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          key: _roleDropdownKey,
          onTap: isSaving ? null : () async {
            // Calculate position for the popup menu
            final RenderBox renderBox = _roleDropdownKey.currentContext?.findRenderObject() as RenderBox;
            final offset = renderBox.localToGlobal(Offset.zero);
            
            final String? selection = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                offset.dx, 
                offset.dy + 52, // Below the field
                offset.dx + constraints.maxWidth, 
                offset.dy + 100 // Arbitrary bottom
              ),
              color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
              ),
              items: options.map((role) {
                final roleCol = role.toLowerCase() == 'admin' ? AppColors.statusDanger : AppColors.statusWarning;
                return PopupMenuItem<String>(
                  value: role,
                  height: 48,
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 14,
                      color: roleCol,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            );

            if (selection != null) {
              onChanged(selection);
            }
          },
          child: Material(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Container(
              height: 52, // Match the text field height
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selected,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GRID CARD WIDGET
// ════════════════════════════════════════════════════════════════════════════
class _UserGridCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final String Function(DateTime) formatDate;

  const _UserGridCard({
    required this.user,
    required this.isDark,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOnline = user['isOnline'] as bool;
    final role = user['role'] as String;
    final roleColor = role.toLowerCase() == 'admin' ? AppColors.statusDanger : AppColors.statusWarning;
    final phone = user['phone'] as String;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top: Status badge ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.statusSafe : cs.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    Text(isOnline ? 'Online' : 'Offline', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
                Icon(Icons.more_horiz, color: cs.onSurfaceVariant.withOpacity(0.5), size: 20),
              ],
            ),
          ),

          // ── Avatar & Identity ──────────────────────────────────────────────
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: roleColor.withOpacity(0.15),
              child: Text(user['name'].toString().substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: roleColor)),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              Text(user['name'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(user['designation'], textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Encased Info Box ───────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? cs.surfaceVariant.withOpacity(0.2) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withOpacity(0.08)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ID + Role
                    Row(children: [
                      Flexible(
                        child: Text('# ${user['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(role.toUpperCase(), textAlign: TextAlign.right, style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    Divider(color: cs.outline.withOpacity(0.1), height: 16),
                    // Username
                    _buildIconLabel(Icons.alternate_email, user['username'], cs),
                    const SizedBox(height: 6),
                    // Email & Phone
                    _buildIconLabel(Icons.mail_outline, user['email'], cs),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _buildIconLabel(Icons.phone_outlined, phone, cs),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('Joined at ${formatDate(user['createdAt'] as DateTime)}', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('View details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  Icon(Icons.chevron_right, size: 16, color: cs.onSurface),
                ]),
              ],
            ),
          ),

          // ── Colored Bottom Border ──────────────────────────────────────────
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: roleColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String text, ColorScheme cs) {
    return Row(
      children: [
        Icon(icon, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
