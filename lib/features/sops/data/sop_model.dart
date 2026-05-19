import 'dart:convert';

class SopModel {
  final int id;
  final String title;
  final String commodity;
  final String? description;
  final int? durationDays;
  final List<Map<String, dynamic>> monthlyCalendar;
  final List<Map<String, dynamic>>? inputsNeeded;
  final String? thumbnailUrl;
  final String? authorName;
  final String updatedAt;

  SopModel({
    required this.id,
    required this.title,
    required this.commodity,
    this.description,
    this.durationDays,
    required this.monthlyCalendar,
    this.inputsNeeded,
    this.thumbnailUrl,
    this.authorName,
    required this.updatedAt,
  });

  factory SopModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parseList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List)
        return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is List)
          return decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
      }
      return [];
    }

    return SopModel(
      id: json['id'] as int,
      title: json['title'] as String,
      commodity: json['commodity'] as String,
      description: json['description'] as String?,
      durationDays: json['duration_days'] as int?,
      monthlyCalendar: parseList(json['monthly_calendar']),
      inputsNeeded: json['inputs_needed'] != null
          ? parseList(json['inputs_needed'])
          : null,
      thumbnailUrl: json['thumbnail_url'] as String?,
      authorName: (json['author'] as Map<String, dynamic>?)?['name'] as String?,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toLocalDb() => {
        'id': id,
        'title': title,
        'commodity': commodity,
        'description': description,
        'duration_days': durationDays,
        'monthly_calendar': jsonEncode(monthlyCalendar),
        'inputs_needed': inputsNeeded != null ? jsonEncode(inputsNeeded) : null,
        'thumbnail_url': thumbnailUrl,
        'author_name': authorName,
        'updated_at': updatedAt,
      };

  factory SopModel.fromLocalDb(Map<String, dynamic> map) {
    List<Map<String, dynamic>> parseJson(dynamic raw) {
      if (raw == null) return [];
      final decoded = jsonDecode(raw as String);
      if (decoded is List)
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return [];
    }

    return SopModel(
      id: map['id'] as int,
      title: map['title'] as String,
      commodity: map['commodity'] as String,
      description: map['description'] as String?,
      durationDays: map['duration_days'] as int?,
      monthlyCalendar: parseJson(map['monthly_calendar']),
      inputsNeeded:
          map['inputs_needed'] != null ? parseJson(map['inputs_needed']) : null,
      thumbnailUrl: map['thumbnail_url'] as String?,
      authorName: map['author_name'] as String?,
      updatedAt: map['updated_at'] as String,
    );
  }
}
