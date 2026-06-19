import 'package:flutter/material.dart';
import '../../widgets/home_header.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/bottom_navbar.dart';
import '../../services/auth_service.dart';
import '../../services/business_service.dart';
import '../../services/offer_service.dart';
import '../../services/location_service.dart';
import '../offers/offer_detail_screen.dart';
import '../offers/offers_screen.dart';
import '../redeem/redeem_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isBusinessVerified = false;

  @override
  void initState() {
    super.initState();
    _checkBusinessStatus();
  }

  Future<void> _checkBusinessStatus() async {
    bool isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      String mobile = await AuthService.getUserMobile();
      if (mobile.isNotEmpty) {
        final res = await BusinessService.getStatus(mobile);
        if (res['success'] && res['data']['status'] == 'VERIFIED') {
          if (mounted) setState(() => _isBusinessVerified = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeBody(
        onLoginSuccess: _checkBusinessStatus,
        isBusinessVerified: _isBusinessVerified,
      ),
      const OffersScreen(),
      const RedeemScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        isBusinessOwner: _isBusinessVerified,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ─────────────────────────────── HOME BODY ──────────────────────────────────

class HomeBody extends StatefulWidget {
  final Function? onLoginSuccess;
  final bool isBusinessVerified;
  const HomeBody({super.key, this.onLoginSuccess, this.isBusinessVerified = false});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  List<dynamic> _offers = [];
  bool _isLoadingOffers = true;
  String _currentCity = "";
  String _selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadLocationAndOffers();
  }

  Future<void> _loadLocationAndOffers() async {
    String city = await LocationService.getCurrentCity();
    if (city.startsWith("Lat:")) city = "All";
    setState(() => _currentCity = city);
    _fetchOffers(city);
  }

  Future<void> _fetchOffers(String city) async {
    setState(() => _isLoadingOffers = true);
    final offers = await OfferService.getOffersByLocation(city);
    setState(() {
      _offers = offers;
      _isLoadingOffers = false;
    });
  }

  void _onCategoryChanged(String category) {
    setState(() => _selectedCategory = category);
    // Filter locally or re-fetch with category param if backend supports it
  }

  List<dynamic> get _filteredOffers {
    if (_selectedCategory == "All") return _offers;
    return _offers.where((o) {
      final cat = (o['category'] as String? ?? '').toLowerCase();
      return cat.contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: Column(
        children: [
          HomeHeader(
            onLoginSuccess: () {
              widget.onLoginSuccess?.call();
              _loadLocationAndOffers();
            },
            onLocationChanged: (newCity) {
              setState(() => _currentCity = newCity);
              _fetchOffers(newCity);
            },
            onCategoryChanged: _onCategoryChanged,
          ),
          Expanded(
            child: _isLoadingOffers
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFB300)),
                  )
                : _filteredOffers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: const Color(0xFFFFB300),
                        onRefresh: _loadLocationAndOffers,
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                          itemCount: _filteredOffers.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final offer = _filteredOffers[index];
                            return OfferCard(
                              offer: offer,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => OfferDetailScreen(offer: offer)),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No offers in $_currentCity",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later or try a different location",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}