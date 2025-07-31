import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';
import '../models/processing_operation.dart';
import '../widgets/floating_bottom_navigation.dart';
// import '../screens/simple_mask_drawing_screen.dart'; // TODO: Create this screen
import '../widgets/result_widget.dart';
import '../widgets/loading_overlay_widget.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  void initState() {
    super.initState();
    _autoProcessImage();
  }

  void _autoProcessImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ImageEditProvider>(context, listen: false);
      final operation = provider.selectedOperation;
      
      if (operation != null && operation != ProcessingOperation.cleanup) {
        // Tự động xử lý cho các tính năng khác cleanup
        _processImage(operation);
      }
    });
  }

  void _processImage(ProcessingOperation operation) {
    final provider = Provider.of<ImageEditProvider>(context, listen: false);
    
    switch (operation) {
      case ProcessingOperation.removeBackground:
        provider.removeBackground();
        break;
      case ProcessingOperation.removeText:
        provider.removeText();
        break;
      case ProcessingOperation.uncrop:
        provider.uncrop();
        break;
      case ProcessingOperation.imageUpscaling:
        provider.upscaleImage();
        break;
      case ProcessingOperation.reimagine:
        provider.reimagine();
        break;
      case ProcessingOperation.productPhotography:
        provider.productPhotography();
        break;
      case ProcessingOperation.textToImage:
        _showTextToImageDialog();
        break;
      case ProcessingOperation.replaceBackground:
        provider.replaceBackground();
        break;
      case ProcessingOperation.cleanup:
        // Cleanup cần mask drawing
        _navigateToMaskDrawing();
        break;
    }
  }

  void _showTextToImageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo Ảnh Từ Mô Tả'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mô tả hình ảnh bạn muốn tạo:'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'VD: A beautiful sunset over mountains...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (prompt) {
                Navigator.pop(context);
                if (prompt.isNotEmpty) {
                  final provider = Provider.of<ImageEditProvider>(context, listen: false);
                  provider.generateFromText(prompt);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement text submission
              Navigator.pop(context);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _navigateToMaskDrawing() {
    // TODO: Implement mask drawing screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng vẽ mask đang được phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _startOver() {
    final provider = Provider.of<ImageEditProvider>(context, listen: false);
    provider.reset();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/generation',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageEditProvider>(
      builder: (context, provider, child) {
        final operation = provider.selectedOperation;
        
        if (operation == null) {
          // Nếu không có operation, quay về generation
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/generation');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Hiển thị loading khi đang xử lý
        if (provider.state == ProcessingState.processing) {
          return Scaffold(
            backgroundColor: Colors.black54,
            body: LoadingOverlayWidget(operation: _getOperationDisplayName(operation)),
          );
        }

        // Hiển thị kết quả khi hoàn thành
        if (provider.state == ProcessingState.completed && provider.processedImage != null) {
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
                        colors: [Colors.green.shade600, Colors.teal.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
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
                          child: const Icon(
                            Icons.check_circle,
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
                                'Hoàn Thành!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Ảnh đã được xử lý thành công',
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
                  ),
                  
                  // Result widget
                  Expanded(
                    child: ResultWidget(
                      originalImage: provider.originalImage!,
                      processedImageData: provider.processedImage!,
                      onStartOver: _startOver,
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const FloatingBottomNavigation(),
          );
        }

        // Cleanup operation cần mask drawing - hiện tại chưa implement
        if (operation == ProcessingOperation.cleanup && provider.originalImage != null) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Tính năng vẽ mask đang được phát triển',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const FloatingBottomNavigation(),
          );
        }

        // Default fallback
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Có lỗi xảy ra',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const FloatingBottomNavigation(),
        );
      },
    );
  }

  String _getOperationDisplayName(ProcessingOperation operation) {
    switch (operation) {
      case ProcessingOperation.removeBackground:
        return 'Đang xóa nền...';
      case ProcessingOperation.removeText:
        return 'Đang xóa chữ...';
      case ProcessingOperation.cleanup:
        return 'Đang xóa vật thể...';
      case ProcessingOperation.uncrop:
        return 'Đang mở rộng ảnh...';
      case ProcessingOperation.imageUpscaling:
        return 'Đang tăng độ phân giải...';
      case ProcessingOperation.reimagine:
        return 'Đang tái tưởng tượng...';
      case ProcessingOperation.textToImage:
        return 'Đang tạo ảnh...';
      case ProcessingOperation.productPhotography:
        return 'Đang tạo ảnh sản phẩm...';
      case ProcessingOperation.replaceBackground:
        return 'Đang thay nền...';
      default:
        return 'Đang xử lý...';
    }
  }
}