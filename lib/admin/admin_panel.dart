import 'package:flutter/material.dart';
import 'package:kavach_hackvortex/admin/reportcheck_screen.dart';
import 'package:kavach_hackvortex/admin/newcheck_screen.dart';
import 'package:kavach_hackvortex/admin/map_admin.dart';
import 'package:kavach_hackvortex/admin/admin_profile.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> menu = [
    {
      'icon': 'assets/icons/file.png',
      'icon_active': 'assets/icons/file_active.png',
      'label': 'Reports',
    },
    {
      'icon': 'assets/icons/news.png',
      'icon_active': 'assets/icons/news_active.png',
      'label': 'News',
    },
    {
      'icon': 'assets/icons/map.png',
      'icon_active': 'assets/icons/map_active.png',
      'label': 'Map',
    },
    {
      'icon': 'assets/icons/user.png',
      'icon_active': 'assets/icons/user_active.png',
      'label': 'Profile',
    },
  ];

  final List<Widget> _screens = [
    const ReportCheckScreen(),
    const NewsCheckScreen(),
    MapAdmin(),
    const AdminProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(menu.length, (index) {
                final item = menu[index];
                final isActive = _selectedIndex == index;
                return SizedBox(
                  width: MediaQuery.of(context).size.width / menu.length,
                  child: InkWell(
                    onTap: () => _onItemTapped(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          isActive
                              ? item['icon_active'] as String
                              : item['icon'] as String,
                          width: 24,
                          height: 24,
                          color:
                              isActive ? const Color(0xFF007AFF) : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.normal,
                            color:
                                isActive
                                    ? const Color(0xFF007AFF)
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}