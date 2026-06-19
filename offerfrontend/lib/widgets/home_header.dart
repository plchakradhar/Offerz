import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/auth/login_bottomsheet.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/home/location_picker_screen.dart';
import '../screens/watchlist/watchlist_screen.dart';

class HomeHeader extends StatefulWidget {
  final Function? onLoginSuccess;
  final Function(String)? onLocationChanged;
  final Function(String)? onCategoryChanged;

  const HomeHeader({
    super.key,
    this.onLoginSuccess,
    this.onLocationChanged,
    this.onCategoryChanged,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with TickerProviderStateMixin {
  String _location = "Detecting...";
  bool _isLoggedIn = false;
  String _userName = "";
  String _avatarUrl = "";
  String _selectedCategory = "All";

  late AnimationController _entryController;
  late AnimationController _categoryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _amber = Color(0xFFFFB300);
  static const _amberDark = Color(0xFFFF8F00);

  static const List<Map<String, dynamic>> _categories = [
    {"label": "All",         "icon": Icons.apps_rounded},
    {"label": "Restaurant",  "icon": Icons.restaurant_rounded},
    {"label": "Grocery",     "icon": Icons.local_grocery_store_rounded},
    {"label": "Electronics", "icon": Icons.electrical_services_rounded},
    {"label": "Clothes",     "icon": Icons.checkroom_rounded},
    {"label": "Mobiles",     "icon": Icons.smartphone_rounded},
    {"label": "Wellness",    "icon": Icons.spa_rounded},
    {"label": "Offers",      "icon": Icons.local_offer_rounded},
  ];

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _categoryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _entryController.forward();
    _loadUserAndLocation();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndLocation() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    if (_isLoggedIn) {
      _userName = await AuthService.getUserName();
      _avatarUrl = await ProfileService.getAvatar();
      if (mounted) setState(() {});
    }
    final city = await LocationService.getCurrentCity();
    if (mounted) {
      setState(() {
        _location = city.startsWith("Lat:") ? "Unknown" : city;
      });
    }
  }

  void _onLoginSuccess() {
    setState(() => _isLoggedIn = true);
    AuthService.getUserName().then((n) => setState(() => _userName = n));
    ProfileService.getAvatar().then((a) => setState(() => _avatarUrl = a));
    widget.onLoginSuccess?.call();
  }

  Future<void> _openLocationPicker() async {
    HapticFeedback.lightImpact();
    final city = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(currentLocation: _location),
      ),
    );
    if (city != null && city.isNotEmpty && mounted) {
      setState(() => _location = city);
      widget.onLocationChanged?.call(city);
    }
  }

  void _selectCategory(String label, int index) {
    if (_selectedCategory == label) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = label);
    widget.onCategoryChanged?.call(label);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: _buildHeader(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFFCA28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26FFB300),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Row: Location + Action Icons ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 10, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Location tap area
                  Expanded(child: _buildLocationRow()),
                  const SizedBox(width: 6),
                  _buildIconBtn(
                    icon: Icons.bookmark_outline_rounded,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WatchlistScreen())),
                  ),
                  const SizedBox(width: 4),
                  _buildIconBtn(
                    icon: Icons.favorite_outline_rounded,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const WatchlistScreen())),
                  ),
                  const SizedBox(width: 4),
                  _buildAvatar(),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Search Bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildSearchBar(),
            ),

            const SizedBox(height: 10),

            // ── Category Chips ───────────────────────────────────────
            _buildCategoryRow(),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Location Row ──────────────────────────────────────────────────────────
  Widget _buildLocationRow() {
    return GestureDetector(
      onTap: _openLocationPicker,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_rounded, size: 15, color: Colors.black87),
          const SizedBox(width: 3),
          Flexible(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: "Deliver to  ",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: _location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.expand_more_rounded, size: 16, color: Colors.black87),
        ],
      ),
    );
  }

  // ── Icon Button ───────────────────────────────────────────────────────────
  Widget _buildIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: Colors.black87),
      ),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        if (_isLoggedIn) {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          _isLoggedIn = await AuthService.isLoggedIn();
          if (_isLoggedIn) {
            _userName = await AuthService.getUserName();
            _avatarUrl = await ProfileService.getAvatar();
          }
          if (mounted) setState(() {});
        } else {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => LoginBottomSheet(onSuccess: _onLoginSuccess),
          );
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: _isLoggedIn
              ? (_avatarUrl.isNotEmpty
                  ? Image.network(_avatarUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarInitial())
                  : _avatarInitial())
              : const Icon(Icons.person_rounded, size: 17, color: Colors.black54),
        ),
      ),
    );
  }

  Widget _avatarInitial() {
    return Container(
      color: const Color(0xFFFFF3E0),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : "U",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _amberDark,
          ),
        ),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        decoration: InputDecoration(
          hintText: "Search offers, shops & more...",
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12.5,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: _amber, size: 18),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _amber,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 14),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          isDense: true,
        ),
      ),
    );
  }

  // ── Category Chips ────────────────────────────────────────────────────────
  Widget _buildCategoryRow() {
    return SizedBox(
      height: 62,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = _selectedCategory == label;

          return GestureDetector(
            onTap: () => _selectCategory(label, index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 58,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: _amberDark, width: 1.5)
                    : Border.all(color: Colors.transparent),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _amberDark.withValues(alpha: 0.22),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? _amberDark : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? _amberDark : Colors.black54,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}