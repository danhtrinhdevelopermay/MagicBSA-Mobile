import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
                    child: GestureDetector(
                      onPanStart: (details) => _addStroke(details.localPosition),
                      onPanUpdate: (details) => _addStroke(details.localPosition),
                      child: CustomPaint(
                        painter: MaskPainter(
                          originalImage: _originalImageUI,
                          strokes: _maskStrokes,
                          brushSize: _brushSize,
                        ),
                        size: Size.infinite,
                      ),
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

    // Create binary mask image (RGB format)
    final maskImage = img.Image(width: width, height: height);
    img.fill(maskImage, color: img.ColorRgb8(0, 0, 0)); // Black background (keep)

    // Draw white strokes on mask (remove areas)
    for (final stroke in _maskStrokes) {
      // Convert screen coordinates to image coordinates
      final x = (stroke.dx * width / _originalImageUI.width).round();
      final y = (stroke.dy * height / _originalImageUI.height).round();
      
      // Draw brush circle
      final brushRadius = (_brushSize * width / _originalImageUI.width).round();
      
      for (int dx = -brushRadius; dx <= brushRadius; dx++) {
        for (int dy = -brushRadius; dy <= brushRadius; dy++) {
          final px = x + dx;
          final py = y + dy;
          
          if (px >= 0 && px < width && py >= 0 && py < height) {
            final distance = (dx * dx + dy * dy);
            if (distance <= brushRadius * brushRadius) {
              // White pixel = remove (255)
              maskImage.setPixelRgb(px, py, 255, 255, 255);
            }
          }
        }
      }
    }

    // Save mask to temporary file
    final tempDir = await getTemporaryDirectory();
    final maskFile = File('${tempDir.path}/mask_${DateTime.now().millisecondsSinceEpoch}.png');
    
    final pngBytes = img.encodePng(maskImage);
    await maskFile.writeAsBytes(pngBytes);

    print('Mask file created: ${maskFile.path}');
    print('Mask dimensions: ${width}x${height}');
    print('Total strokes: ${_maskStrokes.length}');

    return maskFile;
  }
}

class MaskPainter extends CustomPainter {
  final ui.Image originalImage;
  final List<Offset> strokes;
  final double brushSize;

  MaskPainter({
    required this.originalImage,
    required this.strokes,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw original image
    final paint = Paint();
    canvas.drawImageRect(
      originalImage,
      Rect.fromLTWH(0, 0, originalImage.width.toDouble(), originalImage.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Draw mask strokes
    final maskPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final stroke in strokes) {
      canvas.drawCircle(stroke, brushSize / 2, maskPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}