import 'dart:typed_data';

class HistoryItem {
  final String id;
  final String title;
  final String operation;
  final DateTime createdAt;
  final String? originalImagePath;
  final Uint8List? originalImageData;
  final Uint8List processedImageData;
  final String? cloudinaryUrl;
  final double? processingTime;
  final int? qualityScore;

  HistoryItem({
    required this.id,
    required this.title,
    required this.operation,
    required this.createdAt,
    this.originalImagePath,
    this.originalImageData,
    required this.processedImageData,
    this.cloudinaryUrl,
    this.processingTime,
    this.qualityScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'operation': operation,
      'createdAt': createdAt.toIso8601String(),
      'originalImagePath': originalImagePath,
      'originalImageData': originalImageData?.toList(),
      'processedImageData': processedImageData.toList(),
      'cloudinaryUrl': cloudinaryUrl,
      'processingTime': processingTime,
      'qualityScore': qualityScore,
    };
  }

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'],
      title: json['title'],
      operation: json['operation'],
      createdAt: DateTime.parse(json['createdAt']),
      originalImagePath: json['originalImagePath'],
      originalImageData: json['originalImageData'] != null 
          ? Uint8List.fromList(List<int>.from(json['originalImageData']))
          : null,
      processedImageData: Uint8List.fromList(List<int>.from(json['processedImageData'])),
      cloudinaryUrl: json['cloudinaryUrl'],
      processingTime: json['processingTime']?.toDouble(),
      qualityScore: json['qualityScore'],
    );
  }

  HistoryItem copyWith({
    String? id,
    String? title,
    String? operation,
    DateTime? createdAt,
    String? originalImagePath,
    Uint8List? originalImageData,
    Uint8List? processedImageData,
    String? cloudinaryUrl,
    double? processingTime,
    int? qualityScore,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      operation: operation ?? this.operation,
      createdAt: createdAt ?? this.createdAt,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      originalImageData: originalImageData ?? this.originalImageData,
      processedImageData: processedImageData ?? this.processedImageData,
      cloudinaryUrl: cloudinaryUrl ?? this.cloudinaryUrl,
      processingTime: processingTime ?? this.processingTime,
      qualityScore: qualityScore ?? this.qualityScore,
    );
  }
}