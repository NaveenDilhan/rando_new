import 'package:flutter/material.dart';

class TaskManagerScreen extends StatefulWidget {
  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  List<String> tasks = [
    "Complete Flutter tutorial",
    "Review code for the project",
    "Write blog post on Flutter tips",
  ];

  void _addTask(String task) {
    setState(() {
      tasks.add(task);
    });
  }

  void _removeTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Task Manager"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // You can implement a task adding dialog here.
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  TextEditingController taskController = TextEditingController();
                  return AlertDialog(
                    title: const Text('Add New Task'),
                    content: TextField(
                      controller: taskController,
                      decoration: const InputDecoration(hintText: 'Enter task'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (taskController.text.isNotEmpty) {
                            _addTask(taskController.text);
                          }
                          Navigator.of(context).pop();
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tasks[index]),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeTask(index),
            ),
          );
        },
      ),
    );
  }
}
