import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,  // Handle tap on the bottom navigation bar
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: "Explore",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.create),  // New icon for creating a post
          label: "Create",  // Label for the new "Create" tab
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: "Notifications", 
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
    );
  }
}
