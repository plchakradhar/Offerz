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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
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

  // Colors – strict black & white palette
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF2F2F2);
  static const Color _white = Color(0xFFFFFFFF);

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

    final response = await ProfileService.getProfile(_mobile);
    if (response['success'] == true && mounted) {
      final data = response['data'];
      final serverName = data['fullName'] ?? cachedName;
      final serverEmail = data['email'] ?? cachedEmail;
      final serverAvatar =
          (data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty)
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

    final result =
        await ProfileService.updateProfile(_mobile, newName, newEmail, _selectedAvatar);

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
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: _darkGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: _black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout",
            style: TextStyle(fontWeight: FontWeight.bold, color: _black)),
        content: const Text("Are you sure you want to logout?",
            style: TextStyle(color: _mediumGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: _mediumGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _black,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
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
      backgroundColor: _softGrey,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "My Profile",
              style: TextStyle(
                  color: _white, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),

          // ── Body ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _loading
                ? const SizedBox(
                    height: 300,
                    child: Center(
                        child: CircularProgressIndicator(color: _black)),
                  )
                : _buildBody(),
          ),
        ],
      ),
    );
  }

  // ── Header / Flexible Space ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _black,
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _white))
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 80),
                // Avatar
                GestureDetector(
                  onTap: _openAvatarPicker,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _white.withValues(alpha: 0.15),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: _darkGrey,
                          backgroundImage: _selectedAvatar.isNotEmpty
                              ? NetworkImage(_selectedAvatar)
                              : null,
                          child: _selectedAvatar.isEmpty
                              ? const Icon(Icons.person, size: 50, color: _white)
                              : null,
                        ),
                      ),
                      // Edit badge
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _black, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: _black, size: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Name display
                Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text
                      : "Your Name",
                  style: const TextStyle(
                    color: _white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _mobile,
                  style: const TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 13),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  // ── Main body content ────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Personal Details Section ─────────────────────────
          _sectionLabel("Personal Details"),
          const SizedBox(height: 10),
          _buildPersonalCard(),
          const SizedBox(height: 28),

          // ── My Addresses ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel("My Addresses"),
              _addAddressButton(),
            ],
          ),
          const SizedBox(height: 10),
          _buildAddressSection(),
          const SizedBox(height: 32),

          // ── Logout ───────────────────────────────────────────
          _buildLogoutButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Personal Details Card ─────────────────────────────────────
  Widget _buildPersonalCard() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Name Field
          _buildEditableField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: "Full Name",
            icon: Icons.person_outline_rounded,
            isEditing: _isEditingName,
            isFirst: true,
            isLast: false,
            onEditToggle: () {
              setState(() {
                _isEditingName = !_isEditingName;
                if (_isEditingName) {
                  _isEditingEmail = false;
                  _emailFocus.unfocus();
                  Future.delayed(const Duration(milliseconds: 80),
                      () => _nameFocus.requestFocus());
                } else {
                  _nameFocus.unfocus();
                }
              });
            },
          ),

          _divider(),

          // Email Field
          _buildEditableField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: "Email Address",
            icon: Icons.email_outlined,
            isEditing: _isEditingEmail,
            isFirst: false,
            isLast: false,
            keyboardType: TextInputType.emailAddress,
            onEditToggle: () {
              setState(() {
                _isEditingEmail = !_isEditingEmail;
                if (_isEditingEmail) {
                  _isEditingName = false;
                  _nameFocus.unfocus();
                  Future.delayed(const Duration(milliseconds: 80),
                      () => _emailFocus.requestFocus());
                } else {
                  _emailFocus.unfocus();
                }
              });
            },
          ),

          _divider(),

          // Mobile (read-only)
          _buildReadOnlyField(
            value: _mobile,
            label: "Mobile Number",
            icon: Icons.phone_android_outlined,
          ),

          // Save Button – only when changes exist, inside the card below mobile
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _hasChanges
                ? Column(
                    children: [
                      _divider(),
                      _buildInlineSaveButton(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: _softGrey, indent: 18, endIndent: 18);

  // ── Editable Field ────────────────────────────────────────────
  Widget _buildEditableField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required bool isEditing,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onEditToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isEditing ? _softGrey : _white,
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(18) : Radius.zero,
          topRight: isFirst ? const Radius.circular(18) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(18) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(18) : Radius.zero,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isEditing ? _black : _softGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isEditing ? _white : _mediumGrey, size: 19),
            ),
            const SizedBox(width: 13),

            // Label + Input
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _mediumGrey,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 1),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: isEditing,
                    keyboardType: keyboardType,
                    style: TextStyle(
                      fontSize: 15,
                      color: isEditing ? _black : _darkGrey,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                      filled: false,
                    ),
                    cursorColor: _black,
                  ),
                ],
              ),
            ),

            // Edit / Done toggle button
            GestureDetector(
              onTap: onEditToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isEditing ? _black : _softGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEditing ? Icons.check_rounded : Icons.edit_outlined,
                  color: isEditing ? _white : _mediumGrey,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Read-only Field ───────────────────────────────────────────
  Widget _buildReadOnlyField({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _softGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _lightGrey, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _mediumGrey,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15,
                        color: _lightGrey,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // Lock icon to indicate non-editable
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _softGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: _lightGrey, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Inline Save Button (inside card, below mobile) ────────────
  Widget _buildInlineSaveButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _saving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: _black,
            foregroundColor: _white,
            disabledBackgroundColor: _mediumGrey,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: _white, strokeWidth: 2))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, size: 18),
                    SizedBox(width: 8),
                    Text("Save Changes",
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Address Section ───────────────────────────────────────────
  Widget _addAddressButton() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AddAddressBottomSheet(onAddressAdded: _loadProfile),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.add, color: _white, size: 15),
            SizedBox(width: 4),
            Text("Add New",
                style: TextStyle(
                    color: _white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_addresses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _black.withValues(alpha: 0.05), blurRadius: 10)
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.location_off_outlined, size: 44, color: _lightGrey),
            const SizedBox(height: 10),
            const Text("No addresses saved yet",
                style: TextStyle(color: _mediumGrey, fontSize: 14)),
            const SizedBox(height: 4),
            const Text("Tap 'Add New' to add your address",
                style: TextStyle(color: _lightGrey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _addresses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final addr = _addresses[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _black.withValues(alpha: 0.05), blurRadius: 10)
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _softGrey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_outlined, color: _darkGrey, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${addr['doorNumber']}, ${addr['street']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _black),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${addr['city']}, ${addr['state']} - ${addr['zipcode']}",
                      style: const TextStyle(color: _mediumGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Logout ────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout_rounded, color: _darkGrey, size: 20),
        label: const Text("Logout",
            style: TextStyle(
                color: _darkGrey, fontSize: 15, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _lightGrey, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: _white,
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────
  Widget _sectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _mediumGrey,
          letterSpacing: 0.8),
    );
  }
}
