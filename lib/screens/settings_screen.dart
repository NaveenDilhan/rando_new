import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_screen.dart';
import '../theme_notifier.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../services/profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final themeNotifier = ThemeNotifier();
  final profileService = ProfileService();
  bool notificationsEnabled = true;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = themeNotifier.isDarkMode;
  }

  Future<void> handleLogout(BuildContext context) async {
    try {
      await profileService.updateOnlineStatus(false);
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF000000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Account", style: TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward, color: Colors.white),
              tileColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Change Password", style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward, color: Colors.white),
              tileColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
            const SizedBox(height: 30),
            const Text("App Settings", style: TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Notifications", style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: notificationsEnabled,
                onChanged: (val) => setState(() => notificationsEnabled = val),
              ),
              tileColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text("Dark Mode", style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (val) {
                  themeNotifier.toggleTheme(val);
                  setState(() => isDarkMode = val);
                },
              ),
              tileColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 20),
            const Text("Font Size", style: TextStyle(color: Colors.white)),
            DropdownButton<double>(
              value: themeNotifier.fontSize,
              items: const [
                DropdownMenuItem(value: 14.0, child: Text("14")),
                DropdownMenuItem(value: 16.0, child: Text("16")),
                DropdownMenuItem(value: 18.0, child: Text("18")),
                DropdownMenuItem(value: 20.0, child: Text("20")),
              ],
              onChanged: (val) {
                if (val != null) themeNotifier.setFontSize(val);
              },
              dropdownColor: Colors.grey[850],
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => handleLogout(context),
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
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}