import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/offer_service.dart';
import 'package:flutter/services.dart';
import '../business/add_edit_offer_screen.dart';

class AdminOfferDetailScreen extends StatefulWidget {
  final Map<String, dynamic> offer;
  const AdminOfferDetailScreen({super.key, required this.offer});

  @override
  State<AdminOfferDetailScreen> createState() => _AdminOfferDetailScreenState();
}

class _AdminOfferDetailScreenState extends State<AdminOfferDetailScreen> {
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF2F2F2);
  static const Color _white = Color(0xFFFFFFFF);

  int _currentPhotoIndex = 0;
  bool _deleting = false;

  List<Uint8List> _decodePhotos() {
    final raw = widget.offer['photosBase64'] as String?;
    if (raw == null || raw.isEmpty) return [];
    return raw.split('|').where((s) => s.isNotEmpty).map((s) {
      try { return base64Decode(s); } catch (_) { return null; }
    }).whereType<Uint8List>().toList();
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

  Future<void> _deleteOffer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Offer',
            style: TextStyle(fontWeight: FontWeight.bold, color: _black)),
        content: Text(
          'Delete "${widget.offer['shopName'] ?? 'this offer'}"? This cannot be undone.',
          style: const TextStyle(color: _mediumGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _mediumGrey)),
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
    setState(() => _deleting = true);
    final res = await OfferService.deleteOffer(widget.offer['id']);
    if (!mounted) return;
    setState(() => _deleting = false);
    if (res['success']) {
      Navigator.pop(context, 'deleted');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Failed to delete'),
        backgroundColor: _darkGrey,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = _decodePhotos();
    final offer = widget.offer;

    return Scaffold(
      backgroundColor: _softGrey,
      body: CustomScrollView(
        slivers: [
          // ── Photo carousel header ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: _white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Edit button
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: _white),
                tooltip: 'Edit Offer',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditOfferScreen(offer: offer),
                    ),
                  );
                  if (result == true && mounted) {
                    Navigator.pop(context, 'edited');
                  }
                },
              ),
              // Delete button
              IconButton(
                icon: _deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Delete Offer',
                onPressed: _deleting ? null : _deleteOffer,
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: photos.isEmpty
                  ? Container(
                      color: _darkGrey,
                      child: const Center(
                        child: Icon(Icons.local_offer_rounded,
                            size: 60, color: Color(0xFF555555)),
                      ),
                    )
                  : Stack(
                      children: [
                        PageView.builder(
                          itemCount: photos.length,
                          onPageChanged: (i) =>
                              setState(() => _currentPhotoIndex = i),
                          itemBuilder: (_, i) => Image.memory(
                            photos[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        if (photos.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                photos.length,
                                (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentPhotoIndex == i ? 16 : 6,
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
                        if (photos.length > 1)
                          Positioned(
                            top: 62,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentPhotoIndex + 1}/${photos.length} photos',
                                style: const TextStyle(
                                    color: _white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
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
                  // Shop Name + Price
                  _infoCard([
                    _infoRow('Shop Name', offer['shopName']),
                    _infoRow('Business Mobile', offer['businessMobileNumber']),
                    _infoRow('Category', offer['category']),
                    _divider(),
                    _infoRow('Original Price', offer['originalPrice'] != null
                        ? '₹${offer['originalPrice']}'
                        : null),
                    _infoRow('Discount Price', offer['discountPrice'] != null
                        ? '₹${offer['discountPrice']}'
                        : null),
                  ]),

                  const SizedBox(height: 16),

                  // Description
                  if ((offer['description'] as String? ?? '').isNotEmpty) ...[
                    _sectionLabel('Description'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: _black.withValues(alpha: 0.05),
                              blurRadius: 10)
                        ],
                      ),
                      child: Text(
                        offer['description'] ?? '',
                        style: const TextStyle(
                            fontSize: 14, color: _darkGrey, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Validity & Timings
                  _sectionLabel('Validity & Timings'),
                  const SizedBox(height: 8),
                  _infoCard([
                    _infoRow('From Date', _formatDate(offer['fromDate']?.toString())),
                    _infoRow('To Date', _formatDate(offer['toDate']?.toString())),
                    _divider(),
                    _infoRow('Opening Time', offer['openingTime']),
                    _infoRow('Closing Time', offer['closingTime']),
                  ]),

                  const SizedBox(height: 16),

                  // Location
                  _sectionLabel('Location'),
                  const SizedBox(height: 8),
                  _infoCard([
                    _infoRow('Address', offer['exactLocationAddress']),
                    _infoRow('City', offer['city']),
                  ]),

                  const SizedBox(height: 16),

                  // Meta
                  _sectionLabel('Meta Info'),
                  const SizedBox(height: 8),
                  _infoCard([
                    _infoRow('Offer ID', '#${offer['id']}'),
                    _infoRow('Photos', '${photos.length} photo(s)'),
                    _infoRow('Created At', _formatDate(offer['createdAt']?.toString())),
                    _infoRow('Updated At', _formatDate(offer['updatedAt']?.toString())),
                  ]),

                  const SizedBox(height: 32),

                  // Action buttons at bottom
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleting ? null : _deleteOffer,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete Offer',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditOfferScreen(offer: offer),
                              ),
                            );
                            if (result == true && mounted) {
                              Navigator.pop(context, 'edited');
                            }
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Offer',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _black,
                            foregroundColor: _white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: _mediumGrey,
            letterSpacing: 1.0),
      );

  Widget _infoCard(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 10)
          ],
        ),
        child: Column(children: rows),
      );

  Widget _infoRow(String label, dynamic value) {
    final text = (value == null || value.toString().isEmpty)
        ? '—'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: _mediumGrey,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: _black, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: _softGrey,
        indent: 16,
        endIndent: 16,
      );
}
