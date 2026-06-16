import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const Color _black = Color(0xFF0D0D0D);
  static const Color _darkGrey = Color(0xFF2C2C2C);
  static const Color _lightGrey = Color(0xFFD0D0D0);
  static const Color _white = Color(0xFFFFFFFF);

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (phone.isEmpty || otp.isEmpty) {
      setState(() => _error = 'Please enter both phone and OTP');
      return;
    }
    setState(() { _loading = true; _error = ''; });

    final result = await AdminService.login(phone, otp);
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else {
      setState(() => _error = result['message'] ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Admin badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _white.withValues(alpha: 0.15), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, color: _lightGrey, size: 15),
                    SizedBox(width: 6),
                    Text('Admin Access', style: TextStyle(color: _lightGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Offerz Admin', style: TextStyle(color: _white, fontSize: 32, fontWeight: FontWeight.bold, height: 1.1)),
              const SizedBox(height: 8),
              const Text('Sign in to access the dashboard', style: TextStyle(color: Color(0xFF888888), fontSize: 15)),
              const SizedBox(height: 44),

              // Phone field
              _buildField(controller: _phoneCtrl, label: 'Admin Phone Number', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _buildField(controller: _otpCtrl, label: 'Access OTP', icon: Icons.lock_outline, keyboard: TextInputType.number, obscure: false),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _lightGrey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: _lightGrey, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error, style: const TextStyle(color: _lightGrey, fontSize: 13))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _white,
                    foregroundColor: _black,
                    disabledBackgroundColor: _darkGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(color: _black, strokeWidth: 2.5))
                      : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
              Center(
                child: Text('Offerz © ${DateTime.now().year}',
                    style: const TextStyle(color: Color(0xFF444444), fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboard,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _white.withValues(alpha: 0.1), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        obscureText: obscure,
        style: const TextStyle(color: _white, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xFF888888), fontSize: 13),
          prefixIcon: Icon(icon, color: Color(0xFF888888), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: false,
        ),
        cursorColor: _white,
      ),
    );
  }
}
