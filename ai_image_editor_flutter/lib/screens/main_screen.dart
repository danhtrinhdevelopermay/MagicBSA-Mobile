import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../providers/image_provider.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/enhanced_editor_widget.dart';

import '../widgets/result_widget.dart';
import '../widgets/loading_overlay_widget.dart';
import '../widgets/audio_controls_widget.dart';
import '../services/audio_service.dart';
import 'history_screen.dart';
import 'premium_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for main screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
    
    return Consumer<ImageEditProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          extendBodyBehindAppBar: true,
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Main content with PageView
              PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: [
                  _buildHomeScreen(),
                  const HistoryScreen(),
                  const PremiumScreen(),
                  const ProfileScreen(),
                ],
              ),
              
              // Full-screen loading overlay
              if (provider.state == ProcessingState.processing)
                Positioned.fill(
                  child: LoadingOverlayWidget(
                    message: 'Đang xử lý...',
                    isVisible: provider.state == ProcessingState.processing,
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildModernBottomNavigation(),
        );
      },
    );
  }

  Widget _buildHomeScreen() {
    return Consumer<ImageEditProvider>(
      builder: (context, provider, child) {
        return SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Main content
              Expanded(
                child: _buildMainContent(context, provider),
              ),
              
              // Bottom padding for curved navigation
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_fix_high,
                      color: Colors.white,
                      size: 16,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'TwinkBSA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          const Spacer(),
          const AudioControlsWidget(),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF64748b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ImageEditProvider provider) {
    // Check if an image is selected but not yet processing
    if (provider.originalImage != null && provider.state == ProcessingState.idle) {
      return EnhancedEditorWidget(
        originalImage: provider.originalImage!,
      );
    }
    
    switch (provider.state) {
      case ProcessingState.idle:
        return const ImageUploadWidget();
      case ProcessingState.picking:
        return const ImageUploadWidget();
      case ProcessingState.processing:
        return const ImageUploadWidget(); // Show upload widget since overlay handles processing UI
      case ProcessingState.completed:
        return ResultWidget(
          originalImage: provider.originalImage,
          processedImage: provider.processedImage!,
          onStartOver: () => provider.reset(),
        );
      case ProcessingState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFef4444),
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage.isNotEmpty ? provider.errorMessage : 'Đã xảy ra lỗi',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748b),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.reset(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildModernBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF6366f1).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.15),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
            ),
            child: CurvedNavigationBar(
              index: _currentIndex,
              height: 70,
              items: [
                _buildNavIcon(Icons.home_rounded, Icons.home_outlined, 0),
                _buildNavIcon(Icons.history_rounded, Icons.history_outlined, 1),
                _buildNavIcon(Icons.star_rounded, Icons.star_border_rounded, 2),
                _buildNavIcon(Icons.person_rounded, Icons.person_outline_rounded, 3),
              ],
              color: Colors.transparent,
              buttonBackgroundColor: const Color(0xFF6366f1),
              backgroundColor: Colors.transparent,
              animationCurve: Curves.easeInOutCubic,
              animationDuration: const Duration(milliseconds: 700),
              letIndexChange: (index) => true,
              onTap: _onTabTapped,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData activeIcon, IconData inactiveIcon, int index) {
    final isActive = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutBack,
      transform: Matrix4.identity()
        ..scale(isActive ? 1.1 : 1.0)
        ..rotateZ(isActive ? 0.1 : 0.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.elasticOut,
        switchOutCurve: Curves.easeInBack,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey('$index-$isActive'),
          padding: const EdgeInsets.all(2),
          decoration: isActive
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 1,
                    ),
                  ],
                )
              : null,
          child: Icon(
            isActive ? activeIcon : inactiveIcon,
            size: isActive ? 30 : 26,
            color: isActive 
                ? Colors.white 
                : const Color(0xFF6366f1).withOpacity(0.8),
          ),
        ),
      ),
    );
  }


}