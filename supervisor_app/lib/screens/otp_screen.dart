import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'dashboard_screen.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  final String role;
  const OTPScreen({super.key, required this.email, required this.role});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final otpController = TextEditingController();
  final String demoOTP = "123456";

  Future<void> verifyOTP() async {
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter the 6-digit OTP code sent to your phone!'), backgroundColor: Colors.orange));
      return;
    }

    if (otpController.text == demoOTP) {
      if (widget.role == 'supervisor') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OTP verified! Welcome Supervisor! Redirecting to dashboard...'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()), (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OTP verified! Welcome Farmer! Redirecting to login...'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Invalid OTP! Please check and try again.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('OTP Verification', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_android, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text('OTP Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800])),
              const SizedBox(height: 8),
              Text('${widget.email}\nOTP has been sent', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text('Demo OTP: 123456', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '------',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Verify OTP', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📱 OTP has been resent to your registered phone number!'), backgroundColor: Colors.green));
                },
                child: const Text('Resend OTP', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
