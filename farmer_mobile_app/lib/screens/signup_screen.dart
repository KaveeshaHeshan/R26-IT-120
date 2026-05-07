import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _landSizeController = TextEditingController();
  final _treeCountController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _selectedExperience = 'Less than 1 year';

  final List<String> _experienceOptions = [
    'Less than 1 year',
    '1 - 3 years',
    '3 - 5 years',
    '5 - 10 years',
    'More than 10 years',
  ];

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nicController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _districtController.text.isEmpty ||
        _landSizeController.text.isEmpty ||
        _treeCountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save farmer details to Firestore
      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'nic': _nicController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'address': _addressController.text.trim(),
        'district': _districtController.text.trim(),
        'landSize': double.tryParse(_landSizeController.text.trim()) ?? 0,
        'treeCount': int.tryParse(_treeCountController.text.trim()) ?? 0,
        'experience': _selectedExperience,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Hide loading
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please login.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') message = 'Email already registered';
      if (e.code == 'weak-password') message = 'Password must be at least 6 characters';
      if (e.code == 'invalid-email') message = 'Invalid email address';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Farmer Registration',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_add, color: Color(0xFF2E7D32), size: 30),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Your Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Text(
                        'Fill in your details to get started',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Personal Info
            _buildSectionTitle('Personal Information'),
            _buildTextField('Full Name', Icons.person, _nameController),
            _buildTextField('NIC Number', Icons.credit_card, _nicController),
            _buildTextField(
              'Phone Number',
              Icons.phone,
              _phoneController,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              'Email Address',
              Icons.email,
              _emailController,
              keyboardType: TextInputType.emailAddress,
            ),

            // Location Info
            _buildSectionTitle('Location Details'),
            _buildTextField('Home Address', Icons.home, _addressController),
            _buildTextField(
                'District', Icons.location_city, _districtController),

            // Farm Info
            _buildSectionTitle('Farm Information'),
            _buildTextField(
              'Land Size (Acres)',
              Icons.landscape,
              _landSizeController,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              'Number of Rubber Trees',
              Icons.park,
              _treeCountController,
              keyboardType: TextInputType.number,
            ),

            // Experience dropdown
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedExperience,
                decoration: InputDecoration(
                  labelText: 'Tapping Experience',
                  prefixIcon:
                      const Icon(Icons.work, color: Color(0xFF2E7D32)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
                items: _experienceOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() => _selectedExperience = newValue!);
                },
              ),
            ),

            // Account Setup
            _buildSectionTitle('Account Setup'),
            _buildTextField(
              'Password',
              Icons.lock,
              _passwordController,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF2E7D32),
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            _buildTextField(
              'Confirm Password',
              Icons.lock_outline,
              _confirmPasswordController,
              obscure: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF2E7D32),
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),

            const SizedBox(height: 10),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Login link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: Colors.grey)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}