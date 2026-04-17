import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';

enum MainBottomNavigationTab { home, live, chat, post, profile }

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key, required this.currentTab});

  final MainBottomNavigationTab currentTab;

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _inactive = Color(0xFF9DB2CE);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 77,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomNavItem(
            label: 'Home',
            icon: Icons.home_rounded,
            isActive: currentTab == MainBottomNavigationTab.home,
            onTap: () {
              if (currentTab == MainBottomNavigationTab.home) {
                return;
              }

              Navigator.of(context).pushReplacementNamed(AppRoutes.home);
            },
          ),
          _BottomNavItem(
            label: 'Live',
            icon: Icons.play_circle_filled_rounded,
            isActive: currentTab == MainBottomNavigationTab.live,
            onTap: () {
              if (currentTab == MainBottomNavigationTab.live) {
                return;
              }

              Navigator.of(context).pushReplacementNamed(AppRoutes.live);
            },
          ),
          _BottomNavItem(
            label: 'Chat',
            icon: Icons.chat_bubble_outline_rounded,
            isActive: currentTab == MainBottomNavigationTab.chat,
            onTap: () {
              if (currentTab == MainBottomNavigationTab.chat) {
                return;
              }

              Navigator.of(context).pushReplacementNamed(AppRoutes.chatInbox);
            },
          ),
          _BottomNavItem(
            label: 'Post',
            icon: Icons.add_circle_outline_rounded,
            isActive: currentTab == MainBottomNavigationTab.post,
            onTap: () {
              if (currentTab == MainBottomNavigationTab.post) {
                return;
              }

              Navigator.of(context).pushReplacementNamed(AppRoutes.post);
            },
          ),
          _BottomNavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            isActive: currentTab == MainBottomNavigationTab.profile,
            onTap: () {
              if (currentTab == MainBottomNavigationTab.profile) {
                return;
              }

              Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
            },
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? MainBottomNavigation._primaryBlue
        : MainBottomNavigation._inactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
