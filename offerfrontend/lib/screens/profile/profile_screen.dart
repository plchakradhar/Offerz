import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import 'add_address_bottomsheet.dart';
import 'avatar_picker_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _saving = false;
  bool _hasChanges = false;

  bool _isEditingName = false;
  bool _isEditingEmail = false;

  String _mobile = "";
  String _originalName = "";
  String _originalEmail = "";

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();

  String _selectedAvatar = "";
  String _originalAvatar = "";
  List<dynamic> _addresses = [];

  static const List<String> _avatarList = [
    "https://api.dicebear.com/7.x/avataaars/png?seed=Felix",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Aneka",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Jasper",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Destiny",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Bella",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Leo",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Milo",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Zara",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Nova",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Rex",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Luna",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Echo",
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final changed = _nameController.text.trim() != _originalName ||
        _emailController.text.trim() != _originalEmail ||
        _selectedAvatar != _originalAvatar;
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    _mobile = prefs.getString('userMobile') ?? "";

    if (_mobile.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    // Show cached data immediately for fast UX
    final cachedName = prefs.getString('userName') ?? "";
    final cachedEmail = prefs.getString('userEmail') ?? "";
    final cachedAvatar = prefs.getString('userAvatar') ?? _avatarList[0];
    _nameController.text = cachedName;
    _emailController.text = cachedEmail;
    _selectedAvatar = cachedAvatar.isEmpty ? _avatarList[0] : cachedAvatar;
    _originalName = cachedName;
    _originalEmail = cachedEmail;
    _originalAvatar = _selectedAvatar;
    setState(() => _loading = false);

    // Fetch fresh data from server in background
    final response = await ProfileService.getProfile(_mobile);
    if (response['success'] == true && mounted) {
      final data = response['data'];
      final serverName = data['fullName'] ?? cachedName;
      final serverEmail = data['email'] ?? cachedEmail;
      final serverAvatar = (data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty)
          ? data['avatarUrl']
          : _avatarList[0];
      final serverAddresses = data['addresses'] ?? [];

      setState(() {
        _nameController.text = serverName;
        _emailController.text = serverEmail;
        _selectedAvatar = serverAvatar;
        _originalName = serverName;
        _originalEmail = serverEmail;
        _originalAvatar = serverAvatar;
        _addresses = serverAddresses;
        _hasChanges = false;
      });
    }
  }

  Future<void> _openAvatarPicker() async {
    final picked = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarPickerScreen(
          avatars: _avatarList,
          currentAvatar: _selectedAvatar,
        ),
      ),
    );
    if (picked != null && picked != _selectedAvatar) {
      setState(() {
        _selectedAvatar = picked;
        _hasChanges = _selectedAvatar != _originalAvatar ||
            _nameController.text.trim() != _originalName ||
            _emailController.text.trim() != _originalEmail;
      });
    }
  }

  Future<void> _saveProfile() async {
    // Close keyboards / editing states
    _nameFocus.unfocus();
    _emailFocus.unfocus();

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    if (newName.isEmpty) {
      _showError("Full name cannot be empty");
      return;
    }
    if (newEmail.isNotEmpty && !newEmail.contains('@')) {
      _showError("Please enter a valid email address");
      return;
    }

    setState(() => _saving = true);

    final result = await ProfileService.updateProfile(
        _mobile, newName, newEmail, _selectedAvatar);

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      setState(() {
        _originalName = newName;
        _originalEmail = newEmail;
        _originalAvatar = _selectedAvatar;
        _hasChanges = false;
        _isEditingName = false;
        _isEditingEmail = false;
      });
      _showSuccess("Profile saved successfully!");
    } else {
      _showError(result['message'] ?? "Failed to save changes");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // Collapsible App Bar with avatar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_hasChanges)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    onPressed: _saving ? null : _saveProfile,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                        : const Icon(Icons.check, color: Colors.orange, size: 18),
                    label: const Text("Save", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          // Avatar with edit button
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFF1A1A2E),
                                  backgroundImage: _selectedAvatar.isNotEmpty
                                      ? NetworkImage(_selectedAvatar)
                                      : null,
                                  child: _selectedAvatar.isEmpty
                                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                                      : null,
                                ),
                              ),
                              GestureDetector(
                                onTap: _openAvatarPicker,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF6B35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameController.text.isNotEmpty ? _nameController.text : "Your Name",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _mobile,
                            style: const TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: _loading
                ? const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Personal Details Card
                        _sectionTitle("Personal Details"),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              // Name Field
                              _buildProfileField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                label: "Full Name",
                                icon: Icons.person_outline_rounded,
                                isEditing: _isEditingName,
                                isLast: false,
                                onEditToggle: () {
                                  setState(() {
                                    _isEditingName = !_isEditingName;
                                    if (_isEditingName) {
                                      Future.delayed(const Duration(milliseconds: 100), () => _nameFocus.requestFocus());
                                    } else {
                                      _nameFocus.unfocus();
                                    }
                                  });
                                },
                              ),
                              Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                              // Email Field
                              _buildProfileField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                label: "Email Address",
                                icon: Icons.email_outlined,
                                isEditing: _isEditingEmail,
                                isLast: false,
                                keyboardType: TextInputType.emailAddress,
                                onEditToggle: () {
                                  setState(() {
                                    _isEditingEmail = !_isEditingEmail;
                                    if (_isEditingEmail) {
                                      Future.delayed(const Duration(milliseconds: 100), () => _emailFocus.requestFocus());
                                    } else {
                                      _emailFocus.unfocus();
                                    }
                                  });
                                },
                              ),
                              Divider(height: 1, color: Colors.grey.shade100, indent: 20, endIndent: 20),
                              // Mobile (read-only)
                              _buildReadOnlyField(
                                value: _mobile,
                                label: "Mobile Number",
                                icon: Icons.phone_android_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Save Button (prominent, only when changes exist)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _hasChanges
                              ? _buildSaveButton()
                              : const SizedBox.shrink(),
                        ),
                        if (_hasChanges) const SizedBox(height: 28),

                        // My Addresses
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle("My Addresses"),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => AddAddressBottomSheet(
                                    onAddressAdded: _loadProfile,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add, color: Color(0xFFFF6B35), size: 16),
                                    SizedBox(width: 4),
                                    Text("Add New", style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_addresses.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.location_off_outlined, size: 44, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text("No addresses saved yet", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("Tap 'Add New' to add your address", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _addresses.length,
                            separatorBuilder: (context2, index2) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final addr = _addresses[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.home_outlined, color: Color(0xFFFF6B35), size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${addr['doorNumber']}, ${addr['street']}",
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            "${addr['city']}, ${addr['state']} - ${addr['zipcode']}",
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 32),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout_rounded, color: Colors.red),
                            label: const Text("Logout", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade200, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: Colors.red.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87, letterSpacing: 0.2),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required bool isEditing,
    required bool isLast,
    required VoidCallback onEditToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEditing
                  ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isEditing ? const Color(0xFFFF6B35) : Colors.grey.shade500, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: isEditing,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: false,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isEditing
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 22, key: ValueKey("check"))
                  : const Icon(Icons.edit_outlined, color: Colors.grey, size: 20, key: ValueKey("edit")),
            ),
            onPressed: onEditToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.grey.shade400, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      key: const ValueKey("saveBtn"),
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, size: 20),
                  SizedBox(width: 10),
                  Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
