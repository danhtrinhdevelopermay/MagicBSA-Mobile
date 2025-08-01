import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/image_upload_widget.dart';
import '../widgets/animatediff_widget.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({Key? key}) : super(key: key);

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> with TickerProviderStateMixin {
  Map<String, bool> _isPressed = {};
  
  final List<Feature> features = [
    Feature(
      title: 'Xóa nền ảnh',
      description: 'Loại bỏ hoàn toàn nền ảnh',
      icon: Icons.layers_clear_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'removeBackground',
      gifPath: 'assets/gifs/remove-background.gif',
    ),
    Feature(
      title: 'Mở rộng ảnh',
      description: 'Thêm không gian',
      icon: Icons.open_in_full,
      gradient: LinearGradient(
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'uncrop',
      gifPath: 'assets/gifs/expand-image.gif',
    ),
    Feature(
      title: 'Nâng cấp độ phân giải',
      description: 'Tăng chất lượng ảnh',
      icon: Icons.high_quality,
      gradient: LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'imageUpscaling',
      gifPath: 'assets/gifs/upscaling.gif',
    ),
    Feature(
      title: 'Xóa vật thể',
      description: 'Loại bỏ bất kỳ vật thể nào',
      icon: Icons.auto_fix_high,
      gradient: LinearGradient(
        colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'cleanup',
      gifPath: 'assets/gifs/cleanup.gif',
    ),
    Feature(
      title: 'Xóa chữ khỏi ảnh',
      description: 'Loại bỏ văn bản',
      icon: Icons.text_fields_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'removeText',
      gifPath: 'assets/gifs/remove-text.gif',
    ),
    Feature(
      title: 'Tái tạo ảnh AI',
      description: 'Biến đổi phong cách',
      icon: Icons.auto_awesome,
      gradient: LinearGradient(
        colors: [Color(0xFF8360c3), Color(0xFF2ebf91)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'reimagine',
      gifPath: 'assets/gifs/reimagine.gif',
    ),
    Feature(
      title: 'Tạo ảnh từ văn bản',
      description: 'Biến ý tưởng thành hình ảnh',
      icon: Icons.create,
      gradient: LinearGradient(
        colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'textToImage',
      gifPath: 'assets/gifs/text-to-image.gif',
    ),
    Feature(
      title: 'Chụp ảnh sản phẩm',
      description: 'Tạo ảnh sản phẩm chuyên nghiệp',
      icon: Icons.camera_alt,
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'productPhotography',
      gifPath: 'assets/gifs/product-photography.gif',
    ),
    Feature(
      title: 'Tạo video từ ảnh Pro',
      description: 'AnimateDiff AI biến ảnh thành video sống động',
      icon: Icons.videocam,
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'animateDiffVideo',
      gifPath: 'assets/gifs/text-to-image.gif', // Using existing GIF as placeholder demo
    ),
  ];

  @override
  void initState() {
    super.initState();
    // GIF system doesn't need initialization like videos
  }
  
  @override
  void dispose() {
    // GIF system doesn't need disposal like videos
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
              Color(0xFFf5576c),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Simple Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'AI POWERED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Chọn tính năng AI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Khám phá sức mạnh trí tuệ nhân tạo',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Enhanced Grid with Staggered Animation
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: GridView.builder(
                    physics: BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.78, // Slightly taller for better proportions
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        curve: Curves.easeOutBack,
                        child: _buildGifFeatureCard(feature),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGifFeatureCard(Feature feature) {
    final isPressed = _isPressed[feature.operation] ?? false;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      transform: Matrix4.identity()
        ..scale(isPressed ? 0.95 : 1.0),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _isPressed[feature.operation] = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            _isPressed[feature.operation] = false;
          });
          HapticFeedback.lightImpact();
          _navigateToUpload(feature.operation);
        },
        onTapCancel: () {
          setState(() {
            _isPressed[feature.operation] = false;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              // Multiple shadow layers for depth
              BoxShadow(
                color: feature.gradient.colors.first.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: Offset(0, 5),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                // Glassmorphism background
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Enhanced GIF/Icon Section
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            feature.gradient.colors.first,
                            feature.gradient.colors.last,
                            feature.gradient.colors.first.withOpacity(0.8),
                          ],
                          stops: [0.0, 0.7, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: [
                          // GIF Background with better handling
                          if (feature.gifPath != null)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(28),
                                  topRight: Radius.circular(28),
                                ),
                                child: Stack(
                                  children: [
                                    Image.asset(
                                      feature.gifPath!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: feature.gradient,
                                          ),
                                        );
                                      },
                                    ),
                                    // Subtle overlay for better text readability
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.1),
                                            Colors.black.withOpacity(0.3),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Floating AI Badge
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'AI',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Enhanced Icon with glassmorphism
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                feature.icon,
                                size: 36,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Enhanced Content Section
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with improved typography
                          Text(
                            feature.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),
                          
                          // Description with better styling
                          Text(
                            feature.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.3,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          Spacer(),
                          
                          // Enhanced CTA Button
                          Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  feature.gradient.colors.first,
                                  feature.gradient.colors.last,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: feature.gradient.colors.first.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _navigateToUpload(feature.operation);
                                },
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Thử ngay',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
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
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToUpload(String operation) {
    if (operation == 'animateDiffVideo') {
      // Navigate to AnimateDiff widget instead of upload widget
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: const Color(0xFF1a1a1a),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'AnimateDiff Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: const AnimateDiffWidget(),
          ),
        ),
      );
    } else {
      // Navigate to normal upload widget for other features
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImageUploadWidget(
            preSelectedFeature: operation,
          ),
        ),
      );
    }
  }
}

class Feature {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final String operation;
  final String? gifPath;

  const Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.operation,
    this.gifPath,
  });
}