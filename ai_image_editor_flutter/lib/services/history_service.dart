import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/history_item.dart';
import 'cloudinary_service.dart';

class HistoryService {
  static const String _historyKey = 'processing_history';
  static const String _syncEnabledKey = 'sync_enabled';
  
  static List<HistoryItem> _cachedHistory = [];

  /// Get sync settings
  static Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncEnabledKey) ?? false;
  }

  /// Set sync settings
  static Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, enabled);
  }

  /// Add new item to history
  static Future<void> addHistoryItem(HistoryItem item) async {
    try {
      // Check if sync is enabled
      bool syncEnabled = await isSyncEnabled();
      
      HistoryItem finalItem = item;
      
      // If sync enabled, upload to Cloudinary
      if (syncEnabled) {
        String fileName = 'processed_${item.id}.png';
        String? cloudinaryUrl = await CloudinaryService.uploadImage(
          item.processedImageData, 
          fileName
        );
        
        if (cloudinaryUrl != null) {
          finalItem = item.copyWith(cloudinaryUrl: cloudinaryUrl);
        }
      }

      // Save to local storage
      await _saveToLocalStorage(finalItem);
      
      // Update cache
      _cachedHistory.insert(0, finalItem);
      
      // Keep only last 50 items to prevent memory issues
      if (_cachedHistory.length > 50) {
        _cachedHistory = _cachedHistory.take(50).toList();
      }
      
    } catch (e) {
      print('Error adding history item: $e');
      // Still try to save locally even if cloud sync fails
      await _saveToLocalStorage(item);
      _cachedHistory.insert(0, item);
    }
  }

  /// Save item to local storage (SharedPreferences)
  static Future<void> _saveToLocalStorage(HistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing history
      List<HistoryItem> history = await getHistory();
      
      // Add new item at the beginning
      history.insert(0, item);
      
      // Keep only last 50 items
      if (history.length > 50) {
        history = history.take(50).toList();
      }
      
      // Convert to JSON and save
      List<String> historyJson = history.map((item) => json.encode(item.toJson())).toList();
      await prefs.setStringList(_historyKey, historyJson);
      
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  /// Get all history items
  static Future<List<HistoryItem>> getHistory() async {
    try {
      // Return cached data if available
      if (_cachedHistory.isNotEmpty) {
        return List.from(_cachedHistory);
      }

      final prefs = await SharedPreferences.getInstance();
      List<String>? historyJson = prefs.getStringList(_historyKey);
      
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      List<HistoryItem> history = historyJson
          .map((jsonStr) => HistoryItem.fromJson(json.decode(jsonStr)))
          .toList();

      // Cache the results
      _cachedHistory = history;
      
      return history;
    } catch (e) {
      print('Error loading history: $e');
      return [];
    }
  }

  /// Delete history item
  static Future<void> deleteHistoryItem(String id) async {
    try {
      List<HistoryItem> history = await getHistory();
      
      // Find item to delete
      HistoryItem? itemToDelete = history.where((item) => item.id == id).firstOrNull;
      
      if (itemToDelete != null) {
        // Delete from Cloudinary if URL exists
        if (itemToDelete.cloudinaryUrl != null) {
          // Extract public_id from URL and delete
          String publicId = _extractPublicIdFromUrl(itemToDelete.cloudinaryUrl!);
          await CloudinaryService.deleteImage(publicId);
        }
        
        // Remove from list
        history.removeWhere((item) => item.id == id);
        
        // Save updated list
        final prefs = await SharedPreferences.getInstance();
        List<String> historyJson = history.map((item) => json.encode(item.toJson())).toList();
        await prefs.setStringList(_historyKey, historyJson);
        
        // Update cache
        _cachedHistory.removeWhere((item) => item.id == id);
      }
    } catch (e) {
      print('Error deleting history item: $e');
    }
  }

  /// Clear all history
  static Future<void> clearHistory() async {
    try {
      // Get current history to delete cloud items
      List<HistoryItem> history = await getHistory();
      
      // Delete all cloud items if sync was enabled
      for (HistoryItem item in history) {
        if (item.cloudinaryUrl != null) {
          String publicId = _extractPublicIdFromUrl(item.cloudinaryUrl!);
          await CloudinaryService.deleteImage(publicId);
        }
      }
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      
      // Clear cache
      _cachedHistory.clear();
      
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  /// Extract public_id from Cloudinary URL
  static String _extractPublicIdFromUrl(String url) {
    // Example URL: https://res.cloudinary.com/demo/image/upload/v1234567890/twinkbsa/processed_images/processed_1234567890.png
    // Extract: twinkbsa/processed_images/processed_1234567890
    
    try {
      Uri uri = Uri.parse(url);
      List<String> pathSegments = uri.pathSegments;
      
      // Find the upload segment
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < pathSegments.length - 1) {
        // Skip version if present (v1234567890)
        int startIndex = uploadIndex + 1;
        if (pathSegments[startIndex].startsWith('v') && pathSegments[startIndex].length > 1) {
          startIndex++;
        }
        
        // Join remaining segments and remove file extension
        String publicId = pathSegments.sublist(startIndex).join('/');
        return publicId.replaceAll(RegExp(r'\.[^.]+$'), ''); // Remove extension
      }
    } catch (e) {
      print('Error extracting public_id: $e');
    }
    
    return '';
  }

  /// Get filtered history by operation type
  static Future<List<HistoryItem>> getHistoryByOperation(String operation) async {
    List<HistoryItem> allHistory = await getHistory();
    return allHistory.where((item) => item.operation == operation).toList();
  }

  /// Download history item to device
  static Future<void> downloadHistoryItem(HistoryItem item) async {
    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Get downloads directory
      Directory? downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        // Fallback to external storage directory
        downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir == null) {
          throw Exception('Could not access storage directory');
        }
      }

      // Generate unique filename
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filename = 'twink_ai_${item.operation}_$timestamp.png';
      String filePath = '${downloadsDir.path}/$filename';

      // Write image to file
      File imageFile = File(filePath);
      await imageFile.writeAsBytes(item.processedImageData);

      print('Image saved to: $filePath');
    } catch (e) {
      throw Exception('Failed to download image: $e');
    }
  }

  /// Share history item
  static Future<void> shareHistoryItem(HistoryItem item) async {
    try {
      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filename = 'twink_ai_${item.operation}_$timestamp.png';
      String filePath = '${tempDir.path}/$filename';

      File imageFile = File(filePath);
      await imageFile.writeAsBytes(item.processedImageData);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Ảnh được chỉnh sửa bởi Twink AI - ${item.title}',
      );
    } catch (e) {
      throw Exception('Failed to share image: $e');
    }
  }

  /// Get history stats
  static Future<Map<String, int>> getHistoryStats() async {
    List<HistoryItem> history = await getHistory();
    
    Map<String, int> stats = {};
    for (HistoryItem item in history) {
      stats[item.operation] = (stats[item.operation] ?? 0) + 1;
    }
    
    return stats;
  }
}