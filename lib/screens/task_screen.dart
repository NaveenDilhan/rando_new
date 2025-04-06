import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import '../services/openai_service.dart';

class TaskScreen extends StatefulWidget {
  final String category;

  const TaskScreen({super.key, required this.category});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late Future<Map<String, dynamic>> taskFuture;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    taskFuture = OpenAIService().generateTasks(widget.category);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => isLoading = false);
      }
    });
  }

  void regenerateTasks() {
    setState(() {
      isLoading = true;
      taskFuture = OpenAIService().generateTasks(widget.category);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => isLoading = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.category} Tasks")),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: taskFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data?['error'] != null) {
                return Center(child: Text(snapshot.data?['error'] ?? 'An error occurred'));
              }

              final tasks = snapshot.data!['tasks'];
              final fact = snapshot.data!['fact'];

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        "Category: ${widget.category}",
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeInLeft(
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        "Fun Fact: $fact",
                        style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return FadeInUp(
                            delay: Duration(milliseconds: 300 * index),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                leading: Lottie.asset(
                                  'assets/task_icon.json',
                                  width: 40,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.task, size: 40, color: Colors.blue),
                                ),
                                title: Text(
                                  tasks[index],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: regenerateTasks,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Regenerate"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite),
                          label: const Text("Follow"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          if (isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
