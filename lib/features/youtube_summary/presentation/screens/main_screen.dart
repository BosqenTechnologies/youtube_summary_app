import 'package:flutter/material.dart';
import 'package:youtube_summary_app/core/constants/app_colors.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import 'library_screen.dart';
import 'summary_home_screen.dart';
import 'channel_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Default to Add Link screen as per standard behavior

  final List<Widget> _screens = [
    const LibraryScreen(),
    const SummaryHomeScreen(),
    const ChannelsScreen(), 
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- 4-Color System Setup ---
    final primaryColor = isDark ? AppColors.primaryRedDark : AppColors.primaryRedLight;
    final secondaryText = isDark ? AppColors.darkSecondaryTonal : AppColors.lightSecondaryTonal;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: surfaceColor,
          selectedItemColor: primaryColor,
          unselectedItemColor: secondaryText,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: AppDimensions.fontTiny,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500, 
            fontSize: AppDimensions.fontTiny,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.paddingSmall / 2),
                child: Icon(Icons.inventory_2_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.paddingSmall / 2),
                child: Icon(Icons.inventory_2),
              ),
              label: 'VAULT',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.paddingSmall / 2),
                child: Icon(Icons.add_circle_outline),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.paddingSmall / 2),
                child: Icon(Icons.add_circle),
              ),
              label: 'ADD LINK',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.paddingSmall / 2),
                child: Icon(Icons.subscriptions_outlined),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.paddingSmall / 2),
                child: Icon(Icons.subscriptions),
              ),
              label: 'CHANNELS',
            ),
          ],
        ),
      ),
    );
  }
}