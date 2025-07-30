# OneSignal Push Notifications Debug Guide

## 🔍 Vấn đề hiện tại
Ứng dụng TwinkBSA đã được cấu hình với OneSignal nhưng push notifications không hoạt động khi gửi từ OneSignal dashboard.

## 📋 Checklist debug đã thực hiện

### ✅ 1. Cấu hình OneSignal cơ bản
- App ID: `a503a5c7-6b11-404a-b0ea-8505fdaf59e8`
- OneSignal Flutter SDK: `5.0.4`
- Firebase project: `twink-ai` (Project ID: 290380851437)
- Package name: `com.example.ai_image_editor_flutter`

### ✅ 2. Permissions Android
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### ✅ 3. Firebase Integration
- google-services.json đã được thêm vào `android/app/`
- Google Services plugin đã được apply trong build.gradle
- Firebase Messaging và Analytics dependencies đã được thêm

### ✅ 4. OneSignal Service Setup
- Khởi tạo trong main() với proper async/await
- Debug logging enabled (OSLogLevel.verbose)
- Permission request implemented
- Foreground, click, và subscription listeners đã được thiết lập

## 🔧 Debug Features đã thêm

### 1. Enhanced OneSignal Service
```dart
// Debug status checker
OneSignalService.debugStatus()

// Permission prompt
OneSignalService.promptForPermission()

// Subscription change observer
_onSubscriptionChange()
```

### 2. Debug Button trong ProfileScreen
- Menu item "Debug OneSignal" để kiểm tra trạng thái
- Console logs chi tiết về User ID, Push Token, Permission status
- Button "Yêu cầu Permission lại" để retry permission

### 3. Enhanced Logging
- Detailed console output với emoji indicators
- User ID và Push Token tracking
- Permission status monitoring
- Tags management logging

## 🚀 Các bước debug tiếp theo

### Bước 1: Kiểm tra Console Logs
Khi mở app, kiểm tra console logs cho các thông tin sau:
```
🔄 Bắt đầu khởi tạo OneSignal...
📱 Khởi tạo OneSignal với App ID: a503a5c7-6b11-404a-b0ea-8505fdaf59e8
🔔 Permission hiện tại: true/false
🔔 Permission được cấp: true/false
👤 OneSignal User ID: [user_id]
🔑 Push Token: [push_token]
✅ OneSignal đã được khởi tạo thành công
=== ONESIGNAL DEBUG STATUS ===
```

### Bước 2: Sử dụng Debug Button
1. Mở app và navigate to Profile screen
2. Tap vào "Debug OneSignal"
3. Kiểm tra console logs để xem detailed status
4. Nếu cần, tap "Yêu cầu Permission lại"

### Bước 3: Kiểm tra OneSignal Dashboard
1. Đăng nhập OneSignal dashboard
2. Chọn app với ID: `a503a5c7-6b11-404a-b0ea-8505fdaf59e8`
3. Kiểm tra "Audience" -> "All Users" để xem devices đã subscribe
4. Tìm device với User ID từ debug logs

### Bước 4: Test Push Notification
1. Từ OneSignal dashboard, tạo new message
2. Target "All Subscribed Users" hoặc specific User ID
3. Gửi test message
4. Kiểm tra app nhận notification không

## 🔍 Các vấn đề có thể gặp

### Problem 1: Permission bị từ chối
**Triệu chứng:** `🔔 Permission được cấp: false`
**Giải pháp:**
1. Uninstall và reinstall app
2. Sử dụng debug button "Yêu cầu Permission lại"
3. Kiểm tra Android settings manually

### Problem 2: User ID null
**Triệu chứng:** `👤 OneSignal User ID: null`
**Giải pháp:**
1. Kiểm tra internet connection
2. Đợi lâu hơn (2-3 giây) sau initialization
3. Restart app và kiểm tra lại

### Problem 3: Push Token missing
**Triệu chứng:** `🔑 Push Token: null`
**Giải pháp:**
1. Đảm bảo Firebase đã được setup đúng
2. Kiểm tra google-services.json có đúng package name không
3. Clean build và rebuild app

### Problem 4: Device không xuất hiện trong OneSignal Dashboard
**Giải pháp:**
1. Đảm bảo app đã request permission thành công
2. Kiểm tra App ID có đúng không
3. Restart app và đợi vài phút

## 🛠️ Advanced Debug Steps

### 1. Manual FCM Token Check
Thêm vào OneSignalService để kiểm tra FCM token trực tiếp:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

static Future<void> checkFCMToken() async {
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print("🔥 FCM Token: $fcmToken");
}
```

### 2. OneSignal API Call Test
Sử dụng REST API để test trực tiếp:
```bash
curl -X POST https://onesignal.com/api/v1/notifications \
  -H "Authorization: Basic [YOUR_REST_API_KEY]" \
  -H "Content-Type: application/json" \
  -d '{
    "app_id": "a503a5c7-6b11-404a-b0ea-8505fdaf59e8",
    "include_subscription_ids": ["[USER_ID_FROM_DEBUG]"],
    "contents": {"en": "Test notification"}
  }'
```

### 3. Build Configuration Check
Đảm bảo release build có cùng configuration:
```gradle
buildTypes {
    release {
        // OneSignal configuration for release
        manifestPlaceholders = [
            onesignal_app_id: "a503a5c7-6b11-404a-b0ea-8505fdaf59e8"
        ]
    }
}
```

## 📱 Expected Working Flow

### Khi hoạt động đúng:
1. App khởi động → OneSignal initialize
2. Permission được cấp → User ID và Push Token được tạo
3. Device xuất hiện trong OneSignal dashboard
4. Gửi notification từ dashboard → App nhận notification

### Console logs khi thành công:
```
🔄 Bắt đầu khởi tạo OneSignal...
📱 Khởi tạo OneSignal với App ID: a503a5c7-6b11-404a-b0ea-8505fdaf59e8
🔔 Permission hiện tại: true
🔔 Permission được cấp: true
👤 OneSignal User ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
🔑 Push Token: [long_token_string]
✅ OneSignal đã được khởi tạo thành công
🏷️ Đã gửi tags: {app_version: 1.0.0, platform: android, language: vi}
```

## 📞 Next Steps nếu vẫn không hoạt động

1. **Kiểm tra OneSignal App Settings:**
   - Verify Firebase Server Key trong OneSignal dashboard
   - Đảm bảo Android platform đã được enable

2. **Test với OneSignal Example App:**
   - Download OneSignal Flutter example
   - Test với cùng App ID để isolate issue

3. **Liên hệ OneSignal Support:**
   - Cung cấp App ID và debug logs
   - Mô tả detailed steps đã thực hiện

---

*Guide này sẽ được cập nhật khi có thêm findings từ debug process.*