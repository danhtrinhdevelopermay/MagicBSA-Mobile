import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:math' as math;
import '../widgets/image_upload_widget.dart';
import '../services/video_preload_service.dart';
import '../widgets/pattern_painter.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({Key? key}) : super(key: key);

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  bool _isLoading = true;

  
  final List<Feature> features = [
    Feature(
      title: 'Xóa nền ảnh',
      description: 'Loại bỏ hoàn toàn nền ảnh chỉ trong vài giây với công nghệ AI tiên tiến. Phù hợp để tạo ảnh sản phẩm, ảnh chân dung chuyên nghiệp, hoặc ghép nền mới. Hỗ trợ đầy đủ các định dạng ảnh phổ biến và cho kết quả cực kỳ chính xác, giữ nguyên chất lượng đối tượng chính.',
      videoPath: 'assets/videos/remove-backgroud_1753972662268.mp4',
      icon: Icons.layers_clear_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'removeBackground',
    ),
    Feature(
      title: 'Mở rộng ảnh',
      description: 'Thêm không gian xung quanh ảnh một cách tự nhiên và thông minh. AI sẽ dự đoán và tạo thêm nội dung phù hợp với bối cảnh hiện tại của ảnh. Lý tưởng để chuyển đổi tỷ lệ khung hình, tạo wallpaper, hoặc mở rộng không gian trong ảnh phong cảnh, chân dung.',
      videoPath: 'assets/videos/expand-image_1753972662375.mp4',
      icon: Icons.open_in_full,
      gradient: LinearGradient(
        colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'uncrop',
    ),
    Feature(
      title: 'Nâng cấp độ phân giải',
      description: 'Tăng độ phân giải ảnh lên đến 4K mà không làm mất chất lượng. Công nghệ siêu phân giải AI tái tạo chi tiết sắc nét, khôi phục texture và làm mịn các đường nét. Hoàn hảo cho việc in ấn, thiết kế đồ họa chuyên nghiệp, hoặc phục hồi ảnh cũ có độ phân giải thấp.',
      videoPath: 'assets/videos/Upscaling_1753972662419.mp4',
      icon: Icons.high_quality,
      gradient: LinearGradient(
        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'imageUpscaling',
    ),
    Feature(
      title: 'Xóa vật thể',
      description: 'Loại bỏ bất kỳ vật thể nào không mong muốn khỏi ảnh một cách tự nhiên. Chỉ cần chạm và vẽ lên đối tượng cần xóa, AI sẽ tự động lấp đầy vùng đó bằng nội dung phù hợp. Tuyệt vời để dọn sạch ảnh du lịch, loại bỏ người qua đường, hoặc xóa các chi tiết làm mất thẩm mỹ.',
      videoPath: 'assets/videos/cleanup_1753972662443.mp4',
      icon: Icons.auto_fix_high,
      gradient: LinearGradient(
        colors: [Color(0xFFfc4a1a), Color(0xFFf7b733)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'cleanup',
    ),
    Feature(
      title: 'Xóa chữ khỏi ảnh',
      description: 'Loại bỏ hoàn toàn text, watermark, logo, hay bất kỳ văn bản nào từ ảnh. AI thông minh nhận diện và xóa sạch các ký tự, đồng thời tự động khôi phục nền phía sau. Lý tưởng để làm sạch ảnh stock, xóa watermark không mong muốn, hoặc chuẩn bị ảnh cho thiết kế mới.',
      videoPath: 'assets/videos/remove-text-demo_1753972669081.mp4',
      icon: Icons.text_fields_outlined,
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'removeText',
    ),
    Feature(
      title: 'Tái tạo ảnh AI',
      description: 'Biến đổi hoàn toàn phong cách và diện mạo của ảnh với sức mạnh AI sáng tạo. Giữ nguyên bố cục và đối tượng chính nhưng thay đổi hoàn toàn màu sắc, texture, và phong cách nghệ thuật. Khám phá vô số khả năng sáng tạo từ hiện thực đến abstract, từ cổ điển đến hiện đại.',
      videoPath: 'assets/videos/reimagine_1753972669187.mp4',
      icon: Icons.auto_awesome,
      gradient: LinearGradient(
        colors: [Color(0xFF8360c3), Color(0xFF2ebf91)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'reimagine',
    ),
    Feature(
      title: 'Tạo ảnh từ văn bản',
      description: 'Biến ý tưởng thành hình ảnh thực tế chỉ bằng cách mô tả bằng lời. AI sẽ hiểu và tạo ra những bức ảnh tuyệt đẹp theo đúng mô tả của bạn. Từ phong cảnh thơ mộng, nhân vật anime, đến thiết kế logo, mọi ý tưởng đều có thể thành hiện thực với chất lượng chuyên nghiệp.',
      videoPath: 'assets/videos/text-to-image_1753972669268.mp4',
      icon: Icons.create,
      gradient: LinearGradient(
        colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'textToImage',
    ),
    Feature(
      title: 'Chụp ảnh sản phẩm',
      description: 'Tự động tạo nên những bức ảnh sản phẩm chuyên nghiệp như studio với nền đẹp và ánh sáng hoàn hảo. AI sẽ phân tích sản phẩm và tự động tạo môi trường, bối cảnh phù hợp. Lý tưởng cho thương mại điện tử, catalog sản phẩm, hoặc quảng cáo trên mạng xã hội.',
      videoPath: 'assets/videos/anh-san-pham_1753972669244.mp4',
      icon: Icons.camera_alt,
      gradient: LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      operation: 'productPhotography',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));
    
    _startLoading();
  }

  void _startLoading() async {
    _loadingController.repeat();
    
    // Preload all videos
    await VideoPreloadService.instance.preloadAllVideos(features);
    
    // Simulate minimum loading time for better UX
    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
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
        child: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _loadingAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _loadingAnimation.value * 2 * math.pi,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.3),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 40,
                      color: Color(0xFF667eea),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Đang chuẩn bị video demo...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trải nghiệm sắp được bắt đầu',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _loadingAnimation,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 200 * _loadingAnimation.value,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        // Glass Morphism Header
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
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'AI POWERED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chọn tính năng AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Khám phá sức mạnh trí tuệ nhân tạo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Feature Grid
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: FeatureCard(
                        feature: features[index],
                        onTap: () => _navigateToUpload(features[index]),
                        isVideoReady: VideoPreloadService.instance.isVideoReady(features[index].videoPath),
                        videoController: VideoPreloadService.instance.getController(features[index].videoPath),
                      ),
                    ),
                  );
                },
              );
            },
            childCount: features.length,
          ),
        ),

        // Bottom Spacing with tip
        SliverToBoxAdapter(
          child: Container(
            height: 120,
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.05),
                ],
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chọn tính năng phù hợp với nhu cầu của bạn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToUpload(Feature feature) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageUploadWidget(
          selectedOperation: feature.operation,
        ),
      ),
    );
  }
}

class FeatureCard extends StatefulWidget {
  final Feature feature;
  final VoidCallback onTap;
  final bool isVideoReady;
  final VideoPlayerController? videoController;

  const FeatureCard({
    Key? key,
    required this.feature,
    required this.onTap,
    required this.isVideoReady,
    this.videoController,
  }) : super(key: key);

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
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) {
          _animationController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _animationController.reverse(),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()
                    ..translate(0.0, _isHovered ? -8.0 : 0.0, 0.0),
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class Feature {
  final String title;
  final String description;
  final String videoPath;
  final IconData icon;
  final LinearGradient gradient;
  final String operation;

  const Feature({
    required this.title,
    required this.description,
    required this.videoPath,
    required this.icon,
    required this.gradient,
    required this.operation,
  });
}