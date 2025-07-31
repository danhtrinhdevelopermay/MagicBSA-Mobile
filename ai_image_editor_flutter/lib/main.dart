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