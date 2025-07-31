import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class PrecisionMaskPainter extends StatefulWidget {
  final File originalImage;
  final Function(File) onMaskCreated;
  final double brushSize;

  const PrecisionMaskPainter({
    super.key,
    required this.originalImage,
    required this.onMaskCreated,
    this.brushSize = 20.0,
  });

  @override
  State<PrecisionMaskPainter> createState() => _PrecisionMaskPainterState();
}

class _PrecisionMaskPainterState extends State<PrecisionMaskPainter> {
  final GlobalKey _canvasKey = GlobalKey();
  ui.Image? _backgroundImage;
  Size? _imageDisplaySize;
  Size? _originalImageSize;
  
  // Use bitmap for precise mask creation
  Uint8List? _maskBitmap;
  int? _maskWidth;
  int? _maskHeight;
  double _scaleX = 1.0;
  double _scaleY = 1.0;
  
  bool _isDrawing = false;

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
      _maskWidth = originalImg.width;
      _maskHeight = originalImg.height;
      
      // Initialize mask bitmap with black (0 = keep)
      _maskBitmap = Uint8List(_maskWidth! * _maskHeight!);
      // Already initialized to 0 (black)
    }
    
    setState(() {
      _backgroundImage = frame.image;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
    });
    _addMaskPoint(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing) {
      _addMaskPoint(details.localPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDrawing = false;
    });
  }

  void _addMaskPoint(Offset localPosition) {
    if (_maskBitmap == null || _maskWidth == null || _maskHeight == null || _imageDisplaySize == null) {
      return;
    }

    // Convert screen coordinates to image coordinates
    final int imageX = (localPosition.dx * _scaleX).round();
    final int imageY = (localPosition.dy * _scaleY).round();

    // Calculate brush radius in image coordinates with 15% expansion
    final double avgScale = (_scaleX + _scaleY) / 2;
    final int baseBrushRadius = math.max(2, (widget.brushSize * avgScale * 0.5).round());
    final int expandedBrushRadius = (baseBrushRadius * 1.15).round(); // 15% expansion per Clipdrop docs

    // Apply circular brush to mask bitmap
    for (int dy = -expandedBrushRadius; dy <= expandedBrushRadius; dy++) {
      for (int dx = -expandedBrushRadius; dx <= expandedBrushRadius; dx++) {
        final int pixelX = imageX + dx;
        final int pixelY = imageY + dy;
        
        // Check bounds and circular shape
        if (pixelX >= 0 && pixelX < _maskWidth! && 
            pixelY >= 0 && pixelY < _maskHeight! &&
            (dx * dx + dy * dy) <= (expandedBrushRadius * expandedBrushRadius)) {
          
          // Set to white (255 = remove) in bitmap
          final int index = pixelY * _maskWidth! + pixelX;
          _maskBitmap![index] = 255;
        }
      }
    }

    setState(() {}); // Trigger repaint
  }

  void _clearMask() {
    if (_maskBitmap != null) {
      _maskBitmap!.fillRange(0, _maskBitmap!.length, 0); // Fill with black (keep)
      setState(() {});
    }
  }

  Future<void> _createAndSaveMask() async {
    if (_maskBitmap == null || _maskWidth == null || _maskHeight == null) {
      throw Exception('Mask chưa được khởi tạo');
    }

    // Count white pixels for validation
    int whitePixelCount = 0;
    for (int i = 0; i < _maskBitmap!.length; i++) {
      if (_maskBitmap![i] == 255) {
        whitePixelCount++;
      }
    }

    if (whitePixelCount == 0) {
      throw Exception('Không phát hiện vùng vẽ. Vui lòng vẽ trên những vùng cần xóa.');
    }

    // Create image from bitmap
    final img.Image maskImage = img.Image(
      width: _maskWidth!,
      height: _maskHeight!,
      numChannels: 1, // Grayscale
    );

    // Copy bitmap data to image
    for (int y = 0; y < _maskHeight!; y++) {
      for (int x = 0; x < _maskWidth!; x++) {
        final int index = y * _maskWidth! + x;
        final int value = _maskBitmap![index];
        maskImage.setPixel(x, y, img.ColorUint8(value));
      }
    }

    // Save as PNG
    final directory = await getTemporaryDirectory();
    final maskFile = File('${directory.path}/precision_mask_${DateTime.now().millisecondsSinceEpoch}.png');
    final maskPngBytes = img.encodePng(maskImage, level: 0); // No compression for binary data
    await maskFile.writeAsBytes(maskPngBytes);

    // Debug logging
    final double whitePercentage = (whitePixelCount / _maskBitmap!.length) * 100;
    print('=== PRECISION MASK CREATED ===');
    print('Mask dimensions: ${_maskWidth}x${_maskHeight} (matches original image)');
    print('White pixels (255=remove): $whitePixelCount (${whitePercentage.toStringAsFixed(2)}%)');
    print('Mask file: ${maskFile.path}');
    print('File size: ${maskPngBytes.length} bytes');

    widget.onMaskCreated(maskFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Precision Mask Drawing', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: _clearMask,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _backgroundImage == null
                  ? const CircularProgressIndicator()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (_backgroundImage != null && _originalImageSize != null) {
                          // Calculate display size maintaining aspect ratio
                          final double imageAspectRatio = _originalImageSize!.width / _originalImageSize!.height;
                          final double containerAspectRatio = constraints.maxWidth / constraints.maxHeight;
                          
                          Size displaySize;
                          if (imageAspectRatio > containerAspectRatio) {
                            // Image is wider - fit to width
                            displaySize = Size(
                              constraints.maxWidth,
                              constraints.maxWidth / imageAspectRatio,
                            );
                          } else {
                            // Image is taller - fit to height
                            displaySize = Size(
                              constraints.maxHeight * imageAspectRatio,
                              constraints.maxHeight,
                            );
                          }
                          
                          _imageDisplaySize = displaySize;
                          _scaleX = _originalImageSize!.width / displaySize.width;
                          _scaleY = _originalImageSize!.height / displaySize.height;
                          
                          return GestureDetector(
                            key: _canvasKey,
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            onPanEnd: _onPanEnd,
                            child: Container(
                              width: displaySize.width,
                              height: displaySize.height,
                              child: CustomPaint(
                                painter: _MaskOverlayPainter(
                                  backgroundImage: _backgroundImage!,
                                  maskBitmap: _maskBitmap,
                                  maskWidth: _maskWidth,
                                  maskHeight: _maskHeight,
                                  scaleX: _scaleX,
                                  scaleY: _scaleY,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Brush: ${widget.brushSize.round()}px',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _createAndSaveMask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Mask'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaskOverlayPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final Uint8List? maskBitmap;
  final int? maskWidth;
  final int? maskHeight;
  final double scaleX;
  final double scaleY;

  _MaskOverlayPainter({
    required this.backgroundImage,
    this.maskBitmap,
    this.maskWidth,
    this.maskHeight,
    required this.scaleX,
    required this.scaleY,
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

    // Draw mask overlay
    if (maskBitmap != null && maskWidth != null && maskHeight != null) {
      final paint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.fill;

      // Draw mask pixels as red overlay
      for (int y = 0; y < maskHeight!; y++) {
        for (int x = 0; x < maskWidth!; x++) {
          final int index = y * maskWidth! + x;
          if (maskBitmap![index] == 255) { // White pixels (to be removed)
            final double screenX = x / scaleX;
            final double screenY = y / scaleY;
            canvas.drawRect(
              Rect.fromLTWH(screenX, screenY, 1 / scaleX, 1 / scaleY),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}