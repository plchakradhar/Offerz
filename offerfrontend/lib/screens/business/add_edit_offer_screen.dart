import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/offer_service.dart';
import '../../services/auth_service.dart';

class AddEditOfferScreen extends StatefulWidget {
  final Map<String, dynamic>? offer;
  const AddEditOfferScreen({super.key, this.offer});

  @override
  State<AddEditOfferScreen> createState() => _AddEditOfferScreenState();
}

class _AddEditOfferScreenState extends State<AddEditOfferScreen> {
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _mediumGrey = Color(0xFF6B6B6B);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _softGrey = Color(0xFFF4F4F6);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF6C63FF);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _shopNameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _origPriceCtrl;
  late TextEditingController _discPriceCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _fromDateCtrl;
  late TextEditingController _toDateCtrl;
  late TextEditingController _openTimeCtrl;
  late TextEditingController _closeTimeCtrl;

  String _selectedCategory = 'Restaurant';
  final List<String> _categories = [
    'Restaurant', 'Electronics', 'Phones', 'Fashion',
    'Health', 'Services', 'Other'
  ];

  // Photo handling
  final List<XFile> _newPhotos = [];
  List<String> _existingPhotosBase64 = []; // Already stored photos
  static const int _maxPhotos = 6;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController(text: widget.offer?['shopName'] ?? '');
    _descCtrl = TextEditingController(text: widget.offer?['description'] ?? '');
    _origPriceCtrl = TextEditingController(
        text: widget.offer?['originalPrice']?.toString() ?? '');
    _discPriceCtrl = TextEditingController(
        text: widget.offer?['discountPrice']?.toString() ?? '');
    _addressCtrl = TextEditingController(
        text: widget.offer?['exactLocationAddress'] ?? '');
    _cityCtrl = TextEditingController(text: widget.offer?['city'] ?? '');
    _fromDateCtrl = TextEditingController(text: widget.offer?['fromDate'] ?? '');
    _toDateCtrl = TextEditingController(text: widget.offer?['toDate'] ?? '');
    _openTimeCtrl = TextEditingController(text: widget.offer?['openingTime'] ?? '');
    _closeTimeCtrl =
        TextEditingController(text: widget.offer?['closingTime'] ?? '');

    if (widget.offer?['category'] != null &&
        _categories.contains(widget.offer?['category'])) {
      _selectedCategory = widget.offer!['category'];
    }

    // Parse existing photos
    if (widget.offer?['photosBase64'] != null &&
        widget.offer!['photosBase64'].toString().isNotEmpty) {
      _existingPhotosBase64 = widget.offer!['photosBase64']
          .toString()
          .split('|')
          .where((s) => s.isNotEmpty)
          .toList();
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _descCtrl.dispose();
    _origPriceCtrl.dispose();
    _discPriceCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _fromDateCtrl.dispose();
    _toDateCtrl.dispose();
    _openTimeCtrl.dispose();
    _closeTimeCtrl.dispose();
    super.dispose();
  }

  int get _totalPhotos => _existingPhotosBase64.length + _newPhotos.length;

  Future<void> _pickPhotos() async {
    final remaining = _maxPhotos - _totalPhotos;
    if (remaining <= 0) {
      _showSnack('Maximum $_maxPhotos photos allowed');
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 70);
    if (picked.isEmpty) return;
    final toAdd = picked.take(remaining).toList();
    setState(() => _newPhotos.addAll(toAdd));
  }

  void _removeExistingPhoto(int index) {
    setState(() => _existingPhotosBase64.removeAt(index));
  }

  void _removeNewPhoto(int index) {
    setState(() => _newPhotos.removeAt(index));
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Encode new photos to base64
    List<String> newBase64 = [];
    for (final xfile in _newPhotos) {
      final bytes = await xfile.readAsBytes();
      newBase64.add(base64Encode(bytes));
    }

    final allPhotosBase64 = [..._existingPhotosBase64, ...newBase64];
    final photosStr = allPhotosBase64.join('|');

    String mobile = await AuthService.getUserMobile();

    final data = {
      'businessMobileNumber': mobile,
      'shopName': _shopNameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'originalPrice': double.tryParse(_origPriceCtrl.text.trim()),
      'discountPrice': double.tryParse(_discPriceCtrl.text.trim()),
      'exactLocationAddress': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'fromDate': _fromDateCtrl.text.trim().isEmpty
          ? null
          : _fromDateCtrl.text.trim(),
      'toDate':
          _toDateCtrl.text.trim().isEmpty ? null : _toDateCtrl.text.trim(),
      'openingTime': _openTimeCtrl.text.trim().isEmpty
          ? null
          : _openTimeCtrl.text.trim(),
      'closingTime': _closeTimeCtrl.text.trim().isEmpty
          ? null
          : _closeTimeCtrl.text.trim(),
      'category': _selectedCategory,
      'photosBase64': photosStr,
    };

    Map<String, dynamic> res;
    if (widget.offer == null) {
      res = await OfferService.createOffer(data);
    } else {
      res = await OfferService.updateOffer(widget.offer!['id'], data);
    }

    setState(() => _isLoading = false);

    if (res['success']) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) _showSnack(res['message'] ?? 'Failed to save offer');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _darkGrey,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _black),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      controller.text =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _black),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      controller.text = time.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
      appBar: AppBar(
        backgroundColor: _black,
        title: Text(
          widget.offer == null ? 'Add New Offer' : 'Edit Offer',
          style: const TextStyle(color: _white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _black),
                  SizedBox(height: 16),
                  Text('Saving offer...', style: TextStyle(color: _mediumGrey)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Photo Section ────────────────────────────────────
                    _buildSectionTitle('Offer Photos', '${_totalPhotos}/$_maxPhotos'),
                    const SizedBox(height: 10),
                    _buildPhotoPickerSection(),
                    const SizedBox(height: 24),

                    // ── Offer Details ────────────────────────────────────
                    _buildSectionTitle('Offer Details', null),
                    const SizedBox(height: 10),
                    _buildCard([
                      _buildField('Shop Name', _shopNameCtrl,
                          icon: Icons.storefront_outlined),
                      _buildField('Description', _descCtrl,
                          maxLines: 3, icon: Icons.description_outlined),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField('Original Price (₹)',
                                _origPriceCtrl,
                                isNumber: true,
                                icon: Icons.currency_rupee),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField('Discount Price (₹)',
                                _discPriceCtrl,
                                isNumber: true,
                                icon: Icons.local_offer_outlined),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Location ─────────────────────────────────────────
                    _buildSectionTitle('Location', null),
                    const SizedBox(height: 10),
                    _buildCard([
                      _buildField('Full Address', _addressCtrl,
                          maxLines: 2, icon: Icons.location_on_outlined),
                      _buildField('City', _cityCtrl,
                          icon: Icons.location_city_outlined),
                    ]),
                    const SizedBox(height: 20),

                    // ── Availability ──────────────────────────────────────
                    _buildSectionTitle('Availability', null),
                    const SizedBox(height: 10),
                    _buildCard([
                      Row(
                        children: [
                          Expanded(
                            child: _buildField('From Date', _fromDateCtrl,
                                onTap: () => _selectDate(_fromDateCtrl),
                                icon: Icons.calendar_today_outlined,
                                isRequired: false),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField('To Date', _toDateCtrl,
                                onTap: () => _selectDate(_toDateCtrl),
                                icon: Icons.event_outlined,
                                isRequired: false),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField('Opening Time', _openTimeCtrl,
                                onTap: () => _selectTime(_openTimeCtrl),
                                icon: Icons.access_time_outlined,
                                isRequired: false),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField('Closing Time', _closeTimeCtrl,
                                onTap: () => _selectTime(_closeTimeCtrl),
                                icon: Icons.timelapse_outlined,
                                isRequired: false),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // ── Category ──────────────────────────────────────────
                    _buildSectionTitle('Category', null),
                    const SizedBox(height: 10),
                    _buildCard([
                      Container(
                        decoration: BoxDecoration(
                          color: _white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.category_outlined,
                                color: _mediumGrey, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: _white,
                          ),
                          items: _categories
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val!),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 32),

                    // ── Submit Button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _black,
                          foregroundColor: _white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _saveOffer,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(widget.offer == null
                                ? Icons.add_circle_outline
                                : Icons.save_outlined),
                            const SizedBox(width: 10),
                            Text(
                              widget.offer == null
                                  ? 'Create Offer'
                                  : 'Save Changes',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Photo Picker Section ───────────────────────────────────────────────────

  Widget _buildPhotoPickerSection() {
    final totalSlots = _maxPhotos;
    final existingCount = _existingPhotosBase64.length;
    final newCount = _newPhotos.length;
    final filledCount = existingCount + newCount;
    final canAddMore = filledCount < totalSlots;

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Helper text
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: _mediumGrey),
              const SizedBox(width: 6),
              Text(
                'Add up to $_maxPhotos photos to showcase your offer',
                style: const TextStyle(fontSize: 12, color: _mediumGrey),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Grid of photos + add button
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              // Existing photos
              ...List.generate(existingCount, (i) {
                final bytes = base64Decode(_existingPhotosBase64[i]);
                return _photoThumbnail(
                  child: Image.memory(bytes, fit: BoxFit.cover),
                  onRemove: () => _removeExistingPhoto(i),
                  label: 'Photo ${i + 1}',
                );
              }),
              // New photos
              ...List.generate(newCount, (i) {
                return _photoThumbnail(
                  child: FutureBuilder<Uint8List>(
                    future: _newPhotos[i].readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                  onRemove: () => _removeNewPhoto(i),
                  label: 'New ${i + 1}',
                );
              }),
              // Add button
              if (canAddMore)
                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _softGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _lightGrey, width: 1.5, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _black.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_a_photo_outlined,
                              color: _darkGrey, size: 22),
                        ),
                        const SizedBox(height: 6),
                        const Text('Add Photo',
                            style: TextStyle(
                                fontSize: 11,
                                color: _mediumGrey,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoThumbnail(
      {required Widget child,
      required VoidCallback onRemove,
      required String label}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.expand(child: child),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
        // Label
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, String? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _mediumGrey,
                letterSpacing: 1.2)),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(trailing,
                style: const TextStyle(
                    color: _white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: children
            .map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: w,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
    VoidCallback? onTap,
    IconData? icon,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      readOnly: onTap != null,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _mediumGrey, fontSize: 13),
        prefixIcon: icon != null
            ? Icon(icon, color: _mediumGrey, size: 20)
            : null,
        filled: true,
        fillColor: _softGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _black, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: isRequired
          ? (val) => val == null || val.isEmpty ? 'Required' : null
          : null,
    );
  }
}
