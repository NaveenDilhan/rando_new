import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            String result = await OpenAIService().generateTask();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: Text(result),
              ),
            );
          },
          child: const Text("Generate Task"),
        ),
      ),
    );
  }
}
