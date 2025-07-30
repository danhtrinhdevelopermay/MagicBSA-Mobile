import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = '523636742687724';
  static const String _apiKey = '523636742687724'; 
  static const String _apiSecret = 'b3ZSdWyEUfUjbC2dz4ddFlgYEYM';
  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload image to Cloudinary and return the URL
  static Future<String?> uploadImage(Uint8List imageData, String fileName) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      
      // Add authentication
      String auth = base64Encode(utf8.encode('$_apiKey:$_apiSecret'));
      request.headers['Authorization'] = 'Basic $auth';
      
      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageData,
          filename: fileName,
        ),
      );
      
      // Add upload parameters
      request.fields['upload_preset'] = 'twinkbsa_preset'; // You need to create this preset in Cloudinary
      request.fields['folder'] = 'twinkbsa/processed_images';
      request.fields['public_id'] = 'processed_${DateTime.now().millisecondsSinceEpoch}';
      request.fields['resource_type'] = 'image';
      
      // Send request
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseBody);
        
        // Return the secure URL
        return jsonResponse['secure_url'] as String?;
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        var errorBody = await response.stream.bytesToString();
        print('Error response: $errorBody');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Delete image from Cloudinary
  static Future<bool> deleteImage(String publicId) async {
    try {
      var request = http.MultipartRequest('POST', 
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/destroy'));
      
      String auth = base64Encode(utf8.encode('$_apiKey:$_apiSecret'));
      request.headers['Authorization'] = 'Basic $auth';
      
      request.fields['public_id'] = publicId;
      
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }

  /// Generate thumbnail URL from Cloudinary URL
  static String generateThumbnailUrl(String originalUrl, {int width = 200, int height = 200}) {
    if (!originalUrl.contains('cloudinary.com')) return originalUrl;
    
    // Insert transformation parameters into the URL
    return originalUrl.replaceFirst(
      '/image/upload/',
      '/image/upload/c_fill,w_$width,h_$height,q_auto/',
    );
  }
}