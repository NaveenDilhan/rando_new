import 'package:flutter/material.dart';
import 'package:rando_new/theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                value: true, // Replace with actual state
                onChanged: (bool value) {
                  // Handle notification toggle
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
                value: false, // Replace with actual state
                onChanged: (bool value) {
                  // Handle dark mode toggle
                  ThemeNotifier().toggleTheme(value);
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
                value: false, // Replace with actual state
                onChanged: (bool value) {
                  // Handle light mode toggle
                  ThemeNotifier().toggleTheme(!value); // Invert the value for dark mode
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
              value: ThemeNotifier().fontSize, // Use the public getter for font size
              items: const [
                DropdownMenuItem(value: 14.0, child: Text("14", style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 16.0, child: Text("16", style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 18.0, child: Text("18", style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: 20.0, child: Text("20", style: TextStyle(color: Colors.black))),
              ],
              onChanged: (double? newValue) {
                if (newValue != null) {
                  ThemeNotifier().setFontSize(newValue); // Update font size
                }
              },
              dropdownColor: const Color(0xFF2A2A2A), // Dropdown background color
              style: const TextStyle(color: Colors.white), // Dropdown text color
            ),
          ],
        ),
      ),
    );
  }
} 