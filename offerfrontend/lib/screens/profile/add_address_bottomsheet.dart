import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddAddressBottomSheet extends StatefulWidget {
  final VoidCallback? onAddressAdded;
  const AddAddressBottomSheet({super.key, this.onAddressAdded});

  @override
  State<AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<AddAddressBottomSheet> {
  final _doorController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipcodeController = TextEditingController();

  bool _loading = false;
  bool _fetchingZip = false;
  String? _errorMessage;
  String? _zipStatus; // "found" or "not_found"

  Future<void> _onZipcodeChanged(String value) async {
    final cleaned = value.trim();
    if (cleaned.length == 6) {
      setState(() {
        _fetchingZip = true;
        _zipStatus = null;
        _cityController.text = "";
        _stateController.text = "";
      });

      final details = await LocationService.fetchDetailsFromZipcode(cleaned);

      if (!mounted) return;
      setState(() => _fetchingZip = false);

      if (details != null && details['city']!.isNotEmpty) {
        _cityController.text = details['city']!;
        _stateController.text = details['state']!;
        setState(() => _zipStatus = "found");
      } else {
        setState(() => _zipStatus = "not_found");
      }
    } else {
      if (_zipStatus != null) setState(() => _zipStatus = null);
    }
  }

  Future<void> _saveAddress() async {
    setState(() => _errorMessage = null);

    final door = _doorController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final zip = _zipcodeController.text.trim();

    if (door.isEmpty || street.isEmpty || city.isEmpty || state.isEmpty || zip.isEmpty) {
      setState(() => _errorMessage = "Please fill in all address fields");
      return;
    }

    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final mobile = prefs.getString('userMobile') ?? "";

    if (mobile.isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = "Session expired. Please login again.";
      });
      return;
    }

    final result = await ProfileService.addAddress(mobile, {
      "doorNumber": door,
      "street": street,
      "city": city,
      "state": state,
      "zipcode": zip,
    });
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text("Address added successfully!"),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      widget.onAddressAdded?.call();
    } else {
      setState(() => _errorMessage = result['message'] ?? "Failed to add address. Please try again.");
    }
  }

  @override
  void dispose() {
    _doorController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_location_alt_outlined, color: Color(0xFFFF6B35), size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Add New Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Text("Enter your delivery details", style: TextStyle(fontSize: 13, color: Colors.black45)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Zipcode with auto-fill indicator
            _buildLabel("Pincode / Zipcode *"),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _zipcodeController,
                    hint: "Enter 6-digit pincode",
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    onChanged: _onZipcodeChanged,
                  ),
                ),
                if (_fetchingZip)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFF6B35))),
                  ),
                if (_zipStatus == "found" && !_fetchingZip)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ),
                if (_zipStatus == "not_found" && !_fetchingZip)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.cancel, color: Colors.red, size: 24),
                  ),
              ],
            ),
            if (_zipStatus == "found")
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text("📍 Location auto-filled!", style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            if (_zipStatus == "not_found")
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text("Pincode not found. Please fill city & state manually.", style: TextStyle(color: Colors.orange.shade700, fontSize: 12)),
              ),
            const SizedBox(height: 12),

            _buildLabel("Flat / Door Number *"),
            _buildField(controller: _doorController, hint: "e.g., 12-B, Flat No. 4", icon: Icons.door_front_door_outlined),
            const SizedBox(height: 12),

            _buildLabel("Street / Area *"),
            _buildField(controller: _streetController, hint: "e.g., MG Road, Jubilee Hills", icon: Icons.add_road_outlined),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("City *"),
                      _buildField(controller: _cityController, hint: "City", icon: Icons.location_city_outlined),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("State *"),
                      _buildField(controller: _stateController, hint: "State", icon: Icons.map_outlined),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_outlined, size: 20),
                          SizedBox(width: 10),
                          Text("Save Address", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        counterText: "",
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F6FA),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      ),
    );
  }
}
