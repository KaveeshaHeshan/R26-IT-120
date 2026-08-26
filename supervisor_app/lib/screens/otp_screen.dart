import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import 'sync_screen.dart';

// ─────────────────────────────────────────────────────────────────────────
// Brevo (formerly Sendinblue) transactional email configuration
// 1. Create a free account at https://www.brevo.com
// 2. Go to Settings -> SMTP & API -> API Keys -> Generate a new API key.
// 3. Go to Senders, Domains & Dedicated IPs -> Senders -> add and verify
//    the email address you want OTPs to be sent FROM (just click the
//    confirmation link Brevo emails you — no DNS/domain setup needed).
// 4. Paste the API key and the verified sender email below.
// ─────────────────────────────────────────────────────────────────────────
const String brevoApiKey = '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';
const String brevoSenderEmail = 'sarasaleague@gmail.com';
const String brevoSenderName = 'research';

// How long a generated OTP stays valid.
const Duration otpValidity = Duration(minutes: 10);

class OTPScreen extends StatefulWidget {
  final String email;
  final String role;

  const OTPScreen({super.key, required this.email, required this.role});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final otpController = TextEditingController();

  bool isSending = true;
  bool isVerifying = false;
  String statusMessage = 'Sending OTP…';
  int secondsUntilResend = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    secondsUntilResend = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (secondsUntilResend > 0) {
          secondsUntilResend--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  String _generateCode() {
    final rand = Random.secure();
    return (100000 + rand.nextInt(900000)).toString(); // 6-digit code
  }

  /// Generates a fresh OTP, stores it in Firestore (keyed by uid) with an
  /// expiry, then emails it to the user via Brevo.
  Future<void> _sendOtp() async {
    setState(() {
      isSending = true;
      statusMessage = 'Sending OTP to ${widget.email}…';
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isSending = false;
        statusMessage = 'No signed-in user found. Please sign up again.';
      });
      return;
    }

    final code = _generateCode();
    final expiresAt = DateTime.now().add(otpValidity);

    try {
      // 1. Save the code so we can verify it later.
      await FirebaseFirestore.instance.collection('otp_codes').doc(user.uid).set({
        'code': code,
        'email': widget.email,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Send the email via Brevo's transactional email API.
      final response = await http.post(
        Uri.parse('https://api.brevo.com/v3/smtp/email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'api-key': brevoApiKey,
        },
        body: jsonEncode({
          'sender': {'name': brevoSenderName, 'email': brevoSenderEmail},
          'to': [
            {'email': widget.email},
          ],
          'subject': 'Your OTP code',
          'htmlContent': '''
            <p>To authenticate, please use the following One-Time Password (OTP):</p>
            <h2>$code</h2>
            <p>This OTP will be valid for ${otpValidity.inMinutes} minutes.</p>
            <p>Do not share this OTP with anyone. If you didn't request this, you can safely ignore this email.</p>
          ''',
        }),
      );

      if (!mounted) return;

      // Brevo returns 201 Created on success (not 200).
      if (response.statusCode == 201) {
        setState(() {
          isSending = false;
          statusMessage = 'OTP sent to ${widget.email}';
        });
        _startResendCooldown();
      } else {
        setState(() {
          isSending = false;
          // response.body carries Brevo's actual reason (e.g. an invalid
          // sender), which is far more useful than just the status code
          // when something's misconfigured.
          statusMessage = 'Failed to send OTP: ${response.body}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSending = false;
        statusMessage = 'Failed to send OTP. Check your connection and try again.';
      });
    }
  }

  Future<void> verifyOTP() async {
    final enteredCode = otpController.text.trim();
    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter the 6-digit OTP code sent to your email!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Session expired. Please sign up again.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      final doc = await FirebaseFirestore.instance.collection('otp_codes').doc(user.uid).get();

      if (!doc.exists) {
        _showVerifyError('❌ No OTP found. Tap Resend to get a new one.');
        return;
      }

      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiresAt)) {
        _showVerifyError('❌ This OTP expired. Tap Resend to get a new one.');
        return;
      }

      if (enteredCode != storedCode) {
        _showVerifyError('❌ Invalid OTP! Please check and try again.');
        return;
      }

      // Success: mark account verified and clean up the OTP doc.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isNew': false});
      await FirebaseFirestore.instance.collection('otp_codes').doc(user.uid).delete();

      if (!mounted) return;

      if (widget.role == 'supervisor') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OTP verified! Welcome Supervisor! Redirecting to dashboard...'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => const SyncScreen()), (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OTP verified! Welcome Farmer! Redirecting to login...'),
            backgroundColor: Colors.green,
          ),
        );

        // Sign out so the farmer lands on the login screen and signs in fresh.
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
      }
    } catch (e) {
      _showVerifyError('❌ Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => isVerifying = false);
    }
  }

  void _showVerifyError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    setState(() => isVerifying = false);
  }

  @override
  Widget build(BuildContext context) {
    final canResend = !isSending && secondsUntilResend == 0;

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
              const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text('OTP Verification',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800])),
              const SizedBox(height: 8),
              Text(statusMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              if (isSending) const CircularProgressIndicator(color: Colors.green),
              if (!isSending) ...[
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '------',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isVerifying
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Verify OTP',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: canResend ? _sendOtp : null,
                  child: Text(
                    canResend ? 'Resend OTP' : 'Resend OTP in ${secondsUntilResend}s',
                    style: TextStyle(color: canResend ? Colors.green : Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
