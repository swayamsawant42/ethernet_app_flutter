import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_location_db.dart';
import 'api_service.dart';

/// Service for managing offline location tracking and syncing
class OfflineLocationService {
  static final OfflineLocationService _instance = OfflineLocationService._internal();
  factory OfflineLocationService() => _instance;
  OfflineLocationService._internal();

  final OfflineLocationDB _db = OfflineLocationDB();
  final ApiService _apiService = ApiService();
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isTracking = false;
  String? _currentRouteName;
  String? _currentVehicleType;
  Position? _lastStoredPosition;
  TravelTrackingSession? _currentSession;
  final int _minDistanceMeters = 10; // Store location every 10 meters
  final int _syncIntervalSeconds = 30; // Sync every 30 seconds when online

  /// Start tracking location and storing coordinates offline
  /// Returns the travel record ID if API call succeeds, null otherwise
  Future<int?> startOfflineTracking({
    String? routeName,
    String? vehicleType,
    DateTime? startTime,
  }) async {
    if (_isTracking) {
      print('OfflineLocationService: Already tracking');
      return _currentSession?.travelRecordId;
    }

    // Check for active session (app crash recovery)
    final activeSession = await _db.getActiveSession();
    if (activeSession != null) {
      print('OfflineLocationService: Found active session from previous run, ending it first');
      // End the previous session (mark as ended but not synced)
      final endedSession = TravelTrackingSession(
        id: activeSession.id,
        travelRecordId: activeSession.travelRecordId,
        routeName: activeSession.routeName,
        vehicleType: activeSession.vehicleType,
        startTime: activeSession.startTime,
        endTime: DateTime.now(),
        totalDistance: activeSession.totalDistance,
        date: activeSession.date,
        synced: false,
      );
      await _db.updateTravelSession(endedSession);
    }

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Generate route name if not provided (Route 1, Route 2, etc.)
    if (routeName == null || routeName.isEmpty) {
      // Get count of routes for today to generate route number
      final todayRouteNames = await _db.getTodayRouteNames();
      final routeCount = todayRouteNames.length + 1;
      routeName = 'Route $routeCount';
    }

    _currentRouteName = routeName;
    _currentVehicleType = vehicleType ?? 'Own vehicle';
    _isTracking = true;
    _lastStoredPosition = null;

    // Create travel tracking session
    _currentSession = TravelTrackingSession(
      routeName: routeName,
      vehicleType: _currentVehicleType!,
      startTime: startTime ?? now,
      date: dateStr,
      totalDistance: 0.0,
      synced: false,
    );
    
    final sessionId = await _db.insertTravelSession(_currentSession!);
    _currentSession = TravelTrackingSession(
      id: sessionId,
      routeName: routeName,
      vehicleType: _currentVehicleType!,
      startTime: startTime ?? now,
      date: dateStr,
      totalDistance: 0.0,
      synced: false,
    );

    // Store route name for consistency
    _currentRouteName = routeName;

    // Check location permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission not granted');
    }

    // Get initial position
    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(Duration(seconds: 10));
      
