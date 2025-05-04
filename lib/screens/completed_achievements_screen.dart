import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'home_screen.dart'; // Import HomeScreen which contains the feed

class CompletedAchievementsScreen extends StatefulWidget {
  const CompletedAchievementsScreen({super.key});

  @override
  _CompletedAchievementsScreenState createState() =>
      _CompletedAchievementsScreenState();
}

class _CompletedAchievementsScreenState extends State<CompletedAchievementsScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Function to share an achievement as a post and redirect to HomeScreen
  Future<void> _shareAchievement(Map<String, dynamic> achievement) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You need to be logged in to share an achievement.')),
      );
      return;
    }

    try {
      final postData = {
        'title': 'Achievement Unlocked: ${achievement['name'] ?? 'Unknown'}',
        'content':
            'I just earned the "${achievement['name'] ?? 'Unknown'}" achievement! ${achievement['description'] ?? ''}',
        'imageUrl': achievement['imageUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'userId': user!.uid,
      };

      await _firestore.collection('posts').add(postData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievement shared successfully!')),
      );

      // Delay to ensure SnackBar is visible, then navigate to HomeScreen
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing achievement: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to share achievement. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Achievements',
            style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/empty.json',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please sign in to view achievements',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                 ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(user!.uid)
                  .collection('completed_achievements')
                  .orderBy('completedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading achievements'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loading.json',
                      width: 100,
                      height: 100,
                    ),
                  );
                }

                final achievements = snapshot.data?.docs ?? [];

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Lottie.asset(
                                'assets/animations/achievement.json',
                                width: 30,
                                height: 30,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Your Achievements',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          achievements.isEmpty
                              ? Column(
                                  children: [
                                    Lottie.asset(
                                      'assets/animations/empty.json',
                                      width: 100,
                                      height: 100,
                                    ),
                                    const Text(
                                      'No achievements earned yet. Keep completing tasks!',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.75,
                                  ),
                                  itemCount: achievements.length,
                                  itemBuilder: (context, index) {
                                    final achievement = achievements[index].data()
                                        as Map<String, dynamic>;
                                    return GestureDetector(
                                      onTap: () =>
                                          _showAchievementDetails(context, achievement),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 5,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width: 90,
                                                  height: 90,
                                                  decoration: const BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        Colors.purpleAccent,
                                                        Colors.transparent
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                CircleAvatar(
                                                  radius: 40,
                                                  backgroundImage:
                                                      achievement['imageUrl']
                                                                  ?.isNotEmpty ==
                                                              true
                                                          ? NetworkImage(
                                                              achievement['imageUrl']
                                                                  as String)
                                                          : null,
                                                  backgroundColor: Colors.grey[200],
                                                  child: achievement['imageUrl']
                                                              ?.isEmpty !=
                                                          false
                                                      ? Lottie.asset(
                                                          'assets/animations/trophy.json',
                                                          width: 60,
                                                          height: 60,
                                                        )
                                                      : null,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8.0),
                                              child: Text(
                                                achievement['name'] as String? ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _shareAchievement(achievement),
                                              icon: const Icon(Icons.share, size: 16),
                                              label: const Text('Share',
                                                  style:
                                                      TextStyle(fontSize: 12)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.purple,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showAchievementDetails(
      BuildContext context, Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/achievement.json',
              width: 80,
              height: 80,
            ),
            Text(
              achievement['name'] as String? ?? 'Unknown',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Colors.purpleAccent, Colors.transparent],
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: achievement['imageUrl']?.isNotEmpty == true
                      ? NetworkImage(achievement['imageUrl'] as String)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: achievement['imageUrl']?.isEmpty != false
                      ? Lottie.asset(
                          'assets/animations/trophy.json',
                          width: 80,
                          height: 80,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              achievement['description'] as String? ?? 'No description available',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'Completed: ${(achievement['completedAt'] as Timestamp?)?.toDate().toString().substring(0, 16) ?? 'Unknown'}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _shareAchievement(achievement),
              icon: const Icon(Icons.share),
              label: const Text('Share to Feed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}