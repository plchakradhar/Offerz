import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import 'signup_bottomsheet.dart';

class LoginBottomSheet extends StatefulWidget {
  final VoidCallback? onSuccess;
  const LoginBottomSheet({super.key, this.onSuccess});

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;
  String? _errorMessage;
  String? _displayOtp;
  int _adminTapCount = 0;

  // ─── Get OTP ──────────────────────────────────────────────────────────────
  Future<void> _getOtp() async {
    setState(() => _errorMessage = null);

    final mobile = _mobileController.text.trim();
    if (mobile.length < 10) {
      setState(() => _errorMessage = 'Enter a valid 10-digit mobile number.');
      return;
    }

    if (mobile == '7953161920') {
      setState(() {
        _otpSent = true;
        _displayOtp = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() => _loading = true);
    final response = await AuthService().getOtp(mobile);
    setState(() => _loading = false);

    if (response.startsWith('ERROR:')) {
      setState(() => _errorMessage = response.replaceFirst('ERROR: ', ''));
    } else {
      final otp = response.replaceAll('OTP: ', '');
      setState(() {
        _otpSent = true;
        _displayOtp = otp;
        _errorMessage = null;
      });
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> _verifyOtp() async {
    setState(() => _errorMessage = null);

    if (_otpController.text.trim().length < 4) {
      setState(() => _errorMessage = 'Please enter the 4-digit OTP.');
      return;
    }

    final mobile = _mobileController.text.trim();
    final otp = _otpController.text.trim();

    if (mobile == '7953161920') {
      if (otp == '2006') {
        setState(() => _loading = true);
        final result = await AdminService.login(mobile, otp);
        if (!mounted) return;
        setState(() => _loading = false);

        if (result['success'] == true) {
          Navigator.pop(context); // Close login sheet
          Navigator.pushNamed(context, '/admin-dashboard');
        } else {
          setState(() => _errorMessage = result['message'] ?? 'Admin login failed');
        }
      } else {
        setState(() => _errorMessage = 'Invalid admin OTP.');
      }
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService().verifyLogin(
      _mobileController.text.trim(),
      _otpController.text.trim(),
    );
    setState(() => _loading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text('Welcome back, ${result['fullName'] ?? ''}! 🎉'),
          ]),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      widget.onSuccess?.call();
    } else {
      setState(() => _errorMessage = result['message'] ?? 'Invalid OTP. Please try again.');
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
                  child: const Icon(Icons.login_outlined, color: Color(0xFFFF6B35), size: 26),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _adminTapCount++;
                        if (_adminTapCount >= 5) {
                          _adminTapCount = 0;
                          Navigator.pop(context); // Close bottom sheet
                          Navigator.pushNamed(context, '/admin');
                        }
                      },
                      child: const Text('Welcome Back 👋',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87)),
                    ),
                    const Text('Login to explore the best offers',
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
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // OTP Display Banner
            if (_otpSent && _displayOtp != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
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

            // Mobile field (disabled once OTP is sent)
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              enabled: !_otpSent,
              maxLength: 10,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              decoration: InputDecoration(
                labelText: 'Mobile Number',
                counterText: '',
                prefixIcon: Icon(Icons.phone_android,
                    color: _otpSent ? Colors.grey.shade400 : Colors.grey.shade600, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                ),
                filled: true,
                fillColor: _otpSent ? Colors.grey.shade100 : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
            ),

            // OTP field (shown after OTP is sent)
            if (_otpSent) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                    color: Colors.black87),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
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
              ),
            ],
            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : (_otpSent ? _verifyOtp : _getOtp),
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
                        _otpSent ? 'Login Now' : 'Get OTP',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            // Back / change mobile
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
                  label: const Text('Change mobile number',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
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
                    builder: (_) => SignupBottomSheet(onSuccess: widget.onSuccess),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: 'New User? ',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Create Account',
                        style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
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

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}