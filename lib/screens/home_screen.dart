import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/openai_service.dart';
import 'task_screen.dart';
import 'user_profile_screen.dart'; // Import the new UserProfileScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String greetingMessage;
  late String motivationalQuote;
  List<Map<String, dynamic>> skillCategories = [];
  List<Map<String, dynamic>> feedItems = [];
  Map<String, dynamic>? currentUserData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    greetingMessage = _getGreeting();
    motivationalQuote = _getMotivationalQuote();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    await _fetchUserData();
    await _fetchSkillCategories();
    await _fetchFeedItems();
    if (mounted) setState(() => isLoading = false);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 18) return "Good Afternoon,";
    return "Good Evening,";
  }

  String _getMotivationalQuote() {
    List<String> quotes = [
      "Every day is a fresh start!",
      "Believe in yourself and all that you are.",
      "The secret of getting ahead is getting started.",
      "Success is the sum of small efforts, repeated daily."
    ];
    return quotes[Random().nextInt(quotes.length)];
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (snapshot.exists && mounted) {
        setState(() {
          currentUserData = snapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user info: $e')),
        );
      }
    }
  }

  Future<void> _fetchSkillCategories() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      if (mounted) {
        skillCategories = snapshot.docs.map((doc) {
          return {
            'name': doc['name'] ?? '',
            'imageUrl': doc['imageUrl'] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching skill categories: $e')),
        );
      }
    }
  }

  Future<void> _fetchFeedItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        feedItems = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'title': doc['title'] ?? '',
            'content': doc['content'] ?? '',
            'imageUrl': doc['imageUrl'] ?? '',
            'createdAt': doc['createdAt'],
            'userId': doc['userId'] ?? '',
          };
        }).toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching feed items: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _getUserDetails(String uid) async {
    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  void _generateFunFactAndTasks(String category) async {
    try {
      Map<String, dynamic> response =
          await OpenAIService().generateTasks(category);

      if (response.containsKey('error')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'])),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskScreen(category: category),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating tasks: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike(String postId, String userId, bool isLiked) async {
    final likeRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId);

    try {
      if (isLiked) {
        await likeRef.delete();
      } else {
        await likeRef.set({
          'likedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating like: $e')),
      );
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
                try {
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
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding comment: $e')),
                  );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _sharePost(String title, String content, String? imageUrl) {
    String shareText = '$title\n$content';
    if (imageUrl != null && imageUrl.isNotEmpty) {
      shareText += '\nImage: $imageUrl';
    }
    Share.share(shareText, subject: 'Check out this post!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFF121212),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _initializeData,
              color: Colors.white,
              backgroundColor: Colors.black,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingSection(),
                    const SizedBox(height: 20),
                    _buildMotivationalCard(),
                    const SizedBox(height: 30),
                    _buildSectionTitle("Recommendations"),
                    _buildSkillCategories(),
                    const SizedBox(height: 30),
                    _buildArtisticDivider(),
                    const SizedBox(height: 30),
                    _buildSectionTitle("Feed"),
                    _buildFeed(),
                  ],
                ),
              ),
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: const Text(
        "Rando",
        style: TextStyle(
          color: Color.fromARGB(255, 0, 163, 255),
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    final name = currentUserData != null
        ? "${currentUserData!['firstName']}"
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          child: Text(
            "$greetingMessage $name",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 5),
        FadeInUp(
          duration: const Duration(milliseconds: 800),
          child: Text(
            "Welcome back! Ready to achieve your goals?",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white60),
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationalCard() {
    return SlideInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 4)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              motivationalQuote,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            Text(
              "🔥 You have completed 3 tasks today!",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.orangeAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSkillCategories() {
    return SizedBox(
      height: 120,
      child: skillCategories.isEmpty
          ? const Center(
              child: Text('No categories found',
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: skillCategories.length,
              itemBuilder: (context, index) {
                var category = skillCategories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: FadeInLeft(
                    duration: const Duration(milliseconds: 500),
                    child: GestureDetector(
                      onTap: () => _generateFunFactAndTasks(category['name']),
                      child: _SkillCategoryCard(category),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildFeed() {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.email?.split('@')[0] ?? 'Anonymous';

    return Column(
      children: feedItems.map((feed) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _getUserDetails(feed['userId']),
          builder: (context, snapshot) {
            final userData = snapshot.data;
            final name = userData != null
                ? "${userData['firstName']} ${userData['lastName']}"
                : 'Anonymous';
            final email = userData?['email'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: feed['userId']),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/profile_placeholder.png'),
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              if (feed['createdAt'] != null)
                                Text(
                                  DateFormat('MMM d, y • h:mm a')
                                      .format(feed['createdAt'].toDate()),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    feed['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feed['content'],
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (feed['imageUrl'].isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(feed['imageUrl']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(feed['id'])
                        .collection('likes')
                        .snapshots(),
                    builder: (context, likeSnapshot) {
                      if (likeSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final likes = likeSnapshot.data?.docs ?? [];
                      final isLiked = user != null && likes.any((like) => like.id == user.uid);
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
                                onPressed: user == null
                                    ? null
                                    : () => _toggleLike(feed['id'], user.uid, isLiked),
                              ),
                              Text(
                                '$likeCount',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.comment, color: Colors.white),
                            onPressed: user == null
                                ? null
                                : () => _addComment(context, feed['id'], user.uid, username),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: () => _sharePost(
                              feed['title'],
                              feed['content'],
                              feed['imageUrl'],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .doc(feed['id'])
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
                              DateFormat('MMM d, y').format(commentTimestamp);

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
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildArtisticDivider() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent, Colors.blueAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}

class _SkillCategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  const _SkillCategoryCard(this.category);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: category['imageUrl'],
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: Colors.grey.shade300),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, color: Colors.red),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          Center(
            child: Text(
              category['name'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}