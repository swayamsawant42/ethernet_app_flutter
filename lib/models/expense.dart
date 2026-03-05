import 'dart:convert';

class ExpenseListResponse {
  final List<Expense> expenses;
  final Pagination? pagination;

  ExpenseListResponse({required this.expenses, this.pagination});

  factory ExpenseListResponse.fromResponse(dynamic data) {
    List<dynamic> rawExpenses = [];
    Map<String, dynamic>? paginationMap;

    void extract(dynamic node) {
      if (node == null) return;
      if (node is List && rawExpenses.isEmpty) {
        rawExpenses = node;
      } else if (node is Map<String, dynamic>) {
        if (node['expenses'] is List && rawExpenses.isEmpty) {
          rawExpenses = node['expenses'] as List<dynamic>;
        }
        if (paginationMap == null && node['pagination'] is Map) {
          paginationMap =
              Map<String, dynamic>.from(node['pagination'] as Map<dynamic, dynamic>);
        }
        if (node.containsKey('data') && rawExpenses.isEmpty) {
          extract(node['data']);
        }
      }
    }

    extract(data);

    final expenses = rawExpenses
        .whereType<Map>()
        .map((json) => Expense.fromJson(Map<String, dynamic>.from(json)))
        .toList();

    return ExpenseListResponse(
      expenses: expenses,
      pagination:
          paginationMap != null ? Pagination.fromJson(paginationMap!) : null,
    );
  }
}

class Expense {
  final int? id;
  final String? category;
  final String? status;
  final double amount;
  final double? distanceTravelled;
  final DateTime? date;
  final ExpenseUser? user;
  final List<String> billImages;
  final int? userId;

  Expense({
    this.id,
    this.category,
    this.status,
    required this.amount,
    this.distanceTravelled,
    this.date,
    this.user,
    this.billImages = const [],
    this.userId,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final userData = json['user'];
    return Expense(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      category: json['category']?.toString(),
      status: json['status']?.toString(),
      amount: _parseDouble(json['amount']),
      distanceTravelled: _parseDouble(json['distanceTravelled']),
      date: _parseDate(
        json['date'] ??
            json['createdAt'] ??
            json['created_at'] ??
            json['updatedAt'] ??
            json['updated_at'],
      ),
      user: ExpenseUser.fromDynamic(userData),
      billImages: _parseImages(json['billImages']),
      userId: _parseInt(
        json['userId'] ?? json['user_id'] ?? (userData is Map ? userData['id'] : null),
      ),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    
    try {
      final valueStr = value.toString().trim();
      if (valueStr.isEmpty) return null;
      
      // Try parsing as ISO 8601 format (most common)
      try {
        return DateTime.parse(valueStr);
      } catch (_) {
        // If that fails, try other formats
      }
      
      // Try parsing MySQL datetime format: "YYYY-MM-DD HH:MM:SS"
      if (valueStr.contains(' ') && valueStr.length >= 19) {
        try {
          final parts = valueStr.split(' ');
          if (parts.length == 2) {
            final datePart = parts[0];
            final timePart = parts[1];
            return DateTime.parse('${datePart}T${timePart}');
          }
        } catch (_) {
          // Continue to next format
        }
      }
      
      // Try parsing date only: "YYYY-MM-DD"
      if (valueStr.length == 10 && valueStr.contains('-')) {
        try {
          return DateTime.parse('${valueStr}T00:00:00');
        } catch (_) {
          // Continue
        }
      }
      
      // Last resort: try parsing as milliseconds since epoch
      final numValue = int.tryParse(valueStr);
      if (numValue != null && numValue > 0) {
        try {
          // Check if it's in seconds (10 digits) or milliseconds (13 digits)
          if (valueStr.length == 10) {
            return DateTime.fromMillisecondsSinceEpoch(numValue * 1000);
          } else if (valueStr.length == 13) {
            return DateTime.fromMillisecondsSinceEpoch(numValue);
          }
        } catch (_) {
          // Continue
        }
      }
      
      return null;
    } catch (_) {
      return null;
    }
  }

  static List<String> _parseImages(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    // Handle stringified JSON arrays coming from the API
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          // fall through to default handling
        }
      }
      return [trimmed];
    }

    return [value.toString()];
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String get statusLabel =>
      (status ?? 'PENDING').replaceAll('_', ' ').toUpperCase();
}

class ExpenseUser {
  final String? name;
  final String? employeCode;
  final String? employeeId;
  final int? id;

  ExpenseUser({this.name, this.employeCode, this.employeeId, this.id});

  factory ExpenseUser.fromDynamic(dynamic data) {
    if (data == null) return ExpenseUser();

    Map<String, dynamic>? map;
    if (data is Map<String, dynamic>) {
      map = data;
    } else if (data is String) {
      var cleaned = data.trim();
      if (cleaned.isNotEmpty) {
        // Handle triple-escaped strings: "\"{\\\"employeCode\\\":\\\"...\\\"}\""
        // Step 1: Strip outer quotes if present
        while (cleaned.length >= 2 &&
            cleaned.startsWith('"') &&
            cleaned.endsWith('"')) {
          cleaned = cleaned.substring(1, cleaned.length - 1);
        }

        // Step 2: Try to decode directly first (in case it's already valid JSON)
        try {
          final decoded = jsonDecode(cleaned);
          if (decoded is Map<String, dynamic>) {
            map = decoded;
          } else if (decoded is String) {
            // If decoded result is still a string, try decoding again
            cleaned = decoded;
            final decoded2 = jsonDecode(cleaned);
            if (decoded2 is Map<String, dynamic>) {
              map = decoded2;
            }
          }
        } catch (_) {
          // If direct decode fails, try normalizing escaped quotes
          try {
            // Replace escaped quotes: \" -> "
            final normalized = cleaned.replaceAll(r'\"', '"');
            final decoded = jsonDecode(normalized);
            if (decoded is Map<String, dynamic>) {
              map = decoded;
            }
          } catch (_) {
            // If that also fails, try one more time with double normalization
            try {
              final normalized2 = cleaned.replaceAll(r'\\"', '"').replaceAll(r'\"', '"');
              final decoded = jsonDecode(normalized2);
              if (decoded is Map<String, dynamic>) {
                map = decoded;
              }
            } catch (_) {
              // All parsing attempts failed
              print('Failed to parse ExpenseUser from: $data');
            }
          }
        }
      }
    }

    if (map == null) return ExpenseUser();

    return ExpenseUser(
      name: map['name']?.toString(),
      employeCode: map['employeCode']?.toString(),
      employeeId: map['employeeId']?.toString(),
      id: map['id'] is int ? map['id'] as int : int.tryParse('${map['id']}'),
    );
  }

  String get displayName =>
      name ?? employeCode ?? employeeId ?? 'Unknown Employee';
}

class Pagination {
  final int? page;
  final int? limit;
  final int? totalPages;
  final int? totalItems;

  Pagination({this.page, this.limit, this.totalPages, this.totalItems});

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: _parseInt(json['page']),
      limit: _parseInt(json['limit']),
      totalPages: _parseInt(json['totalPages']) ?? _parseInt(json['total_pages']),
      totalItems: _parseInt(json['totalItems']) ?? _parseInt(json['total']),
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

