import 'package:flutter/material.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key, required String fact, required String category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Your Tasks for Today", style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 10),
            Text("Complete them on time!", style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
