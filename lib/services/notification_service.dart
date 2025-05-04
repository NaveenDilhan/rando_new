import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Map<String, Timer> _taskReminders = {};

  // Initialize notification service
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(initSettings);

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Reminders for your tasks',
      importance: Importance.high,
      showBadge: true,
      enableVibration: true,
      enableLights: true,
    );

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

  // Show notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Task Reminders',
      channelDescription: 'Reminders for your tasks',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      color: Colors.blue,
      ongoing: false,
      autoCancel: true,
      showProgress: false,
      playSound: true,
      ticker: 'Task Reminder',
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    // Save to Firestore for persistence
    await _saveNotificationToFirestore(
      title: title,
      body: body,
      type: type ?? 'general',
      data: data,
    );
  }

  // Schedule task reminder
  Future<void> scheduleTaskReminder(String taskId, String taskTitle) async {
    // Cancel any existing reminder for this task
    _taskReminders[taskId]?.cancel();
    
    // Schedule new reminder after 5 minutes
    _taskReminders[taskId] = Timer(const Duration(minutes: 300), () async {
      await showNotification(
        title: 'Task Reminder',
        body: 'Don\'t forget to: $taskTitle',
        payload: taskId,
        type: 'task_reminder',
        data: {'taskId': taskId},
      );
    });
  }

  // Handle background messages
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    
    // Initialize local notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Reminders for your tasks',
      importance: Importance.high,
      showBadge: true,
      enableVibration: true,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show the notification
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'Task Reminder',
      message.notification?.body ?? 'You have a task to complete',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders for your tasks',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          enableLights: true,
          color: Colors.blue,
          ongoing: false,
          autoCancel: true,
          showProgress: false,
          playSound: true,
          ticker: 'Task Reminder',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: message.data['taskId'],
    );
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling a foreground message: ${message.messageId}');
    
    // Show notification immediately
    await showNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? 'You have a new message',
      payload: message.data['taskId'],
      type: 'firebase',
      data: message.data,
    );

    // Also show a local notification to ensure it appears in the status bar
    await _localNotifications.show(
      DateTime.now().millisecond,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders for your tasks',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          enableLights: true,
          color: Colors.blue,
          ongoing: false,
          autoCancel: true,
          showProgress: false,
          playSound: true,
          ticker: 'Task Reminder',
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: message.data['taskId'],
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
  Future<void> sendTaskNotification(String title, String body, List<String> tasks) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      // Save notification to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'task',
            'data': {
              'tasks': tasks,
            },
          });

      // Show immediate notification
      await showNotification(
        title: title,
        body: body,
        type: 'task',
        data: {'tasks': tasks},
      );

      // Schedule reminders for each task
      for (var task in tasks) {
        await scheduleTaskReminder(DateTime.now().millisecondsSinceEpoch.toString(), task);
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
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
      'Task Completed',
      'You have completed: $taskTitle',
      [taskId],
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
}
