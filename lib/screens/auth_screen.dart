import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController interestFieldController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLogin = true; // Toggle between login and register mode
  bool isLoading = false;

  Future<void> _authenticate() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        // Login logic
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        // Register logic
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Store user details in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'birthdate': birthdateController.text.trim(),
          'address': addressController.text.trim(),
          'interestField': interestFieldController.text.trim(),
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Navigate to Home Screen after success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        obscureText: obscureText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isLogin ? 'Login' : 'Register',
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    if (!isLogin) ...[
                      _buildTextField(firstNameController, 'First Name'),
                      _buildTextField(lastNameController, 'Last Name'),
                      _buildTextField(
                          birthdateController, 'Birthdate (YYYY-MM-DD)'),
                      _buildTextField(addressController, 'Address'),
                      _buildTextField(interestFieldController,
                          'Interested Field (e.g., IT)'),
                      _buildTextField(usernameController, 'Username'),
                    ],
                    _buildTextField(emailController, 'Email'),
                    _buildTextField(passwordController, 'Password',
                        obscureText: true),
                    const SizedBox(height: 20),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _authenticate,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(isLogin ? 'Login' : 'Register'),
                          ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin =
                              !isLogin; // Toggle between login and register
                        });
                      },
                      child: Text(isLogin
                          ? 'New user? Register here'
                          : 'Already have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
