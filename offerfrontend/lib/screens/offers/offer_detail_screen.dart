import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class OfferDetailScreen extends StatefulWidget {
  final Map<String, dynamic> offer;
  const OfferDetailScreen({super.key, required this.offer});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF4F4F6);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _accentGreen = Color(0xFF1A8A2E);

  int _currentPhotoIndex = 0;

  List<Uint8List> _decodePhotos() {
    final raw = widget.offer['photosBase64'] as String?;
    if (raw == null || raw.isEmpty) return [];
    return raw.split('|').where((s) => s.isNotEmpty).map((s) {
      try { return base64Decode(s); } catch (_) { return null; }
    }).whereType<Uint8List>().toList();
  }

  String _discountPercent() {
    final orig = (widget.offer['originalPrice'] as num?)?.toDouble() ?? 0;
    final disc = (widget.offer['discountPrice'] as num?)?.toDouble() ?? 0;
    if (orig <= 0 || disc <= 0 || disc >= orig) return '';
    return '${((orig - disc) / orig * 100).round()}% OFF';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) { return raw; }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _decodePhotos();
    final offer = widget.offer;
    final shopName = offer['shopName'] as String? ?? 'Offer';
    final description = offer['description'] as String? ?? '';
    final originalPrice = (offer['originalPrice'] as num?)?.toDouble();
    final discountPrice = (offer['discountPrice'] as num?)?.toDouble();
    final city = offer['city'] as String? ?? '';
    final address = offer['exactLocationAddress'] as String? ?? '';
    final category = offer['category'] as String? ?? '';
    final fromDate = offer['fromDate'] as String?;
    final toDate = offer['toDate'] as String?;
    final openTime = offer['openingTime'] as String? ?? '';
    final closeTime = offer['closingTime'] as String? ?? '';
    final discount = _discountPercent();

    return Scaffold(
      backgroundColor: _softGrey,
      body: CustomScrollView(
        slivers: [
          // ── Photo Carousel Header ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: _black,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: _white, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: photos.isEmpty
                  ? _heroPlaceholder()
                  : Stack(
                      children: [
                        // Page view
                        PageView.builder(
                          itemCount: photos.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPhotoIndex = i),
                          itemBuilder: (_, i) => Image.memory(
                            photos[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _heroPlaceholder(),
                          ),
                        ),
                        // Dots
                        if (photos.length > 1)
                          Positioned(
                            bottom: 14,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                photos.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentPhotoIndex == i ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentPhotoIndex == i
                                        ? _white
                                        : _white.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Discount badge
                        if (discount.isNotEmpty)
                          Positioned(
                            top: 60,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF3B37D3)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Text(
                                discount,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Photo counter
                        if (photos.length > 1)
                          Positioned(
                            top: 60,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.photo_library_outlined,
                                      color: _white, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_currentPhotoIndex + 1}/${photos.length}',
                                    style: const TextStyle(
                                        color: _white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _black,
                              ),
                            ),
                            if (category.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _black.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _darkGrey,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Price block
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (discountPrice != null)
                            Text(
                              '₹${discountPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: _accentGreen,
                              ),
                            ),
                          if (originalPrice != null &&
                              discountPrice != null &&
                              originalPrice > discountPrice)
                            Text(
                              '₹${originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _mediumGrey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            )
                          else if (originalPrice != null && discountPrice == null)
                            Text(
                              '₹${originalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: _black,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // ── Description ────────────────────────────────────
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('About this Offer'),
                    const SizedBox(height: 8),
                    _infoBox(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _darkGrey,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],

                  // ── Validity ────────────────────────────────────────
                  if (fromDate != null || toDate != null) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Validity'),
                    const SizedBox(height: 8),
                    _infoBox(
                      child: Row(
                        children: [
                          _validityItem(
                              Icons.calendar_today_outlined,
                              'From',
                              _formatDate(fromDate)),
                          const SizedBox(width: 20),
                          _validityItem(
                              Icons.event_outlined, 'Until', _formatDate(toDate)),
                        ],
                      ),
                    ),
                  ],

                  // ── Timings ────────────────────────────────────────
                  if (openTime.isNotEmpty || closeTime.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Shop Timings'),
                    const SizedBox(height: 8),
                    _infoBox(
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 18, color: _mediumGrey),
                          const SizedBox(width: 10),
                          Text(
                            [
                              if (openTime.isNotEmpty) openTime,
                              if (closeTime.isNotEmpty) closeTime,
                            ].join(' – '),
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _darkGrey),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Location ────────────────────────────────────────
                  if (address.isNotEmpty || city.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _sectionTitle('Location'),
                    const SizedBox(height: 8),
                    _infoBox(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on,
                                size: 18, color: Colors.redAccent),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (address.isNotEmpty)
                                  Text(
                                    address,
                                    style: const TextStyle(
                                        fontSize: 14, color: _darkGrey),
                                  ),
                                if (city.isNotEmpty)
                                  Text(
                                    city,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: _mediumGrey,
                                        fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _mediumGrey,
          letterSpacing: 1.1,
        ),
      );

  Widget _infoBox({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _black.withValues(alpha: 0.05),
              blurRadius: 10,
            )
          ],
        ),
        child: child,
      );

  Widget _validityItem(IconData icon, String label, String value) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _softGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _mediumGrey),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 10, color: _mediumGrey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _black)),
            ],
          ),
        ],
      );

  Widget _heroPlaceholder() => Container(
        color: const Color(0xFFE8E8E8),
        child: const Center(
          child: Icon(Icons.local_offer_rounded,
              size: 60, color: Color(0xFFBBBBBB)),
        ),
      );
}
