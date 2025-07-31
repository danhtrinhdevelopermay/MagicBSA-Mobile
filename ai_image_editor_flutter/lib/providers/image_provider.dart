import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/clipdrop_service.dart';
import '../services/history_service.dart';
import '../models/history_item.dart';

enum ProcessingState {
  idle,
  picking,
  processing,
  completed,
  error,
}

class ImageEditProvider extends ChangeNotifier {
  final ClipDropService _clipDropService = ClipDropService();
  final ImagePicker _picker = ImagePicker();
  
  File? _originalImage;
  Uint8List? _processedImage;
  ProcessingState _state = ProcessingState.idle;
  String _errorMessage = '';
  String? _currentOperation;
  double _progress = 0.0;
  ProcessingOperation? _lastCompletedOperation; // Track last operation for auto-scroll control
  
  // Callback function for when image is picked successfully
  Function(File)? _onImagePicked;

  // Getters
  File? get originalImage => _originalImage;
  Uint8List? get processedImage => _processedImage;
  ProcessingState get state => _state;
  String get errorMessage => _errorMessage;
  String? get currentOperation => _currentOperation;
  double get progress => _progress;
  ProcessingOperation? get lastCompletedOperation => _lastCompletedOperation;
  
  // Set callback for image picked
  void setOnImagePickedCallback(Function(File)? callback) {
    _onImagePicked = callback;
  }

  // Pick image from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    try {
      _setState(ProcessingState.picking);
      
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,  
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _originalImage = File(pickedFile.path);
        _processedImage = null;
        _setState(ProcessingState.idle);
        
