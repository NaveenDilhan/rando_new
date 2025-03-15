import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage("assets/profile_placeholder.jpeg"),
            ),
            const SizedBox(height: 10),
            const Text(
              "User Name",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("username@example.com"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add logout functionality here
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
