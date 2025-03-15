import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _result = "";
  String selectedCategory = "Gaming"; // Default category

  void _searchTask() async {
    if (_searchController.text.isEmpty) return;

    String response = await OpenAIService().generateTask(selectedCategory);
    setState(() {
      _result = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                });
              },
              items: <String>['Gaming', 'Swimming', 'Coding', 'Web Designing', 'Music', 'Art']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Enter a topic...",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchTask,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _result.isNotEmpty
                ? Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_result),
                    ),
                  )
                : const Text("Search for a fun fact or task"),
          ],
        ),
      ),
    );
  }
}
