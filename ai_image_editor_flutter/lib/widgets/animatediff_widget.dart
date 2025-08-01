import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../services/huggingface_animatediff_service.dart';

class AnimateDiffWidget extends StatefulWidget {
  const AnimateDiffWidget({Key? key}) : super(key: key);

  @override
  State<AnimateDiffWidget> createState() => _AnimateDiffWidgetState();
}

class _AnimateDiffWidgetState extends State<AnimateDiffWidget> {
  final HuggingFaceAnimateDiffService _animateDiffService = HuggingFaceAnimateDiffService();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController();
  
  File? _selectedImage;
  File? _generatedVideo;
  VideoPlayerController? _videoController;
  bool _isGenerating = false;
  String _statusMessage = '';
  String? _errorMessage;
  
  // Generation parameters
  int _numFrames = 16;
  double _guidanceScale = 7.5;
  int _numInferenceSteps = 25;
  
  @override
  void initState() {
    super.initState();
    _promptController.text = 'masterpiece, high quality, smooth motion, cinematic lighting, gentle movement, professional video';
    _negativePromptController.text = 'bad quality, worst quality, low resolution, blurry, static, no movement';
  }

  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    _videoController?.dispose();
    _animateDiffService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _generatedVideo = null;
        _errorMessage = null;
      });
      _videoController?.dispose();
      _videoController = null;
    }
  }

  Future<void> _generateVideo() async {
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Vui lòng chọn một ảnh để tạo video';
      });
      return;
    }

    if (_promptController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập prompt mô tả video';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _statusMessage = 'Bắt đầu tạo video...';
    });

    try {
      final result = await _animateDiffService.generateVideoFromImage(
        imageFile: _selectedImage!,
        prompt: _promptController.text.trim(),
        negativePrompt: _negativePromptController.text.trim(),
        numFrames: _numFrames,
        guidanceScale: _guidanceScale,
        numInferenceSteps: _numInferenceSteps,
        onStatusUpdate: (status) {
          setState(() {
            _statusMessage = status;
          });
        },
      );

      if (result['success'] == true) {
        // Save video to temporary file
        final videoData = result['video_data'] as Uint8List;
        final tempDir = await getTemporaryDirectory();
        final videoFile = File('${tempDir.path}/animatediff_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await videoFile.writeAsBytes(videoData);

        // Initialize video player
        _videoController = VideoPlayerController.file(videoFile);
        await _videoController!.initialize();
        _videoController!.setLooping(true);
        _videoController!.play();

        setState(() {
          _generatedVideo = videoFile;
          _statusMessage = 'Video đã được tạo thành công!';
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Lỗi không xác định';
          _statusMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tạo video: ${e.toString()}';
        _statusMessage = '';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Widget _buildParameterSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ${value.toStringAsFixed(1)}${suffix ?? ''}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF6C3EF5),
            inactiveTrackColor: Colors.white24,
            thumbColor: const Color(0xFF6C3EF5),
            overlayColor: const Color(0xFF6C3EF5).withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1a1a),
            const Color(0xFF2d2d2d),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AnimateDiff Pro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Biến ảnh thành video sống động với AI tiên tiến',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Image Selection
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn ảnh đầu vào',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedImage != null ? const Color(0xFF6C3EF5) : Colors.white.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Colors.white54,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Chọn ảnh để tạo video',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Prompt Input
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prompt mô tả',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Mô tả chuyển động và phong cách video...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6C3EF5), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Negative Prompt',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _negativePromptController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Những gì bạn không muốn trong video...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6C3EF5), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Advanced Parameters
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cài đặt nâng cao',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildParameterSlider(
                    title: 'Số khung hình',
                    value: _numFrames.toDouble(),
                    min: 8,
                    max: 24,
                    divisions: 16,
                    onChanged: (value) {
                      setState(() {
                        _numFrames = value.round();
                      });
                    },
                    suffix: ' frames',
                  ),
                  const SizedBox(height: 15),
                  _buildParameterSlider(
                    title: 'Guidance Scale',
                    value: _guidanceScale,
                    min: 1.0,
                    max: 15.0,
                    divisions: 28,
                    onChanged: (value) {
                      setState(() {
                        _guidanceScale = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildParameterSlider(
                    title: 'Inference Steps',
                    value: _numInferenceSteps.toDouble(),
                    min: 10,
                    max: 50,
                    divisions: 40,
                    onChanged: (value) {
                      setState(() {
                        _numInferenceSteps = value.round();
                      });
                    },
                    suffix: ' steps',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Generate Button
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isGenerating 
                      ? [Colors.grey.shade600, Colors.grey.shade700]
                      : [const Color(0xFF6C3EF5), const Color(0xFF9C3EF5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C3EF5).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isGenerating ? null : _generateVideo,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: _isGenerating
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                              Text(
                                'Đang tạo video...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Tạo Video AnimateDiff',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C3EF5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6C3EF5).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Error Message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 15),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Video Result
            if (_generatedVideo != null && _videoController != null)
              Container(
                margin: const EdgeInsets.only(top: 25),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video kết quả',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                              setState(() {});
                            },
                            icon: Icon(
                              _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(
                              _videoController!.value.isPlaying ? 'Tạm dừng' : 'Phát',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C3EF5),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement share functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tính năng chia sẻ sẽ sớm có!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Chia sẻ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}