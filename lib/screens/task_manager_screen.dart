import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class TaskManagerScreen extends StatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  _TaskManagerScreenState createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends State<TaskManagerScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  String searchQuery = '';
  String sortBy = 'createdAt';
  bool sortAscending = false;
  List<String> selectedTaskIds = [];
  bool showCompletedTasks = false;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAndUpdateAchievements() async {
    if (user == null) return;

    setState(() => isLoading = true);
    try {
      // Get the count of completed tasks
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('tasks')
          .where('isCompleted', isEqualTo: true)
          .get();
      final completedTasksCount = tasksSnapshot.size;

      // Update user's completedTasks count
      await _firestore.collection('users').doc(user!.uid).set(
        {'completedTasks': completedTasksCount},
        SetOptions(merge: true),
      );

      // Get all available achievements
      final achievementsSnapshot = await _firestore.collection('achievements').get();
      final batch = _firestore.batch();

      for (var achievementDoc in achievementsSnapshot.docs) {
        final achievement = achievementDoc.data();
        final achievementId = achievementDoc.id;
        final requiredTasks = (achievement['requiredTasks'] as num?)?.toInt() ?? 0;

        if (completedTasksCount >= requiredTasks) {
          final completedAchievementRef = _firestore
              .collection('users')
              .doc(user!.uid)
              .collection('completed_achievements')
              .doc(achievementId);

          final completedAchievement = await completedAchievementRef.get();

          if (!completedAchievement.exists) {
            batch.set(completedAchievementRef, {
              'name': achievement['name'] as String? ?? 'Unknown',
              'imageUrl': achievement['imageUrl'] as String? ?? '',
              'description': achievement['description'] as String? ?? '',
              'completedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Commit the batch
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achievements updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating achievements: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteSelectedTasks() async {
    if (selectedTaskIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks selected for deletion')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final batch = _firestore.batch();
      for (var taskId in selectedTaskIds) {
        final ref = _firestore
            .collection('users')
            .doc(user!.uid)
            .collection('tasks')
            .doc(taskId);
        batch.delete(ref);
      }
      await batch.commit();
      setState(() => selectedTaskIds.clear());
      await _checkAndUpdateAchievements();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected tasks deleted successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete tasks: $error')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool currentStatus) async {
    setState(() => isLoading = true);
    try {
      await _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': !currentStatus});
      await _checkAndUpdateAchievements();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $error')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void toggleSortOrder() {
    setState(() => sortAscending = !sortAscending);
  }

  void setSortBy(String newSortBy) {
    setState(() => sortBy = newSortBy);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Task Manager'),
          backgroundColor: Colors.purple,
        ),
        body: const Center(child: Text('Please log in to view your tasks')),
      );
    }

    final userTasksRef = _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('tasks');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
            onPressed: toggleSortOrder,
            tooltip: 'Toggle Sort Order',
          ),
          PopupMenuButton<String>(
            onSelected: setSortBy,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'createdAt', child: Text('Sort by Date')),
              const PopupMenuItem(value: 'task', child: Text('Sort by Task Name')),
            ],
            tooltip: 'Sort Tasks',
          ),
          if (selectedTaskIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: deleteSelectedTasks,
              tooltip: 'Delete Selected Tasks',
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Show Completed Tasks',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: showCompletedTasks,
                      onChanged: (value) => setState(() => showCompletedTasks = value),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: userTasksRef
                      .orderBy(sortBy, descending: !sortAscending)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final allTasks = snapshot.data?.docs.where((doc) {
                      final taskData = doc.data() as Map<String, dynamic>;
                      final taskText = taskData['task']?.toString().toLowerCase() ?? '';
                      return taskText.contains(searchQuery);
                    }).toList() ?? [];

                    final pendingTasks = allTasks.where((task) {
                      final taskData = task.data() as Map<String, dynamic>;
                      return !(taskData['isCompleted'] as bool? ?? false);
                    }).toList();

                    final completedTasks = allTasks.where((task) {
                      final taskData = task.data() as Map<String, dynamic>;
                      return taskData['isCompleted'] as bool? ?? false;
                    }).toList();

                    if (allTasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/empty_tasks.json',
                              width: 200,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.task_alt, size: 100, color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              searchQuery.isEmpty
                                  ? 'No tasks added yet!'
                                  : 'No tasks match your search',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pendingTasks.length,
                              itemBuilder: (context, index) {
                                final task = pendingTasks[index];
                                return _buildTaskTile(task, index);
                              },
                            ),
                          ),
                          if (showCompletedTasks && completedTasks.isNotEmpty) ...[
                            const Divider(height: 20, thickness: 2),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: completedTasks.length,
                                itemBuilder: (context, index) {
                                  final task = completedTasks[index];
                                  return _buildTaskTile(task, index);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(QueryDocumentSnapshot task, int index) {
    final taskData = task.data() as Map<String, dynamic>;
    final taskText = taskData['task'] as String;
    final createdAt = (taskData['createdAt'] as Timestamp?)?.toDate();
    final isCompleted = taskData['isCompleted'] as bool? ?? false;

    return FadeInUp(
      delay: Duration(milliseconds: 200 * index),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          leading: Checkbox(
            value: selectedTaskIds.contains(task.id),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  selectedTaskIds.add(task.id);
                } else {
                  selectedTaskIds.remove(task.id);
                }
              });
            },
          ),
          title: Text(
            taskText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Text(
            createdAt != null
                ? 'Added: ${createdAt.toString().substring(0, 16)}'
                : 'Added: Unknown',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          trailing: IconButton(
            icon: Icon(
              isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            onPressed: () => toggleTaskCompletion(task.id, isCompleted),
            tooltip: isCompleted ? 'Mark as incomplete' : 'Mark as complete',
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}