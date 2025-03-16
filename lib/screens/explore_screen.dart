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
  List<Map<String, dynamic>> categories = []; // List of categories with name and imageUrl
  List<Map<String, dynamic>> filteredCategories = []; // Filtered categories
  bool isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(_filterCategories);
  }

  // Fetch categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      print('Fetching categories from Firestore...');
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();

      if (snapshot.docs.isNotEmpty) {
        categories = snapshot.docs.map((doc) {
          return {
            'name': doc['name'],
            'imageUrl': doc['imageUrl'], // Fetching image URL from Firestore
          };
        }).toList();
        filteredCategories = List.from(categories);
        print('Categories fetched: $categories');
      } else {
        print('No categories found in Firestore');
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Filter categories based on search query
  void _filterCategories() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      filteredCategories = categories
          .where((category) => category['name'].toLowerCase().contains(query))
          .toList();
    });
  }

  // Function to generate tasks and fun facts
  void _generateFunFactAndTasks(String category) async {
    try {
      print('Generating task for category: $category');
      String response = await OpenAIService().generateTask(category);
      print('Received response from OpenAI: $response');
      
      if (response.isEmpty) {
        print('Received empty response from OpenAI');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskScreen(fact: response, category: category),
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
              ? const CircularProgressIndicator()
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
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          var category = filteredCategories[index];
                          String categoryName = category['name'];
                          String imageUrl = category['imageUrl'] ?? ''; // Default to empty if no image URL

                          return GestureDetector(
                            onTap: () => _generateFunFactAndTasks(categoryName),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                color: Colors.blueAccent,
                                child: Container(
                                  width: 180, // Fixed width for the cards
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover, // Make the image cover the entire card
                                      colorFilter: ColorFilter.mode(
                                          Colors.black.withOpacity(0.4), BlendMode.darken), // Overlay for readability
                                    ),
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  child: Text(
                                    categoryName,
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
                    const SizedBox(height: 30),
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