import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("You have new notifications!", style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 10),
            Text("Check them out below.", style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
