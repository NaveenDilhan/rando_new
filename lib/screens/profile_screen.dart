import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_manager_screen.dart';
import 'habits_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If the user is not logged in, show a login prompt or redirect to login screen
      return Center(child: Text("Please log in to view your profile"));
    }

    final email = user.email ?? "user@example.com";
    final username = email.split('@')[0];

    return Scaffold(
      backgroundColor: Colors.black, // Dark background for the entire screen
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 0, 163, 255),
                Color.fromARGB(255, 0, 123, 200),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>( 
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'Tasks':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TaskManagerScreen()),
                  );
                  break;
                case 'Habits':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HabitsScreen()),
                  );
                  break;
                case 'Achievements':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Tasks',
                  child: Row(
                    children: const [
                      Icon(Icons.task_alt, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Tasks'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Habits',
                  child: Row(
                    children: const [
                      Icon(Icons.list, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Habits'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Achievements',
                  child: Row(
                    children: const [
                      Icon(Icons.emoji_events, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Achievements'),
                    ],
                  ),
                ),
              ];
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Start content from the top
          crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Welcome, $username",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 40), // Extra space to separate profile section
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),
            // Fetch and display posts specific to the currently logged-in user
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final posts = snapshot.data?.docs ?? [];
                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      "No posts available.",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true, // Important to allow scrolling within a scrollable widget
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postTimestamp = (post['createdAt'] as Timestamp).toDate();
                    final formattedTime = "${postTimestamp.hour}:${postTimestamp.minute} | ${postTimestamp.day}/${postTimestamp.month}/${postTimestamp.year}";

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Post header with avatar and username
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blueAccent,
                                  child: Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : '',
                                    style: const TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  username,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  formattedTime,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Post content
                            Text(
                              post['content'] ?? 'No content',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            // Post image if available
                            if (post['imageUrl'] != null)
                              Image.network(post['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                            const SizedBox(height: 10),
                            // Interaction buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.thumb_up, color: Colors.white),
                                  onPressed: () {
                                    // Like post action
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.comment, color: Colors.white),
                                  onPressed: () {
                                    // Comment on post action
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white),
                                  onPressed: () {
                                    // Share post action
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
