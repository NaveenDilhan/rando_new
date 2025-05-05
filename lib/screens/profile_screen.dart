import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rando_new/screens/consultant_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadUserProfile();
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
    final doc = await _firestore.collection('users').doc(user!.uid).get();
    return doc.data();
  }

  Future<void> _pickAndUploadImage(String type) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final path = 'users/${user!.uid}/${type}_photo.jpg';
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    final imageUrl = await ref.getDownloadURL();

    await _firestore.collection('users').doc(user!.uid).update({
      if (type == 'profile') 'profileImageUrl': imageUrl,
      if (type == 'cover') 'coverPhotoUrl': imageUrl,
    });

    setState(() {
      _profileFuture = _loadUserProfile(); // Refresh UI
    });
  }

  Future<void> _editBio(String currentBio) async {
    final TextEditingController bioController =
        TextEditingController(text: currentBio);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Edit Bio', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: bioController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter your bio',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newBio = bioController.text.trim();
              await _firestore.collection('users').doc(user!.uid).update({
                'bio': newBio,
              });
              Navigator.pop(context);
              setState(() {
                _profileFuture = _loadUserProfile(); // Refresh UI
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text("Please log in to view your profile"));
    }

    final email = user!.email ?? "user@example.com";
    final username = email.split('@')[0];

    return Scaffold(
      backgroundColor: Colors.grey[900],
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Text('?', style: TextStyle(fontSize: 24)),
        onPressed: () {
          // Navigate to consultant page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConsultantPage()),
          );
        },
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? {};
          final profileImageUrl = data['profileImageUrl'] as String?;
          final coverPhotoUrl = data['coverPhotoUrl'] as String?;
          final bio = data['bio'] ?? 'Software Developer';

          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () => _pickAndUploadImage('cover'),
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          image: coverPhotoUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(coverPhotoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: const Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.camera_alt, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: 20,
                      child: GestureDetector(
                        onTap: () => _pickAndUploadImage('profile'),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null
                              ? Text(
                                  username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bio,
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () => _editBio(bio),
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text('Edit Bio',
                      style: TextStyle(color: Colors.white)),
                ),
                const Divider(height: 30, color: Colors.grey),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("Posts", "10"),
                    _buildStatItem("Connections", "120"),
                    _buildStatItem("Views", "800"),
                  ],
                ),
                const Divider(height: 30, color: Colors.grey),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            )),
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: user!.uid)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final posts = snapshot.data!.docs;
                    if (posts.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No recent posts",
                            style: TextStyle(color: Colors.white)),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post =
                            posts[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading:
                              const Icon(Icons.article, color: Colors.white),
                          title: Text(post['content'] ?? 'No Content',
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            post['createdAt'] != null
                                ? post['createdAt'].toDate().toString()
                                : '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
