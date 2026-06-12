import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_bottomsheet.dart';

class SignupBottomSheet extends StatefulWidget {
  final VoidCallback? onSuccess;
  const SignupBottomSheet({super.key, this.onSuccess});

  @override
  State<SignupBottomSheet> createState() => _SignupBottomSheetState();
}

class _SignupBottomSheetState extends State<SignupBottomSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;
  String? _displayOtp; // Show the OTP inline instead of a dialog

  // ─── Signup ───────────────────────────────────────────────────────────────
  Future<void> _signup() async {
    setState(() => _errorMessage = null);

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (mobile.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService().signup(name, email, mobile);
    setState(() => _loading = false);

    if (result['success'] == true) {
      final otp = result['otpMessage']?.toString().replaceAll('OTP: ', '') ?? '';
      setState(() {
        _otpSent = true;
        _displayOtp = otp;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = result['error'] ?? 'Signup failed. Please try again.');
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> _verifySignup() async {
    setState(() => _errorMessage = null);

    if (_otpController.text.trim().length < 4) {
      setState(() => _errorMessage = 'Please enter the 4-digit OTP.');
      return;
    }

    setState(() => _loading = true);
    final success = await AuthService().verifySignup(
      _mobileController.text.trim(),
      _otpController.text.trim(),
    );
    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Text('Account created! Please login.'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      widget.onSuccess?.call();
    } else {
      setState(() => _errorMessage = 'Incorrect OTP. Please check and try again.');
    }
  }

  // ─── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 30,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_outlined, color: Color(0xFFFF6B35), size: 26),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create Account ✨',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
                    Text('Never miss a local deal again!',
                        style: TextStyle(fontSize: 13, color: Colors.black45)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error Banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // OTP Banner (shown after successful signup call)
            if (_otpSent && _displayOtp != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text('Your OTP (Dev Mode)',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      _displayOtp!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 10),
                    ),
                    const SizedBox(height: 4),
                    const Text('Enter this in the OTP field below',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Form Fields
            if (!_otpSent) ...[
              _buildField(_nameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 14),
              _buildField(_emailController, 'Email Address', Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _buildField(_mobileController, 'Mobile Number (10 digits)', Icons.phone_android,
                  keyboardType: TextInputType.phone, maxLength: 10),
            ] else ...[
              _buildField(_otpController, 'Enter 4-digit OTP', Icons.lock_outline,
                  keyboardType: TextInputType.number, maxLength: 4),
            ],
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : (_otpSent ? _verifySignup : _signup),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _otpSent ? 'Verify & Create Account' : 'Get OTP',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            // Resend / Back to form
            if (_otpSent) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _otpSent = false;
                            _displayOtp = null;
                            _otpController.clear();
                            _errorMessage = null;
                          }),
                  icon: const Icon(Icons.arrow_back, size: 16, color: Colors.black54),
                  label: const Text('Change details', style: TextStyle(color: Colors.black54, fontSize: 13)),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => LoginBottomSheet(onSuccess: widget.onSuccess),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: 'Already have an account? ',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Login',
                        style: TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}