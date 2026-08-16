import 'package:flutter/material.dart';

import 'login_screen.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  final String role;
  OTPScreen({required this.email, required this.role});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final otpController = TextEditingController();
  final String demoOTP = "123456";

  Future<void> verifyOTP() async {
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Please enter the 6-digit OTP code sent to your phone!'), backgroundColor: Colors.orange));
      return;
    }

    if (otpController.text == demoOTP) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.role == 'farmer'
            ? '✅ OTP verified! Welcome Farmer! Redirecting to login...'
            : '✅ OTP verified! Welcome Supervisor! Redirecting to login...'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Invalid OTP! Please check and try again.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text('OTP Verification', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_android, size: 80, color: Colors.green),
              SizedBox(height: 16),
              Text('OTP Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800])),
              SizedBox(height: 8),
              Text('${widget.email}\nOTP has been sent', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text('Demo OTP: 123456', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 40),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '------',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                  counterText: '',
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Verify OTP', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('📱 OTP has been resent to your registered phone number!'), backgroundColor: Colors.green));
                },
                child: Text('Resend OTP', style: TextStyle(color: Colors.green)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}