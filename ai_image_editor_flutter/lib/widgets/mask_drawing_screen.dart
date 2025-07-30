import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class MaskDrawingScreen extends StatefulWidget {
  final File originalImage;
  final Function(File) onMaskCreated;

  const MaskDrawingScreen({
    super.key,
    required this.originalImage,
    required this.onMaskCreated,
  });

  @override
  State<MaskDrawingScreen> createState() => _MaskDrawingScreenState();
}

class _MaskDrawingScreenState extends State<MaskDrawingScreen> {
  final GlobalKey _canvasKey = GlobalKey();
  final List<Offset> _points = [];
  final List<Path> _paths = [];
  double _brushSize = 20.0;
  bool _isDrawing = false;
  Path _currentPath = Path();
  ui.Image? _backgroundImage;
  Size? _imageDisplaySize;
  Size? _originalImageSize;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    final bytes = await widget.originalImage.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    
    // Get original image dimensions
    final img.Image? originalImg = img.decodeImage(bytes);
    if (originalImg != null) {
      _originalImageSize = Size(originalImg.width.toDouble(), originalImg.height.toDouble());
    }
    
    setState(() {
      _backgroundImage = frame.image;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _currentPath = Path();
      _currentPath.moveTo(details.localPosition.dx, details.localPosition.dy);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing) {
      setState(() {
        _currentPath.lineTo(details.localPosition.dx, details.localPosition.dy);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
      _paths.add(Path.from(_currentPath));
    });
  }

  void _clearMask() {
    setState(() {
      _paths.clear();
      _currentPath = Path();
    });
  }

  Future<void> _createMask() async {
    try {
      // Get original image dimensions first
      final originalImageBytes = await widget.originalImage.readAsBytes();
      final img.Image? originalImg = img.decodeImage(originalImageBytes);
      if (originalImg == null || _originalImageSize == null || _imageDisplaySize == null) {
        throw Exception('Không thể đọc ảnh gốc hoặc thông tin kích thước');
      }

      // Calculate scaling factors between display and original image
      final double scaleX = _originalImageSize!.width / _imageDisplaySize!.width;
      final double scaleY = _originalImageSize!.height / _imageDisplaySize!.height;

      // Create binary mask directly with original image dimensions (no resizing needed)
      final img.Image binaryMask = img.Image(
        width: originalImg.width,
        height: originalImg.height,
        numChannels: 3, // RGB format for better compatibility with Clipdrop API
      );

      // Fill with black background (0 = keep as per Clipdrop API)
      img.fill(binaryMask, color: img.ColorRgb8(0, 0, 0));

      // Count pixels to validate mask
      int whitePixelCount = 0;
      int totalPixels = originalImg.width * originalImg.height;

      // Convert drawing paths to mask pixels with accurate coordinate mapping
      for (final path in _paths) {
        // Extract points from path and scale them to original image coordinates
        final PathMetrics pathMetrics = path.computeMetrics();
        for (final PathMetric pathMetric in pathMetrics) {
          for (double distance = 0.0; distance < pathMetric.length; distance += 1.0) {
            final Tangent? tangent = pathMetric.getTangentForOffset(distance);
            if (tangent != null) {
              // Convert display coordinates to original image coordinates
              final int originalX = (tangent.position.dx * scaleX).round();
              final int originalY = (tangent.position.dy * scaleY).round();
              
              // Apply brush size in original image coordinates
              final int brushRadius = (_brushSize * scaleX * 0.5).round();
              
              // Draw brush stroke as circle in original image coordinates
              for (int dy = -brushRadius; dy <= brushRadius; dy++) {
                for (int dx = -brushRadius; dx <= brushRadius; dx++) {
                  final int pixelX = originalX + dx;
                  final int pixelY = originalY + dy;
                  
                  // Check if pixel is within image bounds and brush radius
                  if (pixelX >= 0 && pixelX < originalImg.width && 
                      pixelY >= 0 && pixelY < originalImg.height &&
                      (dx * dx + dy * dy) <= (brushRadius * brushRadius)) {
                    binaryMask.setPixelRgb(pixelX, pixelY, 255, 255, 255); // White = remove
                    whitePixelCount++;
                  }
                }
              }
            }
          }
        }
      }

      // Validate mask quality
      double whitePercentage = (whitePixelCount / totalPixels) * 100;
      print('Mask created: ${originalImg.width}x${originalImg.height} pixels');
      print('White pixels (remove): $whitePixelCount (${whitePercentage.toStringAsFixed(1)}%)');
      print('Black pixels (keep): ${totalPixels - whitePixelCount} (${(100 - whitePercentage).toStringAsFixed(1)}%)');
      
      // Safety check - if more than 80% is white, something is very wrong
      if (whitePercentage > 80.0) {
        print('WARNING: Mask có thể bị lỗi - quá nhiều vùng được đánh dấu xóa');
        throw Exception('Mask không hợp lệ: ${whitePercentage.toStringAsFixed(1)}% ảnh sẽ bị xóa. Vui lòng vẽ lại ít hơn.');
      }
      
      if (whitePixelCount == 0) {
        throw Exception('Không phát hiện vùng vẽ. Vui lòng vẽ trên những vùng cần xóa.');
      }

      // Save mask file as PNG
      final directory = await getTemporaryDirectory();
      final maskFile = File('${directory.path}/cleanup_mask_${DateTime.now().millisecondsSinceEpoch}.png');
      final maskPngBytes = img.encodePng(binaryMask);
      await maskFile.writeAsBytes(maskPngBytes);

      print('Mask file saved: ${maskFile.path}');
      print('Mask file size: ${maskPngBytes.length} bytes');
      
      // Validate saved mask file
      final savedMask = img.decodePng(maskPngBytes);
      if (savedMask == null) {
        throw Exception('Lỗi: Không thể tạo file mask PNG hợp lệ');
      }
      
      print('Mask validation successful: ${savedMask.width}x${savedMask.height}');

      // Return the mask file
      widget.onMaskCreated(maskFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo mask: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            onPressed: _clearMask,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Xóa tất cả',
          ),
          IconButton(
            onPressed: _paths.isNotEmpty ? _createMask : null,
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
              'Vẽ trên những vùng bạn muốn xóa khỏi ảnh. Vùng được vẽ sẽ bị loại bỏ.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Drawing Canvas
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _canvasKey,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate display size that maintains aspect ratio
                        if (_backgroundImage != null && _originalImageSize != null) {
                          final double availableWidth = MediaQuery.of(context).size.width - 32;
                          final double availableHeight = constraints.maxHeight - 100; // Leave space for controls
                          
                          final double imageAspectRatio = _originalImageSize!.width / _originalImageSize!.height;
                          
                          double displayWidth, displayHeight;
                          if (availableWidth / availableHeight > imageAspectRatio) {
                            // Height is limiting factor
                            displayHeight = availableHeight;
                            displayWidth = displayHeight * imageAspectRatio;
                          } else {
                            // Width is limiting factor
                            displayWidth = availableWidth;
                            displayHeight = displayWidth / imageAspectRatio;
                          }
                          
                          // Store display size for coordinate mapping
                          _imageDisplaySize = Size(displayWidth, displayHeight);
                          
                          return CustomPaint(
                            size: Size(displayWidth, displayHeight),
                            painter: MaskPainter(
                              backgroundImage: _backgroundImage,
                              paths: _paths,
                              currentPath: _isDrawing ? _currentPath : null,
                              brushSize: _brushSize,
                            ),
                          );
                        }
                        
                        // Fallback to square canvas if image not loaded
                        final size = MediaQuery.of(context).size.width - 32;
                        _imageDisplaySize = Size(size, size);
                        return CustomPaint(
                          size: Size(size, size),
                          painter: MaskPainter(
                            backgroundImage: _backgroundImage,
                            paths: _paths,
                            currentPath: _isDrawing ? _currentPath : null,
                            brushSize: _brushSize,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Brush Size Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Kích thước cọ: ${_brushSize.round()}px',
                  style: const TextStyle(color: Colors.white),
                ),
                Slider(
                  value: _brushSize,
                  min: 5,
                  max: 50,
                  divisions: 9,
                  activeColor: Colors.blue,
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
}

class MaskPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final List<Path> paths;
  final Path? currentPath;
  final double brushSize;

  MaskPainter({
    this.backgroundImage,
    required this.paths,
    this.currentPath,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background image
    if (backgroundImage != null) {
      final paint = Paint();
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
      
      // Add semi-transparent overlay
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.black.withOpacity(0.3),
      );
    }

    // Draw mask paths
    final maskPaint = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw completed paths
    for (final path in paths) {
      canvas.drawPath(path, maskPaint);
    }

    // Draw current path being drawn
    if (currentPath != null) {
      canvas.drawPath(currentPath!, maskPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}