      await _storeLocation(initialPosition);
      _lastStoredPosition = initialPosition;
    } catch (e) {
      print('OfflineLocationService: Error getting initial position: $e');
    }

    // Start position stream with battery-optimized settings
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.medium, // Medium for battery efficiency
        distanceFilter: _minDistanceMeters, // Only update when moved 10m
        timeLimit: Duration(seconds: 30), // Timeout after 30s
      ),
    ).listen(
      (Position position) async {
        if (!_isTracking) return;

        // Calculate distance from last stored position
        double? distanceFromPrevious;
        if (_lastStoredPosition != null) {
          distanceFromPrevious = Geolocator.distanceBetween(
            _lastStoredPosition!.latitude,
            _lastStoredPosition!.longitude,
            position.latitude,
            position.longitude,
          );
        }

        // Store location if moved enough or it's the first one
        if (_lastStoredPosition == null || 
            (distanceFromPrevious != null && distanceFromPrevious >= _minDistanceMeters)) {
          await _storeLocation(position, distanceFromPrevious: distanceFromPrevious);
          _lastStoredPosition = position;
        }
      },
      onError: (error) {
        print('OfflineLocationService: Position stream error: $error');
      },
    );

    // Start connectivity monitoring
    _startConnectivityMonitoring();

    // Start periodic sync
    _startPeriodicSync();

    print('OfflineLocationService: Started offline tracking');
    
    // Return the travel record ID if available (may be null if API call hasn't completed yet)
    return _currentSession?.travelRecordId;
  }

  /// Stop tracking location
  /// Returns the travel record ID if available
  Future<int?> stopOfflineTracking({double? totalDistance}) async {
    if (!_isTracking) return _currentSession?.travelRecordId;

    _isTracking = false;
    _positionStream?.cancel();
    _positionStream = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _lastStoredPosition = null;

    // Update session with end time and distance
    if (_currentSession != null) {
      final updatedSession = TravelTrackingSession(
        id: _currentSession!.id,
        travelRecordId: _currentSession!.travelRecordId,
        routeName: _currentSession!.routeName,
        vehicleType: _currentSession!.vehicleType,
        startTime: _currentSession!.startTime,
        endTime: DateTime.now(),
        totalDistance: totalDistance ?? _currentSession!.totalDistance,
        date: _currentSession!.date,
        synced: _currentSession!.synced,
      );
      await _db.updateTravelSession(updatedSession);
      _currentSession = updatedSession;
    }

    // Final sync attempt
    await syncOfflineLocations();

    final travelRecordId = _currentSession?.travelRecordId;
    _currentSession = null;

    print('OfflineLocationService: Stopped offline tracking');
    return travelRecordId;
  }

  /// Set travel record ID for current session
  Future<void> setTravelRecordId(int travelRecordId) async {
    if (_currentSession != null) {
      final updatedSession = TravelTrackingSession(
        id: _currentSession!.id,
        travelRecordId: travelRecordId,
        routeName: _currentSession!.routeName,
        vehicleType: _currentSession!.vehicleType,
        startTime: _currentSession!.startTime,
        endTime: _currentSession!.endTime,
        totalDistance: _currentSession!.totalDistance,
        date: _currentSession!.date,
        synced: _currentSession!.synced,
      );
      await _db.updateTravelSession(updatedSession);
      _currentSession = updatedSession;
      
      // Update locations with travel record ID
      if (_currentRouteName != null) {
        await _db.updateLocationsTravelRecordId(_currentRouteName!, travelRecordId);
      }
    }
  }

  /// Get current travel record ID
  int? get currentTravelRecordId => _currentSession?.travelRecordId;

  /// Get current route name
  String? get currentRouteName => _currentRouteName;

  /// Store a location coordinate in the database
  Future<void> _storeLocation(
    Position position, {
    double? distanceFromPrevious,
  }) async {
    try {
      final location = OfflineLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        routeName: _currentRouteName,
        vehicleType: _currentVehicleType,
        distanceFromPrevious: distanceFromPrevious,
        synced: false,
        travelRecordId: _currentSession?.travelRecordId,
      );

      await _db.insertLocation(location);
      
      // Update session distance if applicable
      if (_currentSession != null && distanceFromPrevious != null) {
        final newDistance = _currentSession!.totalDistance + (distanceFromPrevious / 1000);
        final updatedSession = TravelTrackingSession(
          id: _currentSession!.id,
          travelRecordId: _currentSession!.travelRecordId,
          routeName: _currentSession!.routeName,
          vehicleType: _currentSession!.vehicleType,
          startTime: _currentSession!.startTime,
          endTime: _currentSession!.endTime,
          totalDistance: newDistance,
          date: _currentSession!.date,
          synced: _currentSession!.synced,
        );
        await _db.updateTravelSession(updatedSession);
        _currentSession = updatedSession;
      }
      
      print('OfflineLocationService: Stored location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('OfflineLocationService: Error storing location: $e');
    }
  }

  /// Start monitoring network connectivity
  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (ConnectivityResult result) async {
        final isOnline = result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet;

        if (isOnline) {
          print('OfflineLocationService: Network available, syncing...');
          await syncOfflineLocations();
        } else {
          print('OfflineLocationService: Network unavailable');
        }
      },
    );
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(seconds: _syncIntervalSeconds),
      (_) async {
        await syncOfflineLocations();
      },
    );
  }

  /// Sync offline locations to backend
  Future<void> syncOfflineLocations() async {
    try {
      // Check if online
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet;

      if (!isOnline) {
        print('OfflineLocationService: Offline, skipping sync');
        return;
      }

      // Get unsynced locations
      final unsyncedLocations = await _db.getUnsyncedLocations();
      if (unsyncedLocations.isEmpty) {
        print('OfflineLocationService: No unsynced locations');
        return;
      }

      print('OfflineLocationService: Syncing ${unsyncedLocations.length} locations');

      // Group locations by route for batch upload
      final Map<String?, List<OfflineLocation>> locationsByRoute = {};
      for (var location in unsyncedLocations) {
        final routeKey = location.routeName ?? 'unknown';
        if (!locationsByRoute.containsKey(routeKey)) {
          locationsByRoute[routeKey] = [];
        }
        locationsByRoute[routeKey]!.add(location);
      }

      // Upload each route's coordinates
      for (var entry in locationsByRoute.entries) {
        final routeName = entry.key;
        final locations = entry.value;
        
        if (locations.isEmpty) continue;

        try {
          // Calculate total distance for this route
          double totalDistance = 0.0;
          for (var loc in locations) {
            if (loc.distanceFromPrevious != null) {
              totalDistance += loc.distanceFromPrevious! / 1000; // Convert to km
            }
          }

          // Get vehicle type from first location
          final vehicleType = locations.first.vehicleType ?? 'Vehicle 1';
          
          // Get date from first location
          final date = locations.first.timestamp;

          // Upload coordinates to backend
          final success = await _uploadCoordinates(
            locations: locations,
            routeName: routeName == 'unknown' ? null : routeName,
            vehicleType: vehicleType,
            date: date,
            totalDistance: totalDistance,
          );

          if (success) {
            // Mark as synced
            final ids = locations.map((l) => l.id!).whereType<int>().toList();
            await _db.markAsSynced(ids);
            print('OfflineLocationService: Successfully synced ${ids.length} locations');
          } else {
            // Increment retry count for failed locations
            for (var location in locations) {
              if (location.id != null) {
                await _db.incrementRetryCount(location.id!);
              }
            }
            print('OfflineLocationService: Failed to sync locations, will retry');
          }
        } catch (e) {
          print('OfflineLocationService: Error syncing route $routeName: $e');
          // Increment retry count
          for (var location in locations) {
            if (location.id != null) {
              await _db.incrementRetryCount(location.id!);
            }
          }
        }
      }

      // Sync unsynced travel sessions
      await _syncTravelSessions();

      // Clean up old synced locations (older than 7 days)
      await _db.deleteOldSyncedLocations(7);
    } catch (e) {
      print('OfflineLocationService: Error in syncOfflineLocations: $e');
    }
  }

  /// Sync unsynced travel sessions
  Future<void> _syncTravelSessions() async {
    try {
      final unsyncedSessions = await _db.getUnsyncedSessions();
      if (unsyncedSessions.isEmpty) {
        return;
      }

      print('OfflineLocationService: Syncing ${unsyncedSessions.length} travel sessions');

      for (var session in unsyncedSessions) {
        try {
          // Get locations for this session
          final locations = await _db.getLocationsByRoute(session.routeName);
          
          // Prepare coordinates array
          final coordinates = locations.map((loc) => {
            'lat': loc.latitude,
            'lng': loc.longitude,
          }).toList();

          // Prepare route structure with stops and path (matching API format)
          final routeData = <String, dynamic>{
            'stops': locations.isNotEmpty ? [
              {
                'name': 'Start',
                'address': 'Starting point',
                'start_time': session.startTime.toIso8601String(),
                'position': {
                  'lat': locations.first.latitude,
                  'lng': locations.first.longitude,
                },
              },
              if (locations.length > 1)
                {
                  'name': 'End',
                  'address': 'Ending point',
                  'start_time': session.endTime?.toIso8601String() ?? session.startTime.toIso8601String(),
                  'end_time': session.endTime?.toIso8601String(),
                  'position': {
                    'lat': locations.last.latitude,
                    'lng': locations.last.longitude,
                  },
                },
            ] : [],
            'path': coordinates,
          };

          // Submit travel record
          final result = await _apiService.submitTravelRecord(
            date: session.date,
            distanceKm: session.totalDistance,
            vehicleType: session.vehicleType,
            route: routeData, // Send as JSON object
            id: session.travelRecordId, // Include id if available for update
            startedAt: session.startTime.toIso8601String(),
            endedAt: session.endTime?.toIso8601String(),
          );

          if (result != null && !result.containsKey('error')) {
            // Mark session as synced
            if (session.id != null) {
              await _db.markSessionAsSynced(session.id!);
            }
            
            // Update travel record ID if we got one back
            final recordId = result['id'] as int?;
            if (recordId != null && session.id != null) {
              final updatedSession = TravelTrackingSession(
                id: session.id,
                travelRecordId: recordId,
                routeName: session.routeName,
                vehicleType: session.vehicleType,
                startTime: session.startTime,
                endTime: session.endTime,
                totalDistance: session.totalDistance,
                date: session.date,
                synced: true,
              );
              await _db.updateTravelSession(updatedSession);
              
              // Update locations with travel record ID
              await _db.updateLocationsTravelRecordId(session.routeName, recordId);
            }
            
            print('OfflineLocationService: Successfully synced session ${session.id}');
          }
        } catch (e) {
          print('OfflineLocationService: Error syncing session ${session.id}: $e');
        }
      }
    } catch (e) {
      print('OfflineLocationService: Error in _syncTravelSessions: $e');
    }
  }

  /// Upload coordinates to backend
  Future<bool> _uploadCoordinates({
    required List<OfflineLocation> locations,
    String? routeName,
    required String vehicleType,
    required DateTime date,
    required double totalDistance,
  }) async {
    try {
      // Prepare coordinates array
      final coordinates = locations.map((loc) => {
        'latitude': loc.latitude,
        'longitude': loc.longitude,
        'timestamp': loc.timestamp.toIso8601String(),
      }).toList();

      // Format date as YYYY-MM-DD
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Try to upload coordinates first (if API supports it)
      try {
        final coordinateResult = await _apiService.uploadTravelCoordinates(
          date: dateStr,
          route: routeName ?? 'Offline Track',
          vehicleType: vehicleType,
          totalDistance: totalDistance,
          coordinates: coordinates,
        );
        
        if (coordinateResult != null) {
          return true;
        }
      } catch (e) {
        print('OfflineLocationService: Coordinate upload endpoint not available, falling back to travel record: $e');
      }

      // Fallback to regular travel record submission with coordinates
      final result = await _apiService.submitTravelRecord(
        date: dateStr,
        distanceKm: totalDistance,
        vehicleType: vehicleType,
        route: routeName ?? 'Offline Track',
        coordinates: coordinates,
      );

      return result != null;
    } catch (e) {
      print('OfflineLocationService: Error uploading coordinates: $e');
      return false;
    }
  }

  /// Get count of unsynced locations
  Future<int> getUnsyncedCount() async {
    return await _db.getUnsyncedCount();
  }

  /// Get all locations for a route
  Future<List<OfflineLocation>> getLocationsByRoute(String? routeName) async {
    return await _db.getLocationsByRoute(routeName);
  }

  /// Get active session (for crash recovery)
  Future<TravelTrackingSession?> getActiveSession() async {
    return await _db.getActiveSession();
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Dispose resources
  Future<void> dispose() async {
    await stopOfflineTracking();
    await _db.close();
  }
}
