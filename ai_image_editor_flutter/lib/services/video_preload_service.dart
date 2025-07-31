import 'package:video_player/video_player.dart';

class VideoPreloadService {
  static final VideoPreloadService _instance = VideoPreloadService._internal();
  factory VideoPreloadService() => _instance;
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

  VideoPlayerController? getController(String id) {
    return _controllers[id];
  }

  Future<void> preloadAllVideos() async {
    if (_isInitialized) return;

    try {
      print('🎬 Starting video preload...');
      
      for (int i = 0; i < _videoPaths.length; i++) {
        final path = _videoPaths[i];
        final id = _videoIds[i];
        
        print('📹 Loading video: $id');
        
        final controller = VideoPlayerController.asset(path);
        _controllers[id] = controller;
        
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(0);
        controller.play();
        
        print('✅ Video loaded: $id');
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