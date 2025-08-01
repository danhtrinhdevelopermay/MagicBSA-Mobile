import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SegmindApiService {
  static const String _baseUrl = 'https://api.segmind.com/v1';
  static const String _apiKey = 'SG_demo_key_placeholder'; // Demo key, will be replaced with real one
  
  // Using Kling 2.1 model - most cost efficient in 2025
  static const String _modelEndpoint = '/kling-2.1';
  
  final Dio _dio;
  
  SegmindApiService() : _dio = Dio() {
    _dio.options.headers['x-api-key'] = _apiKey;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(minutes: 5);
    _dio.options.receiveTimeout = const Duration(minutes: 10);
  }

  /// Generate video from image using Kling 2.1 model with optimal cost-efficient settings
  Future<Map<String, dynamic>> generateVideoFromImage({
    required File imageFile,
    required String prompt,
    Function(String)? onStatusUpdate,
  }) async {
    try {
      onStatusUpdate?.call('Đang chuẩn bị ảnh...');
      
      // Convert image to base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      onStatusUpdate?.call('Đang gửi yêu cầu tạo video đến Segmind...');
      
      // Optimal cost-efficient settings based on Segmind documentation
      final requestData = {
        'image': base64Image,
        'prompt': prompt,
        'negative_prompt': 'blur, distortion, artifacts, sudden movements, low quality',
        'cfg_scale': 0.5, // Lower CFG = faster processing = lower cost
        'mode': 'standard', // 720p instead of pro (1080p) for cost efficiency
        'duration': 5, // 5 seconds instead of 10 for 50% cost reduction
      };

      final response = await _dio.post(
        '$_baseUrl$_modelEndpoint',
        data: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        onStatusUpdate?.call('Video đã được tạo thành công!');
        
        // The response should contain the video URL or base64 data
        final responseData = response.data;
        
        if (responseData['video'] != null) {
          // If video is returned as base64
          if (responseData['video'] is String && responseData['video'].startsWith('data:')) {
            final base64Video = responseData['video'].split(',')[1];
            final videoBytes = base64Decode(base64Video);
            
            return {
              'success': true,
              'video_data': videoBytes,
              'message': 'Video tạo thành công với chất lượng 720p (5 giây)',
              'metadata': {
                'model': 'Kling 2.1',
                'resolution': '720p',
                'duration': '5 seconds',
                'mode': 'standard',
                'cfg_scale': 0.5,
              }
            };
          } else if (responseData['video'] is String) {
            // If video is returned as URL, download it
            final videoUrl = responseData['video'];
            final videoResponse = await _dio.get(
              videoUrl,
              options: Options(responseType: ResponseType.bytes),
            );
            
            return {
              'success': true,
              'video_data': videoResponse.data as Uint8List,
              'message': 'Video tạo thành công với chất lượng 720p (5 giây)',
              'metadata': {
                'model': 'Kling 2.1',
                'resolution': '720p',
                'duration': '5 seconds',
                'mode': 'standard',
                'cfg_scale': 0.5,
              }
            };
          }
        }
        
        // For demo purposes with placeholder API key
        return {
          'success': false,
          'error': 'Demo API Key',
          'message': 'Cần API key thật từ Segmind để tạo video. Chi phí: ~\$0.10-0.30/video (tiết kiệm 50% với cài đặt tối ưu).'
        };
        
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.statusMessage}',
          'message': 'Không thể tạo video từ Segmind API'
        };
      }
      
    } on DioException catch (e) {
      String errorMessage = 'Cần API key Segmind để tạo video';
      
      if (e.response != null) {
        try {
          final errorData = e.response?.data;
          if (errorData is String) {
            final errorJson = jsonDecode(errorData);
            errorMessage = errorJson['error'] ?? 'Lỗi từ Segmind API';
          } else if (errorData is Map) {
            errorMessage = errorData['error'] ?? 'Lỗi từ Segmind API';
          }
        } catch (_) {
          errorMessage = 'HTTP ${e.response?.statusCode}: ${e.response?.statusMessage}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Hết thời gian kết nối. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Hết thời gian chờ phản hồi. Video đang được xử lý.';
      }
      
      return {
        'success': false,
        'error': errorMessage,
        'message': 'Cần cấu hình API key Segmind để sử dụng tính năng này. Chi phí ~\$0.10-0.30/video.'
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Cần API key Segmind để tạo video'
      };
    }
  }

  /// Check Segmind API status
  Future<Map<String, dynamic>> checkApiStatus() async {
    try {
      // Try a simple request to check API availability
      final response = await _dio.get('$_baseUrl/health');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': 'ready',
          'message': 'Segmind API sẵn sàng sử dụng'
        };
      } else {
        return {
          'success': false,
          'status': 'error',
          'message': 'Cần API key Segmind để sử dụng'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'status': 'error',
        'message': 'Cần cấu hình API key Segmind'
      };
    }
  }

  /// Get cost-efficient recommended prompts for video generation
  static List<String> getOptimalPrompts() {
    return [
      'Gentle floating motion in clean environment, soft lighting, smooth transitions',
      'Subtle rotation with elegant movement, professional lighting, minimal motion blur',
      'Smooth camera pan across the scene, natural lighting, steady movement',
      'Product showcase with gentle spinning motion, studio lighting, clean background',
      'Natural swaying motion like gentle breeze, soft shadows, smooth animation',
      'Elegant zoom-in movement with cinematic lighting, professional quality',
      'Gentle water ripples or fabric movement, natural lighting, smooth flow',
      'Subtle breathing or pulsing effect, soft glow, minimal but engaging motion',
    ];
  }

  /// Get recommended negative prompts for better quality
  static List<String> getOptimalNegativePrompts() {
    return [
      'blur, distortion, artifacts, sudden movements, low quality',
      'fast zooms, jerky motion, poor lighting, noise, pixelated',
      'abrupt changes, static frames, frozen motion, unnatural movement',
      'overexposed, underexposed, harsh shadows, artificial lighting',
      'repetitive loops, mechanical motion, robotic movement, choppy animation',
    ];
  }

  /// Get cost information and optimal settings
  static Map<String, dynamic> getCostOptimizedSettings() {
    return {
      'model': 'Kling 2.1',
      'resolution': '720p (Standard)',
      'duration': '5 seconds',
      'cfg_scale': 0.5,
      'estimated_cost': '\$0.10-0.30 per video',
      'processing_time': '2-4 minutes',
      'advantages': [
        '5x cheaper than Google Veo 3',
        '50% cost reduction vs 10-second videos',
        'High quality 720p output',
        'Fast processing with optimized settings',
        'Reliable Kling 2.1 model (latest version)',
      ],
      'technical_specs': {
        'input_resolution': 'Up to 2048x2048px',
        'output_format': 'MP4',
        'frame_rate': '24fps',
        'aspect_ratios': 'Dynamic (any ratio supported)',
        'max_file_size': '50MB output',
      }
    };
  }

  void dispose() {
    _dio.close();
  }
}