import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_screen.dart';
import '../theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // Update user status before logging out
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'logoutTime': FieldValue.serverTimestamp(),
          'isOnline': false,
        });

        // Sign out the user
        await FirebaseAuth.instance.signOut();

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the theme state and notifications setting state
    final themeNotifier = ThemeNotifier();
    final bool isDarkMode = themeNotifier.isDarkMode;
    final bool notificationsEnabled = true; // Replace with actual state for notifications

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF000000), // Black background
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // Back button icon
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Container(
        color: const Color(0xFF1A1A1A), // Darker background for better contrast
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // Notifications toggle
            ListTile(
              title: const Text("Notifications", style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: notificationsEnabled, // Use actual notification setting
                onChanged: (bool value) {
                  // Handle notification toggle state change here
                },
              ),
              tileColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            // Dark Mode toggle
            ListTile(
              title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: isDarkMode, // Use the actual dark mode state
                onChanged: (bool value) {
                  themeNotifier.toggleTheme(value); // Toggle theme
                },
              ),
              tileColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
            // Light Mode toggle
            ListTile(
              title: const Text("Light Mode", style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: !isDarkMode, // Invert the value for light mode toggle
                onChanged: (bool value) {
                  themeNotifier.toggleTheme(!value); // Invert the value for dark mode
                },
              ),
              tileColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            // Font Size Selector
            const Text(
              "Font Size",
              style: TextStyle(color: Colors.white),
            ),
            DropdownButton<double>(
              value: themeNotifier.fontSize, // Use the public getter for font size
              items: const [
                DropdownMenuItem(value: 14.0, child: Text("14", style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 16.0, child: Text("16", style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 18.0, child: Text("18", style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 20.0, child: Text("20", style: TextStyle(color: Colors.black))),
              ],
              onChanged: (double? newValue) {
                if (newValue != null) {
                  themeNotifier.setFontSize(newValue); // Update font size
                }
              },
              dropdownColor: const Color(0xFF2A2A2A), // Dropdown background color
              style: const TextStyle(color: Colors.white), // Dropdown text color
            ),
            const Spacer(),
            // Logout Button
            GestureDetector(
              onTap: () => _handleLogout(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Logout',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
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
}
