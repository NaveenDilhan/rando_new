import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupFirebaseMessaging();
  }

  void _setupFirebaseMessaging() {
    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        setState(() {
          _notifications.insert(0, {
            'title': message.notification!.title ?? 'New Notification',
            'body': message.notification!.body ?? 'You have a new message',
            'timestamp': DateTime.now(),
            'isRead': false,
            'type': 'firebase',
            'data': message.data,
          });
        });
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.notification != null) {
        setState(() {
          _notifications.insert(0, {
            'title': message.notification!.title ?? 'New Notification',
            'body': message.notification!.body ?? 'You have a new message',
            'timestamp': DateTime.now(),
            'isRead': true,
            'type': 'firebase',
            'data': message.data,
          });
        });
      }
    });
  }

  Future<void> _initializeNotifications() async {
    setState(() => _isLoading = true);
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Get initial notifications from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _notifications.clear();
        _notifications.addAll(snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Notification',
            'body': data['body'] ?? '',
            'timestamp': (data['timestamp'] as Timestamp).toDate(),
            'isRead': data['isRead'] ?? false,
            'type': data['type'] ?? 'task',
            'data': data['data'] ?? {},
          };
        }).toList());
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: const Color(0xFF007ACC),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeNotifications,
            tooltip: 'Refresh notifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No New Notifications",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 8),
                      Text("You're all caught up!", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _initializeNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['isRead'] as bool;
                      final timestamp = notification['timestamp'] as DateTime;

                      return Dismissible(
                        key: Key(notification['id'] ?? index.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          if (notification['id'] != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_auth.currentUser?.uid)
                                .collection('notifications')
                                .doc(notification['id'])
                                .delete();
                          }
                          setState(() {
                            _notifications.removeAt(index);
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isRead ? Colors.white : Colors.blue.shade50,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isRead ? Colors.grey : Colors.blue,
                              child: Icon(
                                _getNotificationIcon(notification['type']),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              notification['title'],
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification['body']),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(timestamp),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isRead ? Icons.check_circle : Icons.check_circle_outline,
                                color: isRead ? Colors.grey : Colors.blue,
                              ),
                              onPressed: () {
                                if (!isRead && notification['id'] != null) {
                                  _markAsRead(notification['id']);
                                }
                              },
                            ),
                            onTap: () {
                              if (!isRead && notification['id'] != null) {
                                _markAsRead(notification['id']);
                              }
                              _handleNotificationTap(notification);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'task':
        return Icons.task;
      case 'activity':
        return Icons.history;
      case 'firebase':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'] as Map<String, dynamic>?;

    switch (type) {
      case 'task':
        final taskId = data?['taskId'];
        if (taskId != null) {
          // Navigate to task details or perform task-related action
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task ID: $taskId')),
          );
        }
        break;
      case 'firebase':
        // Handle Firebase notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase notification: ${notification['title']}')),
        );
        break;
      case 'activity':
        // Handle activity notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Activity: ${notification['body']}')),
        );
        break;
    }
  }
}
