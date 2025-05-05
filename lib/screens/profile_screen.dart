import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'task_manager_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import '../services/profile_service.dart';
import 'consultant_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Function to handle liking/unliking a post
  Future<void> _toggleLike(String postId, String userId, bool isLiked) async {
    final likeRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId);

    if (isLiked) {
      // Unlike: Remove the like document
      await likeRef.delete();
    } else {
      // Like: Add a like document
      await likeRef.set({
        'likedAt': Timestamp.now(),
      });
    }
  }

  // Function to add a comment
  Future<void> _addComment(BuildContext context, String postId, String userId, String username) async {
    final commentController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(hintText: 'Enter your comment'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (commentController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .collection('comments')
                    .add({
                  'userId': userId,
                  'username': username,
                  'content': commentController.text.trim(),
                  'createdAt': Timestamp.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // Function to delete a post
  Future<void> _deletePost(BuildContext context, String postId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete the post and its subcollections (likes and comments)
                await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post deleted successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting post: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Function to share a post
  void _sharePost(String content, String? imageUrl) {
    String shareText = content;
    if (imageUrl != null) {
      shareText += '\nImage: $imageUrl';
    }
    Share.share(shareText, subject: 'Check out this post!');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to view your profile"));
    }

    final email = user.email ?? "user@example.com";
    final username = email.split('@')[0];
    final profileService = ProfileService();

    return Scaffold(
      backgroundColor: Colors.black,
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
                    MaterialPageRoute(builder: (context) => const TaskManagerScreen()),
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
                      Icon(Icons.task_alt, color: Color.fromARGB(255, 224, 220, 220)),
                      SizedBox(width: 10),
                      Text('Tasks'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'Achievements',
                  child: Row(
                    children: const [
                      Icon(Icons.emoji_events, color: Color.fromARGB(255, 224, 220, 220)),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConsultantPage()),
          );
        },
        backgroundColor: Colors.lightBlue.withOpacity(0.8),
        mini: true, 
        child: const Icon(Icons.question_mark, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: profileService.loadUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  return CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : '',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  );
                }

                final profileData = snapshot.data!;
                final profileImageUrl = profileData['profileImageUrl'] as String?;
                final bio = profileData['bio'] as String? ?? '';

                return Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blueAccent,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child: profileImageUrl == null
                          ? Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '',
                              style: const TextStyle(fontSize: 40, color: Colors.white),
                            )
                          : null,
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
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        bio,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),
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
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postData = post.data() as Map<String, dynamic>;
                    final postTimestamp = (postData['createdAt'] as Timestamp).toDate();
                    final formattedTime =
                        "${postTimestamp.hour}:${postTimestamp.minute} | ${postTimestamp.day}/${postTimestamp.month}/${postTimestamp.year}";
                    final content = postData['content'] ?? 'No content';
                    final imageUrl = postData['imageUrl'] as String?;

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
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePost(context, post.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              content,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            if (imageUrl != null)
                              Image.network(
                                imageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                              ),
                            const SizedBox(height: 10),
                            // Like, Comment, Share Buttons with Like Count
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(post.id)
                                  .collection('likes')
                                  .snapshots(),
                              builder: (context, likeSnapshot) {
                                if (likeSnapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                final likes = likeSnapshot.data?.docs ?? [];
                                final isLiked = likes.any((like) => like.id == user.uid);
                                final likeCount = likes.length;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                            color: isLiked ? Colors.blue : Colors.white,
                                          ),
                                          onPressed: () => _toggleLike(post.id, user.uid, isLiked),
                                        ),
                                        Text(
                                          '$likeCount',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.comment, color: Colors.white),
                                      onPressed: () => _addComment(context, post.id, user.uid, username),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share, color: Colors.white),
                                      onPressed: () => _sharePost(content, imageUrl),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // Comments Section
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(post.id)
                                  .collection('comments')
                                  .orderBy('createdAt', descending: true)
                                  .snapshots(),
                              builder: (context, commentSnapshot) {
                                if (commentSnapshot.connectionState == ConnectionState.waiting) {
                                  return const SizedBox.shrink();
                                }
                                final comments = commentSnapshot.data?.docs ?? [];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: comments.map((comment) {
                                    final commentData = comment.data() as Map<String, dynamic>;
                                    final commentUsername = commentData['username'] ?? 'Unknown';
                                    final commentContent = commentData['content'] ?? '';
                                    final commentTimestamp = (commentData['createdAt'] as Timestamp).toDate();
                                    final formattedCommentTime =
                                        "${commentTimestamp.day}/${commentTimestamp.month}/${commentTimestamp.year}";

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 5),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 15,
                                            backgroundColor: Colors.blueAccent,
                                            child: Text(
                                              commentUsername.isNotEmpty ? commentUsername[0].toUpperCase() : '',
                                              style: const TextStyle(fontSize: 12, color: Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$commentUsername ($formattedCommentTime)',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  commentContent,
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
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