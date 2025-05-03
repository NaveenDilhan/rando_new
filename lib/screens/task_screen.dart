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
  final NotificationService _notificationService = NotificationService();

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
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final userTasksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks');

      for (var task in tasks) {
        final taskDoc = await userTasksRef.add({
          'task': task,
          'category': widget.category,
          'createdAt': Timestamp.now(),
          'status': 'pending',
        });

        // Send notification for new task
        await _notificationService.sendTaskNotification(
          userId: userId,
          taskId: taskDoc.id,
          title: 'New Task Added',
          body: 'You have a new task: $task',
          data: {'category': widget.category},
        );

        // Track activity
        await _notificationService.trackActivity(
          userId: userId,
          type: 'task_creation',
          description: 'Created new task: $task',
          metadata: {'category': widget.category},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tasks saved successfully!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save tasks')),
        );
      }
    }
  }

  Future<void> completeTask(String taskId, String taskTitle) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _notificationService.completeTask(
        userId: userId,
        taskId: taskId,
        taskTitle: taskTitle,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task marked as completed!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to complete task')),
        );
      }
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
      appBar: AppBar(
        title: Text("${widget.category} Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: regenerateTasks,
          ),
        ],
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

              return Column(
                children: [
                  if (fact != null) ...[
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Fun Fact",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(fact),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "Select Tasks to Follow",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        return FadeInUp(
                          delay: Duration(milliseconds: 300 * index),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              leading: Lottie.asset(
                                'assets/task_icon.json',
                                width: 40,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.task, size: 40, color: Colors.blue),
                              ),
                              title: Text(
                                tasks[index],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => followTasks(tasks),
                      icon: const Icon(Icons.favorite),
                      label: const Text("Follow Selected Tasks"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
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
