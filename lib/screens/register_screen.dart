import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'interest_selection_screen.dart'; // Import the Interest Selection screen

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  // Method to authenticate user for registration
  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Upload user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'uid': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isOnline': true,
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'address': addressController.text.trim(),
        'birthdate': birthdateController.text.trim(),
      });

      // After registration, navigate to the Interest Selection screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InterestSelectionScreen(userCredential.user!.uid),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e);
    } catch (e) {
      _showErrorDialog(e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorDialog(dynamic error) {
    String message = 'An unexpected error occurred.';
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          message = 'Email already in use.';
          break;
        case 'weak-password':
          message = 'Password should be at least 6 characters.';
          break;
        default:
          message = error.message ?? message;
          break;
      }
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(  // To avoid overflow on small screens
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField(
              label: 'Email',
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter an email';
                if (!value.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Password',
              controller: passwordController,
              keyboardType: TextInputType.text,
              obscureText: !isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter a password';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'First Name',
              controller: firstNameController,
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your first name';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Last Name',
              controller: lastNameController,
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your last name';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Address',
              controller: addressController,
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your address';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              label: 'Birthdate',
              controller: birthdateController,
              keyboardType: TextInputType.datetime,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your birthdate';
                return null;
              },
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: _authenticate,
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            spreadRadius: 3,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.black.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
