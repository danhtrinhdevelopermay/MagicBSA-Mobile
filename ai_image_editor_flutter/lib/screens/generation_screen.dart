import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../widgets/image_upload_widget.dart';
import '../services/video_preload_service.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({super.key});

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
  final VideoPreloadService _videoService = VideoPreloadService();
  bool _serviceReady = false;
  final List<FeatureModel> features = [
    FeatureModel(
      id: 'remove_background',
      title: 'Xóa nền ảnh',
      description: 'Tự động loại bỏ nền ảnh với độ chính xác cao, giữ nguyên đối tượng chính. Hỗ trợ đa dạng loại ảnh từ chân dung, sản phẩm đến động vật.',
      videoPath: 'assets/videos/remove_background.mp4',
      icon: Icons.layers_clear_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureModel(
      id: 'expand_image',
      title: 'Mở rộng ảnh',
      description: 'Mở rộng khung hình thông minh, tự động tạo nội dung phù hợp xung quanh ảnh gốc. Lý tưởng cho việc thay đổi tỷ lệ và tạo không gian mới.',
      videoPath: 'assets/videos/expand_image.mp4',
      icon: Icons.crop_free_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureModel(
      id: 'upscaling',
      title: 'Nâng cấp độ phân giải',
      description: 'Tăng độ phân giải ảnh lên 2x, 4x với AI tiên tiến. Khôi phục chi tiết mất mát, làm sắc nét và cải thiện chất lượng ảnh cũ.',
      videoPath: 'assets/videos/upscaling.mp4',
      icon: Icons.high_quality_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureModel(
      id: 'cleanup',
      title: 'Làm sạch ảnh',
      description: 'Xóa bỏ đối tượng không mong muốn như người, vật thể, bóng râm. AI tự động lấp đầy vùng trống một cách tự nhiên và hài hòa.',
      videoPath: 'assets/videos/cleanup.mp4',
      icon: Icons.cleaning_services_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureModel(
      id: 'remove_text',
      title: 'Xóa chữ và watermark',
      description: 'Loại bỏ hoàn toàn văn bản, logo, watermark khỏi ảnh. Công nghệ AI phục hồi nền một cách tự nhiên, không để lại dấu vết.',
      videoPath: 'assets/videos/remove_text.mp4',
      icon: Icons.text_fields_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureModel(
      id: 'reimagine',
      title: 'Tái tạo ảnh sáng tạo',
      description: 'Tạo ra những phiên bản hoàn toàn mới của ảnh với phong cách nghệ thuật khác biệt. Biến ảnh thường thành tác phẩm nghệ thuật độc đáo.',
      videoPath: 'assets/videos/reimagine.mp4',
      icon: Icons.auto_fix_high_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    FeatureModel(
      id: 'text_to_image',
      title: 'Tạo ảnh từ văn bản',
      description: 'Biến ý tưởng thành hình ảnh chỉ bằng mô tả văn bản. Tạo ra những bức ảnh nghệ thuật, minh họa hoặc khái niệm hoàn toàn từ trí tưởng tượng.',
      videoPath: 'assets/videos/text_to_image.mp4',
      icon: Icons.image_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkVideoService();
  }

  void _checkVideoService() async {
    if (!_videoService.isInitialized) {
      await _videoService.preloadAllVideos();
    }
    
    if (mounted) {
      setState(() {
        _serviceReady = _videoService.isInitialized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tính năng AI ✨',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                      Color(0xFFEC4899),
                                    ],
                                  ).createShader(
                                    const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                  ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chọn tính năng bạn muốn sử dụng',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Feature Grid or Loading
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _serviceReady 
                ? SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final feature = features[index];
                        return FeatureCard(
                          feature: feature,
                          videoController: _videoService.getController(feature.id),
                          isVideoReady: _serviceReady,
                          onTap: () => _onFeatureTap(feature),
                        );
                      },
                      childCount: features.length,
                    ),
                  )
                : SliverToBoxAdapter(
                    child: Container(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.movie_creation_outlined,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Đang tải video demo...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vui lòng chờ một chút',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 200,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: const LinearProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                  backgroundColor: Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  void _onFeatureTap(FeatureModel feature) {
    // Navigate to upload screen with selected feature
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadImageScreen(selectedFeature: feature.id),
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final FeatureModel feature;
  final VideoPlayerController? videoController;
  final bool isVideoReady;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.feature,
    this.videoController,
    required this.isVideoReady,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Container
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: widget.feature.gradient,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: isVideoReady && videoController != null
                      ? AspectRatio(
                          aspectRatio: videoController!.value.aspectRatio,
                          child: VideoPlayer(videoController!),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: feature.gradient,
                          ),
                          child: Center(
                            child: Icon(
                              feature.icon,
                              size: 40,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Content
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: feature.gradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            feature.icon,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        feature.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadImageScreen extends StatelessWidget {
  final String selectedFeature;

  const UploadImageScreen({
    super.key,
    required this.selectedFeature,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ),
        title: Text(
          'Tải ảnh lên',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: ImageUploadWidget(preSelectedFeature: selectedFeature),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeatureModel {
  final String id;
  final String title;
  final String description;
  final String videoPath;
  final IconData icon;
  final LinearGradient gradient;

  FeatureModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoPath,
    required this.icon,
    required this.gradient,
  });
}