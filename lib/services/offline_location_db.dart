import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Model for storing offline location coordinates
class OfflineLocation {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? routeName;
  final String? vehicleType;
  final double? distanceFromPrevious; // Distance in meters
  final bool synced;
  final int retryCount;
  final int? travelRecordId; // ID from API when travel record is created

  OfflineLocation({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.routeName,
    this.vehicleType,
    this.distanceFromPrevious,
    this.synced = false,
    this.retryCount = 0,
    this.travelRecordId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'route_name': routeName,
      'vehicle_type': vehicleType,
      'distance_from_previous': distanceFromPrevious,
      'synced': synced ? 1 : 0,
      'retry_count': retryCount,
      'travel_record_id': travelRecordId,
    };
  }

  factory OfflineLocation.fromMap(Map<String, dynamic> map) {
    return OfflineLocation(
      id: map['id'] as int?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
      routeName: map['route_name'] as String?,
      vehicleType: map['vehicle_type'] as String?,
      distanceFromPrevious: map['distance_from_previous'] as double?,
      synced: (map['synced'] as int) == 1,
      retryCount: map['retry_count'] as int? ?? 0,
      travelRecordId: map['travel_record_id'] as int?,
    );
  }
}

/// Model for storing travel tracking sessions
class TravelTrackingSession {
  final int? id;
  final int? travelRecordId; // ID from API
  final String routeName;
  final String vehicleType;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistance; // in km
  final String date; // YYYY-MM-DD
  final bool synced;

  TravelTrackingSession({
    this.id,
    this.travelRecordId,
    required this.routeName,
    required this.vehicleType,
    required this.startTime,
    this.endTime,
    this.totalDistance = 0.0,
    required this.date,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'travel_record_id': travelRecordId,
      'route_name': routeName,
      'vehicle_type': vehicleType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'total_distance': totalDistance,
      'date': date,
      'synced': synced ? 1 : 0,
    };
  }

