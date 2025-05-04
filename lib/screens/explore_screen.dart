import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/openai_service.dart';
import 'task_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final TextEditingController _searchController;
  List<Map<String, dynamic>> subCategories = [];
  List<Map<String, dynamic>> filteredSubCategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_filterSubCategories);
    _fetchSubCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubCategories() async {
    try {
      QuerySnapshot categorySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();

      List<Map<String, dynamic>> allSubCategories = [];

      for (var categoryDoc in categorySnapshot.docs) {
        QuerySnapshot subCategorySnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryDoc.id)
            .collection('sub-categories')
            .get();

        if (subCategorySnapshot.docs.isNotEmpty) {
          var subCats = subCategorySnapshot.docs.map((doc) {
            return {
              'name': doc['name'],
              'imageUrl': doc['imageUrl'] ?? '',
            };
          }).toList();
          allSubCategories.addAll(subCats);
        }
      }

      if (!mounted) return;

      if (allSubCategories.isNotEmpty) {
        setState(() {
          subCategories = allSubCategories;
          filteredSubCategories = List.from(subCategories);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching sub-categories: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _filterSubCategories() {
    String query = _searchController.text.toLowerCase();
    if (!mounted) return;
    setState(() {
      filteredSubCategories = subCategories
          .where((subCategory) => subCategory['name'].toLowerCase().contains(query))
          .toList();
    });
  }

  void _generateFunFactAndTasks(String subCategory) async {
    try {
      Map<String, dynamic> response = await OpenAIService().generateTasks(subCategory);
      if (!mounted) return;

      if (response.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'])),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskScreen(category: subCategory),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating tasks: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
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
          title: const Text("Explore"),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Skills',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : filteredSubCategories.isEmpty
                    ? const Expanded(
                        child: Center(
                          child: Text(
                            'No sub-categories found',
                            style: TextStyle(fontSize: 18, color: Color.fromARGB(255, 158, 158, 158)),
                          ),
                        ),
                      )
                    : Flexible(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredSubCategories.length,
                          itemBuilder: (context, index) {
                            var subCategory = filteredSubCategories[index];
                            return GestureDetector(
                              onTap: () => _generateFunFactAndTasks(subCategory['name']),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Card(
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  color: Colors.blueAccent,
                                  child: Container(
                                    width: 180,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(15.0),
                                          child: CachedNetworkImage(
                                            imageUrl: subCategory['imageUrl'],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            placeholder: (context, url) =>
                                                Container(color: Colors.grey.shade300),
                                            errorWidget: (context, url, error) =>
                                                const Icon(Icons.error, color: Colors.red),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(15.0),
                                          ),
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                subCategory['name'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            const SizedBox(height: 20),
            const Text(
              'Choose a skills to explore and generate daily tasks!',
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
    );
  }
}
