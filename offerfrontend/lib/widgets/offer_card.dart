import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final VoidCallback? onTap;

  const OfferCard({super.key, required this.offer, this.onTap});

  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _softGrey = Color(0xFFF4F4F6);
  static const Color _white = Color(0xFFFFFFFF);

  Uint8List? _getFirstPhoto() {
    final raw = offer['photosBase64'] as String?;
    if (raw == null || raw.isEmpty) return null;
    final first = raw.split('|').firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (first.isEmpty) return null;
    try {
      return base64Decode(first);
    } catch (_) {
      return null;
    }
  }

  int _photoCount() {
    final raw = offer['photosBase64'] as String?;
    if (raw == null || raw.isEmpty) return 0;
    return raw.split('|').where((s) => s.isNotEmpty).length;
  }

  String _discountPercent() {
    final orig = (offer['originalPrice'] as num?)?.toDouble() ?? 0;
    final disc = (offer['discountPrice'] as num?)?.toDouble() ?? 0;
    if (orig <= 0 || disc <= 0 || disc >= orig) return '';
    final pct = ((orig - disc) / orig * 100).round();
    return '$pct% OFF';
  }

  String _validityText() {
    final from = offer['fromDate'];
    final to = offer['toDate'];
    if (from == null && to == null) return '';
    if (from != null && to != null) {
      final f = _shortDate(from.toString());
      final t = _shortDate(to.toString());
      return '$f – $t';
    }
    if (to != null) return 'Until ${_shortDate(to.toString())}';
    return 'From ${_shortDate(from.toString())}';
  }

  String _shortDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month]}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoBytes = _getFirstPhoto();
    final discount = _discountPercent();
    final shopName = offer['shopName'] as String? ?? 'Shop';
    final description = offer['description'] as String? ?? '';
    final originalPrice = (offer['originalPrice'] as num?)?.toDouble();
    final discountPrice = (offer['discountPrice'] as num?)?.toDouble();
    final city = offer['city'] as String? ?? '';
    final category = offer['category'] as String? ?? '';
    final validity = _validityText();
    final photoCount = _photoCount();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo / Image Section ────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: photoBytes != null
                        ? Image.memory(
                            photoBytes,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderImage(),
                          )
                        : _placeholderImage(),
                  ),

                  // Discount badge (top-left)
                  if (discount.isNotEmpty)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF3B37D3)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                  // Photo count badge (top-right)
                  if (photoCount > 1)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.photo_library_outlined,
                                color: Colors.white, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              '$photoCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Category chip (bottom-left)
                  if (category.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: _darkGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Info Section ─────────────────────────────────────────
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shop Name
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _black,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Description
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: _mediumGrey,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (discountPrice != null)
                          Text(
                            '₹${discountPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A8A2E),
                            ),
                          ),
                        if (originalPrice != null &&
                            discountPrice != null &&
                            originalPrice > discountPrice) ...[
                          const SizedBox(width: 5),
                          Text(
                            '₹${originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _mediumGrey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ] else if (originalPrice != null &&
                            discountPrice == null)
                          Text(
                            '₹${originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _black,
                            ),
                          ),
                      ],
                    ),

                    // Validity & City row
                    if (validity.isNotEmpty || city.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (city.isNotEmpty) ...[
                              const Icon(Icons.location_on,
                                  size: 11, color: _mediumGrey),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  city,
                                  style: const TextStyle(
                                      fontSize: 10, color: _mediumGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (validity.isNotEmpty) ...[
                              if (city.isNotEmpty)
                                const Text(' · ',
                                    style: TextStyle(
                                        color: _mediumGrey, fontSize: 10)),
                              Flexible(
                                child: Text(
                                  validity,
                                  style: const TextStyle(
                                      fontSize: 10, color: _mediumGrey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── View Offer Button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _black,
                    foregroundColor: _white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: onTap,
                  child: const Text(
                    'View Offer',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_rounded,
                size: 34, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text('No Photo',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}