import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/offer_service.dart';
import 'business_request_detail_screen.dart';
import 'admin_offer_detail_screen.dart';
import '../business/add_edit_offer_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF2F2F2);
  static const Color _white = Color(0xFFFFFFFF);

  int _tabIndex = 0;
  bool _loadingUsers = true;
  bool _loadingRequests = true;
  bool _loadingOffers = true;

  List<dynamic> _users = [];
  List<dynamic> _requests = [];
  List<dynamic> _offers = [];
  String _requestFilter = 'ALL';
  String _offerSearch = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingUsers = true;
      _loadingRequests = true;
      _loadingOffers = true;
    });
    final users = await AdminService.getAllUsers();
    final requests = await AdminService.getAllRequests();
    final offers = await OfferService.getAllOffers();
    if (!mounted) return;
    setState(() {
      _users = users;
      _requests = requests;
      _offers = offers;
      _loadingUsers = false;
      _loadingRequests = false;
      _loadingOffers = false;
    });
  }

  List<dynamic> get _filteredRequests {
    if (_requestFilter == 'ALL') return _requests;
    return _requests.where((r) => r['status'] == _requestFilter).toList();
  }

  List<dynamic> get _filteredOffers {
    if (_offerSearch.isEmpty) return _offers;
    final q = _offerSearch.toLowerCase();
    return _offers.where((o) {
      final shop = (o['shopName'] as String? ?? '').toLowerCase();
      final city = (o['city'] as String? ?? '').toLowerCase();
      final cat = (o['category'] as String? ?? '').toLowerCase();
      return shop.contains(q) || city.contains(q) || cat.contains(q);
    }).toList();
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  int get _pendingCount =>
      _requests.where((r) => r['status'] == 'PENDING').length;
  int get _verifiedCount =>
      _requests.where((r) => r['status'] == 'VERIFIED').length;
  int get _rejectedCount =>
      _requests.where((r) => r['status'] == 'REJECTED').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
      body: Column(
        children: [
          _buildTopBar(),
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: _black,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Dashboard',
                    style: TextStyle(
                        color: _white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('Offerz Management Portal',
                    style:
                        TextStyle(color: Color(0xFF888888), fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _white),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: Color(0xFF888888)),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/admin'),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Overview', 'Users', 'Requests', 'Offers'];
    final icons = [
      Icons.dashboard_outlined,
      Icons.people_outline,
      Icons.business_outlined,
      Icons.local_offer_outlined,
    ];
    return Container(
      color: _black,
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 8),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(icons[i],
                        color: sel ? _black : const Color(0xFF666666),
                        size: 18),
                    const SizedBox(height: 3),
                    Text(tabs[i],
                        style: TextStyle(
                          color: sel
                              ? _black
                              : const Color(0xFF666666),
                          fontSize: 10,
                          fontWeight: sel
                              ? FontWeight.bold
                              : FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab Content ───────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildRequestsTab();
      case 3:
        return _buildOffersTab();
      default:
        return const SizedBox();
    }
  }

  // ── Overview Tab ──────────────────────────────────────────────────────────
  Widget _buildOverview() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _black,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('Summary',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _black)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _statCard('Total Users', _users.length.toString(),
                  Icons.people_outline, _black),
              _statCard('Total Offers', _offers.length.toString(),
                  Icons.local_offer_outlined, const Color(0xFF6C63FF)),
              _statCard('Pending', _pendingCount.toString(),
                  Icons.hourglass_top_rounded, _darkGrey),
              _statCard('Verified', _verifiedCount.toString(),
                  Icons.verified_rounded, _black),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent Business Requests',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _black)),
          const SizedBox(height: 12),
          if (_loadingRequests)
            const Center(
                child: CircularProgressIndicator(color: _black))
          else if (_requests.isEmpty)
            _emptyState('No business requests yet')
          else
            ..._requests.take(5).map((r) => _requestCard(r)),
          const SizedBox(height: 24),
          const Text('Recent Offers',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _black)),
          const SizedBox(height: 12),
          if (_loadingOffers)
            const Center(
                child: CircularProgressIndicator(color: _black))
          else if (_offers.isEmpty)
            _emptyState('No offers posted yet')
          else
            ..._offers.take(5).map((o) => _offerCard(o)),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: _black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: _white.withValues(alpha: 0.7), size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: _white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1)),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      color: _white.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Users Tab ─────────────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    if (_loadingUsers)
      return const Center(child: CircularProgressIndicator(color: _black));
    if (_users.isEmpty) return _emptyState('No registered users yet');
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: _black,
      child: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _userCard(_users[i]),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user) {
    final name = user['fullName'] ?? 'Unknown';
    final mobile = user['mobileNumber'] ?? '';
    final email = user['email'] ?? '—';
    final avatar = user['avatarUrl'] as String?;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _softGrey,
            backgroundImage: (avatar != null && avatar.isNotEmpty)
                ? NetworkImage(avatar)
                : null,
            child: (avatar == null || avatar.isEmpty)
                ? Text(initials,
                    style: const TextStyle(
                        color: _black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _black)),
                const SizedBox(height: 2),
                Text(mobile,
                    style: const TextStyle(
                        fontSize: 13, color: _mediumGrey)),
                if (email != '—')
                  Text(email,
                      style: const TextStyle(
                          fontSize: 11, color: _lightGrey)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _softGrey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('#${user['id']}',
                style: const TextStyle(
                    fontSize: 11,
                    color: _mediumGrey,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Requests Tab ──────────────────────────────────────────────────────────
  Widget _buildRequestsTab() {
    return Column(
      children: [
        Container(
          color: _white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['ALL', 'PENDING', 'VERIFIED', 'REJECTED'].map((f) {
                final sel = _requestFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _requestFilter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? _black : _softGrey,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(f,
                          style: TextStyle(
                              color: sel ? _white : _mediumGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: _loadingRequests
              ? const Center(
                  child: CircularProgressIndicator(color: _black))
              : _filteredRequests.isEmpty
                  ? _emptyState(
                      'No ${_requestFilter == 'ALL' ? '' : _requestFilter.toLowerCase()} requests')
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: _black,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(18),
                        itemCount: _filteredRequests.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _requestCard(_filteredRequests[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _requestCard(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? 'PENDING';
    final statusColor = status == 'VERIFIED'
        ? _black
        : status == 'REJECTED'
            ? _mediumGrey
            : _darkGrey;
    final statusIcon = status == 'VERIFIED'
        ? Icons.verified_rounded
        : status == 'REJECTED'
            ? Icons.cancel_outlined
            : Icons.hourglass_top_rounded;

    return GestureDetector(
      onTap: () async {
        final refreshed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessRequestDetailScreen(
                request: Map<String, dynamic>.from(req)),
          ),
        );
        if (refreshed == true) _loadAll();
      },
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: _black.withValues(alpha: 0.05), blurRadius: 10)
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: _softGrey,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.storefront_outlined,
                      color: _darkGrey, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(req['businessName'] ?? 'Unnamed Business',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _black)),
                      Text(req['mobileNumber'] ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: _mediumGrey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            if (req['businessType'] != null) ...[
              const SizedBox(height: 8),
              Text(
                  '${req['businessType']} · ${req['businessCity'] ?? ''}',
                  style: const TextStyle(
                      fontSize: 12, color: _mediumGrey)),
            ],
            if (req['adminRemark'] != null &&
                req['adminRemark'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _softGrey,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('Remark: ${req['adminRemark']}',
                    style: const TextStyle(
                        fontSize: 11, color: _mediumGrey)),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                Text('Tap to review →',
                    style: TextStyle(
                        fontSize: 11,
                        color: _lightGrey,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Offers Tab ────────────────────────────────────────────────────────────
  Widget _buildOffersTab() {
    return Column(
      children: [
        // Search bar
        Container(
          color: _white,
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: TextField(
            onChanged: (val) => setState(() => _offerSearch = val),
            decoration: InputDecoration(
              hintText: 'Search offers by shop, city, category...',
              hintStyle:
                  const TextStyle(fontSize: 13, color: _lightGrey),
              prefixIcon: const Icon(Icons.search, color: _mediumGrey),
              filled: true,
              fillColor: _softGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        // Count bar
        Container(
          color: _softGrey,
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_filteredOffers.length} offer(s)',
                style: const TextStyle(
                    fontSize: 12,
                    color: _mediumGrey,
                    fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Icon(Icons.sort, size: 16, color: _mediumGrey),
              const SizedBox(width: 4),
              const Text('Newest first',
                  style: TextStyle(fontSize: 11, color: _mediumGrey)),
            ],
          ),
        ),
        // List
        Expanded(
          child: _loadingOffers
              ? const Center(
                  child: CircularProgressIndicator(color: _black))
              : _filteredOffers.isEmpty
                  ? _emptyState('No offers found')
                  : RefreshIndicator(
                      onRefresh: _loadAll,
                      color: _black,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(18),
                        itemCount: _filteredOffers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _offerCard(_filteredOffers[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _offerCard(Map<String, dynamic> offer) {
    // Decode first photo thumbnail
    Uint8List? thumbBytes;
    final photosRaw = offer['photosBase64'] as String?;
    if (photosRaw != null && photosRaw.isNotEmpty) {
      final first = photosRaw.split('|').firstWhere(
          (s) => s.isNotEmpty,
          orElse: () => '');
      if (first.isNotEmpty) {
        try {
          thumbBytes = base64Decode(first);
        } catch (_) {}
      }
    }

    final photoCount = photosRaw == null || photosRaw.isEmpty
        ? 0
        : photosRaw.split('|').where((s) => s.isNotEmpty).length;

    final origPrice =
        (offer['originalPrice'] as num?)?.toDouble();
    final discPrice =
        (offer['discountPrice'] as num?)?.toDouble();

    String discountLabel = '';
    if (origPrice != null && discPrice != null && origPrice > discPrice) {
      discountLabel =
          '${((origPrice - discPrice) / origPrice * 100).round()}% OFF';
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminOfferDetailScreen(
                offer: Map<String, dynamic>.from(offer)),
          ),
        );
        if (result != null) _loadAll();
      },
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: _black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(18)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: thumbBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(thumbBytes, fit: BoxFit.cover),
                          if (photoCount > 1)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('+${photoCount - 1}',
                                    style: const TextStyle(
                                        color: _white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                        ],
                      )
                    : Container(
                        color: _softGrey,
                        child: const Center(
                          child: Icon(Icons.local_offer_outlined,
                              color: Color(0xFFBBBBBB), size: 28),
                        ),
                      ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer['shopName'] ?? 'Unnamed Shop',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _black),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (discountLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              discountLabel,
                              style: const TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 11, color: _mediumGrey),
                        const SizedBox(width: 3),
                        Text(
                          offer['businessMobileNumber'] ?? '',
                          style: const TextStyle(
                              fontSize: 11, color: _mediumGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (origPrice != null)
                          Text(
                            '₹${origPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: _mediumGrey,
                                decoration: discPrice != null
                                    ? TextDecoration.lineThrough
                                    : null),
                          ),
                        if (discPrice != null) ...[
                          const SizedBox(width: 5),
                          Text(
                            '₹${discPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A8A2E)),
                          ),
                        ],
                        const Spacer(),
                        if ((offer['category'] as String? ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _softGrey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              offer['category'] ?? '',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: _mediumGrey,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    if ((offer['city'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 11, color: Colors.redAccent),
                          const SizedBox(width: 3),
                          Text(
                            offer['city'] ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: _mediumGrey),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions column
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _offerActionBtn(
                    icon: Icons.visibility_outlined,
                    color: _black,
                    onTap: () async {
                      final result = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminOfferDetailScreen(
                              offer: Map<String, dynamic>.from(offer)),
                        ),
                      );
                      if (result != null) _loadAll();
                    },
                  ),
                  const SizedBox(height: 6),
                  _offerActionBtn(
                    icon: Icons.edit_outlined,
                    color: const Color(0xFF1565C0),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditOfferScreen(offer: offer),
                        ),
                      );
                      if (result == true) _loadAll();
                    },
                  ),
                  const SizedBox(height: 6),
                  _offerActionBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red.shade700,
                    onTap: () => _confirmDeleteOffer(offer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offerActionBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Future<void> _confirmDeleteOffer(
      Map<String, dynamic> offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Offer',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: _black)),
        content: Text(
          'Delete "${offer['shopName'] ?? 'this offer'}"? This cannot be undone.',
          style: const TextStyle(color: _mediumGrey),
        ),
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
    if (confirm != true || !mounted) return;
    final res = await OfferService.deleteOffer(offer['id']);
    if (!mounted) return;
    if (res['success']) {
      _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✓ Offer deleted'),
        backgroundColor: _black,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Failed to delete'),
        backgroundColor: _darkGrey,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _emptyState(String msg) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: _lightGrey),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(
                    color: _mediumGrey, fontSize: 15)),
          ],
        ),
      );
}
