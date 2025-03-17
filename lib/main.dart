import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart'; // Import the authentication screen
import 'widgets/bottom_nav.dart';
import 'firebase_options.dart';
import 'theme_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully!');

    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $fcmToken');

    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Push notifications permission granted.');
    } else {
      print('Push notifications permission denied.');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          "Notification opened from background: ${message.notification?.title}");
    });

    var testConnection =
        await FirebaseFirestore.instance.collection('test').limit(1).get();
    if (testConnection.docs.isNotEmpty) {
      var status = testConnection.docs[0].data()['Status'];
      print(status != null
          ? 'Firestore connected! Status: $status'
          : 'Firestore connected, but no Status field.');
    } else {
      print('Firestore test document not found.');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(const MyApp());
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
          title: 'Task & Fun Fact Generator',
          theme: theme,
          home:
              const AuthWrapper(), // Redirect to authentication or main screen
        );
      },
    );
  }
}

// Checks if the user is authenticated, then navigates accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user == null ? const AuthScreen() : const MainScreen();
        }
        return const Center(
            child: CircularProgressIndicator()); // Loading state
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
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
