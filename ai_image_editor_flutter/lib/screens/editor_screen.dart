import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';
import '../services/clipdrop_service.dart'; // For ProcessingOperation enum
import '../widgets/enhanced_editor_widget.dart';
import '../widgets/result_widget.dart';
import '../widgets/loading_overlay_widget.dart';
import '../widgets/audio_controls_widget.dart';

class EditorScreen extends StatefulWidget {
  final File originalImage;
  final String? preSelectedFeature;
  
  const EditorScreen({
    super.key,
    required this.originalImage,
    this.preSelectedFeature,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultWidgetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    
    // Listen to provider state changes for auto-scroll functionality
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ImageEditProvider>(context, listen: false);
      provider.addListener(_onProviderStateChanged);
    });
  }

  @override
  void dispose() {
    try {
      final provider = Provider.of<ImageEditProvider>(context, listen: false);
      provider.removeListener(_onProviderStateChanged);
    } catch (e) {
      // Handle case where provider is no longer available
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderStateChanged() {
    final provider = Provider.of<ImageEditProvider>(context, listen: false);
    
    // Auto-scroll to results when processing completes (excluding cleanup/object removal)
    if (provider.state == ProcessingState.completed && 
        provider.processedImage != null &&
        provider.currentOperation == null) {
      
      // Skip auto-scroll for object removal/cleanup operations
      final lastOperation = provider.lastCompletedOperation;
      if (lastOperation == ProcessingOperation.cleanup) {
        print('⏭️ Skipping auto-scroll for object removal/cleanup operation');
        return;
      }
      
      // Check if we're still in the same screen context
      if (mounted && _resultWidgetKey.currentContext != null) {
        print('🎯 Auto-scrolling to results after ${lastOperation.toString()} completion');
        
        // Wait a short delay to ensure the result widget is rendered
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollToResults();
          }
        });
      }
    }
  }

  void _scrollToResults() {
    try {
      // Find the result widget context
      final resultContext = _resultWidgetKey.currentContext;
      if (resultContext != null) {
        // Use Scrollable.ensureVisible for accurate positioning
        Scrollable.ensureVisible(
          resultContext,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
          alignment: 0.1, // Show result widget 10% from top of screen
        );
        
        print('✅ Auto-scrolled to results using ensureVisible');
      }
    } catch (e) {
      print('⚠️ Auto-scroll failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for editor screen
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
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Custom AppBar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Back Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () {
                                // Reset provider and go back
                                provider.reset();
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: Color(0xFF6366F1),
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chọn tính năng AI',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF8B5CF6),
                                          Color(0xFFEC4899),
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                      ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Chỉnh sửa ảnh của bạn',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 32,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Editor Section  
                            EnhancedEditorWidget(
                              originalImage: widget.originalImage,
                              preSelectedFeature: widget.preSelectedFeature,
                            ),
                            const SizedBox(height: 24),
                            
                            // Result Section with GlobalKey for auto-scroll targeting
                            if (provider.processedImage != null)
                              Container(
                                key: _resultWidgetKey,
                                child: ResultWidget(
                                  originalImage: provider.originalImage,
                                  processedImage: provider.processedImage!,
                                  onStartOver: () {
                                    provider.reset();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Loading Overlay
              if (provider.currentOperation != null)
                LoadingOverlayWidget(
                  isVisible: provider.currentOperation != null,
                  message: provider.currentOperation?.toString() ?? 'Đang xử lý...',
                ),
                
              // Audio Controls
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                right: 20,
                child: const AudioControlsWidget(),
              ),
            ],
          ),
        );
      },
    );
  }
}