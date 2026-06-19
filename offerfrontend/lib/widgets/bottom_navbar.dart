import 'package:flutter/material.dart';
import '../screens/business/business_dashboard_screen.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isBusinessOwner;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isBusinessOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home_rounded),
        label: "Home",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.local_offer_outlined),
        activeIcon: Icon(Icons.local_offer),
        label: "Offers",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.redeem_outlined),
        activeIcon: Icon(Icons.redeem),
        label: "Redeem",
      ),
      if (isBusinessOwner)
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          activeIcon: Icon(Icons.storefront),
          label: "Dashboard",
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex.clamp(0, items.length - 1),
        onTap: (index) {
          // If business owner taps Dashboard tab (index 3), navigate directly
          if (isBusinessOwner && index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
            );
          } else {
            onTap(index);
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFB300),
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: items,
      ),
    );
  }
}