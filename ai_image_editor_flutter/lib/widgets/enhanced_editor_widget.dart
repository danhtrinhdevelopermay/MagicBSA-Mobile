import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/image_provider.dart';
import '../services/clipdrop_service.dart';
import 'simple_mask_drawing_screen.dart';


enum InputType {
  prompt,
  uncrop,
  scene,
  scale,
  upscaling,
  mask,
}

class Feature {
  final ProcessingOperation operation;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool needsInput;
  final InputType? inputType;

  Feature({
    required this.operation,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.needsInput,
    this.inputType,
  });
}

class FeatureCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<Feature> features;

  FeatureCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.features,
  });
}

class EnhancedEditorWidget extends StatefulWidget {
  final File originalImage;
  final String? preSelectedFeature;

  const EnhancedEditorWidget({
    super.key,
    required this.originalImage,
    this.preSelectedFeature,
  });

  @override
  State<EnhancedEditorWidget> createState() => _EnhancedEditorWidgetState();
}

class _EnhancedEditorWidgetState extends State<EnhancedEditorWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController _promptController = TextEditingController();
  String _selectedScene = 'forest';
  int _extendLeft = 200;
  int _extendRight = 200;
  int _extendUp = 200;
  int _extendDown = 200;
  int _targetWidth = 2048;
  int _targetHeight = 2048;

  final List<String> _scenes = [
    'forest',
    'city',
    'beach',
    'mountain',
    'studio',
    'office',
    'kitchen',
    'bedroom',
  ];

  final List<FeatureCategory> _categories = [
    FeatureCategory(
      title: 'Chỉnh sửa cơ bản',
      icon: Icons.edit,
      color: Colors.blue,
      features: [
        Feature(
          operation: ProcessingOperation.removeBackground,
          title: 'Xóa Background',
          subtitle: 'Loại bỏ nền ảnh tự động',
          icon: Icons.layers_clear,
          needsInput: false,
        ),

        Feature(
          operation: ProcessingOperation.removeText,
          title: 'Xóa văn bản',
          subtitle: 'Loại bỏ chữ viết trên ảnh',
          icon: Icons.text_fields_outlined,
          needsInput: false,
        ),
        Feature(
          operation: ProcessingOperation.cleanup,
          title: 'Dọn dẹp đối tượng',
          subtitle: 'Xóa vật thể không mong muốn',
          icon: Icons.cleaning_services,
          needsInput: true,
          inputType: InputType.mask,
        ),
      ],
    ),
    FeatureCategory(
      title: 'Chỉnh sửa nâng cao',
      icon: Icons.auto_awesome,
      color: Colors.purple,
      features: [
        Feature(
          operation: ProcessingOperation.uncrop,
          title: 'Mở rộng ảnh',
          subtitle: 'Tự động mở rộng khung ảnh',
          icon: Icons.crop_free,
          needsInput: true,
          inputType: InputType.uncrop,
        ),
        Feature(
          operation: ProcessingOperation.reimagine,
          title: 'Tái tạo ảnh',
          subtitle: 'Tạo phiên bản mới với AI',
          icon: Icons.refresh,
          needsInput: false,
        ),
        Feature(
          operation: ProcessingOperation.replaceBackground,
          title: 'Thay thế Background',
          subtitle: 'Thay đổi nền ảnh bằng mô tả',
          icon: Icons.landscape,
          needsInput: true,
          inputType: InputType.prompt,
        ),
        Feature(
          operation: ProcessingOperation.imageUpscaling,
          title: 'Nâng cấp độ phân giải',
          subtitle: 'Tăng chất lượng và kích thước ảnh',
          icon: Icons.high_quality,
          needsInput: true,
          inputType: InputType.upscaling,
        ),
      ],
    ),
    FeatureCategory(
      title: 'Tạo ảnh chuyên nghiệp',
      icon: Icons.camera_alt,
      color: Colors.green,
      features: [
        Feature(
          operation: ProcessingOperation.productPhotography,
          title: 'Chụp sản phẩm',
          subtitle: 'Tạo ảnh sản phẩm chuyên nghiệp',
          icon: Icons.inventory_2,
          needsInput: true,
          inputType: InputType.scene,
        ),
        Feature(
          operation: ProcessingOperation.textToImage,
          title: 'Tạo ảnh từ mô tả',
          subtitle: 'Tạo ảnh mới từ văn bản',
          icon: Icons.image,
          needsInput: true,
          inputType: InputType.prompt,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-execute feature if preselected
    if (widget.preSelectedFeature != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _executePreselectedFeature();
      });
    }
  }

  void _executePreselectedFeature() {
    final featureId = widget.preSelectedFeature!;
    ProcessingOperation? operation;
    
    // Map feature IDs to operations
    switch (featureId) {
      case 'remove_background':
        operation = ProcessingOperation.removeBackground;
        break;
      case 'expand_image':
        operation = ProcessingOperation.uncrop;
        break;
      case 'upscaling':
        operation = ProcessingOperation.imageUpscaling;
        break;
      case 'cleanup':
        operation = ProcessingOperation.cleanup;
        break;
      case 'remove_text':
        operation = ProcessingOperation.removeText;
        break;
      case 'reimagine':
        operation = ProcessingOperation.reimagine;
        break;
      case 'text_to_image':
        operation = ProcessingOperation.textToImage;
        break;
    }

    if (operation != null) {
      final feature = _findFeatureByOperation(operation);
      if (feature != null) {
        _handleFeatureTap(feature);
      }
    }
  }

  Feature? _findFeatureByOperation(ProcessingOperation operation) {
    for (final category in _categories) {
      for (final feature in category.features) {
        if (feature.operation == operation) {
          return feature;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // If there's a preselected feature, show minimal UI
    if (widget.preSelectedFeature != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            _buildImagePreview(),
            const SizedBox(height: 24),
            
            // Processing message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đang xử lý tính năng đã chọn...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview
          _buildImagePreview(),
          const SizedBox(height: 24),
          
          // Feature categories
          const Text(
            'Chọn tính năng chỉnh sửa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1e293b),
            ),
          ),
          const SizedBox(height: 16),
          
          // Fixed height container for PageView
          SizedBox(
            height: 400, // Fixed height instead of Expanded
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _categories.length,
              itemBuilder: (context, index) => _buildCategoryPage(_categories[index]),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Page indicator
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 200,
        minHeight: 120,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          widget.originalImage,
          fit: BoxFit.contain, // Preserve aspect ratio
        ),
      ),
    );
  }

  Widget _buildCategoryPage(FeatureCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              category.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: category.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Features list - Fixed height instead of Expanded
        SizedBox(
          height: 320, // Fixed height for features list
          child: ListView.builder(
            itemCount: category.features.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFeatureCard(category.features[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(Feature feature) {
    return Container(
      height: 80, // Fixed height for consistent spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleFeatureTap(feature),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366f1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  feature.icon,
                  color: const Color(0xFF6366f1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1e293b),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feature.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748b),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF94a3b8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFeatureTap(Feature feature) {
    final provider = context.read<ImageEditProvider>();
    
    if (feature.needsInput) {
      _showInputDialog(feature, provider);
    } else {
      provider.processImage(feature.operation);
    }
  }

  void _showInputDialog(Feature feature, ImageEditProvider provider) {
    switch (feature.inputType) {
      case InputType.prompt:
        _showPromptDialog(feature, provider);
        break;
      case InputType.uncrop:
        _showUncropDialog(feature, provider);
        break;
      case InputType.scene:
        _showSceneDialog(feature, provider);
        break;

      case InputType.upscaling:
        _showUpscalingDialog(feature, provider);
        break;
      case InputType.mask:
        _showMaskDialog(feature, provider);
        break;
      case InputType.scale:
        // Handle scale input type (for future features)
        provider.processImage(feature.operation);
        break;
      case null:
        provider.processImage(feature.operation);
        break;
    }
  }

  void _showPromptDialog(Feature feature, ImageEditProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature.title),
        content: TextField(
          controller: _promptController,
          decoration: const InputDecoration(
            hintText: 'Nhập mô tả ảnh bạn muốn tạo...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.processImage(
                feature.operation,
                prompt: _promptController.text,
              );
            },
            child: const Text('Xử lý'),
          ),
        ],
      ),
    );
  }



  void _showUncropDialog(Feature feature, ImageEditProvider provider) {
    showDialog(
      context: context,  
      builder: (context) => AlertDialog(
        title: Text(feature.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Số pixel để mở rộng theo mỗi hướng (tối đa 2000px):'),
              const SizedBox(height: 16),
              
              // Extend Left
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Trái:')),
                  Expanded(
                    child: Slider(
                      value: _extendLeft.toDouble(),
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      label: '${_extendLeft}px',
                      onChanged: (value) {
                        setState(() {
                          _extendLeft = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              // Extend Right
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Phải:')),
                  Expanded(
                    child: Slider(
                      value: _extendRight.toDouble(),
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      label: '${_extendRight}px',
                      onChanged: (value) {
                        setState(() {
                          _extendRight = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              // Extend Up
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Trên:')),
                  Expanded(
                    child: Slider(
                      value: _extendUp.toDouble(),
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      label: '${_extendUp}px',
                      onChanged: (value) {
                        setState(() {
                          _extendUp = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              // Extend Down
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Dưới:')),
                  Expanded(
                    child: Slider(
                      value: _extendDown.toDouble(),
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      label: '${_extendDown}px',
                      onChanged: (value) {
                        setState(() {
                          _extendDown = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _extendLeft = _extendRight = _extendUp = _extendDown = 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Reset', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _extendLeft = _extendRight = _extendUp = _extendDown = 200;
                      });
                    },
                    child: const Text('200px tất cả'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.processImage(
                feature.operation,
                extendLeft: _extendLeft,
                extendRight: _extendRight,
                extendUp: _extendUp,
                extendDown: _extendDown,
              );
            },
            child: const Text('Xử lý'),
          ),
        ],
      ),
    );
  }

  void _showSceneDialog(Feature feature, ImageEditProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn bối cảnh:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedScene,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _scenes.map((scene) {
                return DropdownMenuItem(
                  value: scene,
                  child: Text(scene),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedScene = value!;
                });
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
              Navigator.pop(context);
              provider.processImage(
                feature.operation,
                scene: _selectedScene,
              );
            },
            child: const Text('Xử lý'),
          ),
        ],
      ),
    );
  }



  void _showUpscalingDialog(Feature feature, ImageEditProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn kích thước đầu ra (1-4096 pixels):'),
              const SizedBox(height: 16),
              
              // Target Width
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Chiều rộng:')),
                  Expanded(
                    child: Slider(
                      value: _targetWidth.toDouble(),
                      min: 1,
                      max: 4096,
                      divisions: 40,
                      label: '${_targetWidth}px',
                      onChanged: (value) {
                        setState(() {
                          _targetWidth = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              // Target Height
              Row(
                children: [
                  const SizedBox(width: 80, child: Text('Chiều cao:')),
                  Expanded(
                    child: Slider(
                      value: _targetHeight.toDouble(),
                      min: 1,
                      max: 4096,
                      divisions: 40,
                      label: '${_targetHeight}px',
                      onChanged: (value) {
                        setState(() {
                          _targetHeight = value.round();
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _targetWidth = 1024;
                          _targetHeight = 1024;
                        });
                      },
                      child: const Text('1024x1024'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _targetWidth = 2048;
                          _targetHeight = 2048;
                        });
                      },
                      child: const Text('2048x2048'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _targetWidth = 4096;
                          _targetHeight = 4096;
                        });
                      },
                      child: const Text('4096x4096'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Text(
                'Lưu ý: Kích thước lớn hơn sẽ tốn nhiều credit hơn và thời gian xử lý lâu hơn.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.processImage(
                feature.operation,
                targetWidth: _targetWidth,
                targetHeight: _targetHeight,
              );
            },
            child: const Text('Nâng cấp'),
          ),
        ],
      ),
    );
  }

  void _showMaskDialog(Feature feature, ImageEditProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn cách tạo mask để xóa vật thể:'),
            const SizedBox(height: 16),
            
            // Option 1: Draw mask
            ListTile(
              leading: const Icon(Icons.brush),
              title: const Text('Vẽ vùng cần xóa'),
              subtitle: const Text('Vẽ trực tiếp trên ảnh'),
              onTap: () {
                Navigator.pop(context);
                _navigateToMaskDrawing(feature, provider);
              },
            ),
            
            const Divider(),
            
            // Option 2: Upload mask image
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Tải mask PNG'),
              subtitle: const Text('Sử dụng ảnh mask có sẵn'),
              onTap: () {
                Navigator.pop(context);
                _uploadMaskFile(feature, provider);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToMaskDrawing(Feature feature, ImageEditProvider provider) async {
    print('Navigating to mask drawing screen...');
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleMaskDrawingScreen(
          originalImage: widget.originalImage,
          operation: feature.operation,
        ),
      ),
    );

    print('Returned from mask drawing screen');
    print('Result is null: ${result == null}');
    if (result != null) {
      print('Result size: ${result.length} bytes');
      // Set processed image in provider
      provider.setProcessedImage(result);
      print('Processed image set in provider');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xử lý thành công! Kéo xuống để xem kết quả.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      print('No result returned from mask drawing screen');
    }
  }

  Future<void> _uploadMaskFile(Feature feature, ImageEditProvider provider) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final maskFile = File(pickedFile.path);
        
        // Validate mask file
        if (!maskFile.path.toLowerCase().endsWith('.png')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng chọn file PNG cho mask'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Process with mask file
        await provider.processImage(
          feature.operation,
          maskFile: maskFile,
          mode: 'fast',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải mask: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _categories.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? const Color(0xFF6366f1)
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}