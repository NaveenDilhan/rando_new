import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'daily_tasks_screen.dart';
import 'habits_screen.dart';
import 'achievements_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import '../services/openai_service.dart'; 
import 'task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String greetingMessage;
  late String motivationalQuote;
  List<bool> taskCompletion = [false, false, false];
  List<Map<String, dynamic>> skillCategories = [];
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    greetingMessage = _getGreeting();
    motivationalQuote = _getMotivationalQuote();
    _fetchSkillCategories();
  }

  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning,";
    } else if (hour < 18) {
      return "Good Afternoon,";
    } else {
      return "Good Evening,";
    }
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

  Future<void> _fetchSkillCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          skillCategories = snapshot.docs.map((doc) {
            return {
              'name': doc['name'],
              'imageUrl': doc['imageUrl'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching skill categories: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _generateFunFactAndTasks(String category) async {
    try {
      Map<String, dynamic> response = await OpenAIService().generateTasks(category);
      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'])),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskScreen(category: category),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating tasks: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
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
            _buildArtisticDivider(), // Artistic divider between sections
            const SizedBox(height: 30),
            _buildSectionTitle("Personalized Challenges & More"),
            _buildChallengesGrid(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF000000),
      elevation: 0,
      title: const Text(
        "Rando",
        style: TextStyle(
          color: Color(0xFF00A3FF),
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeInUp(
          duration: const Duration(seconds: 1),
          child: Text(greetingMessage, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 5),
        FadeInUp(
          duration: const Duration(seconds: 1),
          child: Text("Welcome back! Ready to achieve your goals?",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
        ),
      ],
    );
  }

  Widget _buildMotivationalCard() {
    return SlideInUp(
      duration: const Duration(seconds: 1),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(motivationalQuote, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Text("🔥 You have completed 3 tasks today!",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.orangeAccent)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSkillCategories() {
    return SizedBox(
      height: 120,
      child: isLoading
          ? const _LoadingIndicator()
          : skillCategories.isEmpty
              ? const Center(child: Text('No categories found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: skillCategories.length,
                  itemBuilder: (context, index) {
                    var category = skillCategories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: FadeInLeft(
                        duration: const Duration(seconds: 1),
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

  Widget _buildChallengesGrid() {
    List<Map<String, dynamic>> challenges = [
      {'icon': Icons.task, 'label': 'Daily Tasks', 'page': DailyTasksScreen()},
      {'icon': Icons.fitness_center, 'label': 'Habits', 'page': HabitsScreen()},
      {'icon': Icons.star, 'label': 'Achievements', 'page': AchievementsScreen()},
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: Lottie.asset(
            'assets/animations/challenge_background.json', // Ensure the Lottie animation exists
            fit: BoxFit.cover,
            repeat: true,
            animate: true,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => challenges[index]['page']),
                );
              },
              child: BounceIn(
                duration: const Duration(seconds: 1),
                child: _ChallengeCard(challenges[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildArtisticDivider() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent, Colors.blueAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
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
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              imageUrl: category['imageUrl'],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey.shade300),
              errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
            ),
          ),
          // Darken the background with an overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5), // Darken the background with opacity
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

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  const _ChallengeCard(this.challenge);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), spreadRadius: 2, blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(challenge['icon'], size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(challenge['label'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
