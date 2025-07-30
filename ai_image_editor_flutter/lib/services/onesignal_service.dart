import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý OneSignal push notifications cho TwinkBSA app
class OneSignalService {
  static const String _oneSignalAppId = "a503a5c7-6b11-404a-b0ea-8505fdaf59e8"; // OneSignal App ID
  static const String _userIdKey = "onesignal_user_id";
  
  static OneSignalService? _instance;
  static OneSignalService get instance => _instance ??= OneSignalService._();
  
  OneSignalService._();
  
  /// Khởi tạo OneSignal service
  static Future<void> initialize() async {
    try {
      print("🔄 Bắt đầu khởi tạo OneSignal...");
      
      // Debug mode - enable để kiểm tra chi tiết
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      
      // Khởi tạo OneSignal với App ID
      print("📱 Khởi tạo OneSignal với App ID: $_oneSignalAppId");
      OneSignal.initialize(_oneSignalAppId);
      
      // Đợi một chút để OneSignal khởi tạo hoàn tất
      await Future.delayed(const Duration(seconds: 2));
      
      // Kiểm tra trạng thái permission hiện tại
      final currentPermission = await OneSignal.Notifications.permission;
      print("🔔 Permission hiện tại: $currentPermission");
      
      // Yêu cầu permission cho notifications
      print("🔔 Yêu cầu permission notifications...");
      final granted = await OneSignal.Notifications.requestPermission(true);
      print("🔔 Permission được cấp: $granted");
      
      // Lắng nghe khi nhận notification trong foreground
      OneSignal.Notifications.addForegroundWillDisplayListener(_onForegroundWillDisplay);
      
      // Lắng nghe khi user click vào notification
      OneSignal.Notifications.addClickListener(_onNotificationClick);
      
      // Lắng nghe khi permission thay đổi
      OneSignal.Notifications.addPermissionObserver(_onPermissionChange);
      
      // Lắng nghe khi subscription thay đổi
      OneSignal.User.pushSubscription.addObserver(_onSubscriptionChange);
      
      // Đợi và lấy User ID
      await Future.delayed(const Duration(seconds: 1));
      final userId = OneSignal.User.pushSubscription.id;
      final pushToken = OneSignal.User.pushSubscription.token;
      
      print("👤 OneSignal User ID: $userId");
      print("🔑 Push Token: $pushToken");
      
      if (userId != null) {
        await _saveUserId(userId);
      }
      
      // Đặt tags mặc định để dễ targeting
      await sendTags({
        'app_version': '1.0.0',
        'platform': 'android',
        'language': 'vi'
      });
      
      print("✅ OneSignal đã được khởi tạo thành công");
    } catch (e) {
      print("❌ Lỗi khởi tạo OneSignal: $e");
    }
  }
  
  /// Xử lý notification khi app đang mở (foreground)
  static void _onForegroundWillDisplay(OSNotificationWillDisplayEvent event) {
    print("Nhận notification trong foreground: ${event.notification.body}");
    
    // Có thể tùy chỉnh notification trước khi hiển thị
    event.notification.display();
  }
  
  /// Xử lý khi user click vào notification
  static void _onNotificationClick(OSNotificationClickEvent event) {
    print("User click vào notification: ${event.notification.body}");
    
    // Xử lý navigation hoặc action dựa trên notification data
    final additionalData = event.notification.additionalData;
    if (additionalData != null) {
      if (additionalData.containsKey('screen')) {
        _navigateToScreen(additionalData['screen']);
      }
    }
  }
  
  /// Xử lý khi notification permission thay đổi
  static void _onPermissionChange(bool granted) {
    print("🔔 Notification permission: ${granted ? 'Cho phép' : 'Từ chối'}");
  }
  
  /// Xử lý khi push subscription thay đổi
  static void _onSubscriptionChange(OSPushSubscriptionChangedState state) {
    print("📱 Push subscription changed:");
    print("  Previous ID: ${state.previous.id}");
    print("  Current ID: ${state.current.id}");
    print("  Previous Token: ${state.previous.token}");
    print("  Current Token: ${state.current.token}");
    print("  OptedIn: ${state.current.optedIn}");
    
    // Lưu user ID mới nếu có
    if (state.current.id != null) {
      _saveUserId(state.current.id!);
    }
  }
  
