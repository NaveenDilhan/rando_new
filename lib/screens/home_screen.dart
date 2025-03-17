import 'package:flutter/material.dart';
// import '../services/openai_service.dart';
import 'profile_screen.dart'; // Import the profile screen
import 'dart:math'; // For random motivational quotes
import 'settings_screen.dart'; // Import the settings screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Function to get a greeting message based on the time of day
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

  // Function to get a random motivational quote
  String _getMotivationalQuote() {
    List<String> quotes = [
      "Every day is a fresh start!",
      "Believe in yourself and all that you are.",
      "The secret of getting ahead is getting started.",
      "Success is the sum of small efforts, repeated daily."
    ];
    return quotes[Random().nextInt(quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000), // Black background
        elevation: 0,
        title: const Text(
          "Rando", // App Name
          style: TextStyle(
            color: Color(0xFF0099FF), // Blue text
            fontSize: 26, // Increased font size for the app name
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false, // App name is left-aligned
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // TODO: Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              // Navigate to Profile Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings,
                color: Colors.white), // Settings icon
            onPressed: () {
              // Navigate to Settings Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF000000), // Black background
      body: SingleChildScrollView(
        // Make the body scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              _getGreeting(), // Dynamic greeting message
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 5),
            Text(
              "Welcome back! Ready to achieve your goals?",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Darker gray background
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMotivationalQuote(), // Random motivational quote
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "🔥 You have completed 3 tasks today!",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Skill Categories",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            // Skill Categories Section (Scrollable)
            SizedBox(
              height: 150, // Set height for scrollable section
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSkillCategory(context, Icons.fitness_center, "Fitness"),
                  _buildSkillCategory(context, Icons.music_note, "Music"),
                  _buildSkillCategory(context, Icons.school, "Teaching"),
                  _buildSkillCategory(context, Icons.sports, "Sports"),
                  _buildSkillCategory(context, Icons.directions_run, "Dance"),
                  _buildSkillCategory(context, Icons.code, "Code"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              "Today's Personalized Challenges",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            // Daily Task & AI Recommendation Section
            Column(
              children: [
                _buildDailyTask(context, "Practice coding for 30 minutes"),
                _buildDailyTask(context, "Complete a workout session"),
                _buildDailyTask(context, "Practice playing your favorite song"),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Habit Tracker / Streaks",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            // Habit Tracker Section with Calendar View and Streaks
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Darker gray background
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  // Calendar view placeholder (you can use a calendar package for an actual calendar)
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You're on a 5-day streak!",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Keep it up! You're doing amazing!",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Gamification & Rewards Section
            Text(
              "Gamification & Rewards",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Darker gray background
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "XP Points Earned: 120",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Badges Earned: Code Master, Fitness Guru, Dance Enthusiast",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Leaderboard: You are ranked #4 in the global leaderboard!",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Handle achievements
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor:
                          const Color(0xFF0099FF), // Blue background
                    ),
                    child: const Text("View Achievements"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build skill category icons with labels
  Widget _buildSkillCategory(
      BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // Handle navigation to respective skill module (not implemented here)
        // For example, you can navigate to a new screen:
        // Navigator.push(context, MaterialPageRoute(builder: (context) => SkillModuleScreen(skill: label)));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        width: 100,
        decoration: BoxDecoration(
          color:
              const Color(0xFF1A1A1A), // Dark background for skill categories
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  // Function to build each daily task with completion indicator and CTA button
  Widget _buildDailyTask(BuildContext context, String taskDescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark gray background for tasks
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                taskDescription,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 5),
              Text(
                "Progress: In Progress", // You can update this dynamically
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          Column(
            children: [
              Checkbox(
                value:
                    false, // This should be tied to the task completion state
                onChanged: (bool? value) {
                  // Update task completion state
                },
                checkColor: Colors.white,
                activeColor: const Color(0xFF0099FF), // Blue
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  // TODO: Handle "Start Task" action
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF0099FF),
                ),
                child: const Text("Start Task"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import '../services/openai_service.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   String selectedCategory = "Gaming"; // Default category

//   void _generateTask() async {
//     String result = await OpenAIService().generateTask(selectedCategory); // Pass the selected category
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Generated Task"),
//         content: Text(result),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: const Text("Close"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Home")),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               DropdownButton<String>(
//                 value: selectedCategory,
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     selectedCategory = newValue!;
//                   });
//                 },
//                 items: <String>['Gaming', 'Swimming', 'Coding', 'Web Designing', 'Music', 'Art']
//                     .map<DropdownMenuItem<String>>((String value) {
//                   return DropdownMenuItem<String>(
//                     value: value,
//                     child: Text(value),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _generateTask,
//                 child: const Text("Generate Task"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
