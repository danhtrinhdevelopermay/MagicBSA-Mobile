# AI Image Editor

## Overview
This project offers AI-powered image editing capabilities, specifically background and object removal, through both a React-based web application and a Flutter mobile app. Both platforms integrate with the Clipdrop API for core AI processing. The project aims to provide intuitive and efficient image manipulation tools for users, distributed via a web interface and an Android APK.

## User Preferences
Preferred communication style: Simple, everyday language.
Always provide manual Git push commands from root directory when making changes to the codebase.
Minimize code changes that could break GitHub Actions APK build process.
Focus on practical, working solutions.

**Important Code Change Protocol (from loinhac.md):**
1. Khi có thay đổi code thí gửi kèm theo lệnh push git thủ công, push toàn bộ code trong thư mục gốc không cần cd
2. Đảm bảo không ảnh hưởng đến việc build apk khi thay đổi hoặc phát triển ứng dụng

## System Architecture

### Web Application
The web application features a React 18 frontend with TypeScript, utilizing Wouter for routing, TanStack Query for state management, and Tailwind CSS with shadcn/ui for UI. The backend is built with Node.js and Express.js, handling file uploads with Multer. Database operations are managed via Drizzle ORM with PostgreSQL (configured for Neon serverless).

### Flutter Mobile Application
The mobile application is developed using Flutter 3.22.0 and Dart, employing the Provider pattern for state management and Material 3 for UI design. It's configured for Android APK builds with GitHub Actions support.

#### Core Features & Design Patterns:
- **Feature-First Flow**: The Flutter app's user flow is redesigned to prioritize feature selection (e.g., Remove Background, Cleanup) before image upload. This is demonstrated with simple icon-based feature cards with gradient backgrounds.
- **Precision Mask Drawing**: For object removal, a pixel-perfect mask creation system is implemented, using bitmap manipulation for accuracy and real-time visual feedback.
- **Auto-Scroll to Results**: After AI processing, the EditorScreen automatically scrolls to display the results for applicable operations.
- **Enhanced UI/UX**: Both web and mobile applications feature modern design elements, including glassmorphism effects, gradient themes, advanced animations (e.g., floating bottom navigation with elastic animations), and intuitive controls.
- **Comprehensive History System**: A complete history feature saves processed images locally (with optional cloud sync), allowing users to view, download, share, and delete past edits.
- **API Auto-Resize**: All Clipdrop API integrations include automatic image resizing to comply with API limits while preserving aspect ratio.
- **Coordinate Mapping**: Critical fixes have been implemented for accurate coordinate mapping in mask drawing, ensuring user input precisely matches AI processing areas.
- **Loading Overlay**: A full-screen, blurred loading overlay with animated elements enhances user experience during AI processing.
- **System UI Transparency**: The app is designed for full edge-to-edge immersive experience with transparent system bars.

## External Dependencies

### Web Application
- **Clipdrop API**: For all AI image processing (background removal, object cleanup, uncrop, reimagine, text-to-image, product photography, image upscaling).
- **@neondatabase/serverless**: PostgreSQL serverless connection.
- **@tanstack/react-query**: Server state management.
- **drizzle-orm**: Type-safe ORM.
- **multer**: File upload handling.

### Flutter Mobile Application
- **Clipdrop API**: Integrated for all AI image processing functionalities.
- **Segmind API**: Advanced integration for AI image-to-video generation using LTX Video model (24fps real-time).
- **Firebase**: For OneSignal push notification integration.
- **OneSignal**: Push notification service.
- **audioplayers**: For background music and sound effects.
- **image_picker, image**: For image file operations.
- **dio, http**: For HTTP requests to Clipdrop and Segmind APIs.
- **path_provider, share_plus**: For local storage and sharing.
- **permission_handler**: For Android permissions.
- **curved_navigation_bar**: For advanced bottom navigation UI.
- **video_player**: For video playback of generated content.

## Recent Changes (August 1, 2025)

✓ **UPGRADED: LTX VIDEO API FOR IMAGE-TO-VIDEO GENERATION** - Major upgrade to cutting-edge LTX Video model:
  - Migrated from Kling AI to LTX Video model (24fps real-time generation)
  - Updated SegmindApiService to use ltx-video endpoint with multipart/form-data
  - Enhanced ImageToVideoWidget with frame-based duration control (97-257 frames)
  - Advanced CFG scale 1-20 with optimal recommendations (3.0-3.5)
  - Professional UI with LTX Video branding and technical specifications
  - Support for multiple aspect ratios and target sizes (512-1024px)
  - Improved prompt guidance for cinematic quality results
  - Standard (30 steps) vs Pro (40+ steps) modes for speed/quality balance
  - Real-time video generation faster than viewing time (768x512 resolution)
  - Enhanced error handling with detailed Vietnamese messages

