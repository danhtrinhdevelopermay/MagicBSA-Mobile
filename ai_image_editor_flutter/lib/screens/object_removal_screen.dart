import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/image_provider.dart';
import '../services/clipdrop_service.dart';

class ObjectRemovalScreen extends StatefulWidget {
  final File imageFile;
  
  const ObjectRemovalScreen({
    Key? key,
    required this.imageFile,
  }) : super(key: key);

  @override
  State<ObjectRemovalScreen> createState() => _ObjectRemovalScreenState();
}

class _ObjectRemovalScreenState extends State<ObjectRemovalScreen> {
  double _brushSize = 50.0; // Default brush size
  bool _isOriginalVisible = true; // Toggle for eye icon
  final GlobalKey _canvasKey = GlobalKey();
  final List<Offset> _maskPoints = [];
  late ui.Image _backgroundImage;
  bool _imageLoaded = false;
  
  @override
  void initState() {
    super.initState();
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _backgroundImage = frame.image;
      _imageLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Main image display with mask drawing
          Positioned.fill(
            child: _imageLoaded
                ? GestureDetector(
                    onPanStart: (details) {
                      _addMaskPoint(details.localPosition);
                    },
                    onPanUpdate: (details) {
                      _addMaskPoint(details.localPosition);
                    },
                    child: RepaintBoundary(
                      key: _canvasKey,
                      child: CustomPaint(
                        painter: MaskPainter(
                          backgroundImage: _backgroundImage,
                          maskPoints: _maskPoints,
                          brushSize: _brushSize,
                          showOriginal: _isOriginalVisible,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9ACD32)),
                      ),
                    ),
                  ),
          ),
          
          // Top header bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back arrow
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      
                      // Center controls (eye icon and toggle)
                      Row(
                        children: [
                          // Eye icon
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isOriginalVisible = !_isOriginalVisible;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _isOriginalVisible ? Icons.visibility : Icons.visibility_off,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Toggle switch
                          Container(
                            width: 60,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  left: _isOriginalVisible ? 4 : 28,
                                  top: 4,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Settings icon
                      GestureDetector(
                        onTap: () {
                          // Handle settings tap
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Right sidebar with tools
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Object removal tool (circle with line)
                  GestureDetector(
                    onTap: _clearMask,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.clear,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  // Zoom/search tool
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom controls
          Positioned(
            bottom: 60,
            left: 60,
            right: 16,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Brush label and slider
                  Expanded(
                    child: Row(
                      children: [
                        const Text(
                          'Brush',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                              activeTrackColor: const Color(0xFF9ACD32), // Lime green
                              inactiveTrackColor: Colors.grey[600],
                              thumbColor: Colors.black,
                              overlayColor: const Color(0xFF9ACD32).withOpacity(0.2),
                            ),
                            child: Slider(
                              value: _brushSize,
                              min: 10,
                              max: 100,
                              onChanged: (value) {
                                setState(() {
                                  _brushSize = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Clean button
                  GestureDetector(
                    onTap: () {
                      _handleCleanTap();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9ACD32), // Lime green
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9ACD32).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Clean',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _addMaskPoint(Offset point) {
    setState(() {
      _maskPoints.add(point);
    });
  }

  void _clearMask() {
    setState(() {
      _maskPoints.clear();
    });
  }

  Future<void> _handleCleanTap() async {
    if (_maskPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng vẽ vùng cần xóa trước'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create mask file
      final maskFile = await _createMaskFile();
      
      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9ACD32)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đang xử lý ảnh...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );

      // Process with provider
      final provider = Provider.of<ImageEditProvider>(context, listen: false);
      await provider.processImageWithMask(
        ProcessingOperation.cleanup,
        maskFile: maskFile,
      );

      Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      Navigator.pop(context); // Close dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<File> _createMaskFile() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Get image dimensions
    final imageSize = Size(_backgroundImage.width.toDouble(), _backgroundImage.height.toDouble());
    
    // Create black background (keep areas)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      Paint()..color = Colors.black,
    );
    
    // Draw white circles for mask points (remove areas)
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    for (final point in _maskPoints) {
      // Convert screen coordinates to image coordinates
      final imagePoint = Offset(
        point.dx * imageSize.width / MediaQuery.of(context).size.width,
        point.dy * imageSize.height / MediaQuery.of(context).size.height,
      );
      
      canvas.drawCircle(imagePoint, _brushSize / 2, paint);
    }
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(imageSize.width.toInt(), imageSize.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    
    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final maskFile = File('${tempDir.path}/mask_${DateTime.now().millisecondsSinceEpoch}.png');
    await maskFile.writeAsBytes(bytes);
    
    return maskFile;
  }
}

class MaskPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final List<Offset> maskPoints;
  final double brushSize;
  final bool showOriginal;

  MaskPainter({
    required this.backgroundImage,
    required this.maskPoints,
    required this.brushSize,
    required this.showOriginal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate scale to fit image in screen
    final imageSize = Size(backgroundImage.width.toDouble(), backgroundImage.height.toDouble());
    final scale = math.min(size.width / imageSize.width, size.height / imageSize.height);
    final scaledSize = Size(imageSize.width * scale, imageSize.height * scale);
    final offset = Offset(
      (size.width - scaledSize.width) / 2,
      (size.height - scaledSize.height) / 2,
    );

    // Draw background image
    canvas.drawImageRect(
      backgroundImage,
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      Rect.fromLTWH(offset.dx, offset.dy, scaledSize.width, scaledSize.height),
      Paint(),
    );

    if (!showOriginal && maskPoints.isNotEmpty) {
      // Draw semi-transparent overlay
      canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy, scaledSize.width, scaledSize.height),
        Paint()..color = Colors.black.withOpacity(0.3),
      );
    }

    // Draw mask points
    final maskPaint = Paint()
      ..color = const Color(0xFF9ACD32).withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in maskPoints) {
      canvas.drawCircle(point, brushSize / 2, maskPaint);
      canvas.drawCircle(point, brushSize / 2, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}