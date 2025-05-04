import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/create_post_screen.dart';  // Import the Create Post Screen
import 'widgets/bottom_nav.dart';
import 'firebase_options.dart';
import 'theme_notifier.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');

    // Initialize Notification Service
    final notificationService = NotificationService();
    await notificationService.initialize();
    print('✅ Notification service initialized successfully!');

    // Firebase Cloud Messaging (FCM) initialization
    await initializeFCM();

    // Firestore test to verify the connection
    var testConnection = await FirebaseFirestore.instance.collection('test').limit(1).get();
    if (testConnection.docs.isNotEmpty) {
      var status = testConnection.docs[0].data()['Status'];
      print('✅ Firestore connected! Status: $status');
    } else {
      print('❓ Firestore test document not found.');
    }
  } catch (e) {
    print('🔥 Error initializing Firebase: $e');
  }

  runApp(const MyApp());
}

// Function to initialize Firebase Cloud Messaging (FCM)
Future<void> initializeFCM() async {
  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $fcmToken');

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission for push notifications
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 Push notifications granted.');
    } else {
      print('🔕 Push notifications denied.');
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message: ${message.notification?.title}");
      // Handle foreground notification
    });

    // Opened from background message handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📨 Opened from background: ${message.notification?.title}");
      // Handle background notification
    });
  } catch (e) {
    print('🔥 Error initializing FCM: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
      valueListenable: ThemeNotifier(),
      builder: (context, theme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Rando',
          theme: theme,
          home: const AuthWrapper(),
          routes: {
            '/login': (context) => const AuthScreen(),
          },
        );
      },
    );
  }
}

// Handles session state (authentication state)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const MainScreen(); // User logged in, show main screen with bottom navigation
        } else {
          return const AuthScreen(); // User not logged in, show auth screen
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ExploreScreen(),
    CreatePostScreen(),  // New Create Post screen
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  // Handle bottom navigation tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Content of the selected tab
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
