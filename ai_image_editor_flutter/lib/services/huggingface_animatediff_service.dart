import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class HuggingFaceAnimateDiffService {
  static const String _baseUrl = 'https://api-inference.huggingface.co';
  static const String _apiKey = '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';
  static const String _modelEndpoint = '/models/guoyww/animatediff-motion-adapter-v1-5-2';
  
  final Dio _dio;
  
  HuggingFaceAnimateDiffService() : _dio = Dio() {
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    _dio.options.connectTimeout = const Duration(minutes: 5);
    _dio.options.receiveTimeout = const Duration(minutes: 10);
  }

  /// Generate video from image using AnimateDiff
  Future<Map<String, dynamic>> generateVideoFromImage({
    required File imageFile,
    required String prompt,
    String? negativePrompt,
    int numFrames = 16,
    double guidanceScale = 7.5,
    int numInferenceSteps = 25,
    int? seed,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call('Đang chuẩn bị ảnh và prompt...');
      
      // Read image file as bytes
      final imageBytes = await imageFile.readAsBytes();
      
      // Prepare request payload
      final formData = FormData.fromMap({
        'inputs': prompt,
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'input_image.jpg',
        ),
        'parameters': jsonEncode({
          'negative_prompt': negativePrompt ?? 'bad quality, worst quality, low resolution, blurry',
          'num_frames': numFrames,
          'guidance_scale': guidanceScale,
          'num_inference_steps': numInferenceSteps,
          'seed': seed ?? DateTime.now().millisecondsSinceEpoch,
        }),
      });

      onStatusUpdate?.call('Đang gửi yêu cầu tạo video đến Hugging Face...');
      
      // Make API request
      final response = await _dio.post(
        '$_baseUrl$_modelEndpoint',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        onStatusUpdate?.call('Video đã được tạo thành công!');
        
        return {
          'success': true,
          'video_data': response.data as Uint8List,
          'message': 'Video tạo thành công với ${numFrames} khung hình',
          'metadata': {
            'prompt': prompt,
            'negative_prompt': negativePrompt,
            'num_frames': numFrames,
            'guidance_scale': guidanceScale,
            'num_inference_steps': numInferenceSteps,
            'seed': seed,
          }
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.statusMessage}',
          'message': 'Lỗi từ server Hugging Face'
        };
      }
      
    } on DioException catch (e) {
      String errorMessage = 'Lỗi kết nối mạng';
      
      if (e.response != null) {
        try {
          final errorData = e.response?.data;
          if (errorData is String) {
            final errorJson = jsonDecode(errorData);
            errorMessage = errorJson['error'] ?? 'Lỗi không xác định từ API';
          } else if (errorData is Map) {
            errorMessage = errorData['error'] ?? 'Lỗi không xác định từ API';
          }
        } catch (_) {
          errorMessage = 'HTTP ${e.response?.statusCode}: ${e.response?.statusMessage}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Hết thời gian kết nối. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Hết thời gian chờ phản hồi. Video có thể mất nhiều thời gian để tạo.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'message': 'Không thể tạo video. Vui lòng thử lại sau.'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Lỗi không mong muốn xảy ra'
      };
    }
  }

  /// Check model status
  Future<Map<String, dynamic>> checkModelStatus() async {
    try {
      final response = await _dio.get('$_baseUrl$_modelEndpoint');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': 'ready',
          'message': 'Model AnimateDiff sẵn sàng sử dụng'
        };
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': 'Model không khả dụng'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'error',
        'message': 'Không thể kiểm tra trạng thái model'
      };
    }
  }

  /// Get recommended prompts for better video generation
  static List<String> getRecommendedPrompts() {
    return [
      'masterpiece, high quality, smooth motion, cinematic lighting',
      'beautiful landscape, gentle wind, flowing water, serene atmosphere',
      'portrait, subtle facial expressions, natural lighting, professional photography',
      'abstract art, fluid motion, colorful gradients, artistic style',
      'nature scene, swaying trees, moving clouds, peaceful environment',
      'urban cityscape, bustling street, dynamic movement, modern architecture',
      'fantasy world, magical elements, ethereal glow, mystical atmosphere',
      'underwater scene, floating bubbles, gentle currents, aquatic life',
    ];
  }

  /// Get recommended negative prompts
  static List<String> getRecommendedNegativePrompts() {
    return [
      'bad quality, worst quality, low resolution, blurry, distorted',
      'static, no movement, frozen, still image, lifeless',
      'jumpy motion, erratic movement, inconsistent frames',
      'oversaturated, underexposed, poor lighting, noise',
      'cartoon, anime, unrealistic, artificial, fake',
    ];
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}