# 🎯 Hướng Dẫn Vẽ Mask Chính Xác - Precision Mask Drawing

## 🚨 Vấn Đề Cần Giải Quyết

**Hiện tượng**: Mask drawing hiện tại không chính xác, user vẽ nhưng AI không xóa đúng vùng được đánh dấu.

**Nguyên nhân**: 
- Phương pháp cũ sử dụng Path drawing với coordinate mapping không chính xác
- Mask resolution không khớp với ảnh gốc
- Canvas capture bị nhiễu background
- Không tuân thủ đúng spec của Clipdrop API

## ✅ Giải Pháp: Precision Mask Painter

### 1. **Bitmap-Based Mask Creation**
```dart
// Thay vì dùng Path drawing, sử dụng bitmap trực tiếp
Uint8List _maskBitmap = Uint8List(_maskWidth * _maskHeight);
```

**Lợi ích**:
- ✅ **Pixel-perfect accuracy**: Mỗi pixel được control trực tiếp
- ✅ **Exact dimensions**: Mask có cùng kích thước với ảnh gốc
- ✅ **No coordinate drift**: Không có lỗi mapping tọa độ
- ✅ **Pure binary data**: Chỉ có 0 (keep) và 255 (remove)

### 2. **Clipdrop API Compliance**
```dart
// Mask format theo đúng yêu cầu Clipdrop
final img.Image maskImage = img.Image(
  width: originalImage.width,    // Cùng kích thước với ảnh gốc
  height: originalImage.height,  // Cùng kích thước với ảnh gốc  
  numChannels: 1,               // Grayscale
);

// Black = keep (0), White = remove (255)
maskImage.setPixel(x, y, img.ColorUint8(255)); // Remove
```

**Spec tuân thủ**:
- ✅ **PNG format**: Saved as PNG như yêu cầu
- ✅ **Same resolution**: Cùng kích thước với ảnh gốc
- ✅ **Binary values**: Chỉ 0 và 255, không có gray
- ✅ **15% expansion**: Brush tự động mở rộng 15% như khuyến nghị

### 3. **Real-time Visual Feedback**
```dart
class _MaskOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background image
    canvas.drawImageRect(backgroundImage, ...);
    
    // Draw mask overlay with red highlight
    for (pixel in maskBitmap) {
      if (pixel == 255) { // White pixels = to be removed
        canvas.drawRect(..., Colors.red.withOpacity(0.5));
      }
    }
  }
}
```

**Visual cues**:
- ✅ **Background image**: Hiển thị ảnh gốc
- ✅ **Red overlay**: Vùng đỏ = vùng sẽ bị xóa
- ✅ **Real-time update**: Cập nhật ngay khi vẽ

## 🔄 So Sánh 2 Phương Pháp

### **Phương Pháp Cũ (Path-based)**
```
User vẽ Path → Convert to canvas → Resize mask → API call
    ❌ Coordinate mapping errors
    ❌ Canvas capture noise  
    ❌ Resolution mismatch
    ❌ Gray pixels in mask
```

### **Phương Pháp Mới (Bitmap-based)**  
```
User vẽ → Direct bitmap update → PNG export → API call
    ✅ Pixel-perfect accuracy
    ✅ No background noise
    ✅ Exact resolution match
    ✅ Pure binary mask
```

## 📱 User Experience

### **Flow Cũ**:
```
Click cleanup → Mask drawing screen → Vẽ → Often fails "không xóa đúng vùng"
```

### **Flow Mới**:
```
Click cleanup → Choose method dialog:
├── "Phương Pháp Chuẩn" → Original ObjectRemovalScreen
└── "Phương Pháp Chính Xác" → PrecisionMaskPainter → Accurate removal
```

## 🎯 Tính Năng Precision Mask Painter

### **Core Features**:
- ✅ **Bitmap drawing**: Vẽ trực tiếp lên bitmap mask
- ✅ **Coordinate accuracy**: Tọa độ screen → image chính xác 100%
- ✅ **Brush expansion**: Tự động mở rộng 15% theo khuyến nghị Clipdrop
- ✅ **Real-time preview**: Hiển thị vùng đỏ sẽ bị xóa
- ✅ **Clear function**: Xóa mask và vẽ lại
- ✅ **Validation**: Kiểm tra mask trước khi gửi API

### **Advanced Features**:
- ✅ **Aspect ratio aware**: Maintain proper aspect ratio
- ✅ **Scale calculation**: Accurate screen-to-image mapping
- ✅ **Memory efficient**: Direct bitmap manipulation
- ✅ **Debug logging**: Comprehensive mask stats

## 🔧 Technical Implementation

### **Key Classes**:
```dart
PrecisionMaskPainter          // Main widget
├── _PrecisionMaskPainterState // State management
├── _MaskOverlayPainter       // Custom painter
└── Uint8List _maskBitmap     // Core bitmap data
```

### **Integration Points**:
```dart
// Enhanced Editor Widget
void _showMaskDialog(Feature feature) {
  showDialog(... choose method dialog);
}

// Navigation to precision painter
Navigator.push(PrecisionMaskPainter(
  originalImage: widget.originalImage,
  onMaskCreated: (maskFile) => processWithMask(maskFile),
));
```

## 📈 Expected Results

### **Before (Issues)**:
- ❌ User vẽ nhưng AI không xóa đúng vùng
- ❌ Mask bitmap không chính xác  
- ❌ Coordinate mapping errors
- ❌ Background contamination

### **After (Fixed)**:
- ✅ User vẽ → AI xóa chính xác vùng đã vẽ
- ✅ Pixel-perfect mask creation
- ✅ Exact coordinate mapping
- ✅ Pure binary mask data

## 🔄 Git Push Commands

Theo yêu cầu trong loinhac.md:

```bash
cd ai_image_editor_flutter
git add .
git commit -m "🎯 ADD: Precision Mask Drawing for accurate object removal

- Create PrecisionMaskPainter with bitmap-based mask creation
- Implement pixel-perfect coordinate mapping without drift
- Add 15% brush expansion per Clipdrop API recommendations
- Real-time red overlay showing areas to be removed
- Pure binary mask (0=keep, 255=remove) with exact image dimensions
- Choice dialog between standard and precision mask methods
- Full Clipdrop API compliance for better removal accuracy
- Enhanced user experience with visual feedback"

git push origin main
```

## 📋 Files Created/Modified

### **New Files**:
- `ai_image_editor_flutter/lib/widgets/precision_mask_painter.dart`
- `PRECISION_MASK_DRAWING_GUIDE.md`

### **Modified Files**:
- `ai_image_editor_flutter/lib/widgets/enhanced_editor_widget.dart`
  - Added PrecisionMaskPainter import
  - Updated _showMaskDialog with method selection
  - Integrated precision painter navigation

## 🏁 Expected Outcome

Sau khi user test:

1. **Method Selection**: User có thể chọn giữa 2 phương pháp
2. **Precision Drawing**: Phương pháp mới cho kết quả chính xác hơn
3. **Visual Feedback**: Thấy rõ vùng nào sẽ bị xóa (màu đỏ)
4. **Better API Results**: Clipdrop API nhận mask đúng format → xóa chính xác

## 🔮 Future Enhancements

- **Brush size slider**: Điều chỉnh brush size real-time
- **Undo/Redo**: Multiple levels của mask edits
- **Magic select**: Auto-detect object boundaries
- **Zoom functionality**: Zoom in để vẽ chi tiết