import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'library_screen.dart';
import 'summary_home_screen.dart';
// Keep the import for the subscriptions screen
import 'subscriptions_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LibraryScreen(),
    const SummaryHomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 FIX: I completely removed the extra AppBar here so they don't stack!
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Vault',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_link),
            label: 'Add Link',
          ),
        ],
      ),
    );
  }
}