  factory TravelTrackingSession.fromMap(Map<String, dynamic> map) {
    return TravelTrackingSession(
      id: map['id'] as int?,
      travelRecordId: map['travel_record_id'] as int?,
      routeName: map['route_name'] as String,
      vehicleType: map['vehicle_type'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      totalDistance: (map['total_distance'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] as String,
      synced: (map['synced'] as int) == 1,
    );
  }
}

/// Database helper for offline location storage
class OfflineLocationDB {
  static final OfflineLocationDB _instance = OfflineLocationDB._internal();
  factory OfflineLocationDB() => _instance;
  OfflineLocationDB._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'offline_locations.db');
    return await openDatabase(
      path,
      version: 2, // Increment version for schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_locations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        route_name TEXT,
        vehicle_type TEXT,
        distance_from_previous REAL,
        synced INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        travel_record_id INTEGER
      )
    ''');

    // Create travel tracking sessions table
    await db.execute('''
      CREATE TABLE travel_tracking_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        travel_record_id INTEGER,
        route_name TEXT NOT NULL,
        vehicle_type TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        total_distance REAL NOT NULL DEFAULT 0.0,
        date TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_synced ON offline_locations(synced)
    ''');
    await db.execute('''
      CREATE INDEX idx_timestamp ON offline_locations(timestamp)
    ''');
    await db.execute('''
      CREATE INDEX idx_travel_record_id ON offline_locations(travel_record_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_sessions_synced ON travel_tracking_sessions(synced)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add travel_record_id column to offline_locations
      await db.execute('''
        ALTER TABLE offline_locations ADD COLUMN travel_record_id INTEGER
      ''');

      // Create travel tracking sessions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS travel_tracking_sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          travel_record_id INTEGER,
          route_name TEXT NOT NULL,
          vehicle_type TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          total_distance REAL NOT NULL DEFAULT 0.0,
          date TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Create new indexes
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_travel_record_id ON offline_locations(travel_record_id)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_sessions_synced ON travel_tracking_sessions(synced)
      ''');
    }
  }

  /// Insert a new location coordinate
  Future<int> insertLocation(OfflineLocation location) async {
    final db = await database;
    return await db.insert('offline_locations', location.toMap());
  }

  /// Get all unsynced locations
  Future<List<OfflineLocation>> getUnsyncedLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_locations',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => OfflineLocation.fromMap(maps[i]));
  }

  /// Get all locations for a specific route/tracking session
  Future<List<OfflineLocation>> getLocationsByRoute(String? routeName) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_locations',
      where: 'route_name = ?',
      whereArgs: [routeName],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => OfflineLocation.fromMap(maps[i]));
  }

  /// Get all unique route names for today
  Future<List<String>> getTodayRouteNames() async {
    final db = await database;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_locations',
      columns: ['DISTINCT route_name'],
      where: 'route_name IS NOT NULL AND timestamp >= ? AND timestamp < ?',
      whereArgs: [todayStart.toIso8601String(), todayEnd.toIso8601String()],
    );
    
    return maps
        .map((m) => m['route_name'] as String?)
        .whereType<String>()
        .toList();
  }

  /// Get all locations for today
  Future<List<OfflineLocation>> getTodayLocations() async {
    final db = await database;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(Duration(days: 1));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_locations',
      where: 'timestamp >= ? AND timestamp < ?',
      whereArgs: [todayStart.toIso8601String(), todayEnd.toIso8601String()],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => OfflineLocation.fromMap(maps[i]));
  }

  /// Mark locations as synced
  Future<int> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    return await db.update(
      'offline_locations',
      {'synced': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// Increment retry count for failed syncs
  Future<int> incrementRetryCount(int id) async {
    final db = await database;
    final location = await db.query(
      'offline_locations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (location.isEmpty) return 0;
    
    final currentRetry = location.first['retry_count'] as int? ?? 0;
    return await db.update(
      'offline_locations',
      {'retry_count': currentRetry + 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete synced locations older than specified days
  Future<int> deleteOldSyncedLocations(int daysOld) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return await db.delete(
      'offline_locations',
      where: 'synced = ? AND timestamp < ?',
      whereArgs: [1, cutoffDate.toIso8601String()],
    );
  }

  /// Get count of unsynced locations
  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM offline_locations WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Delete all locations (for testing/cleanup)
  Future<int> deleteAllLocations() async {
    final db = await database;
    return await db.delete('offline_locations');
  }

  /// Insert a travel tracking session
  Future<int> insertTravelSession(TravelTrackingSession session) async {
    final db = await database;
    return await db.insert('travel_tracking_sessions', session.toMap());
  }

  /// Get active travel tracking session (not synced and no end_time)
  Future<TravelTrackingSession?> getActiveSession() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'travel_tracking_sessions',
      where: 'synced = ? AND end_time IS NULL',
      whereArgs: [0],
      orderBy: 'start_time DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return TravelTrackingSession.fromMap(maps.first);
  }

  /// Update travel tracking session
  Future<int> updateTravelSession(TravelTrackingSession session) async {
    if (session.id == null) return 0;
    final db = await database;
    return await db.update(
      'travel_tracking_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Get all unsynced travel sessions
  Future<List<TravelTrackingSession>> getUnsyncedSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'travel_tracking_sessions',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'start_time ASC',
    );
    return List.generate(maps.length, (i) => TravelTrackingSession.fromMap(maps[i]));
  }

  /// Mark travel session as synced
  Future<int> markSessionAsSynced(int sessionId) async {
    final db = await database;
    return await db.update(
      'travel_tracking_sessions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// Update travel record ID for locations in a session
  Future<int> updateLocationsTravelRecordId(String routeName, int travelRecordId) async {
    final db = await database;
    return await db.update(
      'offline_locations',
      {'travel_record_id': travelRecordId},
      where: 'route_name = ? AND travel_record_id IS NULL',
      whereArgs: [routeName],
    );
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}







