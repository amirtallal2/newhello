import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/layout/responsive.dart';

enum MainBottomNavigationTab { home, live, chat, post, profile }

class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key, required this.currentTab});

  final MainBottomNavigationTab currentTab;

  static const Color _primaryBlue = Color(0xFF285F98);
  static const Color _inactive = Color(0xFF9DB2CE);

  @override
  Widget build(BuildContext context) {
    final metrics = ResponsiveMetrics.of(context);
    final iconSize = metrics.size(24).clamp(20, 26).toDouble();
    final labelSize = metrics.font(12, min: 11, max: 13);

    return Container(
      height: metrics.bottomBarHeight(),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.pageHorizontalPadding(compact: 8, regular: 12),
      ),
      color: Colors.white,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Expanded(
              child: _BottomNavItem(
                label: 'الرئيسية',
                icon: Icons.home_rounded,
                isActive: currentTab == MainBottomNavigationTab.home,
                iconSize: iconSize,
                labelSize: labelSize,
                onTap: () {
                  if (currentTab == MainBottomNavigationTab.home) {
                    return;
                  }

                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'اللايف',
                icon: Icons.play_circle_filled_rounded,
                isActive: currentTab == MainBottomNavigationTab.live,
                iconSize: iconSize,
                labelSize: labelSize,
                onTap: () {
                  if (currentTab == MainBottomNavigationTab.live) {
                    return;
                  }

                  Navigator.of(context).pushReplacementNamed(AppRoutes.live);
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'الدردشة',
                icon: Icons.chat_bubble_outline_rounded,
                isActive: currentTab == MainBottomNavigationTab.chat,
                iconSize: iconSize,
                labelSize: labelSize,
                onTap: () {
                  if (currentTab == MainBottomNavigationTab.chat) {
                    return;
                  }

                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.chatInbox);
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'المنشورات',
                icon: Icons.add_circle_outline_rounded,
                isActive: currentTab == MainBottomNavigationTab.post,
                iconSize: iconSize,
                labelSize: labelSize,
                onTap: () {
                  if (currentTab == MainBottomNavigationTab.post) {
                    return;
                  }

                  Navigator.of(context).pushReplacementNamed(AppRoutes.post);
                },
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'الملف',
                icon: Icons.person_outline_rounded,
                isActive: currentTab == MainBottomNavigationTab.profile,
                iconSize: iconSize,
                labelSize: labelSize,
                onTap: () {
                  if (currentTab == MainBottomNavigationTab.profile) {
                    return;
                  }

                  Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
                },
              ),
            ),
          ],
        ),
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
    required this.iconSize,
    required this.labelSize,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final double iconSize;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? MainBottomNavigation._primaryBlue
        : MainBottomNavigation._inactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: iconSize),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: labelSize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
