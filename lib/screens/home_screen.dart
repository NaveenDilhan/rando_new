import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = "Gaming"; // Default category

  void _generateTask() async {
    String result = await OpenAIService().generateTask(selectedCategory); // Pass the selected category
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Generated Task"),
        content: Text(result),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              ElevatedButton(
                onPressed: _generateTask,
                child: const Text("Generate Task"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
