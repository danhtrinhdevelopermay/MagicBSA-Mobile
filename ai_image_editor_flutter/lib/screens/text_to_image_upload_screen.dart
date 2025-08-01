import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/image_provider.dart';
import '../services/clipdrop_service.dart';

class TextToImageUploadScreen extends StatefulWidget {
  const TextToImageUploadScreen({super.key});

  @override
  State<TextToImageUploadScreen> createState() => _TextToImageUploadScreenState();
}

class _TextToImageUploadScreenState extends State<TextToImageUploadScreen> {
  final TextEditingController _promptController = TextEditingController();
  double _strength = 0.8;
  bool _isGenerating = false;

  final List<String> _samplePrompts = [
    'tropical beach with palm trees and clear blue water',
    'modern office space with plants and natural lighting',
    'cozy living room with fireplace and warm lighting',
    'mountain landscape with snow peaks and green valley',
    'abstract geometric patterns in vibrant colors',
    'cute cartoon cat sitting on a cloud',
    'futuristic city skyline at sunset',
    'beautiful flower garden with butterflies',
  ];

  final LinearGradient _gradient = const LinearGradient(
    colors: [Color(0xFF00d2ff), Color(0xFF3a7bd5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _useSamplePrompt(String prompt) {
    _promptController.text = prompt;
    setState(() {});
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mô tả cho ảnh'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final provider = Provider.of<ImageEditProvider>(context, listen: false);
      
      // Gọi text-to-image API
      await provider.processTextToImage(_promptController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ảnh đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to main screen hoặc hiển thị kết quả
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tạo ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _gradient,
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
                    const Column(
                      children: [
                        Icon(
                          Icons.create,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tạo ảnh từ văn bản',
                          style: TextStyle(
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
                        // Prompt Input Section
                        const Text(
                          'Mô tả ảnh bạn muốn tạo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
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
                          child: TextField(
                            controller: _promptController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Ví dụ: tropical beach with palm trees and clear blue water, sunset lighting, beautiful landscape, high quality, detailed',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(20),
                              hintStyle: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Strength Control
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tune,
                                    color: _gradient.colors.first,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Độ sáng tạo: ${(_strength * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1e293b),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: _gradient.colors.first,
                                  thumbColor: _gradient.colors.first,
                                  overlayColor: _gradient.colors.first.withOpacity(0.2),
                                  inactiveTrackColor: Colors.grey[300],
                                ),
                                child: Slider(
                                  value: _strength,
                                  onChanged: (value) => setState(() => _strength = value),
                                  min: 0.1,
                                  max: 1.0,
                                  divisions: 9,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Cao hơn = sáng tạo hơn, thấp hơn = gần với mô tả hơn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748b),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Sample Prompts
                        const Text(
                          'Gợi ý mô tả',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1e293b),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _samplePrompts.map((prompt) {
                            return GestureDetector(
                              onTap: () => _useSamplePrompt(prompt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _gradient.colors.first.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _gradient.colors.first.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  prompt,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _gradient.colors.first,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Generate Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _gradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _gradient.colors.first.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _isGenerating ? null : _generateImage,
                              child: Center(
                                child: _isGenerating
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Tạo',
                                            style: TextStyle(
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
}