        // Call the callback if it's set
        if (_onImagePicked != null) {
          _onImagePicked!(_originalImage!);
        }
      } else {
        _setState(ProcessingState.idle);
      }
    } catch (e) {
      _setError('Lỗi khi chọn ảnh: $e');
    }
  }

  // Process image with specific operation
  Future<void> processImage(
    ProcessingOperation operation, {
    File? maskFile,
    File? backgroundFile,
    String? prompt,
    String? scene,
    int? extendLeft,
    int? extendRight,
    int? extendUp,
    int? extendDown,
    int? seed,
    int? targetWidth,
    int? targetHeight,
    String? mode,
  }) async {
    if (_originalImage == null && operation != ProcessingOperation.textToImage) return;
    
    try {
      String operationText;
      switch (operation) {
        case ProcessingOperation.removeBackground:
          operationText = 'Đang xóa background...';
          break;
        case ProcessingOperation.removeText:
          operationText = 'Đang xóa văn bản...';
          break;
        case ProcessingOperation.cleanup:
          operationText = 'Đang dọn dẹp đối tượng...';
          break;
        case ProcessingOperation.uncrop:
          operationText = 'Đang mở rộng ảnh...';
          break;
        case ProcessingOperation.reimagine:
          operationText = 'Đang tái tưởng tượng ảnh...';
          break;
        case ProcessingOperation.productPhotography:
          operationText = 'Đang tạo ảnh sản phẩm...';
          break;
        case ProcessingOperation.textToImage:
          operationText = 'Đang tạo ảnh từ văn bản...';
          break;
        case ProcessingOperation.replaceBackground:
          operationText = 'Đang thay thế background...';
          break;
        case ProcessingOperation.imageUpscaling:
          operationText = 'Đang nâng cấp độ phân giải...';
          break;
      }
      
      _currentOperation = operationText;
      _setState(ProcessingState.processing);
      _startProgressAnimation();

      Uint8List result;
      if (operation == ProcessingOperation.textToImage) {
        // For text-to-image, use the dedicated method with just the prompt
        result = await _clipDropService.generateImageFromText(prompt!);
      } else {
        result = await _clipDropService.processImage(
          _originalImage!, 
          operation, 
          maskFile: maskFile,
          backgroundFile: backgroundFile,
          prompt: prompt,
          scene: scene,
          extendLeft: extendLeft,
          extendRight: extendRight,
          extendUp: extendUp,
          extendDown: extendDown,
          seed: seed,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
          mode: mode,
        );
      }
      
      _processedImage = result;
      _lastCompletedOperation = operation; // Track completed operation for auto-scroll control
      _currentOperation = null; // Clear current operation when completed
      _setState(ProcessingState.completed);
      _progress = 1.0;
      
      // Save to history after successful processing
      await _saveToHistory(operation, operationText);
    } catch (e) {
      _setError('Lỗi khi xử lý ảnh: $e');
    }
  }

  // Convenience methods for backward compatibility
  Future<void> removeBackground() async {
    await processImage(ProcessingOperation.removeBackground);
  }

  Future<void> removeText() async {
    await processImage(ProcessingOperation.removeText);
  }





  // New ClipDrop API methods
  Future<void> uncrop({
    int? extendLeft,
    int? extendRight,
    int? extendUp,
    int? extendDown,
    int? seed,
  }) async {
    await processImage(
      ProcessingOperation.uncrop,
      extendLeft: extendLeft,
      extendRight: extendRight,
      extendUp: extendUp,
      extendDown: extendDown,
      seed: seed,
    );
  }

  Future<void> reimagine() async {
    await processImage(ProcessingOperation.reimagine);
  }

  Future<void> replaceBackground({File? backgroundFile, String? prompt}) async {
    await processImage(
      ProcessingOperation.replaceBackground,
      backgroundFile: backgroundFile,
      prompt: prompt,
    );
  }

  Future<void> productPhotography({String? scene}) async {
    await processImage(
      ProcessingOperation.productPhotography,
      scene: scene,
    );
  }

  Future<void> generateFromText(String prompt) async {
    try {
      _currentOperation = 'Đang tạo ảnh từ văn bản...';
      _setState(ProcessingState.processing);
      _startProgressAnimation();

      final result = await _clipDropService.generateImageFromText(prompt);
      
      _processedImage = result;
      _setState(ProcessingState.completed);
      _progress = 1.0;
    } catch (e) {
      _setError('Lỗi khi tạo ảnh từ văn bản: $e');
    }
  }

  // Clear processed image
  void clearProcessedImage() {
    _processedImage = null;
    _setState(ProcessingState.idle);
  }

  // Set processed image (for external processing results - used by object removal)
  void setProcessedImage(Uint8List imageData) {
    print('Setting processed image in provider...');
    print('Image data size: ${imageData.length} bytes');
    _processedImage = imageData;
    _lastCompletedOperation = ProcessingOperation.cleanup; // Mark as cleanup operation
    _currentOperation = null; // Clear current operation
    _progress = 1.0; // Set progress to complete
    _setState(ProcessingState.completed);
    print('Provider state updated to completed');
    
    // Save to history after setting processed image
    if (_originalImage != null) {
      _saveToHistory(ProcessingOperation.cleanup, 'Dọn dẹp đối tượng');
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = '';
    _currentOperation = null;
    _setState(ProcessingState.idle);
  }

  // Reset all data - complete reset
  void reset() {
    _originalImage = null;
    _processedImage = null;
    _errorMessage = '';
    _currentOperation = null;
    _lastCompletedOperation = null;
    _progress = 0.0;
    _setState(ProcessingState.idle);
  }

  void _setState(ProcessingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _currentOperation = null; // Clear current operation when error occurs
    _setState(ProcessingState.error);
  }

  void _startProgressAnimation() {
    _progress = 0.0;
    // Simulate progress animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_state == ProcessingState.processing) {
        _progress = 0.3;
        notifyListeners();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_state == ProcessingState.processing) {
        _progress = 0.6;
        notifyListeners();
      }
    });
    
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_state == ProcessingState.processing) {
        _progress = 0.9;
        notifyListeners();
      }
    });
  }

  /// Save processed image to history
  Future<void> _saveToHistory(ProcessingOperation operation, String operationText) async {
    if (_processedImage == null) return;
    
    try {
      // Get operation name for display
      String operationName = _getOperationDisplayName(operation);
      
      // Create history item
      HistoryItem historyItem = HistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: operationName,
        operation: operation.toString().split('.').last,
        createdAt: DateTime.now(),
        originalImagePath: _originalImage?.path,
        originalImageData: _originalImage != null ? await _originalImage!.readAsBytes() : null,
        processedImageData: _processedImage!,
        processingTime: 3.2, // Mock processing time
        qualityScore: 98, // Mock quality score
      );
      
      // Save to history service
      await HistoryService.addHistoryItem(historyItem);
      
    } catch (e) {
      print('Error saving to history: $e');
      // Don't show error to user, just log it
    }
  }

  /// Get display name for operation
  String _getOperationDisplayName(ProcessingOperation operation) {
    switch (operation) {
      case ProcessingOperation.removeBackground:
        return 'Xóa background';
      case ProcessingOperation.removeText:
        return 'Xóa text';
      case ProcessingOperation.uncrop:
        return 'Mở rộng ảnh';
      case ProcessingOperation.reimagine:
        return 'Tái tạo ảnh';
      case ProcessingOperation.textToImage:
        return 'Tạo ảnh từ text';
      case ProcessingOperation.cleanup:
        return 'Dọn dẹp đối tượng';
      case ProcessingOperation.replaceBackground:
        return 'Thay background';
      case ProcessingOperation.productPhotography:
        return 'Chụp sản phẩm';
      case ProcessingOperation.imageUpscaling:
        return 'Nâng cấp độ phân giải';
      default:
        return 'Xử lý ảnh';
    }
  }
}