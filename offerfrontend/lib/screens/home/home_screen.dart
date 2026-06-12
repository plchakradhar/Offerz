import 'package:flutter/material.dart';
import '../../widgets/home_header.dart';
import '../../widgets/category_section.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/bottom_navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeBody(),
    const OffersScreen(),
    const RedeemScreen(),
    const WatchlistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final offers = [
      {"title": "50% OFF Pizza", "business": "Pizza Hut"},
      {"title": "40% OFF Mobiles", "business": "Reliance Digital"},
      {"title": "Buy 1 Get 1", "business": "Trends"},
      {"title": "30% OFF Electronics", "business": "Croma"},
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(),
            const CategorySection(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: offers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) => OfferCard(
                  title: offers[index]["title"]!,
                  business: offers[index]["business"]!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Stub screens (add similar for offers, redeem, watchlist)
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