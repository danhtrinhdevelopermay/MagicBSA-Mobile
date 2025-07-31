import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';
import '../models/processing_operation.dart';
import '../widgets/floating_bottom_navigation.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({super.key});

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
  final Map<String, VideoPlayerController> _controllers = {};
  bool _isInitialized = false;

  final List<FeatureCard> features = [
    FeatureCard(
      operation: ProcessingOperation.removeBackground,
      title: 'Xóa Nền',
      description: 'Loại bỏ nền ảnh tự động bằng AI',
      videoPath: 'assets/videos/remove-background.mp4',
      icon: Icons.layers_clear,
      gradient: const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureCard(
      operation: ProcessingOperation.cleanup,
      title: 'Xóa Vật Thể',
      description: 'Xóa bỏ các đối tượng không mong muốn',
      videoPath: 'assets/videos/cleanup.mp4',
      icon: Icons.cleaning_services,
      gradient: const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFF97316)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureCard(
      operation: ProcessingOperation.removeText,
      title: 'Xóa Chữ',
      description: 'Loại bỏ văn bản khỏi hình ảnh',
      videoPath: 'assets/videos/remove-text.mp4',
      icon: Icons.text_fields_outlined,
      gradient: const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureCard(
      operation: ProcessingOperation.uncrop,
      title: 'Mở Rộng Ảnh',
      description: 'Mở rộng khung hình với AI',
      videoPath: 'assets/videos/expand-image.mp4',
      icon: Icons.crop_free,
      gradient: const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureCard(
      operation: ProcessingOperation.imageUpscaling,
      title: 'Tăng Độ Phân Giải',
      description: 'Nâng cao chất lượng và độ phân giải',
      videoPath: 'assets/videos/upscaling.mp4',
      icon: Icons.high_quality,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureCard(
      operation: ProcessingOperation.reimagine,
      title: 'Tái Tưởng Tượng',
      description: 'Tạo biến thể mới từ ảnh gốc',
      videoPath: 'assets/videos/reimagine.mp4',
      icon: Icons.auto_fix_high,
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureCard(
      operation: ProcessingOperation.textToImage,
      title: 'Tạo Ảnh Từ Chữ',
      description: 'Tạo hình ảnh từ mô tả bằng văn bản',
      videoPath: 'assets/videos/text-to-image.mp4',
      icon: Icons.create,
      gradient: const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureCard(
      operation: ProcessingOperation.productPhotography,
      title: 'Ảnh Sản Phẩm',
      description: 'Tạo ảnh sản phẩm chuyên nghiệp',
      videoPath: 'assets/videos/product-photo.mp4',
      icon: Icons.camera_alt,
      gradient: const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeVideoControllers();
  }

  Future<void> _initializeVideoControllers() async {
    for (final feature in features) {
      final controller = VideoPlayerController.asset(feature.videoPath);
      _controllers[feature.operation.toString()] = controller;
      
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0); // Mute videos
      controller.play();
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectFeature(ProcessingOperation operation) {
    // Lưu operation đã chọn và chuyển đến màn hình upload
    final provider = Provider.of<ImageEditProvider>(context, listen: false);
    provider.setSelectedOperation(operation);
    
    Navigator.pushNamed(context, '/upload');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Features',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Chọn tính năng AI phù hợp',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Feature Cards Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: features.length,
                  itemBuilder: (context, index) {
                    final feature = features[index];
                    final controller = _controllers[feature.operation.toString()];
                    
                    return GestureDetector(
                      onTap: () => _selectFeature(feature.operation),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // Video Background
                              if (_isInitialized && controller != null)
                                Positioned.fill(
                                  child: AspectRatio(
                                    aspectRatio: controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  ),
                                )
                              else
                                // Placeholder while video loads
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: feature.gradient,
                                  ),
                                ),
                              
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Content
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon and play indicator
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            feature.icon,
                                            color: Colors.purple.shade600,
                                            size: 20,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.play_arrow,
                                            color: Colors.purple.shade600,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const Spacer(),
                                    
                                    // Title and description
                                    Text(
                                      feature.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      feature.description,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const FloatingBottomNavigation(),
    );
  }
}

class FeatureCard {
  final ProcessingOperation operation;
  final String title;
  final String description;
  final String videoPath;
  final IconData icon;
  final Gradient gradient;

  const FeatureCard({
    required this.operation,
    required this.title,
    required this.description,
    required this.videoPath,
    required this.icon,
    required this.gradient,
  });
}