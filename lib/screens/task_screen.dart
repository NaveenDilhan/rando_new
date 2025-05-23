import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/openai_service.dart';
import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskScreen extends StatefulWidget {
  final String category;

  const TaskScreen({super.key, required this.category});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late Future<Map<String, dynamic>> taskFuture;
  bool isLoading = true;
  List<bool> selectedTasks = [];
  List<String> tasks = [];

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
      selectedTasks.clear();
      taskFuture = OpenAIService().generateTasks(widget.category);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => isLoading = false);
      });
    });
  }

  Future<void> saveSelectedTasks(List<String> tasks) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save tasks')),
      );
      return;
    }

    try {
      final userTasksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks');

      for (var task in tasks) {
        await userTasksRef.add({
          'task': task,
          'createdAt': Timestamp.now(),
        });
      }

      // Send notification for followed tasks
      final notificationService = NotificationService();
      await notificationService.sendTaskNotification(
        'New Tasks Added',
        'You have ${tasks.length} new tasks to complete!',
        tasks,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tasks saved successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save tasks')),
      );
    }
  }

  void followTasks(List<String> tasks) {
    final selectedTaskList = <String>[];

    for (int i = 0; i < selectedTasks.length; i++) {
      if (selectedTasks[i]) {
        selectedTaskList.add(tasks[i]);
      }
    }

    if (selectedTaskList.isNotEmpty) {
      saveSelectedTasks(selectedTaskList);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one task to follow.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: true,
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
          title: Text("${widget.category} Tasks"),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: taskFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data?['error'] != null) {
                return Center(child: Text(snapshot.data?['error'] ?? 'An error occurred'));
              }

              tasks = List<String>.from(snapshot.data!['tasks']);
              final fact = snapshot.data!['fact'];

              if (selectedTasks.length != tasks.length) {
                selectedTasks = List.generate(tasks.length, (index) => false);
              }

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
                                      const Icon(Icons.task, size: 40, color: Colors.blue),
                                ),
                                title: Text(
                                  tasks[index],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                                trailing: Checkbox(
                                  value: selectedTasks[index],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedTasks[index] = value!;
                                    });
                                  },
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
                          onPressed: () => followTasks(tasks),
                          icon: const Icon(Icons.favorite),
                          label: const Text("Follow"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
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
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}