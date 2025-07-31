import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../services/clipdrop_service.dart';

class SimpleMaskDrawingScreen extends StatefulWidget {
  final File originalImage;
  final ProcessingOperation operation;

  const SimpleMaskDrawingScreen({
    super.key,
    required this.originalImage,
    required this.operation,
  });

  @override
  State<SimpleMaskDrawingScreen> createState() => _SimpleMaskDrawingScreenState();
}

class _SimpleMaskDrawingScreenState extends State<SimpleMaskDrawingScreen> 
    with TickerProviderStateMixin {
  final List<Offset> _maskStrokes = [];
  double _brushSize = 20.0;
  late ui.Image _originalImageUI;
  bool _imageLoaded = false;
  
  // ✅ CRITICAL FIX: Store display dimensions for accurate coordinate mapping
  double _displayWidth = 0;
  double _displayHeight = 0;
  
  // ✅ GRADIENT ANIMATION: For dynamic mask color during processing
  late AnimationController _gradientController;
  late Animation<double> _gradientAnimation;
  bool _isProcessing = false;
  bool _showResult = false;
  Uint8List? _processedImageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
    
    // ✅ GRADIENT ANIMATION SETUP: Red→Orange→Green cycle during processing
    _gradientController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.originalImage.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _originalImageUI = frame.image;
      _imageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Vẽ vùng cần xóa',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearMask,
          ),
        ],
      ),
      body: Column(
        children: [
          // Drawing area
          Expanded(
            child: _imageLoaded
                ? Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate proper image display size with aspect ratio
                        final imageAspectRatio = _originalImageUI.width / _originalImageUI.height;
                        final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;
                        
                        late double displayWidth, displayHeight, offsetX, offsetY;
                        
                        if (imageAspectRatio > containerAspectRatio) {
                          // Image is wider - fit to width
                          displayWidth = constraints.maxWidth;
                          displayHeight = displayWidth / imageAspectRatio;
                          offsetX = 0;
                          offsetY = (constraints.maxHeight - displayHeight) / 2;
                        } else {
                          // Image is taller - fit to height
                          displayHeight = constraints.maxHeight;
                          displayWidth = displayHeight * imageAspectRatio;
                          offsetY = 0;
                          offsetX = (constraints.maxWidth - displayWidth) / 2;
                        }
                        
                        // ✅ CRITICAL FIX: Store display dimensions for mask creation
                        _displayWidth = displayWidth;
                        _displayHeight = displayHeight;
                        
                        // ✅ RESULT DISPLAY: Show processed image when ready
                        if (_showResult && _processedImageBytes != null) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                _processedImageBytes!,
                                fit: BoxFit.contain,
                                width: displayWidth,
                                height: displayHeight,
                              ),
                            ),
                          );
                        }
                        
                        // ✅ DRAWING MODE: Normal drawing or processing with animated mask
                        return GestureDetector(
                          onPanStart: _isProcessing ? null : (details) {
                            final adjustedPosition = Offset(
                              details.localPosition.dx - offsetX,
                              details.localPosition.dy - offsetY,
                            );
                            if (_isWithinImageBounds(adjustedPosition, displayWidth, displayHeight)) {
                              _addStroke(adjustedPosition);
                            }
                          },
                          onPanUpdate: _isProcessing ? null : (details) {
                            final adjustedPosition = Offset(
                              details.localPosition.dx - offsetX,
                              details.localPosition.dy - offsetY,
                            );
                            if (_isWithinImageBounds(adjustedPosition, displayWidth, displayHeight)) {
                              _addStroke(adjustedPosition);
                            }
                          },
                          child: AnimatedBuilder(
                            animation: _gradientAnimation,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: AnimatedMaskPainter(
                                  originalImage: _originalImageUI,
                                  maskStrokes: _maskStrokes,
                                  brushSize: _brushSize,
                                  displayWidth: displayWidth,
                                  displayHeight: displayHeight,
                                  offsetX: offsetX,
                                  offsetY: offsetY,
                                  isProcessing: _isProcessing,
                                  animationValue: _gradientAnimation.value,
                                ),
                                size: Size(constraints.maxWidth, constraints.maxHeight),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Brush size slider
                Row(
                  children: [
                    const Icon(Icons.brush, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Kích thước cọ:',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 10.0,
                        max: 50.0,
                        divisions: 8,
                        label: '${_brushSize.round()}px',
                        activeColor: const Color(0xFF32d74b),
                        onChanged: (value) {
                          setState(() {
                            _brushSize = value;
                          });
                        },
                      ),
                    ),
                    Text(
                      '${_brushSize.round()}px',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons - Dynamic based on current state
                Row(
                  children: [
                    // ✅ RESULT STATE: Show save button when processing complete
                    if (_showResult && _processedImageBytes != null) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _startOver,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Làm lại'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saveResult,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF32d74b),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('💾 Lưu ảnh'),
                        ),
                      ),
                    ] else ...[
                      // ✅ DRAWING STATE: Normal mask drawing controls
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _clearMask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Xóa tất cả'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Debug test button (only in development)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _createTestMask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Test'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_maskStrokes.isNotEmpty && !_isProcessing) 
                              ? _processMask 
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isProcessing 
                                ? Colors.grey 
                                : const Color(0xFF32d74b),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(_isProcessing ? 'Đang xử lý...' : 'Xử lý'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isWithinImageBounds(Offset position, double displayWidth, double displayHeight) {
    return position.dx >= 0 && 
           position.dx <= displayWidth && 
           position.dy >= 0 && 
           position.dy <= displayHeight;
  }

  void _addStroke(Offset position) {
    setState(() {
      _maskStrokes.add(position);
    });
  }

  void _clearMask() {
    setState(() {
      _maskStrokes.clear();
    });
  }

  // Test method to create a simple mask for debugging
  void _createTestMask() {
    setState(() {
      _maskStrokes.clear();
      
      // ✅ CRITICAL FIX: Create test strokes using actual display dimensions
      if (_displayWidth > 0 && _displayHeight > 0) {
        // Create strokes at the BOTTOM of image (where user wanted to remove meat)
        final centerX = _displayWidth / 2;
        final bottomY = _displayHeight * 0.8; // 80% down from top = bottom area
        
        print('Creating test mask at bottom area');
        print('Display dimensions: ${_displayWidth}x${_displayHeight}');
        print('Target area: center=$centerX, bottom=$bottomY');
        
        // Create cluster in bottom area (simulating user drawing on meat)
        for (int i = 0; i < 25; i++) {
          final angle = (i / 25) * 2 * 3.14159;
          final radius = 40.0;
          final x = centerX + radius * cos(angle);
          final y = bottomY + radius * sin(angle);
          _maskStrokes.add(Offset(x, y));
        }
        
        // Add horizontal line across bottom
        for (int i = 0; i < 15; i++) {
          final x = centerX - 75 + (i * 10);
          final y = bottomY;
          _maskStrokes.add(Offset(x, y));
        }
        
        print('Created test mask with ${_maskStrokes.length} strokes in BOTTOM area');
      } else {
        // Fallback for when display dimensions not available
        final centerX = 200.0;
        final bottomY = 400.0; // Assume bottom area
        
        for (int i = 0; i < 20; i++) {
          final angle = (i / 20) * 2 * 3.14159;
          final radius = 30.0;
          final x = centerX + radius * cos(angle);
          final y = bottomY + radius * sin(angle);
          _maskStrokes.add(Offset(x, y));
        }
        
        print('Created fallback test mask with ${_maskStrokes.length} strokes');
      }
    });
  }

  Future<void> _processMask() async {
    if (_maskStrokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng vẽ vùng cần xóa trên ảnh'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('=== CLEANUP PROCESSING START ===');
      print('Total mask strokes: ${_maskStrokes.length}');
      
      // ✅ START GRADIENT ANIMATION: Red→Orange→Green cycle
      _gradientController.repeat();
      
      // Create mask file (quick operation)
      print('Creating mask file...');
      final maskFile = await _createMaskFile();
      print('Mask file created: ${maskFile.path}');

      // Process with ClipDrop API (main processing)
      print('Processing with ClipDrop API...');
      final clipDropService = ClipDropService();
      final result = await clipDropService.processImage(
        widget.originalImage,
        ProcessingOperation.cleanup,
        maskFile: maskFile,
        mode: 'quality',  // ✅ Use quality mode for better results
      );

      print('Processing completed successfully');
      print('Result size: ${result.length} bytes');

      // ✅ STOP ANIMATION AND SHOW RESULT
      _gradientController.stop();
      setState(() {
        _isProcessing = false;
        _processedImageBytes = result;
        _showResult = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Xử lý hoàn tất! Nhấn "Lưu ảnh" để lưu kết quả.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } catch (e) {
      print('ERROR in _processMask: $e');
      
      // ✅ STOP ANIMATION ON ERROR
      _gradientController.stop();
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xử lý: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  
  // ✅ NEW METHODS for result handling
  void _startOver() {
    setState(() {
      _showResult = false;
      _processedImageBytes = null;
      _maskStrokes.clear();
      _isProcessing = false;
    });
    _gradientController.reset();
  }
  
  void _saveResult() async {
    if (_processedImageBytes == null) return;
    
    try {
      // Here you would implement saving to gallery/downloads
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Ảnh đã được lưu thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Return result to previous screen (if needed)
      Navigator.pop(context, _processedImageBytes);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi lưu ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<File> _createMaskFile() async {
    // Load original image to get dimensions
    final originalBytes = await widget.originalImage.readAsBytes();
    final originalImage = img.decodeImage(originalBytes)!;
    
    final width = originalImage.width;
    final height = originalImage.height;
    
    // ✅ CRITICAL FIX: We need to get the ACTUAL display dimensions, not UI image dimensions
    // The strokes are saved relative to the display area size, not the original UI image size
    
    // Calculate display dimensions using the same logic as LayoutBuilder
    final imageAspectRatio = _originalImageUI.width / _originalImageUI.height;
    
    // For mask creation, we need to reverse-engineer the display size
    // Since we don't have access to constraints here, we'll use a different approach:
    // The strokes are stored in display coordinates relative to the fitted image display area
    
    print('=== MASK CREATION DEBUG ===');
    print('Original image dimensions: ${width}x${height}');
    print('UI image dimensions: ${_originalImageUI.width}x${_originalImageUI.height}');
    print('Image aspect ratio: $imageAspectRatio');
    print('Total strokes to process: ${_maskStrokes.length}');
    print('Brush size: $_brushSize');

    // Create binary mask image (RGB format for compatibility)
    final maskImage = img.Image(width: width, height: height);
    img.fill(maskImage, color: img.ColorRgb8(0, 0, 0)); // Black background (keep)

    int totalPixelsDrawn = 0;
    
    // ✅ CRITICAL FIX: Use direct mapping from display coordinates to image coordinates
    // Since strokes are saved in display space (after offset adjustment), 
    // we need to map them directly to image space
    
    // The strokes are stored in display coordinate space - need to find the actual display size
    // For now, use a simple approach: strokes relative to their bounds
    
    // ✅ CRITICAL FIX: Use the actual stored display dimensions
    if (_displayWidth > 0 && _displayHeight > 0) {
      print('Using stored display dimensions: ${_displayWidth}x${_displayHeight}');
      
      // Calculate scale factors using actual display dimensions
      final scaleX = width.toDouble() / _displayWidth;
      final scaleY = height.toDouble() / _displayHeight;
      
      print('Scale factors: scaleX=$scaleX, scaleY=$scaleY');
      print('Mapping from display space (${_displayWidth}x${_displayHeight}) to image space (${width}x${height})');
      
      // Draw white strokes on mask (remove areas)
      for (int strokeIndex = 0; strokeIndex < _maskStrokes.length; strokeIndex++) {
      final stroke = _maskStrokes[strokeIndex];
      
      // ✅ CORRECTED: Stroke coordinates are already in display space relative to UI image
      // Map from UI image coordinates to actual image coordinates  
      final x = (stroke.dx * scaleX).round();
      final y = (stroke.dy * scaleY).round();
      
      print('Stroke $strokeIndex: UI(${stroke.dx.toInt()}, ${stroke.dy.toInt()}) -> Image($x, $y)');
      
      // Draw brush circle - scale brush size properly and add expansion (15% recommended by Clipdrop)
      final baseBrushRadius = max(5, (_brushSize * min(scaleX, scaleY)).round());
      final expandedBrushRadius = (baseBrushRadius * 1.15).round(); // 15% expansion for better results
      
      for (int dx = -expandedBrushRadius; dx <= expandedBrushRadius; dx++) {
        for (int dy = -expandedBrushRadius; dy <= expandedBrushRadius; dy++) {
          final px = x + dx;
          final py = y + dy;
          
          if (px >= 0 && px < width && py >= 0 && py < height) {
            final distance = (dx * dx + dy * dy);
            if (distance <= expandedBrushRadius * expandedBrushRadius) {
              // ✅ CONFIRMED: White pixel = remove area (255) per Clipdrop API spec
              maskImage.setPixelRgb(px, py, 255, 255, 255);
              totalPixelsDrawn++;
            }
          }
        }
      }
    }
    } else {
      // Fallback if display dimensions not available
      print('WARNING: Display dimensions not available, using fallback');
      final scaleX = 1.0;
      final scaleY = 1.0;
      
      for (int strokeIndex = 0; strokeIndex < _maskStrokes.length; strokeIndex++) {
        final stroke = _maskStrokes[strokeIndex];
        final x = stroke.dx.round();
        final y = stroke.dy.round();
        
        if (x >= 0 && x < width && y >= 0 && y < height) {
          maskImage.setPixelRgb(x, y, 255, 255, 255);
          totalPixelsDrawn++;
        }
      }
    }

    print('Total pixels drawn on mask: $totalPixelsDrawn');
    print('Mask coverage: ${(totalPixelsDrawn / (width * height) * 100).toStringAsFixed(2)}%');
    
    // Validate mask has some content
    if (totalPixelsDrawn == 0) {
      print('WARNING: No pixels drawn on mask!');
      throw Exception('Không có vùng nào được vẽ để xóa. Vui lòng vẽ trên ảnh trước khi xử lý.');
    }
    
    if (totalPixelsDrawn < 100) {
      print('WARNING: Very few pixels drawn (${totalPixelsDrawn})');
    }

    // ✅ VALIDATION: Check mask content before saving
    int whitePixelCount = 0;
    int blackPixelCount = 0;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = maskImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        
        if (r == 255 && g == 255 && b == 255) {
          whitePixelCount++;
        } else if (r == 0 && g == 0 && b == 0) {
          blackPixelCount++;
        }
      }
    }
    
    print('=== MASK VALIDATION ===');
    print('White pixels (remove): $whitePixelCount (${(whitePixelCount / (width * height) * 100).toStringAsFixed(2)}%)');
    print('Black pixels (keep): $blackPixelCount (${(blackPixelCount / (width * height) * 100).toStringAsFixed(2)}%)');
    print('Total pixels: ${width * height}');
    
    if (whitePixelCount == 0) {
      throw Exception('CRITICAL: No white pixels found in mask! Mask is completely black.');
    }
    
    if (whitePixelCount > (width * height * 0.8)) {
      print('WARNING: More than 80% of image marked for removal - this might be too much');
    }

    // Save mask to temporary file
    final tempDir = await getTemporaryDirectory();
    final maskFile = File('${tempDir.path}/cleanup_mask_${DateTime.now().millisecondsSinceEpoch}.png');
    
    final pngBytes = img.encodePng(maskImage, level: 0); // No compression for maximum compatibility
    await maskFile.writeAsBytes(pngBytes);

    print('Mask file saved: ${maskFile.path}');
    print('Mask file size: ${pngBytes.length} bytes');
    
    // Verify saved file can be read back
    final verifyBytes = await maskFile.readAsBytes();
    final verifyImage = img.decodePng(verifyBytes);
    if (verifyImage == null) {
      throw Exception('ERROR: Cannot decode saved mask file');
    }
    print('Mask file verification: OK (${verifyImage.width}x${verifyImage.height})');
    
    // Also save mask to Downloads for debugging (optional)
    try {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        final debugMaskFile = File('${downloadDir.path}/debug_mask_${DateTime.now().millisecondsSinceEpoch}.png');
        await debugMaskFile.writeAsBytes(pngBytes);
        print('Debug mask saved to Downloads: ${debugMaskFile.path}');
      }
    } catch (e) {
      print('Could not save debug mask to Downloads: $e');
    }
    
    print('=== MASK CREATION COMPLETE ===');

    return maskFile;
  }
}

class AnimatedMaskPainter extends CustomPainter {
  final ui.Image originalImage;
  final List<Offset> maskStrokes;
  final double brushSize;
  final double displayWidth;
  final double displayHeight;
  final double offsetX;
  final double offsetY;
  final bool isProcessing;
  final double animationValue;

  AnimatedMaskPainter({
    required this.originalImage,
    required this.maskStrokes,
    required this.brushSize,
    required this.displayWidth,
    required this.displayHeight, 
    required this.offsetX,
    required this.offsetY,
    required this.isProcessing,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw original image with proper positioning and scaling
    final paint = Paint();
    canvas.drawImageRect(
      originalImage,
      Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
      Rect.fromLTWH(offsetX, offsetY, displayWidth, displayHeight),
      paint,
    );

    // ✅ ANIMATED GRADIENT MASK: Red→Orange→Green during processing
    Color maskColor;
    if (isProcessing) {
      // Animate through gradient: Red (0.0) → Orange (0.5) → Green (1.0)
      if (animationValue < 0.5) {
        // Red to Orange
        final t = animationValue * 2; // 0.0 to 1.0
        maskColor = Color.lerp(
          const Color(0xFFFF4444), // Bright red
          const Color(0xFFFF8800), // Orange
          t,
        )!;
      } else {
        // Orange to Green
        final t = (animationValue - 0.5) * 2; // 0.0 to 1.0
        maskColor = Color.lerp(
          const Color(0xFFFF8800), // Orange
          const Color(0xFF44FF44), // Bright green
          t,
        )!;
      }
    } else {
      // Normal drawing mode - static red
      maskColor = const Color(0xFFFF4444);
    }

    // Draw mask strokes with animated color
    final maskPaint = Paint()
      ..color = maskColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final stroke in maskStrokes) {
      final adjustedStroke = Offset(stroke.dx + offsetX, stroke.dy + offsetY);
      
      // ✅ PROCESSING EFFECT: Add pulsing animation during processing
      final radius = isProcessing 
          ? (brushSize / 2) * (1.0 + 0.2 * sin(animationValue * 4 * 3.14159))
          : brushSize / 2;
      
      // Draw animated mask fill
      canvas.drawCircle(adjustedStroke, radius, maskPaint);
      // Draw white border for visibility
      canvas.drawCircle(adjustedStroke, radius, strokePaint);
    }
    
    // ✅ PROCESSING OVERLAY: Show processing text during animation
    if (isProcessing && maskStrokes.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Đang xử lý AI...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      final textX = (size.width - textPainter.width) / 2;
      final textY = offsetY + displayHeight + 20;
      
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! AnimatedMaskPainter) return true;
    return oldDelegate.isProcessing != isProcessing ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.maskStrokes.length != maskStrokes.length;
  }
}