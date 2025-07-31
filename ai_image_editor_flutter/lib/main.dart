import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/image_provider.dart';
import 'services/audio_service.dart';
import 'services/onesignal_service.dart';
import 'services/video_preload_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ INSTANT STARTUP: Only set critical UI immediately
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  ));
  
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  
  // ✅ IMMEDIATE APP START - No waiting for services
  runApp(const AIImageEditorApp());
  
  // ✅ BACKGROUND INITIALIZATION: Initialize services after app starts
  _initializeServicesInBackground();
}

// ✅ BACKGROUND SERVICE INITIALIZATION: No blocking main thread
void _initializeServicesInBackground() async {
  try {
    // Create features list for video preloading
    final features = [
      SimpleFeature(videoPath: 'assets/videos/remove-backgroud_1753972662268.mp4'),
      SimpleFeature(videoPath: 'assets/videos/expand-image_1753972662375.mp4'),
      SimpleFeature(videoPath: 'assets/videos/Upscaling_1753972662419.mp4'),
      SimpleFeature(videoPath: 'assets/videos/cleanup_1753972662443.mp4'),
      SimpleFeature(videoPath: 'assets/videos/remove-text-demo_1753972669081.mp4'),
      SimpleFeature(videoPath: 'assets/videos/reimagine_1753972669187.mp4'),
      SimpleFeature(videoPath: 'assets/videos/text-to-image_1753972669268.mp4'),
      SimpleFeature(videoPath: 'assets/videos/anh-san-pham_1753972669244.mp4'),
    ];
    
    // Initialize video service first (highest priority for UX)
    VideoPreloadService().preloadAllVideos(features).then((_) {
      print('✅ Video preload service ready');
    }).catchError((e) {
      print('❌ Video preload failed: $e');
    });
    
    // Initialize audio service in background (non-blocking)
    AudioService().initialize().then((_) {
      // Start background music after initialization (optional)
      AudioService().playBackgroundMusic().catchError((e) {
        print('Background music failed to start: $e');
      });
    }).catchError((e) {
      print('Audio service initialization failed: $e');
    });
    
    // Initialize OneSignal in background (non-blocking)
    OneSignalService.initialize().then((_) {
      // Debug after 2 seconds instead of 3 (reduced delay)
      Future.delayed(const Duration(seconds: 2), () {
        OneSignalService.debugStatus().catchError((e) {
          print('OneSignal debug failed: $e');
        });
      });
    }).catchError((e) {
      print('OneSignal initialization failed: $e');
    });
    
  } catch (e) {
    print('Background service initialization error: $e');
  }
}

// Simple feature class for video preloading
class SimpleFeature {
  final String videoPath;
  
  SimpleFeature({required this.videoPath});
}

class AIImageEditorApp extends StatelessWidget {
  const AIImageEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ImageEditProvider(),
      child: MaterialApp(
        title: 'Twink AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366f1),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const SplashScreen(),
      ),
    );
  }
}