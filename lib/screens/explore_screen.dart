import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import 'task_screen.dart'; // Import the TaskScreen

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<String> categories = []; // List of all categories
  List<String> filteredCategories = []; // List for filtered categories based on search input
  bool isLoading = true; // To show a loading indicator until data is fetched
  TextEditingController _searchController = TextEditingController(); // Controller for search bar

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories from Firestore when the screen is initialized
    _searchController.addListener(_filterCategories); // Add listener to search input
  }

  // Function to fetch categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      print('Fetching categories from Firestore...');
      // Fetch categories collection from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
      
      // Check if data is returned
      if (snapshot.docs.isNotEmpty) {
        categories = snapshot.docs.map((doc) => doc['name'] as String).toList();
        filteredCategories = List.from(categories); // Initially, show all categories
        print('Categories fetched: $categories'); // Debugging print statement
      } else {
        print('No categories found in Firestore');
      }

      setState(() {
        isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to filter categories based on search query
  void _filterCategories() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredCategories = categories
          .where((category) => category.toLowerCase().contains(query))
          .toList();
    });
  }

  void _generateFunFactAndTasks(String category) async {
    try {
      print('Generating task for category: $category');
      String response = await OpenAIService().generateTask(category); // Pass the category
      print('Received response from OpenAI: $response');
      
      if (response.isEmpty) {
        print('Received empty response from OpenAI');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskScreen(fact: response, category: category), // Pass the fact and category to TaskScreen
        ),
      );
    } catch (e) {
      print('Error generating task: $e');
    }
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
          child: isLoading
              ? const CircularProgressIndicator() // Show a loading indicator while fetching data
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Categories',
                          hintText: 'Enter category name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    // Category Carousel
                    SizedBox(
                      height: 250, // Height for the carousel
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, // Horizontal scrolling
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          print('Building category card for: ${filteredCategories[index]}');
                          return GestureDetector(
                            onTap: () => _generateFunFactAndTasks(filteredCategories[index]),
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
                                    filteredCategories[index],
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
                    const SizedBox(height: 30), // Space between carousel and other content
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
