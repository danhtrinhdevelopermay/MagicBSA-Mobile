import 'package:video_player/video_player.dart';

class VideoPreloadService {
  static final VideoPreloadService _instance = VideoPreloadService._internal();
  factory VideoPreloadService() => _instance;
  static VideoPreloadService get instance => _instance;
  VideoPreloadService._internal();

  final Map<String, VideoPlayerController> _controllers = {};
  bool _isInitialized = false;

  static const List<String> _videoPaths = [
    'assets/videos/remove_background.mp4',
    'assets/videos/expand_image.mp4',
    'assets/videos/upscaling.mp4',
    'assets/videos/cleanup.mp4',
    'assets/videos/remove_text.mp4',
    'assets/videos/reimagine.mp4',
    'assets/videos/text_to_image.mp4',
  ];

  static const List<String> _videoIds = [
    'remove_background',
    'expand_image',
    'upscaling',
    'cleanup',
    'remove_text',
    'reimagine',
    'text_to_image',
  ];

  bool get isInitialized => _isInitialized;

  VideoPlayerController? getController(String path) {
    // Extract filename from path for controller lookup
    final filename = path.split('/').last.split('.').first;
    return _controllers[filename];
  }

  bool isVideoReady(String path) {
    final filename = path.split('/').last.split('.').first;
    return _controllers.containsKey(filename) && _controllers[filename]!.value.isInitialized;
  }

  Future<void> preloadAllVideos(List<dynamic> features) async {
    if (_isInitialized) return;

    try {
      print('🎬 Starting video preload...');
      
      for (final feature in features) {
        final path = feature.videoPath;
        final filename = path.split('/').last.split('.').first;
        
        print('📹 Loading video: $filename');
        
        final controller = VideoPlayerController.asset(path);
        _controllers[filename] = controller;
        
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(0);
        controller.play();
        
        print('✅ Video loaded: $filename');
      }
      
      _isInitialized = true;
      print('🎊 All videos preloaded successfully!');
      
    } catch (e) {
      print('❌ Error preloading videos: $e');
    }
  }

  void disposeAll() {
    print('🗑️ Disposing all video controllers...');
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _isInitialized = false;
  }

  void pauseAll() {
    for (final controller in _controllers.values) {
      if (controller.value.isInitialized && controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  void resumeAll() {
    for (final controller in _controllers.values) {
      if (controller.value.isInitialized && !controller.value.isPlaying) {
        controller.play();
      }
    }
  }
}