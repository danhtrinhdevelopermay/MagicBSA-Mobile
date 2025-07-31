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

class _SimpleMaskDrawingScreenState extends State<SimpleMaskDrawingScreen> {
  final List<Offset> _maskStrokes = [];
  double _brushSize = 20.0;
  late ui.Image _originalImageUI;
  bool _imageLoaded = false;
  
  // ✅ CRITICAL FIX: Store display dimensions for accurate coordinate mapping
  double _displayWidth = 0;
  double _displayHeight = 0;

  @override
  void initState() {
    super.initState();
    _loadImage();
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
                        
                        return GestureDetector(
                          onPanStart: (details) {
                            final adjustedPosition = Offset(
                              details.localPosition.dx - offsetX,
                              details.localPosition.dy - offsetY,
                            );
                            if (_isWithinImageBounds(adjustedPosition, displayWidth, displayHeight)) {
                              _addStroke(adjustedPosition);
                            }
                          },
                          onPanUpdate: (details) {
                            final adjustedPosition = Offset(
                              details.localPosition.dx - offsetX,
                              details.localPosition.dy - offsetY,
                            );
                            if (_isWithinImageBounds(adjustedPosition, displayWidth, displayHeight)) {
                              _addStroke(adjustedPosition);
                            }
                          },
                          child: CustomPaint(
                            painter: MaskPainter(
                              originalImage: _originalImageUI,
                              strokes: _maskStrokes,
                              brushSize: _brushSize,
                              displayWidth: displayWidth,
                              displayHeight: displayHeight,
                              offsetX: offsetX,
                              offsetY: offsetY,
                            ),
                            size: Size(constraints.maxWidth, constraints.maxHeight),
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

                // Action buttons
                Row(
                  children: [
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
                    // Debug test button
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
                        onPressed: _maskStrokes.isNotEmpty ? _processMask : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF32d74b),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Xử lý'),
                      ),
                    ),
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

    try {
      print('=== CLEANUP PROCESSING START ===');
      print('Total mask strokes: ${_maskStrokes.length}');
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang tạo mask...'),
            ],
          ),
        ),
      );

      // Create mask file
      print('Creating mask file...');
      final maskFile = await _createMaskFile();
      print('Mask file created: ${maskFile.path}');

      Navigator.pop(context); // Close loading dialog

      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Đang xử lý với AI...'),
            ],
          ),
        ),
      );

      // Process with ClipDrop API
      print('Processing with ClipDrop API...');
      final clipDropService = ClipDropService();
      final result = await clipDropService.processImage(
        widget.originalImage,
        ProcessingOperation.cleanup,
        maskFile: maskFile,
        mode: 'quality',  // ✅ CHANGED: Use quality mode for better results
      );

      Navigator.pop(context); // Close processing dialog
      print('Processing completed successfully');
      print('Result size: ${result.length} bytes');

      // Return result to previous screen
      Navigator.pop(context, result);

    } catch (e) {
      print('ERROR in _processMask: $e');
      Navigator.of(context).popUntil((route) => route.settings.name != null || route.isFirst); // Close any dialogs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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

class MaskPainter extends CustomPainter {
  final ui.Image originalImage;
  final List<Offset> strokes;
  final double brushSize;
  final double displayWidth;
  final double displayHeight;
  final double offsetX;
  final double offsetY;

  MaskPainter({
    required this.originalImage,
    required this.strokes,
    required this.brushSize,
    required this.displayWidth,
    required this.displayHeight, 
    required this.offsetX,
    required this.offsetY,
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

    // Draw mask strokes only within image bounds
    final maskPaint = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final stroke in strokes) {
      final adjustedStroke = Offset(stroke.dx + offsetX, stroke.dy + offsetY);
      // Draw red fill for removal area
      canvas.drawCircle(adjustedStroke, brushSize / 2, maskPaint);
      // Draw white border for visibility
      canvas.drawCircle(adjustedStroke, brushSize / 2, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}