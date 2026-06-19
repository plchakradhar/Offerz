import 'package:flutter/material.dart';
import '../../services/offer_service.dart';
import '../../widgets/offer_card.dart';
import 'offer_detail_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<dynamic> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllOffers();
  }

  Future<void> _loadAllOffers() async {
    setState(() => _isLoading = true);
    final offers = await OfferService.getOffersByLocation("All");
    setState(() {
      _offers = offers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Offers',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFB300)))
          : _offers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No offers available',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFFB300),
                  onRefresh: _loadAllOffers,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
                    itemCount: _offers.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final offer = _offers[index];
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
    );
  }
}