✓ **ENHANCED GENERATION SCREEN WITH VIDEO DEMOS** - Cải thiện layout và thêm video minh họa cho tất cả tính năng:
  - Fixed layout spacing issues (16px grid spacing thay vì 12px bị dính nhau)
  - Added 8 video demo files cho visual preview của mỗi tính năng AI
  - Enhanced card design với video background, gradient overlay, và icon badges
  - Improved grid layout với aspect ratio 0.85 và proper padding (20px horizontal)
  - Video auto-play với loop và muted audio cho smooth experience
  - Modern card styling với 24px border radius và professional shadows
  - Enhanced typography với 15px titles và 12px descriptions
  - Proper video controller management với memory leak prevention
  - **CRITICAL FIX**: Sửa callback scope issue trong video controller initialization để pass APK build
  - **VIDEO PLAYBACK FIX**: Sửa tất cả video paths để match với file names thực tế, tất cả 8 tính năng AI bây giờ có video demos phát được
  - Enhanced error handling với comprehensive debug logging cho video loading
  - Maintained navigation flow với preSelectedFeature parameter

✓ **VIDEO SIMULTANEOUS PLAYBACK SYSTEM** - Individual monitoring cho tất cả videos phát đồng thời:
  - **Staggered initialization**: Mỗi video khởi tạo cách nhau 200ms để tránh resource conflicts
  - **Individual monitoring timers**: Mỗi video có Timer riêng để monitor và restart độc lập
  - **Enhanced fallback system**: Alternative video paths cho mỗi feature với comprehensive error handling
  - **Resource management**: Proper disposal của timers và controllers với memory leak prevention
  - **Conflict resolution**: Tránh việc videos dừng khi video khác phát bằng independent lifecycle
  - **COMPILATION FIX**: Sửa duplicate method declaration `_tryAlternativeVideo` gây lỗi APK build
  - **APK BUILD READY**: Đảm bảo tất cả 8 videos phát đồng thời mà không ảnh hưởng build process

✓ **VIDEO TO GIF OPTIMIZATION SYSTEM** - Chuyển đổi hoàn toàn từ video sang GIF system:
  - **GIF Generation**: Converted 8 MP4 files thành optimized GIF format (496KB-1.3MB)
  - **Performance optimization**: Loại bỏ video controller system và complex monitoring
  - **Memory efficiency**: Simplified lifecycle management, không cần initialization/disposal
  - **Resource management**: Eliminated video resource conflicts và timing issues  
  - **UI Enhancement**: Replaced VideoPlayer với Image.asset cho GIF display
  - **File structure**: Updated Feature class từ videoPath → gifPath
  - **Assets integration**: Added assets/gifs/ directory với 8 demo GIF files
  - **APK compatibility**: Maintained build process compatibility với cleaner codebase

✓ **BEAUTIFUL FEATURE CARDS REDESIGN** - Modern glassmorphism design với interactive animations:
  - **Glassmorphism effects**: Semi-transparent backgrounds với border highlights
  - **Multi-layered shadows**: Color-coordinated depth effects cho realistic appearance
  - **Enhanced typography**: Larger fonts (16px titles, 13px descriptions) với better spacing
  - **Press animations**: Scale transform (95%) với state management cho tactile feedback
  - **Staggered loading**: Delayed animations với easeOutBack curve cho bouncy entrance
  - **AI status badges**: Floating indicators với green dot và subtle shadows
  - **Premium CTA buttons**: Enhanced gradients với arrow icons và ripple effects
  - **Improved grid layout**: BouncingScrollPhysics với optimized spacing (18px/20px)
  - **Better aspect ratio**: 0.78 cho taller cards với improved proportions

✓ **VIDEO GENERATOR PRO FEATURE REMOVED** - Xóa hoàn toàn tính năng Replicate-based video generation:
  - **REMOVED FILES**: Deleted huggingface_animatediff_service.dart, animatediff_widget.dart, and documentation
  - **CLEANED GENERATION SCREEN**: Removed "Tạo video từ ảnh Pro" feature card from generation grid
  - **SIMPLIFIED NAVIGATION**: All features now use standard ImageUploadWidget flow
  - **REMOVED DEPENDENCIES**: No more Replicate API calls or video generation complexity
  - **APK BUILD OPTIMIZED**: Reduced app size by removing unused video generation components
  - **USER EXPERIENCE**: Streamlined to focus on core AI image editing features only
  - **STATUS**: Video generation feature completely removed per user request