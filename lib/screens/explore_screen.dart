import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import 'task_screen.dart'; // Import the TaskScreen

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<String> categories = [
    "Gaming",
    "Swimming",
    "Coding",
    "Web Designing",
    "Music",
    "Art"
  ];

  void _generateFunFactAndTasks(String category) async {
    String response = await OpenAIService().generateTask(category); // Pass the category
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskScreen(fact: response, category: category), // Pass the fact and category to TaskScreen
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore"),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: 250,  // Increased height for better visibility
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,  // Horizontal scrolling
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _generateFunFactAndTasks(categories[index]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Card(
                          elevation: 8, // Card elevation for a modern look
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0), // Rounded corners for card
                          ),
                          color: Colors.blueAccent,
                          child: Container(
                            width: 180, // Fixed width for the cards
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blueAccent.withOpacity(0.7),
                                  Colors.blue.withOpacity(0.6),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Text(
                              categories[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),  // Space between carousel and other content
              const Text(
                'Choose a category to explore and generate daily tasks!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
