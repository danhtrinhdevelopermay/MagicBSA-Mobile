import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;
import '../widgets/image_upload_widget.dart';
import '../services/video_preload_service.dart';
import '../widgets/pattern_painter.dart';

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
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Enhanced Header with Glass Effect
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'AI POWERED',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Tính năng AI ✨',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Khám phá sức mạnh AI để biến đổi ảnh của bạn',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Feature Grid or Loading with Enhanced Styling
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _serviceReady 
                ? SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final feature = features[index];
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOutCubic,
                          child: FeatureCard(
                            feature: feature,
                            videoController: _videoService.getController(feature.id),
                            isVideoReady: _serviceReady,
                            onTap: () => _onFeatureTap(feature),
                            index: index,
                          ),
                        );
                      },
                      childCount: features.length,
                    ),
                  )
                : SliverToBoxAdapter(
                    child: Container(
                      height: 400,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.movie_creation_outlined,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Đang chuẩn bị video demo...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Trải nghiệm sắp được bắt đầu',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: 200,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

class FeatureCard extends StatefulWidget {
  final FeatureModel feature;
  final VideoPlayerController? videoController;
  final bool isVideoReady;
  final VoidCallback onTap;
  final int index;

  const FeatureCard({
    super.key,
    required this.feature,
    this.videoController,
    required this.isVideoReady,
    required this.onTap,
    required this.index,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) {
                _animationController.reverse();
                widget.onTap();
              },
              onTapCancel: () => _animationController.reverse(),
              child: MouseRegion(
                onEnter: (_) {
                  setState(() => _isHovered = true);
                },
                onExit: (_) {
                  setState(() => _isHovered = false);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..translate(0.0, _isHovered ? -8.0 : 0.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.feature.gradient.colors.first.withOpacity(0.3),
                        blurRadius: _isHovered ? 30 : 20,
                        offset: Offset(0, _isHovered ? 15 : 10),
                        spreadRadius: _isHovered ? 2 : 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
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
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                            gradient: widget.feature.gradient,
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                            child: widget.isVideoReady && widget.videoController != null
                                ? Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: widget.videoController!.value.aspectRatio,
                                        child: VideoPlayer(widget.videoController!),
                                      ),
                                      // Gradient overlay for better text readability
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.4),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Play indicator
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: widget.feature.gradient,
                                    ),
                                    child: Stack(
                                      children: [
                                        // Animated background pattern
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: PatternPainter(
                                              color: Colors.white.withOpacity(0.1),
                                              animation: _animationController,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                widget.feature.icon,
                                                size: 48,
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'Loading...',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                ),
              ),
            ),

                          ),
                        ),
                      ),

                      // Enhanced Content Section
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: widget.feature.gradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.feature.gradient.colors.first.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      widget.feature.icon,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.feature.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1F2937),
                                            letterSpacing: -0.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          height: 2,
                                          width: 30,
                                          decoration: BoxDecoration(
                                            gradient: widget.feature.gradient,
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: Text(
                                  widget.feature.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Try now button
                              Container(
                                width: double.infinity,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: widget.feature.gradient,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.feature.gradient.colors.first.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Thử ngay',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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