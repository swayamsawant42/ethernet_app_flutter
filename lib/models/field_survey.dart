class FieldSurveyListResponse {
  final List<FieldSurvey> surveys;
  final SurveyPagination? pagination;

  FieldSurveyListResponse({required this.surveys, this.pagination});

  factory FieldSurveyListResponse.fromResponse(dynamic data) {
    List<dynamic> rawSurveys = [];
    Map<String, dynamic>? paginationMap;

    if (data is Map<String, dynamic>) {
      if (data['survey'] is List) {
        rawSurveys = data['survey'] as List<dynamic>;
      } else if (data['data'] is List) {
        rawSurveys = data['data'] as List<dynamic>;
      }

      if (data['pagination'] is Map) {
        paginationMap = Map<String, dynamic>.from(data['pagination'] as Map);
      } else if (data['data'] is Map &&
          (data['data'] as Map)['pagination'] is Map) {
        paginationMap = Map<String, dynamic>.from(
          (data['data'] as Map)['pagination'] as Map,
        );
      }
    } else if (data is List) {
      rawSurveys = data;
    }

    final surveys = rawSurveys
        .whereType<Map>()
        .map((json) => FieldSurvey.fromJson(Map<String, dynamic>.from(json)))
        .toList();

    return FieldSurveyListResponse(
      surveys: surveys,
      pagination:
          paginationMap != null ? SurveyPagination.fromJson(paginationMap) : null,
    );
  }
}

class FieldSurvey {
  final int? id;
  final String? serviceRating;
  final String? likedFeatures;
  final String? heardFrom;
  final String? contactNumber;
  final String? feedback;
  final int? userId;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FieldSurvey({
    this.id,
    this.serviceRating,
    this.likedFeatures,
    this.heardFrom,
    this.contactNumber,
    this.feedback,
    this.userId,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory FieldSurvey.fromJson(Map<String, dynamic> json) {
    // Handle likedFeatures - can be array or string
    String? likedFeaturesStr;
    if (json['likedFeatures'] != null) {
      if (json['likedFeatures'] is List) {
        // Convert array to comma-separated string
        likedFeaturesStr = (json['likedFeatures'] as List)
            .map((e) => e.toString())
            .join(', ');
      } else {
        likedFeaturesStr = json['likedFeatures']?.toString();
      }
    }
    
    return FieldSurvey(
      id: _parseInt(json['id']),
      serviceRating: json['serviceRating']?.toString(),
      likedFeatures: likedFeaturesStr,
      heardFrom: json['heardFrom']?.toString(),
      contactNumber: json['contactNumber']?.toString(),
      feedback: json['feedback']?.toString() ?? json['suggestions']?.toString(),
      userId: _parseInt(json['userId'] ?? json['user_id']),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  List<String> get likedFeaturesList {
    if (likedFeatures == null || likedFeatures!.trim().isEmpty) {
      return [];
    }
    return likedFeatures!
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String get displayRating => serviceRating ?? 'N/A';

  FieldSurvey copyWith({
    String? serviceRating,
    String? likedFeatures,
    String? heardFrom,
    String? contactNumber,
    String? feedback,
    double? latitude,
    double? longitude,
  }) {
    return FieldSurvey(
      id: id,
      serviceRating: serviceRating ?? this.serviceRating,
      likedFeatures: likedFeatures ?? this.likedFeatures,
      heardFrom: heardFrom ?? this.heardFrom,
      contactNumber: contactNumber ?? this.contactNumber,
      feedback: feedback ?? this.feedback,
      userId: userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

class SurveyPagination {
  final int? total;
  final int? page;
  final int? limit;
  final int? totalPages;

  SurveyPagination({this.total, this.page, this.limit, this.totalPages});

  factory SurveyPagination.fromJson(Map<String, dynamic> json) {
    return SurveyPagination(
      total: _parseInt(json['total']),
      page: _parseInt(json['page']),
      limit: _parseInt(json['limit']),
      totalPages: _parseInt(json['totalPages'] ?? json['pages']),
    );
  }

  bool get hasMore {
    if (totalPages == null || page == null) return true;
    return page! < totalPages!;
  }

  int get nextPage => (page ?? 1) + 1;

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}


