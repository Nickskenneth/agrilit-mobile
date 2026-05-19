class DiseaseScanModel {
  final int? id;
  final String commodity;
  final String? resultLabel;
  final String? resultLabelId;
  final double? confidenceScore;
  final String? confidencePercent;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool synced;
  final String scannedAt;
  final String? notes;

  DiseaseScanModel({
    this.id,
    required this.commodity,
    this.resultLabel,
    this.resultLabelId,
    this.confidenceScore,
    this.confidencePercent,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.synced,
    required this.scannedAt,
    this.notes,
  });

  factory DiseaseScanModel.fromJson(Map<String, dynamic> json) =>
      DiseaseScanModel(
        id: json['id'] as int?,
        commodity: json['commodity'] as String,
        resultLabel: json['result_label'] as String?,
        resultLabelId: json['result_label_id'] as String?,
        confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
        confidencePercent: json['confidence_percent'] as String?,
        imageUrl: json['image_url'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        locationName: json['location_name'] as String?,
        synced: json['synced'] as bool? ?? true,
        scannedAt: json['scanned_at'] as String,
        notes: json['notes'] as String?,
      );

  bool get isHealthy => resultLabel?.toLowerCase().contains('healthy') ?? false;

  String get confidenceDisplay =>
      confidencePercent ??
      (confidenceScore != null
          ? '${(confidenceScore! * 100).toStringAsFixed(1)}%'
          : 'N/A');
}
