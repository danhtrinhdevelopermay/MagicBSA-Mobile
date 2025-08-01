import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';
import '../screens/editor_screen.dart';
import '../widgets/text_to_image_widget.dart';
import '../services/segmind_api_service.dart';
import '../services/onesignal_service.dart';
import '../widgets/video_player_widget.dart';
import 'package:path_provider/path_provider.dart';

class FeatureUploadScreen extends StatefulWidget {
  final String operation;
  final String title;
  final String description;
  final LinearGradient gradient;

  const FeatureUploadScreen({
    Key? key,
    required this.operation,
    required this.title,
    required this.description,
    required this.gradient,
  }) : super(key: key);

  @override
  State<FeatureUploadScreen> createState() => _FeatureUploadScreenState();
}

class _FeatureUploadScreenState extends State<FeatureUploadScreen> {
  File? _selectedImage;
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController();
  final TextEditingController _objectDescriptionController = TextEditingController();
  
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _generatedVideoPath;
  
  final SegmindApiService _apiService = SegmindApiService();

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
  }

  void _initializeDefaultValues() {
    switch (widget.operation) {
      case 'imageToVideo':
        _promptController.text = 'Smooth camera movement with cinematic lighting, gentle transitions, realistic motion';
        _negativePromptController.text = 'No sudden movements, no fast zooms, low quality, distorted';
        break;
      case 'textToImage':
        _promptController.text = '';
        _negativePromptController.text = 'low quality, blurry, distorted, ugly';
        break;
      case 'cleanup':
        _objectDescriptionController.text = '';
        break;
    }
  }

  bool _needsParameters() {
    return ['cleanup', 'textToImage', 'imageToVideo'].contains(widget.operation);
  }

  bool _needsImageUpload() {
    return widget.operation != 'textToImage';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _processImage() async {
    if (_needsImageUpload() && _selectedImage == null) {
      _showErrorSnackBar('Vui lòng chọn ảnh trước');
      return;
    }

    // Validate required parameters
    if (widget.operation == 'textToImage' && _promptController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập mô tả ảnh');
      return;
    }

    if (widget.operation == 'imageToVideo' && _promptController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng nhập mô tả chuyển động');
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.0;
    });

    // Show processing notification
    _showProcessingNotification();

    try {
      switch (widget.operation) {
        case 'imageToVideo':
          await _generateVideo();
          break;
        case 'textToImage':
          await _generateTextToImage();
          break;
        case 'cleanup':
          await _processCleanup();
          break;
        default:
          await _processSimpleFeature();
          break;
      }

      // Show completion notification and popup
      _showCompletionNotification();
      _showCompletionPopup();

    } catch (e) {
      _showErrorSnackBar('Lỗi xử lý: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _generateVideo() async {
    final videoBytes = await _apiService.generateVideoFromImage(
      imageFile: _selectedImage!,
      prompt: _promptController.text.trim(),
      negativePrompt: _negativePromptController.text.trim(),
      cfgScale: 0.5, // Optimal resource-efficient setting
      mode: 'std', // Standard mode for efficiency
      duration: 5, // 5 seconds for cost efficiency
      onProgress: (progress) {
        setState(() {
          _progress = progress;
        });
      },
    );

    // Save video to temporary directory
    final tempDir = await getTemporaryDirectory();
    final videoFile = File('${tempDir.path}/generated_video_${DateTime.now().millisecondsSinceEpoch}.mp4');
    await videoFile.writeAsBytes(videoBytes);

    setState(() {
      _generatedVideoPath = videoFile.path;
    });
  }

  Future<void> _generateTextToImage() async {
    // Implement text to image generation
    // This would call the appropriate API service
    await Future.delayed(Duration(seconds: 3)); // Simulate processing
  }

  Future<void> _processCleanup() async {
    // Implement cleanup with object description
    final provider = Provider.of<ImageEditProvider>(context, listen: false);
    
    // Navigate to editor with cleanup operation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          originalImage: _selectedImage!,
          preSelectedFeature: 'cleanup',
        ),
      ),
    );
  }

  Future<void> _processSimpleFeature() async {
    final provider = Provider.of<ImageEditProvider>(context, listen: false);
    
    // Navigate to editor for simple features
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          originalImage: _selectedImage!,
          preSelectedFeature: widget.operation,
        ),
      ),
    );
  }

  void _showProcessingNotification() {
    // Show local snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Ảnh của bạn đang được xử lý...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    // Send push notification for processing
    _sendPushNotification(
      title: '🎨 AI đang xử lý',
      message: 'Ảnh của bạn đang được xử lý bằng AI. Vui lòng chờ trong giây lát...',
    );
  }

  void _showCompletionNotification() {
    // Show local snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Đã xử lý xong!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Send push notification for completion
    _sendPushNotification(
      title: '✅ Hoàn thành!',
      message: 'Sản phẩm AI của bạn đã sẵn sàng! Xem ngay ở trang Lịch sử.',
    );
  }

  // Helper method to send push notifications
  void _sendPushNotification({required String title, required String message}) {
    try {
      // You can use OneSignal's local notification or external API here
      // For now, we'll just log it since OneSignal setup may vary
      print('📱 Push Notification - $title: $message');
    } catch (e) {
      print('❌ Failed to send push notification: $e');
    }
  }

  void _showCompletionPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Hoàn thành!'),
            ],
          ),
          content: Text(
            'Sản phẩm đã được xử lý thành công.\nBạn có thể xem kết quả ở trang Lịch sử.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to main screen and switch to history tab
                Navigator.of(context).popUntil((route) => route.isFirst);
                // The main screen should handle tab switching to history
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Xem Lịch sử'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: widget.gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: _isProcessing ? _buildProcessingView() : _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.arrow_back,
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
            widget.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.gradient.colors.first.withOpacity(0.1),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: _progress > 0 ? _progress : null,
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(widget.gradient.colors.first),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Đang xử lý...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Vui lòng chờ trong giây lát',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          if (_progress > 0)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: widget.gradient.colors.first,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Upload Section (if needed)
          if (_needsImageUpload()) ...[
            _buildImageUploadSection(),
            SizedBox(height: 24),
          ],
          
          // Parameters Section (if needed)
          if (_needsParameters()) ...[
            _buildParametersSection(),
            SizedBox(height: 24),
          ],
          
          // Generate Button
          _buildGenerateButton(),
          
          // Result Section
          if (_generatedVideoPath != null) ...[
            SizedBox(height: 24),
            _buildResultSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn ảnh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        
        if (_selectedImage == null) ...[
          // Upload options
          Row(
            children: [
              Expanded(
                child: _buildUploadOption(
                  icon: Icons.photo_library,
                  label: 'Thư viện',
                  onTap: _pickImage,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildUploadOption(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  onTap: _takePhoto,
                ),
              ),
            ],
          ),
        ] else ...[
          // Selected image preview
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 2,
          ),
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: widget.gradient.colors.first,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cài đặt',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        
        if (widget.operation == 'textToImage') ...[
          _buildTextField(
            controller: _promptController,
            label: 'Mô tả ảnh muốn tạo',
            hintText: 'Ví dụ: tropical beach with palm trees...',
            maxLines: 3,
          ),
        ],
        
        if (widget.operation == 'imageToVideo') ...[
          _buildTextField(
            controller: _promptController,
            label: 'Mô tả chuyển động',
            hintText: 'Ví dụ: gentle camera movement, cinematic...',
            maxLines: 2,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _negativePromptController,
            label: 'Những gì không muốn',
            hintText: 'Ví dụ: sudden movements, distortion...',
            maxLines: 2,
          ),
        ],
        
        if (widget.operation == 'cleanup') ...[
          _buildTextField(
            controller: _objectDescriptionController,
            label: 'Mô tả vật thể cần xóa',
            hintText: 'Ví dụ: người phía sau, xe hơi, logo...',
            maxLines: 1,
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.gradient.colors.first),
            ),
            contentPadding: EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    bool canGenerate = true;
    
    if (_needsImageUpload() && _selectedImage == null) {
      canGenerate = false;
    }
    
    if (widget.operation == 'textToImage' && _promptController.text.trim().isEmpty) {
      canGenerate = false;
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: canGenerate ? widget.gradient : LinearGradient(
          colors: [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: canGenerate ? [
          BoxShadow(
            color: widget.gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: canGenerate ? _processImage : null,
          child: Center(
            child: Text(
              'Tạo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết quả',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        if (_generatedVideoPath != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: VideoPlayerWidget(videoPath: _generatedVideoPath!),
            ),
          ),
      ],
    );
  }
}