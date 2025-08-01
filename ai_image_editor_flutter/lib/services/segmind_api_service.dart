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

  /// Generate video from image using Kling Image2Video model (resource efficient)
  Future<Uint8List> generateVideoFromImage({
    required File imageFile,
    required String prompt,
    String? negativePrompt,
    double cfgScale = 0.5, // Optimal resource-efficient setting (0-1)
    String mode = 'std', // std = standard, pro = professional
    int duration = 5, // Duration in seconds (5 or 10)
    Function(double)? onProgress,
  }) async {
    try {
      // Convert image to base64 for Kling API
      final imageBase64 = _imageFileToBase64(imageFile);
      
      // Prepare data according to Kling Image2Video API spec
      final data = {
        'image': imageBase64,
        'prompt': prompt,
        'negative_prompt': negativePrompt ?? 'No sudden movements, no fast zooms, low quality, distorted',
        'cfg_scale': cfgScale, // CFG scale to control how closely animation matches prompt (0-1)
        'mode': mode, // std (standard) or pro (professional)  
        'duration': duration, // Duration in seconds (5 or 10)
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
          headers: {
            'Content-Type': 'application/json',
          },
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

  /// Get available generation modes for Kling Image2Video
  static List<String> getAvailableModes() {
    return ['std', 'pro']; // std = standard (resource efficient), pro = professional
  }

  /// Get available durations for Kling Image2Video
  static List<int> getAvailableDurations() {
    return [5, 10]; // Duration in seconds
  }

  /// Get available durations (in frames) for LTX Video
  static List<int> getAvailableDurations() {
    return [97, 129, 161, 193, 225, 257]; // Available frame counts from LTX Video API
  }

  /// Get mode description
  static String getModeDescription(String mode) {
    switch (mode) {
      case 'standard':
        return 'Standard - 30 steps, faster generation';
      case 'pro':
        return 'Pro - 40+ steps, highest quality';
      default:
        return 'Unknown mode';
    }
  }

  /// Get duration description (convert frames to seconds at 24fps)
  static String getDurationDescription(int frames) {
    final seconds = (frames / 24.0).toStringAsFixed(1);
    return '${seconds}s (${frames} frames)';
  }

  /// Get available aspect ratios for LTX Video
  static List<String> getAvailableAspectRatios() {
    return ['1:1', '1:2', '2:1', '2:3', '3:2', '3:4', '4:3', '4:5', '5:4', '9:16', '16:9', '9:21', '21:9'];
  }

  /// Get available target sizes for LTX Video
  static List<int> getAvailableTargetSizes() {
    return [512, 576, 640, 704, 768, 832, 896, 960, 1024];
  }
}

class SegmindApiException implements Exception {
  final String message;
  final int statusCode;

  SegmindApiException(this.message, this.statusCode);

  @override
  String toString() => 'SegmindApiException: $message (Status: $statusCode)';
}