# AI Image Editor

## Overview
This project offers AI-powered image editing capabilities, specifically background and object removal, through both a React-based web application and a Flutter mobile app. Both platforms integrate with the Clipdrop API for core AI processing. The project aims to provide intuitive and efficient image manipulation tools for users, distributed via a web interface and an Android APK.

## User Preferences
Preferred communication style: Simple, everyday language.
Always provide manual Git push commands from root directory when making changes to the codebase.
Minimize code changes that could break GitHub Actions APK build process.
Focus on practical, working solutions.

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
  - Maintained navigation flow với preSelectedFeature parameter full functionality while fixing video playback issues