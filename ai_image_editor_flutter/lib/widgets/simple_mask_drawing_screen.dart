import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Simple and reliable mask drawing screen following Clipdrop API specification exactly
/// Based on: https://clipdrop.co/apis/docs/cleanup
class SimpleMaskDrawingScreen extends StatefulWidget {
  final File originalImage;
  final Function(File) onMaskCreated;

  const SimpleMaskDrawingScreen({
    super.key,
    required this.originalImage,
    required this.onMaskCreated,
  });

  @override
  State<SimpleMaskDrawingScreen> createState() => _SimpleMaskDrawingScreenState();
}

class _SimpleMaskDrawingScreenState extends State<SimpleMaskDrawingScreen> {
  // Core drawing state
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isDrawing = false;
  double _brushSize = 25.0;
  
  // Image data
  ui.Image? _backgroundImage;
  img.Image? _originalImgData;
  Size _originalImageSize = Size.zero;
  Size _displaySize = Size.zero;
  
  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
  }

  /// Load and decode original image for display and mask creation
  Future<void> _loadOriginalImage() async {
    try {
      final bytes = await widget.originalImage.readAsBytes();
      
      // Load for display
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      // Load for mask creation
      final originalImg = img.decodeImage(bytes);
      
      if (originalImg != null) {
        setState(() {
          _backgroundImage = frame.image;
          _originalImgData = originalImg;
          _originalImageSize = Size(originalImg.width.toDouble(), originalImg.height.toDouble());
        });
        print('✅ Image loaded: ${originalImg.width}x${originalImg.height}');
      }
    } catch (e) {
      print('❌ Error loading image: $e');
    }
  }

  /// Start drawing stroke
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _currentStroke = [details.localPosition];
    });
  }

  /// Continue drawing stroke
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing) {
      setState(() {
        _currentStroke.add(details.localPosition);
      });
    }
  }

  /// Finish stroke
  void _onPanEnd(DragEndDetails details) {
    if (_isDrawing && _currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_currentStroke));
        _currentStroke.clear();
        _isDrawing = false;
      });
    }
  }

  /// Clear all strokes
  void _clearMask() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
      _isDrawing = false;
    });
  }

  /// Create binary mask according to Clipdrop API specification
  Future<void> _createMask() async {
    if (_originalImgData == null || _strokes.isEmpty) {
      _showError('Vui lòng vẽ trên vùng cần xóa trước khi tạo mask');
      return;
    }

    try {
      print('🎯 Creating Clipdrop-compliant mask...');
      
      // Calculate scale factors from display to original image
      final scaleX = _originalImageSize.width / _displaySize.width;
      final scaleY = _originalImageSize.height / _displaySize.height;
      
      print('📐 Scale factors: ${scaleX.toStringAsFixed(2)}x, ${scaleY.toStringAsFixed(2)}x');
      
      // Create binary mask with EXACT same dimensions as original (Clipdrop requirement)
      final maskImage = img.Image(
        width: _originalImgData!.width,
        height: _originalImgData!.height,
        numChannels: 3, // RGB format
      );
      
      // Fill with black (0 = keep areas per Clipdrop docs)
      img.fill(maskImage, color: img.ColorRgb8(0, 0, 0));
      
      int whitePixelCount = 0;
      final totalPixels = _originalImgData!.width * _originalImgData!.height;
      
      // Process each stroke
      for (final stroke in _strokes) {
        for (int i = 0; i < stroke.length; i++) {
          final point = stroke[i];
          
          // Convert display coordinates to original image coordinates
          final originalX = (point.dx * scaleX).round();
          final originalY = (point.dy * scaleY).round();
          
          // Calculate brush radius in original coordinates
          final brushRadius = math.max(2, (_brushSize * 0.5 * math.min(scaleX, scaleY)).round());
          
          // Draw filled circle (white = 255 = remove per Clipdrop docs)
          for (int dy = -brushRadius; dy <= brushRadius; dy++) {
            for (int dx = -brushRadius; dx <= brushRadius; dx++) {
              final pixelX = originalX + dx;
              final pixelY = originalY + dy;
              
              // Check bounds and circle radius
              if (pixelX >= 0 && pixelX < _originalImgData!.width &&
                  pixelY >= 0 && pixelY < _originalImgData!.height &&
                  (dx * dx + dy * dy) <= (brushRadius * brushRadius)) {
                
                // Set white pixel (255,255,255 = remove)
                maskImage.setPixel(pixelX, pixelY, img.ColorRgb8(255, 255, 255));
                whitePixelCount++;
              }
            }
          }
        }
      }
      
      // Validate mask quality
      final whitePercentage = (whitePixelCount / totalPixels) * 100;
      print('📊 Mask stats: ${whitePercentage.toStringAsFixed(2)}% removal area');
      
      if (whitePercentage > 70.0) {
        _showError('Mask quá lớn (${whitePercentage.toStringAsFixed(1)}% ảnh sẽ bị xóa). Vui lòng vẽ ít hơn.');
        return;
      }
      
      if (whitePercentage < 0.1) {
        _showError('Mask quá nhỏ. Vui lòng vẽ rõ hơn trên vùng cần xóa.');
        return;
      }
      
      // Save mask as PNG (Clipdrop requirement)
      final directory = await getTemporaryDirectory();
      final maskFile = File('${directory.path}/clipdrop_binary_mask_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Encode as PNG with no compression for pure binary data
      final pngBytes = img.encodePng(maskImage, level: 0);
      await maskFile.writeAsBytes(pngBytes);
      
      print('💾 Mask saved: ${maskFile.path}');
      print('📏 Mask format: PNG, ${_originalImgData!.width}x${_originalImgData!.height}, RGB, binary (0,0,0/255,255,255)');
      print('📦 File size: ${pngBytes.length} bytes');
      
      // Return mask file to caller
      widget.onMaskCreated(maskFile);
      
    } catch (e) {
      print('❌ Mask creation error: $e');
      _showError('Lỗi tạo mask: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Vẽ vùng cần xóa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _strokes.isNotEmpty ? _clearMask : null,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Xóa hết',
          ),
          IconButton(
            onPressed: _strokes.isNotEmpty ? _createMask : null,
            icon: const Icon(Icons.check),
            tooltip: 'Hoàn thành',
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Vẽ trên những vùng bạn muốn xóa. App sẽ tự động xóa và fill background tự nhiên.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Drawing area
          Expanded(
            child: Center(
              child: _backgroundImage != null
                  ? _buildDrawingCanvas()
                  : const CircularProgressIndicator(),
            ),
          ),
          
          // Brush controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              children: [
                Text(
                  'Kích thước cọ: ${_brushSize.round()}px',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Slider(
                  value: _brushSize,
                  min: 10,
                  max: 50,
                  divisions: 8,
                  activeColor: Colors.white,
                  inactiveColor: Colors.grey,
                  onChanged: (value) {
                    setState(() {
                      _brushSize = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate display size maintaining aspect ratio
        final availableWidth = constraints.maxWidth - 32;
        final availableHeight = constraints.maxHeight - 32;
        final imageAspect = _originalImageSize.width / _originalImageSize.height;
        
        double displayWidth, displayHeight;
        if (availableWidth / availableHeight > imageAspect) {
          displayHeight = availableHeight;
          displayWidth = displayHeight * imageAspect;
        } else {
          displayWidth = availableWidth;
          displayHeight = displayWidth / imageAspect;
        }
        
        _displaySize = Size(displayWidth, displayHeight);
        
        return Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
          ),
          child: ClipRect(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                size: Size(displayWidth, displayHeight),
                painter: _SimpleMaskPainter(
                  backgroundImage: _backgroundImage!,
                  strokes: _strokes,
                  currentStroke: _isDrawing ? _currentStroke : [],
                  brushSize: _brushSize,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Simple custom painter for mask drawing
class _SimpleMaskPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final double brushSize;

  _SimpleMaskPainter({
    required this.backgroundImage,
    required this.strokes,
    required this.currentStroke,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background image
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    // Draw completed strokes
    final strokePaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length > 1) {
        final path = Path();
        path.moveTo(stroke.first.dx, stroke.first.dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, strokePaint);
      }
    }

    // Draw current stroke
    if (currentStroke.length > 1) {
      final currentPaint = Paint()
        ..color = Colors.red.withOpacity(0.8)
        ..strokeWidth = brushSize
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(currentStroke.first.dx, currentStroke.first.dy);
      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }
      canvas.drawPath(path, currentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}