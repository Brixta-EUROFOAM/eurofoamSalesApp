// lib/screens/bottomNavBar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'homeScreen.dart';
import 'profileScreen.dart';
import 'pjpScreen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  // We use the screens array in an IndexedStack to preserve their state.
  final List<Widget> _screens = const [
    HomeScreen(),
    PjpScreen(), // We will build this next
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of the screens (e.g., scroll position, camera state)
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A));
            }
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.lightImpact();
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.white,
          indicatorColor: Colors.blueAccent.withOpacity(0.15),
          elevation: 8,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.home_rounded, color: Colors.blueAccent),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.map_rounded, color: Colors.blueAccent),
              label: 'Journey Plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey),
              selectedIcon: Icon(Icons.person_rounded, color: Colors.blueAccent),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}