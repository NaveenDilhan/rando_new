import 'package:flutter/material.dart';

class HabitsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Habits")),
      body: Center(child: const Text("Display habit report here.")),
    );
  }
}
