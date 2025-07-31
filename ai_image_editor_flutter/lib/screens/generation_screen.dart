import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/image_upload_widget.dart';

class GenerationScreen extends StatefulWidget {
  const GenerationScreen({Key? key}) : super(key: key);

  @override
  State<GenerationScreen> createState() => _GenerationScreenState();
}

class _GenerationScreenState extends State<GenerationScreen> {
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
    ),
  ];

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
              
              // Simple Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return _buildSimpleFeatureCard(feature);
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

  Widget _buildSimpleFeatureCard(Feature feature) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _navigateToUpload(feature.operation);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: feature.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: feature.gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon Section (Larger)
            Expanded(
              flex: 3,
              child: Center(
                child: Icon(
                  feature.icon,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Content Section (Smaller)
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      feature.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    Container(
                      width: double.infinity,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: feature.gradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          'Thử ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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

  const Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.operation,
  });
}