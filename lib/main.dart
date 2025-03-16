import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore to check connectivity
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/notification_screen.dart'; // Import the NotificationScreen
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav.dart';
import 'firebase_options.dart'; // Import the generated Firebase options

void main() async {
  // Ensure Firebase is initialized before the app starts
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // Automatically generated options from flutterfire configure
    );
    // Add a debug message once Firebase is initialized
    print('Firebase initialized successfully!');
    
    // Check Firestore connection by fetching a test document or collection
    var testConnection = await FirebaseFirestore.instance.collection('test').limit(1).get();
    if (testConnection.docs.isNotEmpty) {
      // Retrieve the 'Status' field from the document
      var status = testConnection.docs[0].data()['Status'];
      if (status != null) {
        print('Firestore connection successful! Status: $status');
      } else {
        print('Firestore connection successful, but Status field is missing.');
      }
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task & Fun Fact Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
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
    const NotificationScreen(), // Added NotificationScreen after ExploreScreen
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
