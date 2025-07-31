import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const BottomNavigationWidget({
    super.key,
    this.currentIndex = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: PhosphorIcons.sparkle(),
                iconFilled: PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                label: 'Generation',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _buildNavItem(
                icon: PhosphorIcons.clockCounterClockwise(),
                iconFilled: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
                label: 'History',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _buildNavItem(
                icon: PhosphorIcons.crown(),
                iconFilled: PhosphorIcons.crown(PhosphorIconsStyle.fill),
                label: 'Premium',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _buildNavItem(
                icon: PhosphorIcons.user(),
                iconFilled: PhosphorIcons.user(PhosphorIconsStyle.fill),
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required PhosphorIconData icon,
    required PhosphorIconData iconFilled,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    const Color activeColor = Color(0xFF6C3EF5); // Purple color
    const Color inactiveColor = Color(0xFF6B7280); // Gray color
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              isActive ? iconFilled : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
                fontFamily: 'SF Pro Display', // Modern sans-serif font
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}