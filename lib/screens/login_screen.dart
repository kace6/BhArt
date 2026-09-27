import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:bhart/theme/app_theme.dart';
import 'package:bhart/services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.sendOtp(_phoneController.text.trim());
      if (mounted) {
        setState(() {
          _otpSent = true;
          _otpController.clear();
        });
      }
    } catch (_) {
      _showError('Something went wrong sending the OTP. Please check the number and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.verifyOtp(_phoneController.text.trim(), _otpController.text.trim());
      if (mounted) context.go('/merchant');
    } catch (_) {
      _showError('Incorrect OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.khadi,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeChip(onTap: () => context.go('/')),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('BhArt',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                        const SizedBox(height: 8),
                        const Text('Sign in to continue',
                            style: TextStyle(color: AppColors.weaverBlue, fontSize: 16)),
                        const SizedBox(height: 24),
                        _buildAuthCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      // Fixed 400px caused overflow on phones narrower than ~430dp (i.e. most
      // phones) once the 16px screen padding was subtracted. This now grows
      // to fill the available width and only caps out at 400 on wide screens.
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('साइन इन करें (Sign In)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.weaverBlue)),
          const SizedBox(height: 24),
          if (!_otpSent) ...[
            const Text('फ़ोन नंबर (Phone Number)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              // Rebuild on every keystroke so the button below enables as soon
              // as 10 digits are typed (a controller alone doesn't rebuild us).
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(prefixText: '+91  ', hintText: '99999 99999', counterText: ''),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_loading || _phoneController.text.length < 10) ? null : _sendOtp,
              child: Text(_loading ? 'कृपया प्रतीक्षा करें...' : 'OTP भेजें (Send OTP)'),
            ),
          ] else ...[
            const Text('OTP दर्ज करें (Enter OTP)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, letterSpacing: 4),
              decoration: const InputDecoration(hintText: '123456', counterText: ''),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (_loading || _otpController.text.length < 6) ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.weaverBlue),
              child: Text(_loading ? 'कृपया प्रतीक्षा करें...' : 'सत्यापित करें (Verify)'),
            ),
            Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _otpSent = false;
                  _otpController.clear();
                }),
                child: const Text('गलत नंबर? (Wrong number?)', style: TextStyle(color: AppColors.terracotta)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeChip extends StatelessWidget {
  final VoidCallback onTap;
  const _HomeChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.home, size: 20, color: AppColors.weaverBlue),
            SizedBox(width: 8),
            Text('Home', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.weaverBlue)),
          ]),
        ),
      ),
    );
  }
}