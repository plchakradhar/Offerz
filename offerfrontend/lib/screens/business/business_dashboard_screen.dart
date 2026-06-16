import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/offer_service.dart';
import '../../services/business_service.dart';
import '../../services/auth_service.dart';
import 'add_edit_offer_screen.dart';
import '../offers/offer_detail_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF4F4F6);
  static const Color _white = Color(0xFFFFFFFF);

  late TabController _tabController;
  List<dynamic> _offers = [];
  bool _isLoading = true;
  String _mobile = '';
  String _currentPlan = 'BASIC';
  bool _isLoadingPlan = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _mobile = await AuthService.getUserMobile();
    if (_mobile.isNotEmpty) {
      final statusRes = await BusinessService.getStatus(_mobile);
      if (statusRes['success']) {
        setState(() {
          _currentPlan =
              statusRes['data']['subscriptionPlan'] ?? 'BASIC';
        });
      }
      await _fetchOffers();
    }
  }

  Future<void> _fetchOffers() async {
    setState(() => _isLoading = true);
    final offers = await OfferService.getOffersByBusiness(_mobile);
    setState(() {
      _offers = offers;
      _isLoading = false;
    });
  }

  Future<void> _updatePlan(String plan) async {
    setState(() => _isLoadingPlan = true);
    final res = await BusinessService.updateSubscription(_mobile, plan);
    if (res['success']) {
      setState(() => _currentPlan = plan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan updated to $plan'),
            backgroundColor: _black,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'])),
        );
      }
    }
    setState(() => _isLoadingPlan = false);
  }

  Future<void> _deleteOffer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Offer',
            style: TextStyle(fontWeight: FontWeight.bold, color: _black)),
        content: const Text(
            'Are you sure you want to delete this offer?',
            style: TextStyle(color: _mediumGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _mediumGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: _white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final res = await OfferService.deleteOffer(id);
      if (res['success']) {
        _fetchOffers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('✓ Offer deleted'),
            backgroundColor: _black,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(res['message'])));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
      appBar: AppBar(
        backgroundColor: _black,
        title: const Text('Business Dashboard',
            style: TextStyle(color: _white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: _white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _white,
          labelColor: _white,
          unselectedLabelColor: const Color(0xFF888888),
          tabs: const [
            Tab(text: 'My Offers'),
            Tab(text: 'Subscription'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOffersTab(),
          _buildSubscriptionTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: _black,
              foregroundColor: _white,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddEditOfferScreen()),
                );
                if (result == true) _fetchOffers();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Offer',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // ── My Offers Tab ─────────────────────────────────────────────────────────
  Widget _buildOffersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_offers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchOffers,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 64, color: _lightGrey),
                  const SizedBox(height: 16),
                  const Text("No offers yet",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _darkGrey)),
                  const SizedBox(height: 8),
                  const Text("Tap + Add Offer to create your first offer",
                      style: TextStyle(fontSize: 13, color: _mediumGrey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchOffers,
      color: _black,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return _buildOfferCard(offer);
        },
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    // Decode thumbnail
    Uint8List? thumbBytes;
    final photosRaw = offer['photosBase64'] as String?;
    if (photosRaw != null && photosRaw.isNotEmpty) {
      final first = photosRaw
          .split('|')
          .firstWhere((s) => s.isNotEmpty, orElse: () => '');
      if (first.isNotEmpty) {
        try { thumbBytes = base64Decode(first); } catch (_) {}
      }
    }
    final photoCount = photosRaw == null || photosRaw.isEmpty
        ? 0
        : photosRaw.split('|').where((s) => s.isNotEmpty).length;

    final origPrice = (offer['originalPrice'] as num?)?.toDouble();
    final discPrice = (offer['discountPrice'] as num?)?.toDouble();

    String discountLabel = '';
    if (origPrice != null && discPrice != null && origPrice > discPrice) {
      discountLabel =
          '${((origPrice - discPrice) / origPrice * 100).round()}% OFF';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo banner
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: thumbBytes != null
                      ? Image.memory(thumbBytes, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder())
                      : _photoPlaceholder(),
                ),
                // Discount badge
                if (discountLabel.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF3B37D3)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF)
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Text(discountLabel,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                // Photo count
                if (photoCount > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.photo_library_outlined,
                              color: _white, size: 12),
                          const SizedBox(width: 3),
                          Text('$photoCount',
                              style: const TextStyle(
                                  color: _white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                // Category chip
                if ((offer['category'] as String? ?? '').isNotEmpty)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(offer['category'] ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _darkGrey)),
                    ),
                  ),
              ],
            ),
          ),

          // Info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop name + actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        offer['shopName'] ?? '',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _black),
                      ),
                    ),
                    // Edit & Delete menu
                    PopupMenuButton<String>(
                      onSelected: (val) async {
                        if (val == 'edit') {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    AddEditOfferScreen(offer: offer)),
                          );
                          if (result == true) _fetchOffers();
                        } else if (val == 'view') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OfferDetailScreen(offer: offer),
                            ),
                          );
                        } else if (val == 'delete') {
                          _deleteOffer(offer['id']);
                        }
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(children: [
                            Icon(Icons.visibility_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('View Offer'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline,
                                size: 16, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(
                                    color: Colors.red.shade700)),
                          ]),
                        ),
                      ],
                      icon: const Icon(Icons.more_vert, color: _mediumGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Description
                if ((offer['description'] as String? ?? '').isNotEmpty)
                  Text(
                    offer['description'],
                    style: const TextStyle(
                        fontSize: 13, color: _mediumGrey, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 10),

                // Price row
                Row(
                  children: [
                    if (discPrice != null)
                      Text(
                        '₹${discPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A8A2E)),
                      ),
                    if (origPrice != null &&
                        discPrice != null &&
                        origPrice > discPrice) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${origPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: _mediumGrey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ] else if (origPrice != null && discPrice == null)
                      Text(
                        '₹${origPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _black),
                      ),
                    const Spacer(),
                    // City
                    if ((offer['city'] as String? ?? '').isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 13, color: Colors.redAccent),
                          const SizedBox(width: 3),
                          Text(offer['city'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: _mediumGrey)),
                        ],
                      ),
                  ],
                ),

                // Validity
                if (offer['fromDate'] != null || offer['toDate'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: _mediumGrey),
                      const SizedBox(width: 4),
                      Text(
                        _validityText(offer),
                        style: const TextStyle(
                            fontSize: 12, color: _mediumGrey),
                      ),
                    ],
                  ),
                ],

                // Hours
                if ((offer['openingTime'] as String? ?? '').isNotEmpty ||
                    (offer['closingTime'] as String? ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 13, color: _mediumGrey),
                      const SizedBox(width: 4),
                      Text(
                        [
                          if ((offer['openingTime'] as String? ?? '')
                              .isNotEmpty)
                            offer['openingTime'],
                          if ((offer['closingTime'] as String? ?? '')
                              .isNotEmpty)
                            offer['closingTime'],
                        ].join(' – '),
                        style: const TextStyle(
                            fontSize: 12, color: _mediumGrey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _validityText(Map<String, dynamic> offer) {
    final from = offer['fromDate'];
    final to = offer['toDate'];
    if (from != null && to != null) {
      return '${_shortDate(from.toString())} – ${_shortDate(to.toString())}';
    }
    if (from != null) return 'From ${_shortDate(from.toString())}';
    if (to != null) return 'Until ${_shortDate(to.toString())}';
    return '';
  }

  String _shortDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = [
        '',
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month]}';
    } catch (_) {
      return raw;
    }
  }

  Widget _photoPlaceholder() => Container(
        color: const Color(0xFFEEEEEE),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined,
                  size: 40, color: Color(0xFFCCCCCC)),
              SizedBox(height: 6),
              Text('No Photo Added',
                  style:
                      TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            ],
          ),
        ),
      );

  // ── Subscription Tab ──────────────────────────────────────────────────────
  Widget _buildSubscriptionTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Choose a Subscription Plan',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _black)),
        const SizedBox(height: 6),
        const Text('Upgrade to post more offers and get better visibility',
            style: TextStyle(fontSize: 13, color: _mediumGrey)),
        const SizedBox(height: 24),
        _buildPlanCard(
          'BASIC',
          'Free',
          ['Up to 5 active offers', 'Standard visibility'],
          const Color(0xFF455A64),
        ),
        _buildPlanCard(
          'PREMIUM',
          '₹999 / month',
          [
            'Up to 50 active offers',
            'Priority visibility',
            'Analytics dashboard'
          ],
          const Color(0xFF1565C0),
        ),
        _buildPlanCard(
          'DIAMOND',
          '₹2499 / month',
          [
            'Unlimited offers',
            'Top tier visibility',
            'Dedicated account manager'
          ],
          const Color(0xFF6A1B9A),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
      String name, String price, List<String> features, Color color) {
    bool isCurrent = _currentPlan == name;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent
            ? Border.all(color: color, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: _black.withValues(alpha: isCurrent ? 0.12 : 0.05),
            blurRadius: isCurrent ? 16 : 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('CURRENT',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(price,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _darkGrey)),
          const SizedBox(height: 14),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 16, color: color),
                    const SizedBox(width: 10),
                    Text(f,
                        style: const TextStyle(
                            fontSize: 13, color: _darkGrey)),
                  ],
                ),
              )),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isCurrent ? _softGrey : color,
                foregroundColor:
                    isCurrent ? _mediumGrey : _white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed:
                  isCurrent || _isLoadingPlan ? null : () => _updatePlan(name),
              child: _isLoadingPlan && _currentPlan != name
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      isCurrent ? 'Current Plan' : 'Upgrade to $name',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
