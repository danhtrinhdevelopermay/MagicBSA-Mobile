import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/image_provider.dart';
import '../models/processing_operation.dart';
import '../widgets/floating_bottom_navigation.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  Map<ProcessingOperation, Map<String, dynamic>> get featureDetails => {
    ProcessingOperation.removeBackground: {
      'title': 'Xóa Nền Ảnh',
      'description': 'Loại bỏ nền ảnh tự động bằng công nghệ AI tiên tiến. Phù hợp cho ảnh chân dung, sản phẩm, hay bất kỳ đối tượng nào bạn muốn tách khỏi nền.',
      'icon': Icons.layers_clear,
      'gradient': const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'tips': [
        'Ảnh có nền đơn giản cho kết quả tốt nhất',
        'Đối tượng chính rõ ràng, không bị che khuất',
        'Độ phân giải cao để có chất lượng tốt',
      ],
    },
    ProcessingOperation.cleanup: {
      'title': 'Xóa Vật Thể',
      'description': 'Xóa bỏ các đối tượng không mong muốn trong ảnh bằng cách vẽ mask. AI sẽ tự động lấp đầy vùng đã xóa một cách tự nhiên.',
      'icon': Icons.cleaning_services,
      'gradient': const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFF97316)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'tips': [
        'Vẽ chính xác vùng cần xóa',
        'Tránh xóa quá nhiều chi tiết quan trọng',
        'Nên xóa từng vật thể một để có kết quả tốt',
      ],
    },
    ProcessingOperation.removeText: {
      'title': 'Xóa Chữ Trong Ảnh',
      'description': 'Loại bỏ văn bản, chữ viết, logo hay watermark khỏi hình ảnh một cách tự nhiên và không để lại dấu vết.',
      'icon': Icons.text_fields_outlined,
      'gradient': const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'tips': [
        'Hoạt động tốt với văn bản rõ ràng',
        'Nền đằng sau chữ càng đơn giản càng tốt',
        'Kết quả phụ thuộc vào độ phức tạp của nền',
      ],
    },
    ProcessingOperation.uncrop: {
      'title': 'Mở Rộng Khung Ảnh',
      'description': 'Mở rộng khung hình ảnh bằng AI để có thêm không gian xung quanh. Tính năng này sẽ dự đoán và tạo ra nội dung phù hợp.',
      'icon': Icons.crop_free,
      'gradient': const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'tips': [
        'Hoạt động tốt với ảnh có nền đơn giản',
        'Kết quả phụ thuộc vào ngữ cảnh xung quanh',
        'Phù hợp cho ảnh phong cảnh, kiến trúc',
      ],
    },
    ProcessingOperation.imageUpscaling: {
      'title': 'Tăng Độ Phân Giải',
      'description': 'Nâng cao chất lượng và độ phân giải của ảnh bằng AI. Làm cho ảnh nhỏ trở nên sắc nét và chi tiết hơn.',
      'icon': Icons.high_quality,
      'gradient': const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'tips': [
        'Phù hợp cho ảnh có độ phân giải thấp',
        'Kết quả tốt nhất với ảnh rõ nét ban đầu',
        'Có thể tăng kích thước lên 2-4 lần',
      ],
    },
    ProcessingOperation.reimagine: {
      'title': 'Tái Tưởng Tượng',
      'description': 'Tạo ra các biến thể mới từ ảnh gốc với phong cách và chi tiết khác nhau. AI sẽ giữ nguyên ý tưởng chính nhưng thay đổi cách thể hiện.',
      'icon': Icons.auto_fix_high,
      'gradient': const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'tips': [
        'Ảnh càng có tính nghệ thuật càng tốt',
        'Kết quả có thể khác biệt hoàn toàn',
        'Thử nhiều lần để có kết quả ưng ý',
      ],
    },
    ProcessingOperation.textToImage: {
      'title': 'Tạo Ảnh Từ Mô Tả',
      'description': 'Tạo ra hình ảnh hoàn toàn mới từ mô tả bằng văn bản. Chỉ cần mô tả những gì bạn muốn thấy.',
      'icon': Icons.create,
      'gradient': const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'tips': [
        'Mô tả càng chi tiết càng tốt',
        'Sử dụng tiếng Anh cho kết quả tốt nhất',
        'Bao gồm màu sắc, phong cách, bối cảnh',
      ],
    },
    ProcessingOperation.productPhotography: {
      'title': 'Ảnh Sản Phẩm Chuyên Nghiệp',
      'description': 'Tạo ảnh sản phẩm chuyên nghiệp với nền đẹp và ánh sáng hoàn hảo. Phù hợp cho e-commerce và marketing.',
      'icon': Icons.camera_alt,
      'gradient': const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'tips': [
        'Sản phẩm được chụp rõ ràng, tách nền',
        'Ánh sáng đều, không có bóng đổ quá mạnh',
        'Góc chụp phù hợp với sản phẩm',
      ],
    },
  };

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final provider = Provider.of<ImageEditProvider>(context, listen: false);
    
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 4096,
        maxHeight: 4096,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        await provider.setOriginalImage(pickedFile.path);
        
        // Chuyển đến editor screen
        if (context.mounted) {
          Navigator.pushNamed(context, '/editor');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageEditProvider>(
      builder: (context, provider, child) {
        final selectedOperation = provider.selectedOperation;
        final details = selectedOperation != null 
            ? featureDetails[selectedOperation] 
            : null;

        if (details == null) {
          // Nếu không có operation được chọn, quay về generation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/generation');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              children: [
                // Header với gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: details['gradient'] as Gradient,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              details['icon'] as IconData,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  details['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tải ảnh lên để bắt đầu',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
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

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mô tả tính năng
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Về tính năng này',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                details['description'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Tips
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.amber[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mẹo để có kết quả tốt nhất',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...((details['tips'] as List<String>).map((tip) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 8, right: 12),
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          tip,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Upload buttons
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickImage(context, ImageSource.gallery),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: details['gradient'] as Gradient,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.photo_library,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Thư viện',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickImage(context, ImageSource.camera),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: (details['gradient'] as LinearGradient)
                                          .colors.first.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: (details['gradient'] as LinearGradient).colors.first,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Máy ảnh',
                                        style: TextStyle(
                                          color: (details['gradient'] as LinearGradient).colors.first,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const FloatingBottomNavigation(),
        );
      },
    );
  }
}