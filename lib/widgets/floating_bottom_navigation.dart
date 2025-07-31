import 'package:flutter/material.dart';

class FloatingBottomNavigation extends StatelessWidget {
  const FloatingBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade600,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.auto_awesome,
                label: 'Generation',
                isActive: true,
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/generation',
                    (route) => false,
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.history,
                label: 'History',
                isActive: false,
                onTap: () {
                  // Navigate to history
                },
              ),
              _buildNavItem(
                icon: Icons.workspace_premium,
                label: 'Premium',
                isActive: false,
                onTap: () {
                  // Navigate to premium
                },
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                isActive: false,
                onTap: () {
                  // Navigate to profile
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isActive ? 24 : 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}