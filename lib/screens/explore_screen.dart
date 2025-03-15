import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _fact = "Press the button to generate a fun fact!";

  void _generateFunFact() async {
    String response = await OpenAIService().generateTask();
    setState(() {
      _fact = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Explore")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _fact,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: _generateFunFact,
              child: const Text("Generate Fun Fact"),
            ),
          ],
        ),
      ),
    );
  }
}
