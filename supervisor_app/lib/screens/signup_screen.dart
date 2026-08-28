import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'otp_screen.dart';

/// Tapping-experience buckets, written verbatim to `users.experience`.
///
/// These strings must match the categories the spoilage model was trained on
/// exactly. The backend one-hot encodes this field and reindexes with
/// `fill_value=0`, so an unrecognised string scores as all-zeros without
/// raising — a silently wrong prediction rather than an error. Do not reword
/// or re-space these without retraining the model.
const List<String> kExperienceOptions = [
  '1 - 3 years',
  '3 - 5 years',
  '5 - 10 years',
  'More than 10 years',
];

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final nicController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final addressController = TextEditingController();
  final districtController = TextEditingController();
  final landSizeController = TextEditingController();
  final rubberTreesController = TextEditingController();
  final employeeIdController = TextEditingController();

  bool passwordVisible = false;
  bool isLoading = false;
  String selectedRole = 'farmer';

  /// Must stay one of [kExperienceOptions] — a value outside that list makes
  /// DropdownButtonFormField assert at build time.
  String selectedExperience = kExperienceOptions.first;

  Future<void> signUpUser() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter your full name!'), backgroundColor: Colors.orange));
      return;
    }
    if (nicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter your NIC number!'), backgroundColor: Colors.orange));
      return;
    }
    if (phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter your phone number!'), backgroundColor: Colors.orange));
      return;
    }
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter your email address!'), backgroundColor: Colors.orange));
      return;
    }
    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter a password!'), backgroundColor: Colors.orange));
      return;
    }
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Password must be at least 6 characters!'), backgroundColor: Colors.orange));
      return;
    }
    if (selectedRole == 'farmer') {
      if (addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter your home address!'), backgroundColor: Colors.orange));
        return;
      }
      if (districtController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter your district!'), backgroundColor: Colors.orange));
        return;
      }
    }
    if (selectedRole == 'supervisor') {
      if (employeeIdController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Please enter your Employee ID!'), backgroundColor: Colors.orange));
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'nic': nicController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
        'isNew': true,
        'createdAt': DateTime.now().toString(),
      };

      if (selectedRole == 'farmer') {
        userData.addAll({
          'address': addressController.text.trim(),
          'district': districtController.text.trim(),
          'landSize': landSizeController.text.trim(),
          'rubberTrees': rubberTreesController.text.trim(),
          'experience': selectedExperience,
        });
      } else if (selectedRole == 'supervisor') {
        userData.addAll({
          'employeeId': employeeIdController.text.trim(),
        });
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Account created successfully! Please verify OTP 📱'), backgroundColor: Colors.green));

      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => OTPScreen(email: emailController.text.trim(), role: selectedRole)));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Registration failed! Email may already be in use.'), backgroundColor: Colors.red));
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          selectedRole == 'farmer' ? 'Farmer Registration' : 'Supervisor Registration',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Select Role'),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedRole = 'farmer'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedRole == 'farmer' ? Colors.green : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.agriculture, color: selectedRole == 'farmer' ? Colors.white : Colors.grey),
                              const SizedBox(width: 8),
                              Text('Farmer', style: TextStyle(color: selectedRole == 'farmer' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedRole = 'supervisor'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedRole == 'supervisor' ? Colors.green : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.supervisor_account, color: selectedRole == 'supervisor' ? Colors.white : Colors.grey),
                              const SizedBox(width: 8),
                              Text('Supervisor', style: TextStyle(color: selectedRole == 'supervisor' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _sectionTitle('Personal Information'),
                _buildField(nameController, 'Full Name', Icons.person),
                _buildField(nicController, 'NIC Number', Icons.credit_card),
                _buildField(phoneController, 'Phone Number', Icons.phone, type: TextInputType.phone),
                _buildField(emailController, 'Email Address', Icons.email, type: TextInputType.emailAddress),
                const SizedBox(height: 16),

                if (selectedRole == 'farmer') ...[
                  _sectionTitle('Location Details'),
                  _buildField(addressController, 'Home Address', Icons.home),
                  _buildField(districtController, 'District', Icons.location_city),
                  const SizedBox(height: 16),
                  _sectionTitle('Farm Information'),
                  _buildField(landSizeController, 'Land Size (Acres)', Icons.landscape, type: TextInputType.number),
                  _buildField(rubberTreesController, 'Number of Rubber Trees', Icons.park, type: TextInputType.number),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedExperience,
                    decoration: InputDecoration(
                      labelText: 'Tapping Experience',
                      prefixIcon: const Icon(Icons.work, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: kExperienceOptions
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) => setState(() => selectedExperience = value!),
                  ),
                  const SizedBox(height: 16),
                ],

                if (selectedRole == 'supervisor') ...[
                  _sectionTitle('Employment Details'),
                  _buildField(employeeIdController, 'Employee ID', Icons.badge),
                  const SizedBox(height: 16),
                ],

                _sectionTitle('Account Setup'),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock, color: Colors.green),
                    suffixIcon: IconButton(
                      icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => passwordVisible = !passwordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signUpUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
        ),
      ),
    );
  }
}
