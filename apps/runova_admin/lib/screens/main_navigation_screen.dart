import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_header.dart';
import 'dashboard/dashboard_screen.dart';
import 'print_pos/print_pos_screen.dart';
import 'retail/retail_screen.dart';
import 'repairs/repairs_screen.dart';
import 'more/more_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigateToTab: _onTabTapped),
      const RetailScreen(),
      const PrintPosScreen(),
      const RepairsScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      appBar: AppHeader(
        onNotificationsTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications: 1 pending repair ready for delivery.')),
          );
        },
        onProfileTap: () {
          _onTabTapped(4); // navigate to More tab
        },
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 8,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home', 'হোম'),
                _navItem(1, Icons.point_of_sale_outlined, Icons.point_of_sale, 'Retail', 'খুচরা'),
                _navItem(2, Icons.print_outlined, Icons.print, 'Print', 'প্রিন্ট'),
                _navItem(3, Icons.build_outlined, Icons.build, 'Repairs', 'মেরামত'),
                _navItem(4, Icons.widgets_outlined, Icons.widgets, 'More', 'আরো'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label, String bengali) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceContainerHigh.withValues(alpha: 0.6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 22,
                color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                ),
              ),
              Text(
                bengali,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.8) : AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
