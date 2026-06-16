import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class BusinessRequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const BusinessRequestDetailScreen({super.key, required this.request});

  @override
  State<BusinessRequestDetailScreen> createState() => _BusinessRequestDetailScreenState();
}

class _BusinessRequestDetailScreenState extends State<BusinessRequestDetailScreen> {
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF2F2F2);
  static const Color _white = Color(0xFFFFFFFF);

  final _remarkCtrl = TextEditingController();
  bool _actioning = false;

  @override
  void initState() {
    super.initState();
    _remarkCtrl.text = widget.request['adminRemark'] ?? '';
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  String get _status => widget.request['status'] ?? 'PENDING';
  bool get _canAction => _status == 'PENDING';

  Future<void> _action(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          status == 'VERIFIED' ? 'Verify Business?' : 'Reject Request?',
          style: const TextStyle(fontWeight: FontWeight.bold, color: _black),
        ),
        content: Text(
          status == 'VERIFIED'
              ? 'This will mark the business as verified. The user will see a Verified status on their profile.'
              : 'This will reject the registration request.',
          style: const TextStyle(color: _mediumGrey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: _mediumGrey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _black, foregroundColor: _white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(status == 'VERIFIED' ? 'Verify' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _actioning = true);
    final result = await AdminService.actionRequest(
      widget.request['id'] as int,
      status,
      _remarkCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _actioning = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'VERIFIED' ? '✓ Business verified successfully' : '✓ Request rejected'),
        backgroundColor: _black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pop(context, true); // Signal refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Action failed'),
        backgroundColor: _darkGrey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── Decode base64 photos ─────────────────────────────────────────────────
  Uint8List? _decodeBase64(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try { return base64Decode(b64); } catch (_) { return null; }
  }

  List<Uint8List> _decodeShopPhotos() {
    final raw = widget.request['shopPhotosBase64'] as String?;
    if (raw == null || raw.isEmpty) return [];
    return raw.split('|').map((s) {
      try { return base64Decode(s); } catch (_) { return null; }
    }).whereType<Uint8List>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final docPhoto = _decodeBase64(req['documentPhotoBase64'] as String?);
    final shopPhotos = _decodeShopPhotos();

    return Scaffold(
      backgroundColor: _softGrey,
      appBar: AppBar(
        backgroundColor: _black,
        title: Text(req['businessName'] ?? 'Business Request',
            style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_status, style: _statusStyle(_status)),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: _canAction ? 110 : 30),
            children: [
              // ── Personal Info ──────────────────────────────────────────────
              _sectionTitle('Personal Information'),
              const SizedBox(height: 8),
              _infoCard([
                _infoRow('Legal Name', req['legalName']),
                _infoRow('Mobile', req['mobileNumber']),
                _infoRow('Document Type', req['documentType']),
              ]),
              const SizedBox(height: 16),

              // ── KYC Document Photo ─────────────────────────────────────────
              if (docPhoto != null) ...[
                _sectionTitle('KYC Document'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 10)],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(docPhoto, fit: BoxFit.contain, height: 200),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Business Info ──────────────────────────────────────────────
              _sectionTitle('Business Details'),
              const SizedBox(height: 8),
              _infoCard([
                _infoRow('Business Name', req['businessName']),
                _infoRow('Business Type', req['businessType']),
                _infoRow('GST Number', req['gstNumber']),
                _infoRow('PAN Number', req['panNumber']),
                _infoRow('Years in Business', req['yearsInBusiness']),
              ]),
              const SizedBox(height: 16),

              // ── Business Address ───────────────────────────────────────────
              _sectionTitle('Business Address'),
              const SizedBox(height: 8),
              _infoCard([
                _infoRow('Door / Shop No.', req['businessDoor']),
                _infoRow('Street', req['businessStreet']),
                _infoRow('City', req['businessCity']),
                _infoRow('State', req['businessState']),
                _infoRow('Pincode', req['businessPincode']),
              ]),
              const SizedBox(height: 16),

              // ── Shop Photos ────────────────────────────────────────────────
              if (shopPhotos.isNotEmpty) ...[
                _sectionTitle('Shop Photos (${shopPhotos.length})'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 10)],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1,
                    ),
                    itemCount: shopPhotos.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _showFullPhoto(shopPhotos[i]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(shopPhotos[i], fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Submission Dates ───────────────────────────────────────────
              _infoCard([
                _infoRow('Submitted At', _formatDate(req['submittedAt'])),
                _infoRow('Last Updated', _formatDate(req['updatedAt'])),
              ]),
              const SizedBox(height: 16),

              // ── Remark Field ───────────────────────────────────────────────
              _sectionTitle('Admin Remark'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _remarkCtrl,
                  maxLines: 3,
                  enabled: _canAction,
                  style: const TextStyle(fontSize: 14, color: _black),
                  decoration: InputDecoration(
                    hintText: _canAction ? 'Add a remark for the user (optional)...' : 'No remark added',
                    hintStyle: const TextStyle(color: _lightGrey, fontSize: 13),
                    border: InputBorder.none,
                    filled: false,
                  ),
                  cursorColor: _black,
                ),
              ),
            ],
          ),

          // ── Action Buttons (pinned at bottom) ──────────────────────────────
          if (_canAction)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                decoration: BoxDecoration(
                  color: _white,
                  boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: Row(
                  children: [
                    // Reject
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _actioning ? null : () => _action('REJECTED'),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _darkGrey,
                          side: const BorderSide(color: _lightGrey, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: _white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Verify
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _actioning ? null : () => _action('VERIFIED'),
                        icon: _actioning
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _white, strokeWidth: 2))
                            : const Icon(Icons.verified_rounded, size: 18),
                        label: Text(_actioning ? 'Processing...' : 'Verify Business',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _black,
                          foregroundColor: _white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Text(
    t.toUpperCase(),
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _mediumGrey, letterSpacing: 1.0),
  );

  Widget _infoCard(List<Widget> rows) => Container(
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.05), blurRadius: 10)],
    ),
    child: Column(children: rows),
  );

  Widget _infoRow(String label, dynamic value) {
    final text = (value == null || value.toString().isEmpty) ? '—' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12, color: _mediumGrey, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: _black, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  TextStyle _statusStyle(String status) {
    return TextStyle(
      color: status == 'VERIFIED' ? Colors.greenAccent.shade200 : status == 'REJECTED' ? _lightGrey : Colors.orangeAccent.shade200,
      fontSize: 12, fontWeight: FontWeight.bold,
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }

  void _showFullPhoto(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: _lightGrey)),
            ),
          ],
        ),
      ),
    );
  }
}
