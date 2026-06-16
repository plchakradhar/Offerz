import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/business_service.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────────
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF2F2F2);
  static const Color _white = Color(0xFFFFFFFF);

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  bool _submitting = false;
  bool _submitted = false;

  // Controllers
  final _legalNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController();
  final _doorCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  String _mobile = '';
  String _businessType = 'Retail';
  String _documentType = 'AADHAAR';

  // ── Use Uint8List bytes instead of File (cross-platform: works on Web too) ──
  Uint8List? _documentPhotoBytes;
  List<Uint8List> _shopPhotoBytes = [];

  static const List<String> _businessTypes = [
    'Retail', 'Food & Beverage', 'Service', 'Healthcare',
    'Electronics', 'Fashion & Apparel', 'Salon & Beauty',
    'Education', 'Real Estate', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mobile = prefs.getString('userMobile') ?? '';
      _legalNameCtrl.text = prefs.getString('userName') ?? '';
    });
  }

  @override
  void dispose() {
    _legalNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    _yearsCtrl.dispose();
    _doorCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  // ── Image Pickers — read as bytes (cross-platform) ───────────────────────────

  Future<void> _pickDocument() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() => _documentPhotoBytes = bytes);
    }
  }

  Future<void> _pickShopPhotos() async {
    if (_shopPhotoBytes.length >= 10) {
      _showError('Maximum 10 shop photos allowed');
      return;
    }
    final xFiles = await _picker.pickMultiImage(
      imageQuality: 60,
      limit: 10 - _shopPhotoBytes.length,
    );
    if (xFiles.isNotEmpty) {
      final newBytes = await Future.wait(xFiles.map((x) => x.readAsBytes()));
      final all = [..._shopPhotoBytes, ...newBytes];
      setState(() => _shopPhotoBytes = all.take(10).toList());
    }
  }

  // ── Convert bytes to base64 ──────────────────────────────────────────────────

  String _toBase64(Uint8List bytes) => base64Encode(bytes);

  String _shopPhotosBase64() => _shopPhotoBytes.map(_toBase64).join('|');

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_documentPhotoBytes == null) {
      _showError('Please upload your Aadhaar / PAN card photo');
      return;
    }
    if (_shopPhotoBytes.length < 5) {
      _showError('Please upload at least 5 shop photos');
      return;
    }

    setState(() => _submitting = true);

    final result = await BusinessService.submitRegistration(
      mobileNumber: _mobile,
      legalName: _legalNameCtrl.text.trim(),
      documentType: _documentType,
      documentPhotoBase64: _toBase64(_documentPhotoBytes!),
      businessName: _businessNameCtrl.text.trim(),
      businessType: _businessType,
      gstNumber: _gstCtrl.text.trim(),
      panNumber: _panCtrl.text.trim(),
      yearsInBusiness: _yearsCtrl.text.trim(),
      businessDoor: _doorCtrl.text.trim(),
      businessStreet: _streetCtrl.text.trim(),
      businessCity: _cityCtrl.text.trim(),
      businessState: _stateCtrl.text.trim(),
      businessPincode: _pincodeCtrl.text.trim(),
      shopPhotosBase64: _shopPhotosBase64(),
    );

    setState(() => _submitting = false);

    if (result['success'] == true) {
      setState(() => _submitted = true);
    } else {
      _showError(result['message'] ?? 'Submission failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: _white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: _white))),
      ]),
      backgroundColor: _darkGrey,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
      appBar: AppBar(
        backgroundColor: _black,
        title: const Text('Business Registration',
            style: TextStyle(color: _white, fontSize: 17, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _submitted ? _buildSuccessState() : _buildForm(),
    );
  }

  // ── Success State ─────────────────────────────────────────────────────────────

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: _white, size: 48),
            ),
            const SizedBox(height: 28),
            const Text('Verification Pending',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _black)),
            const SizedBox(height: 12),
            Text(
              'Your business registration has been submitted successfully. Our admin team will review your documents and verify your business within 2–3 business days.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: _mediumGrey, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _black,
                  foregroundColor: _white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Back to Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _black,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.storefront_outlined, color: _white, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Become a Business Owner',
                          style: TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Fill in all details. Verification takes 2–3 business days.',
                          style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ── Section 1: Personal Info ─────────────────────────────────────────
          _sectionTitle('Personal Information'),
          const SizedBox(height: 10),
          _card(children: [
            _field(
              controller: _legalNameCtrl,
              label: 'Legal Name (as per Aadhaar/PAN)',
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _divider(),
            // Document Type Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KYC Document Type', style: TextStyle(fontSize: 11, color: _mediumGrey, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _docTypeChip('AADHAAR', Icons.credit_card),
                      const SizedBox(width: 10),
                      _docTypeChip('PAN', Icons.article_outlined),
                    ],
                  ),
                ],
              ),
            ),
            _divider(),
            // Document Photo picker
            _photoPickerRow(
              label: _documentType == 'AADHAAR' ? 'Upload Aadhaar Card Photo' : 'Upload PAN Card Photo',
              icon: Icons.upload_file_outlined,
              bytes: _documentPhotoBytes,
              onTap: _pickDocument,
            ),
          ]),
          const SizedBox(height: 22),

          // ── Section 2: Business Info ─────────────────────────────────────────
          _sectionTitle('Business Information'),
          const SizedBox(height: 10),
          _card(children: [
            _field(
              controller: _businessNameCtrl,
              label: 'Business Name',
              icon: Icons.storefront_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _divider(),
            // Business Type Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: _softGrey, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.category_outlined, color: _mediumGrey, size: 19),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Business Type', style: TextStyle(fontSize: 11, color: _mediumGrey, fontWeight: FontWeight.w500)),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _businessType,
                            isExpanded: true,
                            style: const TextStyle(fontSize: 15, color: _black, fontWeight: FontWeight.w600),
                            onChanged: (v) => setState(() => _businessType = v!),
                            items: _businessTypes.map((t) => DropdownMenuItem(
                              value: t, child: Text(t),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _divider(),
            _field(
              controller: _gstCtrl,
              label: 'GST Number (optional)',
              icon: Icons.receipt_long_outlined,
              hint: 'e.g. 22AAAAA0000A1Z5',
            ),
            _divider(),
            _field(
              controller: _panCtrl,
              label: 'Business PAN Number',
              icon: Icons.article_outlined,
              hint: 'e.g. ABCDE1234F',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _divider(),
            _field(
              controller: _yearsCtrl,
              label: 'Years in Business',
              icon: Icons.calendar_today_outlined,
              hint: 'e.g. 3',
              keyboard: TextInputType.number,
            ),
          ]),
          const SizedBox(height: 22),

          // ── Section 3: Business Address ──────────────────────────────────────
          _sectionTitle('Business Address'),
          const SizedBox(height: 10),
          _card(children: [
            _field(
              controller: _doorCtrl,
              label: 'Door / Shop Number',
              icon: Icons.home_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _divider(),
            _field(
              controller: _streetCtrl,
              label: 'Street / Area',
              icon: Icons.near_me_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _divider(),
            _field(
              controller: _cityCtrl,
              label: 'City',
              icon: Icons.location_city_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _divider(),
            _field(
              controller: _stateCtrl,
              label: 'State',
              icon: Icons.map_outlined,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            _divider(),
            _field(
              controller: _pincodeCtrl,
              label: 'Pincode',
              icon: Icons.pin_drop_outlined,
              keyboard: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (v.trim().length != 6) return 'Enter a valid 6-digit pincode';
                return null;
              },
            ),
          ]),
          const SizedBox(height: 22),

          // ── Section 4: Shop Photos ───────────────────────────────────────────
          _sectionTitle('Shop / Outlet Photos'),
          const SizedBox(height: 4),
          Text('Upload 5 to 10 clear photos of your shop/outlet.',
              style: TextStyle(fontSize: 12, color: _mediumGrey)),
          const SizedBox(height: 10),
          _buildShopPhotoPicker(),
          const SizedBox(height: 32),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _black,
                foregroundColor: _white,
                disabledBackgroundColor: _lightGrey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: _white, strokeWidth: 2.5))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 20),
                        SizedBox(width: 10),
                        Text('Submit for Verification',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Widget Helpers ────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) => Text(
    title.toUpperCase(),
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _mediumGrey, letterSpacing: 1.0),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
    ),
    child: Column(children: children),
  );

  Widget _divider() => Divider(height: 1, thickness: 1, color: _softGrey, indent: 18, endIndent: 18);

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _softGrey, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _mediumGrey, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboard,
              validator: validator,
              style: const TextStyle(fontSize: 15, color: _black, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                labelStyle: TextStyle(fontSize: 11, color: _mediumGrey),
                hintStyle: TextStyle(fontSize: 13, color: _lightGrey),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: false,
              ),
              cursorColor: _black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTypeChip(String type, IconData icon) {
    final selected = _documentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _documentType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _black : _softGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? _black : _lightGrey, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? _white : _mediumGrey, size: 16),
              const SizedBox(width: 6),
              Text(type,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? _white : _darkGrey)),
            ],
          ),
        ),
      ),
    );
  }

  /// Photo picker row — uses Image.memory so it works on mobile AND web
  Widget _photoPickerRow({
    required String label,
    required IconData icon,
    required Uint8List? bytes,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: _softGrey, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: _mediumGrey, size: 19),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                bytes != null ? 'Photo selected ✓' : label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: bytes != null ? _black : _mediumGrey,
                ),
              ),
            ),
            if (bytes != null)
              // ✅ Image.memory works on all platforms including Web
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Upload', style: TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopPhotoPicker() {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _black.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Grid of selected photos — uses Image.memory (web-safe)
          if (_shopPhotoBytes.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _shopPhotoBytes.length,
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // ✅ Image.memory — safe on mobile, Web, Desktop
                    child: Image.memory(_shopPhotoBytes[i], fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _shopPhotoBytes.removeAt(i)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: _black, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: _white, size: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_shopPhotoBytes.isNotEmpty) const SizedBox(height: 12),
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_shopPhotoBytes.length}/10 photos',
                  style: TextStyle(fontSize: 13, color: _mediumGrey, fontWeight: FontWeight.w600)),
              Text('Min 5 required',
                  style: TextStyle(fontSize: 11, color: _shopPhotoBytes.length >= 5 ? _black : _mediumGrey)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _shopPhotoBytes.length / 10,
            backgroundColor: _softGrey,
            color: _shopPhotoBytes.length >= 5 ? _black : _lightGrey,
            borderRadius: BorderRadius.circular(4),
            minHeight: 5,
          ),
          if (_shopPhotoBytes.length < 10) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickShopPhotos,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _softGrey,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _lightGrey, width: 1.5),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: _mediumGrey, size: 28),
                    SizedBox(height: 6),
                    Text('Tap to add photos',
                        style: TextStyle(color: _mediumGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
