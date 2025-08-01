import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/image_provider.dart';
import '../screens/editor_screen.dart';
import '../widgets/text_to_image_widget.dart';
import '../widgets/image_to_video_widget.dart';
import 'text_to_image_upload_screen.dart';

class FeatureUploadScreen extends StatefulWidget {
  final String featureOperation;
  final String featureTitle;
  final IconData featureIcon;
  final LinearGradient featureGradient;
  
  const FeatureUploadScreen({
    super.key,
    required this.featureOperation,
    required this.featureTitle,
    required this.featureIcon,
    required this.featureGradient,
  });

  @override
  State<FeatureUploadScreen> createState() => _FeatureUploadScreenState();
}

class _FeatureUploadScreenState extends State<FeatureUploadScreen> {
  File? _selectedImage;
  String _prompt = '';
  double _strength = 0.8;
  String _backgroundPrompt = 'professional, clean background';
  
  // Tính năng nào cần bảng điều khiển
  bool get _needsControlPanel {
    return widget.featureOperation == 'cleanup';
  }
  
  // Tính năng nào chỉ cần upload ảnh
  bool get _needsImageUpload {
    return widget.featureOperation != 'textToImage';
  }

  @override
  void initState() {
    super.initState();
    
    // Xử lý tính năng đặc biệt không cần upload ảnh
    if (widget.featureOperation == 'textToImage') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => TextToImageUploadScreen()),
        );
      });
      return;
    }
    
    if (widget.featureOperation == 'imageToVideo') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ImageToVideoWidget()),
        );
      });
      return;
    }
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn nguồn ảnh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.photo_library,
                    title: 'Thư viện',
                    onTap: () {
                      Navigator.pop(context);
                      _handleImageSelection(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSourceOption(
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _handleImageSelection(ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.featureGradient.colors.first.withOpacity(0.1),
            border: Border.all(
              color: widget.featureGradient.colors.first.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: widget.featureGradient.colors.first,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.featureGradient.colors.first,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processImage() async {
    if (!_needsImageUpload || _selectedImage != null) {
      HapticFeedback.mediumImpact();
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EditorScreen(
            originalImage: _selectedImage!,
            preSelectedFeature: widget.featureOperation,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh trước khi xử lý'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: widget.featureGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Icon(
                          widget.featureIcon,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.featureTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upload Section (chỉ hiện khi cần upload ảnh)
                        if (_needsImageUpload) ...[
                          const Text(
                            'Upload ảnh',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              width: double.infinity,
                              height: _selectedImage == null ? 200 : 300,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: widget.featureGradient.colors.first.withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                              ),
                              child: _selectedImage == null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: widget.featureGradient,
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                          child: const Icon(
                                            Icons.add_photo_alternate_rounded,
                                            color: Colors.white,
                                            size: 48,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Chạm để chọn ảnh',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: widget.featureGradient.colors.first,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'JPG, PNG, WEBP • Tối đa 10MB',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Stack(
                                        children: [
                                          Image.file(
                                            _selectedImage!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedImage = null;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        // Control Panel (chỉ hiện cho một số tính năng)
                        if (_needsControlPanel) ...[
                          const Text(
                            'Bảng điều khiển',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1e293b),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _buildControlPanelContent(),
                          ),
                          const SizedBox(height: 32),
                        ],
                        
                        // Process Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: widget.featureGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: widget.featureGradient.colors.first.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _processImage,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _needsControlPanel ? 'Tạo' : 'Tạo',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanelContent() {
    switch (widget.featureOperation) {
      case 'cleanup':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high,
                  color: widget.featureGradient.colors.first,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Xóa vật thể',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Sau khi upload ảnh, bạn sẽ có thể vẽ để chọn vật thể cần xóa.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748b),
                height: 1.4,
              ),
            ),
          ],
        );

      default:
        return Container();
    }
  }
}