enum ProcessingOperation {
  removeBackground,
  cleanup,
  removeText,
  uncrop,
  imageUpscaling,
  reimagine,
  textToImage,
  productPhotography,
  replaceBackground,
}

extension ProcessingOperationExtension on ProcessingOperation {
  String get displayName {
    switch (this) {
      case ProcessingOperation.removeBackground:
        return 'Xóa Nền';
      case ProcessingOperation.cleanup:
        return 'Xóa Vật Thể';
      case ProcessingOperation.removeText:
        return 'Xóa Chữ';
      case ProcessingOperation.uncrop:
        return 'Mở Rộng Ảnh';
      case ProcessingOperation.imageUpscaling:
        return 'Tăng Độ Phân Giải';
      case ProcessingOperation.reimagine:
        return 'Tái Tưởng Tượng';
      case ProcessingOperation.textToImage:
        return 'Tạo Ảnh Từ Chữ';
      case ProcessingOperation.productPhotography:
        return 'Ảnh Sản Phẩm';
      case ProcessingOperation.replaceBackground:
        return 'Thay Nền';
    }
  }

  String get description {
    switch (this) {
      case ProcessingOperation.removeBackground:
        return 'Loại bỏ nền ảnh tự động bằng AI';
      case ProcessingOperation.cleanup:
        return 'Xóa bỏ các đối tượng không mong muốn';
      case ProcessingOperation.removeText:
        return 'Loại bỏ văn bản khỏi hình ảnh';
      case ProcessingOperation.uncrop:
        return 'Mở rộng khung hình với AI';
      case ProcessingOperation.imageUpscaling:
        return 'Nâng cao chất lượng và độ phân giải';
      case ProcessingOperation.reimagine:
        return 'Tạo biến thể mới từ ảnh gốc';
      case ProcessingOperation.textToImage:
        return 'Tạo hình ảnh từ mô tả bằng văn bản';
      case ProcessingOperation.productPhotography:
        return 'Tạo ảnh sản phẩm chuyên nghiệp';
      case ProcessingOperation.replaceBackground:
        return 'Thay thế nền ảnh';
    }
  }
}