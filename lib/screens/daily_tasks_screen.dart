import 'package:flutter/material.dart';

class DailyTasksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Tasks")),
      body: Center(child: const Text("Display daily tasks here.")),
    );
  }
}
