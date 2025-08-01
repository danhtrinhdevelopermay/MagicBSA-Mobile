import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../widgets/image_upload_widget.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({Key? key}) : super(key: key);

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> with TickerProviderStateMixin {
  Map<String, VideoPlayerController?> _videoControllers = {};
  
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
      videoPath: 'assets/videos/remove-backgroud_1754010253262.mp4',
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
      videoPath: 'assets/videos/expand-image_1754010253290.mp4',
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
      videoPath: 'assets/videos/Upscaling_1754010253319.mp4',
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
      videoPath: 'assets/videos/cleanup_1754010253223.mp4',
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
      videoPath: 'assets/videos/remove-text-demo_1754010271325.mp4',
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
      videoPath: 'assets/videos/reimagine_1754010271349.mp4',
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
      videoPath: 'assets/videos/text-to-image_1754010271269.mp4',
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
      videoPath: 'assets/videos/anh-san-pham_1754010271301.mp4',
    ),
    Feature(
      title: 'Tạo video từ ảnh',
      description: 'Biến ảnh thành video sống động',
      icon: Icons.videocam,
      gradient: LinearGradient(
        colors: [Color(0xFFff9a56), Color(0xFFff6b95)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'imageToVideo',
      videoPath: null, // No demo video for this feature
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideoControllers();
  }
  
  @override
  void dispose() {
    _disposeVideoControllers();
    super.dispose();
  }
  
  void _initializeVideoControllers() {
    for (var feature in features) {
      if (feature.videoPath != null) {
        final controller = VideoPlayerController.asset(feature.videoPath!);
        _videoControllers[feature.operation] = controller;
        
        controller.initialize().then((_) {
          if (mounted) {
            setState(() {});
            controller.setLooping(true);
            controller.play();
            controller.setVolume(0); // Mute videos
          }
        });
      }
    }
  }
  
  void _disposeVideoControllers() {
    for (var controller in _videoControllers.values) {
      controller?.dispose();
    }
    _videoControllers.clear();
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
              
              // Improved Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return _buildVideoFeatureCard(feature);
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

  Widget _buildVideoFeatureCard(Feature feature) {
    final controller = _videoControllers[feature.operation];
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToUpload(feature.operation);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: feature.gradient.colors.first.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Video/Icon Section
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: feature.gradient,
                  ),
                  child: Stack(
                    children: [
                      // Video Background (if available)
                      if (controller != null && controller.value.isInitialized)
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: controller.value.size.width,
                              height: controller.value.size.height,
                              child: VideoPlayer(controller),
                            ),
                          ),
                        ),
                      
                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                feature.gradient.colors.first.withOpacity(0.3),
                                feature.gradient.colors.last.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Icon (always visible)
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            feature.icon,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content Section
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacer(),
                      Container(
                        width: double.infinity,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: feature.gradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Thử ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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
        ),
      ),
    );
  }

  void _navigateToUpload(String operation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageUploadWidget(
          preSelectedFeature: operation,
        ),
      ),
    );
  }
}

class Feature {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;
  final String operation;
  final String? videoPath;

  const Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.operation,
    this.videoPath,
  });
}