  /// Navigation đến màn hình cụ thể từ notification
  static void _navigateToScreen(String screen) {
    switch (screen) {
      case 'history':
        // Navigate to history screen
        print("Chuyển đến màn hình Lịch sử");
        break;
      case 'premium':
        // Navigate to premium screen
        print("Chuyển đến màn hình Premium");
        break;
      case 'profile':
        // Navigate to profile screen
        print("Chuyển đến màn hình Hồ sơ");
        break;
      default:
        // Navigate to home screen
        print("Chuyển đến màn hình Trang chủ");
        break;
    }
  }
  
  /// Lưu OneSignal User ID vào SharedPreferences
  static Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    print("Đã lưu OneSignal User ID: $userId");
  }
  
  /// Lấy OneSignal User ID đã lưu
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  /// Đặt external user ID (ví dụ: user ID từ database)
  static Future<void> setExternalUserId(String externalId) async {
    try {
      OneSignal.login(externalId);
      print("Đã đặt External User ID: $externalId");
    } catch (e) {
      print("Lỗi đặt External User ID: $e");
    }
  }
  
  /// Gửi tag để phân loại user
  static Future<void> sendTags(Map<String, String> tags) async {
    try {
      OneSignal.User.addTags(tags);
      print("Đã gửi tags: $tags");
    } catch (e) {
      print("Lỗi gửi tags: $e");
    }
  }
  
  /// Gỡ tag
  static Future<void> removeTags(List<String> tagKeys) async {
    try {
      OneSignal.User.removeTags(tagKeys);
      print("Đã gỡ tags: $tagKeys");
    } catch (e) {
      print("Lỗi gỡ tags: $e");
    }
  }
  
  /// Bật/tắt push notifications
  static Future<void> setPushNotificationEnabled(bool enabled) async {
    try {
      OneSignal.User.pushSubscription.optIn();
      if (!enabled) {
        OneSignal.User.pushSubscription.optOut();
      }
      print("Push notifications: ${enabled ? 'Bật' : 'Tắt'}");
    } catch (e) {
      print("Lỗi thiết lập push notifications: $e");
    }
  }
  
  /// Kiểm tra trạng thái permission
  static Future<bool> hasNotificationPermission() async {
    try {
      final permission = await OneSignal.Notifications.permission;
      return permission;
    } catch (e) {
      print("Lỗi kiểm tra permission: $e");
      return false;
    }
  }
  
  /// Gửi notification test (chỉ dùng cho development)
  static Future<void> sendTestNotification() async {
    final userId = await getUserId();
    if (userId != null) {
      print("Gửi test notification đến User ID: $userId");
      // Thực tế cần sử dụng OneSignal REST API để gửi notification
    }
  }
  
  /// Debug: Kiểm tra trạng thái OneSignal hiện tại
  static Future<void> debugStatus() async {
    try {
      print("=== ONESIGNAL DEBUG STATUS ===");
      
      // Kiểm tra permission
      final permission = await OneSignal.Notifications.permission;
      print("🔔 Notification Permission: $permission");
      
      // Kiểm tra User ID và Token
      final userId = OneSignal.User.pushSubscription.id;
      final pushToken = OneSignal.User.pushSubscription.token;
      final optedIn = OneSignal.User.pushSubscription.optedIn;
      
      print("👤 User ID: $userId");
      print("🔑 Push Token: $pushToken");
      print("✅ Opted In: $optedIn");
      
      // Kiểm tra saved User ID
      final savedUserId = await getUserId();
      print("💾 Saved User ID: $savedUserId");
      
      // Kiểm tra tags
      print("🏷️ Current Tags: Checking...");
      
      print("=== END DEBUG STATUS ===");
    } catch (e) {
      print("❌ Debug Status Error: $e");
    }
  }
  
  /// Prompt user để cấp permission lại
  static Future<void> promptForPermission() async {
    try {
      print("🔔 Yêu cầu permission notifications lại...");
      final granted = await OneSignal.Notifications.requestPermission(true);
      print("🔔 Permission result: $granted");
      
      if (granted) {
        // Đợi và kiểm tra subscription
        await Future.delayed(const Duration(seconds: 2));
        await debugStatus();
      }
    } catch (e) {
      print("❌ Lỗi yêu cầu permission: $e");
    }
  }
}