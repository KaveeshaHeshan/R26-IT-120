import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBaOIOHdDBhftD66uSiz41qmxC2aRMHepQ",
      authDomain: "rubberquality-33cab.firebaseapp.com",
      projectId: "rubberquality-33cab",
      storageBucket: "rubberquality-33cab.firebasestorage.app",
      messagingSenderId: "1039456219056",
      appId: "1:1039456219056:web:7a6432b5805e28f94d3075",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rubber App',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  bool passwordVisible     = false;
  bool isLoading           = false;

  Future<void> loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Please enter your email and password to continue!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];
        bool isNew  = userDoc['isNew'] ?? false;

        if (isNew) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'isNew': false});

          Navigator.push(context,
            MaterialPageRoute(
              builder: (context) => OTPScreen(
                email: emailController.text.trim(),
                role: role,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                role == 'farmer'
                  ? '✅ Welcome back farmer! Redirecting to your dashboard...'
                  : '✅ Welcome back Supervisor! Redirecting to dashboard...'
              ),
              backgroundColor: const Color.fromARGB(255, 10, 24, 11),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Account not found! Please sign up or contact admin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Login failed! Invalid email or password. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/rubber_tree.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.55),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    Icon(Icons.eco, size: 80, color: Colors.green[300]),
                    SizedBox(height: 16),
                    Text(
                      'Rubber Collection System',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 40),

                    // Email Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.email, color: Colors.green[300]),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: !passwordVisible,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.lock, color: Colors.green[300]),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        suffixIcon: IconButton(
                          icon: Icon(
                            passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          if (emailController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚠️ Please enter your email address to reset password!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          } else {
                            FirebaseAuth.instance.sendPasswordResetEmail(
                              email: emailController.text.trim(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Password reset email sent! Please check your inbox.'),
                                backgroundColor: const Color.fromARGB(255, 64, 167, 64),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: const Color.fromARGB(255, 0, 1, 1)),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 128, 214, 131),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[300],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController        = TextEditingController();
  final nicController         = TextEditingController();
  final phoneController       = TextEditingController();
  final emailController       = TextEditingController();
  final passwordController    = TextEditingController();
  final addressController     = TextEditingController();
  final districtController    = TextEditingController();
  final landSizeController    = TextEditingController();
  final rubberTreesController = TextEditingController();
  final employeeIdController  = TextEditingController();

  bool passwordVisible      = false;
  bool isLoading            = false;
  String selectedRole       = 'farmer';
  String selectedExperience = 'Less than 1 year';

  Future<void> signUpUser() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Please enter your full name!'), backgroundColor: Colors.orange));
      return;
    }
    if (nicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Please enter your NIC number!'), backgroundColor: Colors.orange));
      return;
    }
    if (phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Please enter your phone number!'), backgroundColor: Colors.orange));
      return;
    }
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Please enter your email address!'), backgroundColor: Colors.orange));
      return;
    }
    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Please enter a password!'), backgroundColor: Colors.orange));
      return;
    }
    if (passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Password must be at least 6 characters!'), backgroundColor: Colors.orange));
      return;
    }
    if (selectedRole == 'farmer') {
      if (addressController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Please enter your home address!'), backgroundColor: Colors.orange));
        return;
      }
      if (districtController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Please enter your district!'), backgroundColor: Colors.orange));
        return;
      }
    }
    if (selectedRole == 'supervisor') {
      if (employeeIdController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Please enter your Employee ID!'), backgroundColor: Colors.orange));
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Account created successfully! Please verify OTP 📱'), backgroundColor: Colors.green));

      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => OTPScreen(email: emailController.text.trim(), role: selectedRole)));

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Registration failed! Email may already be in use.'), backgroundColor: Colors.red));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          selectedRole == 'farmer' ? 'Farmer Registration' : 'Supervisor Registration',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
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
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedRole == 'farmer' ? Colors.green : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.agriculture, color: selectedRole == 'farmer' ? Colors.white : Colors.grey),
                              SizedBox(width: 8),
                              Text('Farmer', style: TextStyle(color: selectedRole == 'farmer' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedRole = 'supervisor'),
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedRole == 'supervisor' ? Colors.green : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.supervisor_account, color: selectedRole == 'supervisor' ? Colors.white : Colors.grey),
                              SizedBox(width: 8),
                              Text('Supervisor', style: TextStyle(color: selectedRole == 'supervisor' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                _sectionTitle('Personal Information'),
                _buildField(nameController, 'Full Name', Icons.person),
                _buildField(nicController, 'NIC Number', Icons.credit_card),
                _buildField(phoneController, 'Phone Number', Icons.phone, type: TextInputType.phone),
                _buildField(emailController, 'Email Address', Icons.email, type: TextInputType.emailAddress),
                SizedBox(height: 16),

                if (selectedRole == 'farmer') ...[
                  _sectionTitle('Location Details'),
                  _buildField(addressController, 'Home Address', Icons.home),
                  _buildField(districtController, 'District', Icons.location_city),
                  SizedBox(height: 16),
                  _sectionTitle('Farm Information'),
                  _buildField(landSizeController, 'Land Size (Acres)', Icons.landscape, type: TextInputType.number),
                  _buildField(rubberTreesController, 'Number of Rubber Trees', Icons.park, type: TextInputType.number),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedExperience,
                    decoration: InputDecoration(
                      labelText: 'Tapping Experience',
                      prefixIcon: Icon(Icons.work, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Less than 1 year', '1-3 years', '3-5 years', 'More than 5 years']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (value) => setState(() => selectedExperience = value!),
                  ),
                  SizedBox(height: 16),
                ],

                if (selectedRole == 'supervisor') ...[
                  _sectionTitle('Employment Details'),
                  _buildField(employeeIdController, 'Employee ID', Icons.badge),
                  SizedBox(height: 16),
                ],

                _sectionTitle('Account Setup'),
                TextField(
                  controller: passwordController,
                  obscureText: !passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.green),
                    suffixIcon: IconButton(
                      icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => passwordVisible = !passwordVisible),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
                  ),
                ),
                SizedBox(height: 24),

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
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Register', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800])),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green)),
        ),
      ),
    );
  }
}

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