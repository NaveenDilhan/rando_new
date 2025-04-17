import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _toggleLike(String postId, String userId, bool isLiked) async {
    final likeRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId);

    if (isLiked) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        'likedAt': Timestamp.now(),
      });
    }
  }

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

  void _sharePost(String content, String? imageUrl) {
    String shareText = content;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      shareText += '\nImage: $imageUrl';
    }
    Share.share(shareText, subject: 'Check out this post!');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUsername = currentUser?.email?.split('@')[0] ?? 'Anonymous';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
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
        title: const Text("User Profile"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserData(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (userSnapshot.hasError || userSnapshot.data == null) {
            return const Center(
              child: Text(
                "Unable to load user profile",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final userData = userSnapshot.data!;
          final username = userData['email']?.split('@')[0] ?? 'Anonymous';
          final email = userData['email'] ?? 'No email';
          final displayName = "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}".trim();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  displayName.isNotEmpty ? displayName : username,
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
                const SizedBox(height: 40),
                const Divider(color: Colors.grey),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: userId)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
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
                                    final isLiked = currentUser != null && likes.any((like) => like.id == currentUser.uid);
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
                                              onPressed: currentUser == null
                                                  ? null
                                                  : () => _toggleLike(post.id, currentUser.uid, isLiked),
                                            ),
                                            Text(
                                              '$likeCount',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.comment, color: Colors.white),
                                          onPressed: currentUser == null
                                              ? null
                                              : () => _addComment(context, post.id, currentUser.uid, currentUsername),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.share, color: Colors.white),
                                          onPressed: () => _sharePost(content, imageUrl),
                                        ),
                                      ],
                                    );
                                  },
                                ),
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
          );
        },
      ),
    );
  }
}