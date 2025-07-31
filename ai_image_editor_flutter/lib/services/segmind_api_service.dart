import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SegmindApiService {
  static const String _baseUrl = 'https://api.segmind.com/v1';
  static const String _apiKey = 'SG_16234ffb7d84cf3d';
  
  final Dio _dio = Dio();

  SegmindApiService() {
    _dio.options.headers['x-api-key'] = _apiKey;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.receiveTimeout = const Duration(minutes: 10); // Video generation takes time
    _dio.options.sendTimeout = const Duration(minutes: 5);
  }

  /// Convert image file to base64 string
  String _imageFileToBase64(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    return base64Encode(bytes);
  }

  /// Generate video from image using Kling AI
  Future<Uint8List> generateVideoFromImage({
    required File imageFile,
    required String prompt,
    String? negativePrompt,
    double cfgScale = 0.5,
    String mode = 'pro', // 'std' or 'pro'
    int duration = 5, // 5 or 10 seconds
    Function(double)? onProgress,
  }) async {
    try {
      final imageBase64 = _imageFileToBase64(imageFile);
      
      final data = {
        'image': imageBase64,
        'prompt': prompt,
        'negative_prompt': negativePrompt ?? 'No sudden movements, no fast zooms.',
        'cfg_scale': cfgScale,
        'mode': mode,
        'duration': duration,
      };

      if (onProgress != null) {
        onProgress(0.1); // Started request
      }

      final response = await _dio.post(
        '$_baseUrl/kling-image2video',
        data: data,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            // Progress from 10% to 90% during download
            final progress = 0.1 + (received / total) * 0.8;
            onProgress(progress);
          }
        },
      );

      if (response.statusCode == 200) {
        if (onProgress != null) {
          onProgress(1.0); // Completed
        }
        return Uint8List.fromList(response.data);
      } else {
        throw SegmindApiException(
          'Failed to generate video: ${response.statusCode}',
          response.statusCode ?? 0,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        throw SegmindApiException(
          'Video generation timed out. Please try again.',
          408,
        );
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw SegmindApiException(
          'Connection timeout. Please check your internet connection.',
          408,
        );
      } else {
        throw SegmindApiException(
          'Network error: ${e.message}',
          e.response?.statusCode ?? 0,
        );
      }
    } catch (e) {
      throw SegmindApiException(
        'Unexpected error: $e',
        0,
      );
    }
  }

  /// Get available generation modes
  static List<String> getAvailableModes() {
    return ['std', 'pro'];
  }

  /// Get available durations
  static List<int> getAvailableDurations() {
    return [5, 10];
  }

  /// Get mode description
  static String getModeDescription(String mode) {
    switch (mode) {
      case 'std':
        return 'Standard - Faster generation, good quality';
      case 'pro':
        return 'Pro - Slower generation, highest quality';
      default:
        return 'Unknown mode';
    }
  }

  /// Get duration description
  static String getDurationDescription(int duration) {
    return '$duration seconds video';
  }
}

class SegmindApiException implements Exception {
  final String message;
  final int statusCode;

  SegmindApiException(this.message, this.statusCode);

  @override
  String toString() => 'SegmindApiException: $message (Status: $statusCode)';
}