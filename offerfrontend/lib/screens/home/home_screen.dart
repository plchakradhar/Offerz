import 'package:flutter/material.dart';
import '../../widgets/home_header.dart';
import '../../widgets/category_section.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/bottom_navbar.dart';
import '../../services/auth_service.dart';
import '../../services/business_service.dart';
import '../../services/offer_service.dart';
import '../../services/location_service.dart';
import '../business/business_dashboard_screen.dart';
import '../offers/offer_detail_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const HomeBody(),
      const OffersScreen(),
      const RedeemScreen(),
      const WatchlistScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  bool _isBusinessVerified = false;
  List<dynamic> _offers = [];
  bool _isLoadingOffers = true;
  String _currentCity = "";

  @override
  void initState() {
    super.initState();
    _checkBusinessStatus();
    _loadLocationAndOffers();
  }

  Future<void> _checkBusinessStatus() async {
    bool isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      // Get user mobile from SharedPreferences (we need a method for this, or just parse status)
      // Actually, AuthService has _userMobileKey but no public getter. 
      // I should update AuthService to get mobile. For now let's assume we can add getMobile()
      // I'll update auth_service.dart as well if needed. Let's use getMobile.
      String mobile = await AuthService.getUserMobile();
      if (mobile.isNotEmpty) {
        final res = await BusinessService.getStatus(mobile);
        if (res['success'] && res['data']['status'] == 'VERIFIED') {
          setState(() {
            _isBusinessVerified = true;
          });
        }
      }
    }
  }

  Future<void> _loadLocationAndOffers() async {
    String city = await LocationService.getCurrentCity();
    if (city.startsWith("Lat:")) {
      city = "All"; // Default or unknown
    }
    setState(() {
      _currentCity = city;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(onLoginSuccess: () {
              _checkBusinessStatus();
              _loadLocationAndOffers();
            }, onLocationChanged: (newCity) {
              _fetchOffers(newCity);
            }),
            if (_isBusinessVerified)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.storefront, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text("Open Business Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()));
                      },
                      child: const Text("Go to Dashboard"),
                    )
                  ],
                ),
              ),
            const CategorySection(),
            Expanded(
              child: _isLoadingOffers
                  ? const Center(child: CircularProgressIndicator())
                  : _offers.isEmpty
                      ? const Center(child: Text("No offers found in your location."))
                      : GridView.builder(
                          padding: const EdgeInsets.all(15),
                          itemCount: _offers.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.62,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final offer = _offers[index];
                            return OfferCard(
                              offer: offer,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OfferDetailScreen(offer: offer),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stub screens
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Offers Screen"));
}
class RedeemScreen extends StatelessWidget {
  const RedeemScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Redeem Screen"));
}
class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text("Watchlist Screen"));
}