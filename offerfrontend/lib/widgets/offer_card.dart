import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final VoidCallback? onTap;

  const OfferCard({super.key, required this.offer, this.onTap});

  static const Color _green = Color(0xFF1E9E4F);
  static const Color _black = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _bgGrey = Color(0xFFF5F5F5);

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
    return '${((orig - disc) / orig * 100).round()}% OFF';
  }

  String _validityText() {
    final to = offer['toDate'];
    if (to == null) return '';
    try {
      final d = DateTime.parse(to.toString());
      final now = DateTime.now();
      final diff = d.difference(now).inDays;
      if (diff < 0) return 'Expired';
      if (diff == 0) return 'Ends today';
      if (diff == 1) return 'Ends tomorrow';
      return 'Ends in $diff days';
    } catch (_) {
      return '';
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
    final hasDiscount = originalPrice != null && discountPrice != null && originalPrice > discountPrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo Banner ────────────────────────────────────────
            SizedBox(
              height: 130,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or placeholder
                  photoBytes != null
                      ? Image.memory(photoBytes, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImage())
                      : _placeholderImage(),

                  // Dark gradient at bottom for readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Discount badge (top-left)
                  if (discount.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                  // Photo count (top-right)
                  if (photoCount > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, color: Colors.white, size: 10),
                            const SizedBox(width: 3),
                            Text('$photoCount',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                  // Category chip (bottom-left)
                  if (category.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: _black,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
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

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 11, color: _textGrey, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

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
                              color: _green,
                            ),
                          ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 5),
                          Text(
                            '₹${originalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: _textGrey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ] else if (originalPrice != null && discountPrice == null)
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

                    const SizedBox(height: 4),

                    // City + Validity row
                    Row(
                      children: [
                        if (city.isNotEmpty) ...[
                          const Icon(Icons.location_on_rounded, size: 11, color: Color(0xFFFFB300)),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              city,
                              style: const TextStyle(fontSize: 10, color: _textGrey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (validity.isNotEmpty) ...[
                          if (city.isNotEmpty) const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: validity == 'Expired'
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              validity,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: validity == 'Expired'
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── View Offer Button ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      color: _bgGrey,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_rounded, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text('No Photo', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}