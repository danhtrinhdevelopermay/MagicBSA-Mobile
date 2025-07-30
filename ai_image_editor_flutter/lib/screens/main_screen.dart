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
              const SizedBox(height: 30),
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
      margin: const EdgeInsets.all(20),
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6366f1),
              Color(0xFF8b5cf6),
              Color(0xFFec4899),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366f1).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return _buildNavItem(index);
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isActive = _currentIndex == index;
    final icons = [
      Icons.home_rounded,
      Icons.history_rounded,
      Icons.diamond_rounded,
      Icons.person_rounded,
    ];
    final labels = ['Trang chủ', 'Lịch sử', 'Premium', 'Hồ sơ'];
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 12,
          vertical: 12,
        ),
        decoration: isActive
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              transform: Matrix4.identity()
                ..scale(isActive ? 1.1 : 0.9)
                ..rotateZ(isActive ? 0.05 : 0.0),
              child: Icon(
                icons[index],
                color: Colors.white,
                size: isActive ? 28 : 24,
                shadows: isActive
                    ? [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isActive ? 1.0 : 0.0,
                child: Text(
                  labels[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }
}