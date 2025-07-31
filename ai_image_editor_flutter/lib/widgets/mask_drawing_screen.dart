import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
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

      // Create binary mask with EXACT same dimensions as original image (per Clipdrop docs)
      final img.Image binaryMask = img.Image(
        width: originalImg.width,
        height: originalImg.height,
        numChannels: 1, // Grayscale for PNG output
      );

      // Fill with pure black (0 = keep as per Clipdrop API documentation)
      img.fill(binaryMask, color: img.ColorUint8(0));

      // Count pixels to validate mask
      int whitePixelCount = 0;
      int totalPixels = originalImg.width * originalImg.height;

      // Convert drawing paths to mask pixels with precise coordinate mapping
      for (final path in _paths) {
        // Create a list to store all stroke points first
        List<Offset> strokePoints = [];
        
        // Extract all points from path
        final ui.PathMetrics pathMetrics = path.computeMetrics();
        for (final ui.PathMetric pathMetric in pathMetrics) {
          // Use very small distance for maximum precision
          for (double distance = 0.0; distance < pathMetric.length; distance += 0.25) {
            final ui.Tangent? tangent = pathMetric.getTangentForOffset(distance);
            if (tangent != null) {
              strokePoints.add(tangent.position);
            }
          }
        }
        
        // Apply each stroke point with expanded brush (15% larger as per Clipdrop tips)
        for (final point in strokePoints) {
          // Convert display coordinates to original image coordinates
          final int originalX = (point.dx * scaleX).round();
          final int originalY = (point.dy * scaleY).round();
          
          // Calculate expanded brush size (15% larger than drawn for better results)
          final int baseBrushRadius = math.max(3, (_brushSize * math.min(scaleX, scaleY) * 0.5).round());
          final int expandedBrushRadius = (baseBrushRadius * 1.15).round(); // 15% expansion
          
          // Draw filled circle with pure white (255 = remove)
          for (int dy = -expandedBrushRadius; dy <= expandedBrushRadius; dy++) {
            for (int dx = -expandedBrushRadius; dx <= expandedBrushRadius; dx++) {
              final int pixelX = originalX + dx;
              final int pixelY = originalY + dy;
              
              // Check if pixel is within image bounds and brush radius
              if (pixelX >= 0 && pixelX < originalImg.width && 
                  pixelY >= 0 && pixelY < originalImg.height &&
                  (dx * dx + dy * dy) <= (expandedBrushRadius * expandedBrushRadius)) {
                // Set pure white (255) for removal as per Clipdrop documentation
                binaryMask.setPixel(pixelX, pixelY, img.ColorUint8(255));
                whitePixelCount++;
              }
            }
          }
        }
      }

      // Validate mask quality with detailed logging per Clipdrop requirements
      double whitePercentage = (whitePixelCount / totalPixels) * 100;
      print('=== CLIPDROP MASK CREATION DEBUG ===');
      print('Original image: ${originalImg.width}x${originalImg.height} pixels');
      print('Display size: ${_imageDisplaySize!.width}x${_imageDisplaySize!.height}');
      print('Scale factors: scaleX=${scaleX.toStringAsFixed(2)}, scaleY=${scaleY.toStringAsFixed(2)}');
      print('Paths drawn: ${_paths.length}');
      final baseBrush = (_brushSize * math.min(scaleX, scaleY) * 0.5).round();
      final expandedBrush = (baseBrush * 1.15).round();
      print('Brush size: $_brushSize (display) -> $baseBrush (base) -> $expandedBrush (expanded +15%)');
      print('White pixels (255=remove): $whitePixelCount (${whitePercentage.toStringAsFixed(2)}%)');
      print('Black pixels (0=keep): ${totalPixels - whitePixelCount} (${(100 - whitePercentage).toStringAsFixed(2)}%)');
      
      // Safety check - if more than 50% is white, likely accidental full removal
      if (whitePercentage > 50.0) {
        print('WARNING: Mask có thể bị lỗi - quá nhiều vùng được đánh dấu xóa');
        throw Exception('Mask không hợp lệ: ${whitePercentage.toStringAsFixed(1)}% ảnh sẽ bị xóa. Vui lòng vẽ lại ít hơn.');
      }
      
      // Check if mask has any drawing
      if (whitePixelCount == 0) {
        throw Exception('Không phát hiện vùng vẽ. Vui lòng vẽ trên những vùng cần xóa.');
      }
      
      // Check minimum mask coverage (at least 0.05% to be effective)
      if (whitePercentage < 0.05) {
        print('WARNING: Mask rất nhỏ (${whitePercentage.toStringAsFixed(3)}%), có thể không hiệu quả');
      }

      // Save mask as PNG with exact dimensions as per Clipdrop API requirements
      final directory = await getTemporaryDirectory();
      final maskFile = File('${directory.path}/clipdrop_mask_${DateTime.now().millisecondsSinceEpoch}.png');
      
      // Encode as grayscale PNG (black=0, white=255 only, no grey values)
      final maskPngBytes = img.encodePng(binaryMask, level: 0); // No compression for pure binary data
      await maskFile.writeAsBytes(maskPngBytes);

      print('Clipdrop mask saved: ${maskFile.path}');
      print('Mask file size: ${maskPngBytes.length} bytes');
      print('Mask format: PNG, ${originalImg.width}x${originalImg.height}, grayscale, binary (0/255 only)');
      
      // Validate saved mask meets Clipdrop requirements
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