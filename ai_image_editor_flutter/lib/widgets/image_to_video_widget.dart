import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/segmind_api_service.dart';
import '../widgets/video_player_widget.dart';

class ImageToVideoWidget extends StatefulWidget {
  const ImageToVideoWidget({Key? key}) : super(key: key);

  @override
  State<ImageToVideoWidget> createState() => _ImageToVideoWidgetState();
}

class _ImageToVideoWidgetState extends State<ImageToVideoWidget>
    with TickerProviderStateMixin {
  File? _selectedImage;
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController();
  
  String _selectedMode = 'pro';
  int _selectedDuration = 5;
  double _cfgScale = 0.5;
  
  bool _isGenerating = false;
  double _progress = 0.0;
  String? _generatedVideoPath;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  final SegmindApiService _apiService = SegmindApiService();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    // Default prompts
    _promptController.text = 'Gentle camera movement, smooth animation, cinematic lighting';
    _negativePromptController.text = 'No sudden movements, no fast zooms, no abrupt changes';
  }

  @override
  void dispose() {
    _progressController.dispose();
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
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
        _generatedVideoPath = null; // Reset previous result
      });
    }
  }

  Future<void> _generateVideo() async {
    if (_selectedImage == null || _promptController.text.trim().isEmpty) {
      _showErrorSnackBar('Vui lòng chọn ảnh và nhập mô tả');
      return;
    }

    setState(() {
      _isGenerating = true;
      _progress = 0.0;
      _generatedVideoPath = null;
    });

    _progressController.forward();

    try {
      final videoBytes = await _apiService.generateVideoFromImage(
        imageFile: _selectedImage!,
        prompt: _promptController.text.trim(),
        negativePrompt: _negativePromptController.text.trim(),
        cfgScale: _cfgScale,
        mode: _selectedMode,
        duration: _selectedDuration,
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
        _isGenerating = false;
      });

      _progressController.reset();
      _showSuccessSnackBar('Video đã được tạo thành công!');

    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      _progressController.reset();
      
      String errorMessage = 'Không thể tạo video';
      if (e is SegmindApiException) {
        errorMessage = e.message;
      }
      _showErrorSnackBar(errorMessage);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
              Color(0xFFff9a56),
              Color(0xFFff6b95),
              Color(0xFFc471f5),
              Color(0xFFfa71cd),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
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
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    ),
                    Expanded(
                      child: Text(
                        'Tạo video từ ảnh',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Selection
                      _buildImageSection(),
                      SizedBox(height: 20),
                      
                      // Settings
                      _buildSettingsSection(),
                      SizedBox(height: 20),
                      
                      // Prompt Input
                      _buildPromptSection(),
                      SizedBox(height: 20),
                      
                      // Generate Button
                      _buildGenerateButton(),
                      SizedBox(height: 20),
                      
                      // Progress
                      if (_isGenerating) _buildProgressSection(),
                      
                      // Video Result
                      if (_generatedVideoPath != null) _buildVideoResult(),
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

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Chọn ảnh gốc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          if (_selectedImage != null)
            Container(
              margin: EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          
          Container(
            margin: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _pickImage,
              icon: Icon(Icons.photo_library),
              label: Text(_selectedImage == null ? 'Chọn ảnh' : 'Thay đổi ảnh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFff6b95),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài đặt tạo video',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          
          // Mode Selection
          Text('Chế độ tạo:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 8),
          Row(
            children: SegmindApiService.getAvailableModes().map((mode) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: mode != 'pro' ? 8 : 0),
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : () {
                      setState(() {
                        _selectedMode = mode;
                      });
                    },
                    child: Text(
                      mode.toUpperCase(),
                      style: TextStyle(
                        color: _selectedMode == mode ? Colors.white : Color(0xFFff6b95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMode == mode 
                          ? Color(0xFFff6b95) 
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 16),
          
          // Duration Selection
          Text('Thời lượng:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 8),
          Row(
            children: SegmindApiService.getAvailableDurations().map((duration) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: duration != 10 ? 8 : 0),
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : () {
                      setState(() {
                        _selectedDuration = duration;
                      });
                    },
                    child: Text(
                      '${duration}s',
                      style: TextStyle(
                        color: _selectedDuration == duration ? Colors.white : Color(0xFFff6b95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDuration == duration 
                          ? Color(0xFFff6b95) 
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 16),
          
          // CFG Scale
          Text('Độ chính xác (${_cfgScale.toStringAsFixed(1)}):', 
               style: TextStyle(color: Colors.white, fontSize: 16)),
          Slider(
            value: _cfgScale,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            activeColor: Colors.white,
            inactiveColor: Colors.white.withOpacity(0.3),
            onChanged: _isGenerating ? null : (value) {
              setState(() {
                _cfgScale = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả chuyển động',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          
          TextField(
            controller: _promptController,
            enabled: !_isGenerating,
            maxLines: 3,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Mô tả cách ảnh sẽ chuyển động...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          Text(
            'Tránh (không bắt buộc)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          
          TextField(
            controller: _negativePromptController,
            enabled: !_isGenerating,
            maxLines: 2,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Mô tả những gì không muốn xảy ra...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: (_isGenerating || _selectedImage == null) ? null : _generateVideo,
        icon: _isGenerating 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFff6b95)),
                ),
              )
            : Icon(Icons.play_arrow, size: 28),
        label: Text(
          _isGenerating ? 'Đang tạo video...' : 'Tạo video',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFFff6b95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Đang tạo video...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoResult() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 12),
              Text(
                'Video đã hoàn thành',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          VideoPlayerWidget(videoPath: _generatedVideoPath!),
        ],
      ),
    );
  }
}