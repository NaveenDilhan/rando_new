import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  // Make the constructor public
  factory NotificationService() {
    return _instance;
  }
  
  // Private constructor
  NotificationService._internal() {
    tz.initializeTimeZones();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notification service
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Create the notification channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveFCMToken);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    }
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    
    // Create a notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // Initialize local notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    // Create notification details
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
    );
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling a foreground message: ${message.messageId}');

    // Create notification details
    final notificationDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // Show the notification
    await _localNotifications.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      notificationDetails,
    );

    // Save the notification to Firestore
    await _saveNotificationToFirestore(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? 'You have a new message',
      type: 'firebase',
      data: message.data,
    );
  }

  // Handle notification taps
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    
    // Handle the notification tap based on the data
    final data = message.data;
    if (data['type'] == 'task') {
      // Navigate to task details or perform task-related action
      print('Task notification tapped: ${data['taskId']}');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  // Save notification to Firestore
  Future<void> _saveNotificationToFirestore({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final notification = {
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': type,
      'data': data ?? {},
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification);
  }

  // Send task notification
  Future<void> sendTaskNotification({
    required String userId,
    required String taskId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notification = {
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'task',
      'data': {
        'taskId': taskId,
        ...?data,
      },
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification);
  }

  // Track activity
  Future<void> trackActivity({
    required String userId,
    required String type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final activity = {
      'type': type,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };

    // Save activity to user's activity log
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .add(activity);

    // Create activity notification
    final notification = {
      'title': 'New Activity',
      'body': description,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'activity',
      'data': {
        'activityType': type,
        ...?metadata,
      },
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification);
  }

  // Mark task as completed and send notification
  Future<void> completeTask({
    required String userId,
    required String taskId,
    required String taskTitle,
  }) async {
    // Update task status in Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });

    // Send completion notification
    await sendTaskNotification(
      userId: userId,
      taskId: taskId,
      title: 'Task Completed',
      body: 'You have completed: $taskTitle',
      data: {'status': 'completed'},
    );

    // Track activity
    await trackActivity(
      userId: userId,
      type: 'task_completion',
      description: 'Completed task: $taskTitle',
      metadata: {'taskId': taskId},
    );
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get recent activities
  Stream<QuerySnapshot> getRecentActivities(String userId, {int limit = 10}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Schedule task reminder
  Future<void> scheduleTaskReminder({
    required String userId,
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
  }) async {
    // Save reminder to Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('task_reminders')
        .add({
      'taskId': taskId,
      'taskTitle': taskTitle,
      'reminderTime': reminderTime,
      'isCompleted': false,
    });

    // Schedule local notification
    final androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for your tasks',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: Colors.blue,
      ledColor: Colors.blue,
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.zonedSchedule(
      DateTime.now().millisecond,
      'Task Reminder',
      'Time to work on: $taskTitle',
      tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: jsonEncode({
        'type': 'task_reminder',
        'taskId': taskId,
        'taskTitle': taskTitle,
      }),
    );
  }

  // Cancel task reminder
  Future<void> cancelTaskReminder(String userId, String taskId) async {
    // Remove from Firestore
    final reminders = await _firestore
        .collection('users')
        .doc(userId)
        .collection('task_reminders')
        .where('taskId', isEqualTo: taskId)
        .get();

    for (var reminder in reminders.docs) {
      await reminder.reference.delete();
    }

    // Cancel local notification
    await _localNotifications.cancel(DateTime.now().millisecond);
  }

  // Get pending task reminders
  Stream<QuerySnapshot> getTaskReminders(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('task_reminders')
        .where('reminderTime', isGreaterThan: Timestamp.now())
        .orderBy('reminderTime')
        .snapshots();
  }

  // Handle background task reminders
  static Future<void> handleBackgroundTaskReminder(NotificationResponse response) async {
    if (response.payload != null) {
      final payload = jsonDecode(response.payload!);
      if (payload['type'] == 'task_reminder') {
        // You can add additional background processing here
        print('Handling background task reminder: ${payload['taskTitle']}');
      }
    }
  }

  // Schedule recurring task reminder
  Future<void> scheduleRecurringTaskReminder({
    required String userId,
    required String taskId,
    required String taskTitle,
    required DateTime startTime,
    required String frequency, // 'daily', 'weekly', 'monthly'
    required List<int> weekdays, // For weekly reminders (0-6, Sunday-Saturday)
    required int dayOfMonth, // For monthly reminders (1-31)
  }) async {
    // Save recurring reminder to Firestore
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_reminders')
        .add({
      'taskId': taskId,
      'taskTitle': taskTitle,
      'startTime': startTime,
      'frequency': frequency,
      'weekdays': weekdays,
      'dayOfMonth': dayOfMonth,
      'isActive': true,
    });

    // Schedule the first notification
    await _scheduleNextRecurringNotification(
      userId: userId,
      taskId: taskId,
      taskTitle: taskTitle,
      startTime: startTime,
      frequency: frequency,
      weekdays: weekdays,
      dayOfMonth: dayOfMonth,
    );
  }

  Future<void> _scheduleNextRecurringNotification({
    required String userId,
    required String taskId,
    required String taskTitle,
    required DateTime startTime,
    required String frequency,
    required List<int> weekdays,
    required int dayOfMonth,
  }) async {
    DateTime nextNotificationTime = _calculateNextNotificationTime(
      startTime: startTime,
      frequency: frequency,
      weekdays: weekdays,
      dayOfMonth: dayOfMonth,
    );

    if (nextNotificationTime.isAfter(DateTime.now())) {
      final androidDetails = AndroidNotificationDetails(
        'task_reminders',
        'Task Reminders',
        channelDescription: 'Reminders for your tasks',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        color: Colors.blue,
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.zonedSchedule(
        DateTime.now().millisecond,
        'Task Reminder',
        'Time to work on: $taskTitle',
        tz.TZDateTime.from(nextNotificationTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({
          'type': 'recurring_task_reminder',
          'taskId': taskId,
          'taskTitle': taskTitle,
          'userId': userId,
          'frequency': frequency,
          'weekdays': weekdays,
          'dayOfMonth': dayOfMonth,
        }),
      );
    }
  }

  DateTime _calculateNextNotificationTime({
    required DateTime startTime,
    required String frequency,
    required List<int> weekdays,
    required int dayOfMonth,
  }) {
    final now = DateTime.now();
    DateTime nextTime = startTime;

    switch (frequency) {
      case 'daily':
        if (nextTime.isBefore(now)) {
          nextTime = now.add(const Duration(days: 1));
        }
        break;
      case 'weekly':
        final currentWeekday = now.weekday;
        int daysToAdd = 0;
        
        // Find the next weekday in the list
        for (int i = 0; i < 7; i++) {
          int nextWeekday = (currentWeekday + i) % 7;
          if (weekdays.contains(nextWeekday)) {
            daysToAdd = i;
            break;
          }
        }
        
        nextTime = now.add(Duration(days: daysToAdd));
        break;
      case 'monthly':
        final currentDay = now.day;
        if (currentDay >= dayOfMonth) {
          // Move to next month
          nextTime = DateTime(now.year, now.month + 1, dayOfMonth);
        } else {
          nextTime = DateTime(now.year, now.month, dayOfMonth);
        }
        break;
    }

    return nextTime;
  }

  // Get all active recurring reminders
  Stream<QuerySnapshot> getRecurringReminders(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_reminders')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // Cancel recurring reminder
  Future<void> cancelRecurringReminder(String userId, String reminderId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_reminders')
        .doc(reminderId)
        .update({'isActive': false});

    await _localNotifications.cancel(DateTime.now().millisecond);
  }

  // Smart reminder suggestions
  Future<void> suggestOptimalReminderTime({
    required String userId,
    required String taskId,
    required String taskTitle,
  }) async {
    // Get user's activity patterns from Firestore
    final activities = await _firestore
        .collection('users')
        .doc(userId)
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(30)
        .get();

    // Analyze activity patterns to suggest optimal time
    // This is a simple example - you can make it more sophisticated
    final mostActiveHour = _analyzeActivityPatterns(activities.docs);
    
    final suggestedTime = DateTime.now().add(Duration(hours: mostActiveHour));
    
    await scheduleTaskReminder(
      userId: userId,
      taskId: taskId,
      taskTitle: taskTitle,
      reminderTime: suggestedTime,
    );
  }

  int _analyzeActivityPatterns(List<QueryDocumentSnapshot> activities) {
    // Simple analysis - you can make this more sophisticated
    final hourCounts = List<int>.filled(24, 0);
    
    for (var activity in activities) {
      final timestamp = activity['timestamp'] as Timestamp;
      final hour = timestamp.toDate().hour;
      hourCounts[hour]++;
    }
    
    return hourCounts.indexOf(hourCounts.reduce((a, b) => a > b ? a : b));
  }

  // Notification categories and priorities
  Future<void> sendPriorityNotification({
    required String userId,
    required String title,
    required String body,
    required String category,
    required int priority, // 1-5, where 5 is highest
  }) async {
    final notification = {
      'title': title,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'priority',
      'category': category,
      'priority': priority,
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification);

    // Schedule local notification with appropriate priority
    final androidDetails = AndroidNotificationDetails(
      'priority_notifications',
      'Priority Notifications',
      channelDescription: 'High priority notifications',
      importance: Importance.values[priority - 1],
      priority: Priority.high,
      enableVibration: true,
      enableLights: true,
      color: _getPriorityColor(priority),
      ledColor: _getPriorityColor(priority),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 2:
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}