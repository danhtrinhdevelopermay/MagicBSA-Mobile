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
      // Add test strokes in UI coordinate space (will be properly mapped to image coordinates)
      // These are relative to the display image size, not the original image
      final centerX = _originalImageUI.width / 2;
      final centerY = _originalImageUI.height / 2;
      
      // Create a small circle of strokes in the center
      for (int i = 0; i < 20; i++) {
        final angle = (i / 20) * 2 * 3.14159;
        final radius = 50.0; // Larger radius for visibility
        final x = centerX + radius * cos(angle);
        final y = centerY + radius * sin(angle);
        _maskStrokes.add(Offset(x, y));
      }
      
      // Add a few strokes on the right side to test coordinate mapping
      for (int i = 0; i < 10; i++) {
        final x = _originalImageUI.width * 0.8; // Right side of image
        final y = _originalImageUI.height * 0.3 + (i * 10); // Vertical line
        _maskStrokes.add(Offset(x, y));
      }
      
      print('Created test mask with ${_maskStrokes.length} strokes');
      print('Test strokes at: center(${centerX.toInt()}, ${centerY.toInt()}) and right side');
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
        mode: 'fast',
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
    
    print('=== MASK CREATION DEBUG ===');
    print('Original image dimensions: ${width}x${height}');
    print('UI image dimensions: ${_originalImageUI.width}x${_originalImageUI.height}');
    print('Total strokes to process: ${_maskStrokes.length}');
    print('Brush size: $_brushSize');

    // Create binary mask image (RGB format for compatibility)
    final maskImage = img.Image(width: width, height: height);
    img.fill(maskImage, color: img.ColorRgb8(0, 0, 0)); // Black background (keep)

    int totalPixelsDrawn = 0;
    
    // Calculate scale factors for proper coordinate mapping
    final scaleX = width / _originalImageUI.width;
    final scaleY = height / _originalImageUI.height;
    
    print('Scale factors: scaleX=$scaleX, scaleY=$scaleY');
    
    // Draw white strokes on mask (remove areas)
    for (int strokeIndex = 0; strokeIndex < _maskStrokes.length; strokeIndex++) {
      final stroke = _maskStrokes[strokeIndex];
      
      // CRITICAL FIX: Use proper coordinate mapping with actual display scaling
      final x = (stroke.dx * scaleX).round();
      final y = (stroke.dy * scaleY).round();
      
      print('Stroke $strokeIndex: UI(${stroke.dx.toInt()}, ${stroke.dy.toInt()}) -> Image($x, $y)');
      
      // Draw brush circle - scale brush size properly
      final brushRadius = max(5, (_brushSize * min(scaleX, scaleY)).round());
      
      for (int dx = -brushRadius; dx <= brushRadius; dx++) {
        for (int dy = -brushRadius; dy <= brushRadius; dy++) {
          final px = x + dx;
          final py = y + dy;
          
          if (px >= 0 && px < width && py >= 0 && py < height) {
            final distance = (dx * dx + dy * dy);
            if (distance <= brushRadius * brushRadius) {
              // White pixel = remove (255)
              maskImage.setPixelRgb(px, py, 255, 255, 255);
              totalPixelsDrawn++;
            }
          }
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

    // Save mask to temporary file
    final tempDir = await getTemporaryDirectory();
    final maskFile = File('${tempDir.path}/mask_${DateTime.now().millisecondsSinceEpoch}.png');
    
    final pngBytes = img.encodePng(maskImage);
    await maskFile.writeAsBytes(pngBytes);

    print('Mask file saved: ${maskFile.path}');
    print('Mask file size: ${pngBytes.length} bytes');
    
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