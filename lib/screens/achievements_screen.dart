import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:lottie/lottie.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoadingAchievements = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    if (user != null) {
      _checkAndUpdateAchievements();
    } else {
      if (kDebugMode) {
        print('AchievementsScreen: No user logged in');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAndUpdateAchievements() async {
    if (user == null) {
      if (kDebugMode) {
        print('AchievementsScreen: Cannot update achievements, user is null');
      }
      return;
    }

    setState(() => _isLoadingAchievements = true);
    
    try {
      if (kDebugMode) {
        print('AchievementsScreen: Checking achievements for user ${user!.uid}');
      }

      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('tasks')
          .where('isCompleted', isEqualTo: true)
          .get();
      final completedTasksCount = tasksSnapshot.size;
      
      await _firestore.collection('users').doc(user!.uid).set(
        {'completedTasks': completedTasksCount},
        SetOptions(merge: true),
      );

      final achievementsSnapshot = await _firestore.collection('achievements').get();
      final batch = _firestore.batch();

      for (var achievementDoc in achievementsSnapshot.docs) {
        final achievement = achievementDoc.data();
        final achievementId = achievementDoc.id;
        final requiredTasks = (achievement['requiredTasks'] as num?)?.toInt() ?? 0;

        if (completedTasksCount >= requiredTasks) {
          final completedAchievementRef = _firestore
              .collection('users')
              .doc(user!.uid)
              .collection('completed_achievements')
              .doc(achievementId);

          final completedAchievement = await completedAchievementRef.get();

          if (!completedAchievement.exists) {
            batch.set(completedAchievementRef, {
              'name': achievement['name'] as String? ?? 'Unknown',
              'imageUrl': achievement['imageUrl'] as String? ?? '',
              'description': achievement['description'] as String? ?? '',
              'completedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        print('AchievementsScreen: Firebase error - ${e.code}: ${e.message}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase error updating achievements: ${e.message}')),
        );
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('AchievementsScreen: Unexpected error - $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected error updating achievements: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAchievements = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: true,
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
          title: const Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
          : _isLoadingAchievements
              ? Center(
                  child: Lottie.asset(
                    'assets/animations/loading.json',
                    width: 100,
                    height: 100,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _checkAndUpdateAchievements,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildUserStats(),
                        const SizedBox(height: 32),
                        _buildBadgesSection(),
                        const SizedBox(height: 32),
                        _buildLeaderboardSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildUserStats() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading stats'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final completedTasks = (data?['completedTasks'] as num?)?.toInt() ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Tasks Completed', '$completedTasks', Icons.task_alt),
                _buildStatItem('Rank', '#${data?['rank'] ?? 'N/A'}', Icons.leaderboard),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return StreamBuilder<QuerySnapshot>(
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
          return const Center(child: CircularProgressIndicator());
        }

        final achievements = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Lottie.asset(
                    'assets/animations/achievement.json',
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Achievements',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            achievements.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
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
                    ),
                  )
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: achievements.length,
                      itemBuilder: (context, index) {
                        final achievement = achievements[index].data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () => _showAchievementDetails(context, achievement),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const RadialGradient(
                                          colors: [Colors.blueAccent, Colors.transparent],
                                        ),
                                      ),
                                    ),
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundImage: achievement['imageUrl']?.isNotEmpty == true
                                          ? NetworkImage(achievement['imageUrl'] as String)
                                          : null,
                                      backgroundColor: Colors.grey[200],
                                      child: achievement['imageUrl']?.isEmpty != false
                                          ? Lottie.asset(
                                              'assets/animations/trophy.json',
                                              width: 60,
                                              height: 60,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    achievement['name'] as String? ?? 'Unknown',
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
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        );
      },
    );
  }

  void _showAchievementDetails(BuildContext context, Map<String, dynamic> achievement) {
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
              'assets/animations/trophy.json',
              width: 80,
              height: 80,
            ),
            Text(
              achievement['name'] as String? ?? 'Unknown',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
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
                      colors: [Colors.blueAccent, Colors.transparent],
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
                          'assets/animations/leaderboard.json',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.blueAccent,
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

  Widget _buildLeaderboardSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .orderBy('completedTasks', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading leaderboard'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Lottie.asset(
                    'assets/animations/leaderboard.json',
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            users.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Lottie.asset(
                          'assets/animations/leaderboard.json',
                          width: 100,
                          height: 100,
                        ),
                        const Text(
                          'No leaderboard data available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: index < 3
                                ? index == 0
                                    ? Colors.amber
                                    : index == 1
                                        ? Colors.grey
                                        : Colors.brown
                                : Colors.blueAccent,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            userData['firstName'] as String? ?? 'Anonymous',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Tasks: ${(userData['completedTasks'] as num?)?.toInt() ?? 0}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: index < 3
                              ? Lottie.asset(
                                  'assets/animations/trophy.json',
                                  width: 130,
                                  height: 130,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ],
        );
      },
    );
  }
}