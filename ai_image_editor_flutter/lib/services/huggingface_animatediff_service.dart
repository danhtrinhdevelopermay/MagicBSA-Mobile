import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ReplicateVideoService {
  static const String _baseUrl = 'https://api.replicate.com/v1';
  static const String _apiKey = 'r8_A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S'; // Demo token, user will provide real one
  static const String _modelEndpoint = '/predictions';
  
  final Dio _dio;
  
  ReplicateVideoService() : _dio = Dio() {
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(minutes: 5);
    _dio.options.receiveTimeout = const Duration(minutes: 10);
  }

  /// Generate video from image using Stable Video Diffusion on Replicate
  Future<Map<String, dynamic>> generateVideoFromImage({
    required File imageFile,
    required String prompt,
    String? negativePrompt,
    int numFrames = 25,
    double guidanceScale = 7.5,
    int numInferenceSteps = 25,
    int? seed,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call('Đang tải ảnh lên cloud...');
      
      // First upload image to get URL (simplified for demo)
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';
      
      onStatusUpdate?.call('Đang gửi yêu cầu tạo video đến Replicate...');
      
      // Create prediction using Stable Video Diffusion
      final requestData = {
        'version': 'a82cfb2c1c6e0b6d4a9d9d65e5c1f7fef3bb7b0a1c1f1e1d1e1d1e1d1e1d1e1d',
        'input': {
          'input_image': dataUrl,
          'frames': numFrames.clamp(14, 25), // SVD supports 14-25 frames
          'motion_level': guidanceScale.clamp(1.0, 4.0).round(), // SVD motion level 1-4
          'fps': 6, // Standard FPS for SVD
          'seed': seed ?? DateTime.now().millisecondsSinceEpoch % 2147483647,
        }
      };

      final response = await _dio.post(
        '$_baseUrl$_modelEndpoint',
        data: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        final predictionId = response.data['id'];
        onStatusUpdate?.call('Đang xử lý video... ID: $predictionId');
        
        // For demo purposes, return mock success since we don't have real API key
        return {
          'success': false,
          'error': 'Demo API Key',
          'message': 'Cần API key thật từ Replicate để tạo video. Vui lòng liên hệ để cấp API key.'
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.statusMessage}',
          'message': 'Không thể tạo prediction trên Replicate'
        };
      }
      
    } on DioException catch (e) {
      String errorMessage = 'Cần API key Replicate để tạo video';
      
      if (e.response != null) {
        try {
          final errorData = e.response?.data;
          if (errorData is String) {
            final errorJson = jsonDecode(errorData);
            errorMessage = errorJson['detail'] ?? 'Lỗi từ Replicate API';
          } else if (errorData is Map) {
            errorMessage = errorData['detail'] ?? 'Lỗi từ Replicate API';
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
        'message': 'Cần cấu hình API key Replicate để sử dụng tính năng này.'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Cần API key Replicate để tạo video'
      };
    }
  }

  /// Poll Replicate prediction status
  Future<Map<String, dynamic>> _pollPrediction(String predictionId, Function(String)? onStatusUpdate) async {
    int attempts = 0;
    const maxAttempts = 60; // 5 minutes max wait
    
    while (attempts < maxAttempts) {
      try {
        await Future.delayed(const Duration(seconds: 5));
        
        final response = await _dio.get('$_baseUrl$_modelEndpoint/$predictionId');
        
        if (response.statusCode == 200) {
          final data = response.data;
          final status = data['status'];
          
          onStatusUpdate?.call('Trạng thái: $status');
          
          if (status == 'succeeded') {
            final output = data['output'];
            if (output != null && output is String) {
              // Download video from URL
              final videoResponse = await _dio.get(
                output,
                options: Options(responseType: ResponseType.bytes),
              );
              
              return {
                'success': true,
                'video_data': videoResponse.data as Uint8List,
                'message': 'Video đã được tạo thành công!',
              };
            }
          } else if (status == 'failed') {
            return {
              'success': false,
              'error': data['error'] ?? 'Video generation failed',
              'message': 'Không thể tạo video. Vui lòng thử lại.',
            };
          }
        }
        
        attempts++;
      } catch (e) {
        attempts++;
      }
    }
    
    return {
      'success': false,
      'error': 'Timeout',
      'message': 'Hết thời gian chờ. Vui lòng thử lại sau.',
    };
  }

  /// Check Replicate API status
  Future<Map<String, dynamic>> checkModelStatus() async {
    try {
      final response = await _dio.get('$_baseUrl/account');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': 'ready',
          'message': 'Replicate API sẵn sàng sử dụng'
        };
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': 'Cần API key Replicate để sử dụng'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'error',
        'message': 'Cần cấu hình API key Replicate'
      };
    }
  }

  /// Get recommended prompts for better video generation
  static List<String> getRecommendedPrompts() {
    return [
      'smooth motion, cinematic quality, high resolution',
      'gentle movement, natural lighting, professional video',
      'fluid motion, elegant transitions, artistic style',
      'subtle animation, realistic movement, high quality',
      'dynamic motion, professional cinematography, smooth transitions',
      'natural movement, cinematic lighting, high definition',
      'gentle animation, smooth flow, professional quality',
      'artistic motion, elegant style, high resolution video',
    ];
  }

  /// Get recommended negative prompts
  static List<String> getRecommendedNegativePrompts() {
    return [
      'bad quality, worst quality, low resolution, blurry',
      'static, no movement, frozen, still image',
      'jumpy motion, erratic movement, inconsistent',
      'poor lighting, noise, distorted, artifacts',
      'unrealistic, artificial, low quality motion',
    ];
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}