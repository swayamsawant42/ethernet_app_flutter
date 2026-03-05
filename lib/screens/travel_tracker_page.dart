import 'dart:async';
import 'package:flutter/material.dart'; // <-- This is the critical line
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/offline_location_service.dart';

class TravelTrackerPage extends StatefulWidget {
  const TravelTrackerPage({super.key});

  @override
  _TravelTrackerPageState createState() => _TravelTrackerPageState();
}

class _TravelTrackerPageState extends State<TravelTrackerPage> {
  String selectedMenu = 'Tracker';
  String selectedVehicle = 'Own vehicle';
  bool isTracking = false;
  double distance = 0.0;
  String? errorMessage;
  bool locationPermissionGranted = false;
  int unsyncedLocationsCount = 0;
  Timer? _syncStatusTimer;

  GoogleMapController? mapController;
  StreamSubscription<Position>? positionStream;
  Position? lastPosition;
  final ApiService _apiService = ApiService();
  final OfflineLocationService _offlineLocationService = OfflineLocationService();
  DateTime? trackingStartTime;
  String? routeName;
  final TextEditingController _routeController = TextEditingController();
  int? _currentTravelRecordId; // Store the ID from API when starting

  // Initial camera position (Mumbai as default)
  static final CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(19.0760, 72.8777),
    zoom: 14.0,
  );

  List<Map<String, dynamic>> timelineTrips = [];
  List<Map<String, dynamic>> payoutData = [];
  bool isLoadingTimeline = false;
  bool isLoadingPayout = false;
  Map<String, dynamic>? monthlySummary;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _startSyncStatusMonitoring();
    _loadUserProfile();
    _checkForActiveSession();
  }

  /// Check for active session from previous app run (crash recovery)
  Future<void> _checkForActiveSession() async {
    try {
      final activeSession = await _offlineLocationService.getActiveSession();
      if (activeSession != null && mounted) {
        // Show notification about previous session
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text("Previous tracking session found. It will be synced."),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error checking for active session: $e');
    }
  }


  Future<void> _loadUserProfile() async {
    try {
      // Get user ID directly from JWT token
      final userId = await _apiService.getCurrentUserId();
      if (mounted) {
        setState(() {
          _currentUserId = userId;
        });
        // Load data after getting user ID
        _loadTimelineData();
        _loadPayoutData();
      }
    } catch (e) {
      print('Error getting user ID from token: $e');
      // Still try to load data, but it won't be filtered
      if (mounted) {
        _loadTimelineData();
        _loadPayoutData();
      }
    }
  }

  Future<void> _loadTimelineData() async {
    setState(() {
      isLoadingTimeline = true;
    });

    try {
      final records = await _apiService.getOwnTravelRecords();
      if (mounted) {
        setState(() {
          if (records != null && records.isNotEmpty) {
            // Filter records by current user ID
            List<dynamic> filteredRecords = records;
            if (_currentUserId != null) {
              filteredRecords = records.where((record) {
                final recordUserId = record['user_id'];
                final userId = recordUserId is int 
                    ? recordUserId 
                    : int.tryParse('$recordUserId');
                return userId == _currentUserId;
              }).toList();
            }
            
            timelineTrips = filteredRecords.map((record) {
              final date = record['date'] ?? '';
              final distance = (record['distance_km'] ?? 0.0).toDouble();
              final payout = (record['payout'] ?? 0.0).toDouble();
              final vehicleType = record['vehicle_type'] ?? 'Unknown';
              
              // Format date
              String formattedDate = date;
              try {
                if (date.isNotEmpty) {
                  final dateTime = DateTime.parse(date);
                  formattedDate = DateFormat('dd MMM').format(dateTime);
                }
              } catch (e) {
                // Keep original date if parsing fails
              }
              
              // Map vehicle type to display name
              String vehicleDisplay = vehicleType;
              if (vehicleType == 'OWN_VEHICLE') {
                vehicleDisplay = 'Own vehicle';
              } else if (vehicleType == 'COLLEAGUE') {
                vehicleDisplay = 'Colleague';
              } else if (vehicleType == 'COMPANY_VEHICLE') {
                vehicleDisplay = 'Company vehicle';
              }
              
              return {
                'date': formattedDate,
                'distance': distance,
                'payout': payout,
                'vehicle': vehicleDisplay,
              };
            }).toList();
          } else {
            timelineTrips = [];
          }
          isLoadingTimeline = false;
        });
      }
    } catch (e) {
      print('Error loading timeline data: $e');
      if (mounted) {
        setState(() {
          timelineTrips = [];
          isLoadingTimeline = false;
        });
      }
    }
  }

  Future<void> _loadPayoutData() async {
    setState(() {
      isLoadingPayout = true;
    });

    try {
      final now = DateTime.now();
      // Pass current user ID to filter server-side
      final result = await _apiService.getMonthlyTravelRecords(
        month: now.month,
        year: now.year,
        userId: _currentUserId, // Filter by current user
      );
      
      if (mounted) {
        setState(() {
          if (result != null) {
            final records = result['records'] as List<dynamic>? ?? [];
            final summary = result['summary'] as Map<String, dynamic>? ?? {};
            
            // Additional client-side filtering as backup (in case server doesn't filter)
            List<dynamic> filteredRecords = records;
            if (_currentUserId != null) {
              filteredRecords = records.where((record) {
                final recordUserId = record['user_id'];
                final userId = recordUserId is int 
                    ? recordUserId 
                    : int.tryParse('$recordUserId');
                return userId == _currentUserId;
              }).toList();
            }
            
            payoutData = filteredRecords.map((record) {
              final date = record['date'] ?? '';
              final distance = (record['distance_km'] ?? 0.0).toDouble();
              final payout = (record['payout'] ?? 0.0).toDouble();
              final vehicleType = record['vehicle_type'] ?? '';
              
              // Format date
              String formattedDate = date;
              try {
                if (date.isNotEmpty) {
                  final dateTime = DateTime.parse(date);
                  formattedDate = DateFormat('dd MMM').format(dateTime);
                }
              } catch (e) {
                // Keep original date if parsing fails
              }
              
              return {
                'date': formattedDate,
                'km': distance,
                'payout': payout,
                'vehicle_type': vehicleType,
              };
            }).toList();
            
            // Recalculate summary for filtered records only
            if (_currentUserId != null && filteredRecords.isNotEmpty) {
              double totalDistance = 0.0;
              double totalPayout = 0.0;
              for (var record in filteredRecords) {
                totalDistance += (record['distance_km'] ?? 0.0).toDouble();
                totalPayout += (record['payout'] ?? 0.0).toDouble();
              }
              monthlySummary = {
                ...summary,
                'totalDistance': totalDistance,
                'totalPayout': totalPayout,
              };
            } else {
              monthlySummary = summary;
            }
          } else {
            payoutData = [];
            monthlySummary = null;
          }
          isLoadingPayout = false;
        });
      }
    } catch (e) {
      print('Error loading payout data: $e');
      if (mounted) {
        setState(() {
          payoutData = [];
          monthlySummary = null;
          isLoadingPayout = false;
        });
      }
    }
  }

  void _startSyncStatusMonitoring() {
    _updateUnsyncedCount();
    _syncStatusTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _updateUnsyncedCount();
    });
  }

  Future<void> _updateUnsyncedCount() async {
    final count = await _offlineLocationService.getUnsyncedCount();
    if (mounted) {
      setState(() {
        unsyncedLocationsCount = count;
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final status = await Permission.location.status;
      if (mounted) {
        setState(() {
          locationPermissionGranted = status.isGranted;
        });
      }
    } catch (e) {
      print('Error checking location permission: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      if (mounted) {
        setState(() {
          locationPermissionGranted = status.isGranted;
          if (!status.isGranted) {
            errorMessage = 'Location permission is required for tracking';
          }
        });
      }
    } catch (e) {
      print('Error requesting location permission: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Error requesting location permission';
        });
      }
    }
  }

  void toggleTracking() async {
    if (!isTracking) {
      if (!locationPermissionGranted) {
        await _requestLocationPermission();
        if (!locationPermissionGranted) return;
      }
      await startTracking();
    } else {
      stopTracking();
    }
  }

  Future<void> startTracking() async {
    try {
      if (mounted) {
        setState(() {
          errorMessage = null;
        });
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            errorMessage =
                'Location services are disabled. Please enable them.';
          });
        }
        await Geolocator.openLocationSettings();
        // After returning from settings, check again
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;
      }

      final startTime = DateTime.now();
      if (mounted) {
        setState(() {
          isTracking = true;
          distance = 0.0;
          lastPosition = null;
          trackingStartTime = startTime;
          _currentTravelRecordId = null; // Reset for new tracking session
          // Keep route name - user might want to edit it, but we can optionally clear it
          // routeName = null; // Uncomment if you want to clear route on new tracking
        });
      }

      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      ).timeout(Duration(seconds: 10));

      lastPosition = initialPosition;

      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(initialPosition.latitude, initialPosition.longitude),
          ),
        );
      }

      // Start offline location tracking service (this will create a session)
      // This will generate route name if not provided
      await _offlineLocationService.startOfflineTracking(
        routeName: routeName,
        vehicleType: selectedVehicle,
        startTime: startTime,
      );

      // Get the actual route name that was used (may have been generated)
      final actualRouteName = _offlineLocationService.currentRouteName ?? routeName ?? 'Tracked Route';
      if (mounted) {
        setState(() {
          routeName = actualRouteName;
          if (_routeController.text.trim().isEmpty) {
            _routeController.text = actualRouteName;
          }
        });
      }

      // Make POST API call when starting (without id)
      await _createTravelRecordOnStart(startTime, actualRouteName);

      positionStream =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 10, // Update every 10 meters
            ),
          ).listen(
            (Position position) {
              if (lastPosition != null) {
                double distanceInMeters = Geolocator.distanceBetween(
                  lastPosition!.latitude,
                  lastPosition!.longitude,
                  position.latitude,
                  position.longitude,
                );
                if (mounted) {
                  setState(() {
                    distance += distanceInMeters / 1000; // Convert to km
                  });
                }
              }

              lastPosition = position;

              if (mapController != null) {
                mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(position.latitude, position.longitude),
                  ),
                );
              }
            },
            onError: (error) {
              print('Location stream error: $error');
              if (mounted) {
                setState(() {
                  errorMessage = 'Location tracking error: $error';
                });
              }
            },
          );
    } catch (e) {
      print('Error starting tracking: $e');
      if (mounted) {
        setState(() {
          isTracking = false;
          errorMessage = 'Failed to start tracking: ${e.toString()}';
        });
      }
    }
  }

  void stopTracking() async {
    positionStream?.cancel();

    // Get the final distance before stopping
    final finalDistance = distance;
    final finalVehicle = selectedVehicle;
    final endTime = DateTime.now();

    // Stop offline location tracking
    final travelRecordId = await _offlineLocationService.stopOfflineTracking(
      totalDistance: finalDistance,
    );

    if (mounted) {
      setState(() {
        isTracking = false;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text("Travel tracking stopped"),
            ],
          ),
          backgroundColor: Colors.green, // Semantic color is fine
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Update travel record with id if distance > 0
    // If offline, the coordinates are already stored and will sync automatically
    if (finalDistance > 0) {
      // Use travel record ID from offline service if available, otherwise use stored one
      final recordIdToUse = travelRecordId ?? _currentTravelRecordId;
      await _updateTravelRecordOnStop(
        distance: finalDistance,
        vehicleType: finalVehicle,
        travelRecordId: recordIdToUse,
        endTime: endTime,
      );
    }

    // Check for unsynced locations and show status
    final unsyncedCount = await _offlineLocationService.getUnsyncedCount();
    if (unsyncedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$unsyncedCount location(s) stored offline. Will sync when online."),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    _showSummaryPopup();
  }

  /// Create travel record when starting tracking (POST without id)
  Future<void> _createTravelRecordOnStart(DateTime startTime, String? actualRouteName) async {
    try {
      // Format date as YYYY-MM-DD
      final String dateStr = DateFormat('yyyy-MM-dd').format(startTime);

      // Use the actual route name from offline service (ensures consistency)
      final String routeText = actualRouteName ?? 
          (_routeController.text.trim().isNotEmpty
              ? _routeController.text.trim()
              : (routeName?.isNotEmpty == true ? routeName! : 'Tracked Route'));

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text("Starting travel tracking..."),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final result = await _apiService.submitTravelRecord(
        date: dateStr,
        distanceKm: 0.0, // Start with 0 distance
        vehicleType: selectedVehicle,
        route: routeText,
        startedAt: startTime.toIso8601String(),
      );

      if (!mounted) return;

      // Extract travel record ID from response
      if (result != null && !result.containsKey('error')) {
        final recordId = result['id'] as int?;
        if (recordId != null) {
          setState(() {
            _currentTravelRecordId = recordId;
          });
          
          // Update offline service with travel record ID
          await _offlineLocationService.setTravelRecordId(recordId);
          
          print("Travel record created with ID: $recordId");
        }
      } else {
        // Error creating record - will retry on stop
        final errorMsg = result?['message'] ?? 'Failed to create travel record';
        print("Error creating travel record on start: $errorMsg");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text("Tracking started offline. Will sync when online."),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating travel record on start: $e');
      // Continue tracking even if API call fails - will retry on stop
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text("Tracking started offline. Will sync when online."),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Update travel record when stopping (POST with id)
  Future<void> _updateTravelRecordOnStop({
    required double distance,
    required String vehicleType,
    int? travelRecordId,
    required DateTime endTime,
  }) async {
    try {
      // Format date as YYYY-MM-DD
      final String dateStr = DateFormat('yyyy-MM-dd').format(endTime);

      // Use route name from controller or state, otherwise use default
      final String routeText = _routeController.text.trim().isNotEmpty
          ? _routeController.text.trim()
          : (routeName?.isNotEmpty == true ? routeName! : 'Tracked Route');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text("Updating travel record..."),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // If we have a travel record ID, update it; otherwise create new
      // This handles the case where start API failed but tracking continued
      final result = await _apiService.submitTravelRecord(
        date: dateStr,
        distanceKm: distance,
        vehicleType: vehicleType,
        route: routeText,
        id: travelRecordId, // Include id for update (null = create new)
        startedAt: trackingStartTime?.toIso8601String(),
        endedAt: endTime.toIso8601String(),
      );

      if (!mounted) return;

      // Check if result contains an error
      if (result != null && result.containsKey('error') && result['error'] == true) {
        // Error from API - show specific error message
        final errorMessage = result['message'] ?? 'Failed to update travel record';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(errorMessage),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } else if (result != null) {
        // Success - show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text("Travel record updated successfully!")),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Extract payout if available
        if (result.containsKey('payout')) {
          print("Payout: ₹${result['payout']}");
        }
        
        // Refresh timeline and payout data after successful submission
        _loadTimelineData();
        _loadPayoutData();
      } else {
        // Error - show generic error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Failed to update travel record. Please try again.",
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error updating travel record on stop: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text("Error: ${e.toString()}")),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }


  void _showSummaryPopup() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            // Pass theme data to the popup
            return Theme(
              data: Theme.of(context),
              child: TravelSummaryPopup(totalDistance: distance),
            );
          },
        );
      }
    });
  }

  void shareLocation() {
    if (lastPosition != null) {
      String googleMapsUrl =
          'https{""}://maps.google.com/?q=${lastPosition!.latitude},${lastPosition!.longitude}';
      Share.share(
        'Check out my current location:\n$googleMapsUrl\n\nLatitude: ${lastPosition!.latitude.toStringAsFixed(6)}\nLongitude: ${lastPosition!.longitude.toStringAsFixed(6)}',
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not available yet'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _syncStatusTimer?.cancel();
    _offlineLocationService.stopOfflineTracking();
    mapController?.dispose();
    _routeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- Get theme data ---
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    // ---

    final String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      // backgroundColor removed, handled by theme
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        // All styling (background, icon color, title text)
        // is now handled by the appBarTheme in main.dart
        title: Text('Travel Tracker'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
            // Error message (Themed)
            if (errorMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer, // Themed color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error), // Themed color
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: colorScheme.onErrorContainer,
                    ), // Themed
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ), // Themed
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onErrorContainer,
                      ), // Themed
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Sync status indicator
            if (unsyncedLocationsCount > 0)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$unsyncedLocationsCount location(s) pending sync',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _offlineLocationService.syncOfflineLocations();
                        await _updateUnsyncedCount();
                      },
                      child: Text(
                        'Sync Now',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Permission warning (Themed)
            if (!locationPermissionGranted && selectedMenu == "Tracker")
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest, // Themed color
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline,
                  ), // Themed color
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: colorScheme.onSurfaceVariant,
                    ), // Themed
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location permission required for tracking',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ), // Themed
                      ),
                    ),
                    TextButton(
                      onPressed: _requestLocationPermission,
                      child: Text('Grant'), // TextButton will be themed
                    ),
                  ],
                ),
              ),

            // Top menu (Themed)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest, // Themed background
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Tracker', 'Timeline', 'Payout'].map((menu) {
                  bool isSelected = selectedMenu == menu;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMenu = menu;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                      margin: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme
                                  .primary // Themed selected color
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        menu,
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme
                                    .onPrimary // Themed selected text
                              : colorScheme
                                    .onSurfaceVariant, // Themed default text
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 16),

            // Conditional content based on selected menu
            if (selectedMenu == "Tracker") ...[
              // Vehicle selection (Themed)
              Card(
                // cardTheme will be applied
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  // Use DropdownButtonFormField to get theme styling
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Vehicle Type",
                      // Remove the border that inputDecorationTheme adds
                      border: InputBorder.none,
                    ),
                    dropdownColor: Colors.white, // Explicitly white background
                    initialValue: selectedVehicle,
                    isExpanded: true,
                    items:
                        [
                              'Own vehicle',
                              'Colleague',
                              'Company vehicle',
                            ]
                            .map(
                              (vehicle) => DropdownMenuItem(
                                value: vehicle,
                                child: Text(vehicle),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedVehicle = value!;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Route input (only show when not tracking)
              if (!isTracking)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: TextField(
                      controller: _routeController,
                      decoration: InputDecoration(
                        labelText: "Route (optional)",
                        hintText: "e.g., Office to Client Site",
                        prefixIcon: Icon(Icons.route),
                      ),
                      onChanged: (value) {
                        setState(() {
                          routeName = value;
                        });
                      },
                    ),
                  ),
                ),
              SizedBox(height: 16),

              // Travel Tracker Box (Themed)
              Card(
                // cardTheme will be applied
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.map,
                                color: colorScheme.primary,
                              ), // Themed
                              SizedBox(width: 6),
                              Text(
                                'Travel Tracking',
                                style: textTheme.titleMedium, // Themed
                              ),
                            ],
                          ),
                          if (isTracking)
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green, // Semantic color
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${distance.toStringAsFixed(2)} km',
                        style: textTheme.displaySmall, // Themed
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Distance tracked today',
                        style: textTheme.bodyMedium, // Themed
                      ),
                      SizedBox(height: 16),

                      // Start/Stop Button (Themed)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            isTracking ? Icons.stop : Icons.play_arrow,
                          ),
                          onPressed: locationPermissionGranted
                              ? toggleTracking
                              : _requestLocationPermission,
                          // Use elevatedButtonTheme for "Start" (Teal)
                          // Use custom error color for "Stop" (Red)
                          style: isTracking
                              ? ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.error,
                                  foregroundColor: colorScheme.onError,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                )
                              : null, // Null uses the default theme
                          label: Text(
                            locationPermissionGranted
                                ? (isTracking
                                      ? 'Stop Tracking'
                                      : 'Start Tracking')
                                : 'Grant Permission First',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                      // Share button (Themed as OutlinedButton)
                      if (isTracking)
                        Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.share),
                              onPressed: shareLocation,
                              // Style will be pulled from OutlinedButtonTheme
                              label: Text(
                                'Share Current Location',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Google Map (Themed)
              // Use SizedBox with fixed height instead of Expanded for scrollable content
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Card(
                  // cardTheme will be applied (shape, elevation)
                  clipBehavior: Clip
                      .antiAlias, // Clips the Google Map to the Card's shape
                  child: GoogleMap(
                    initialCameraPosition: _kInitialPosition,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                  ),
                ),
              ),
            ] else if (selectedMenu == "Timeline") ...[
              // Timeline content (Themed)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Card(
                  // cardTheme will be applied
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Travel History",
                                  style: textTheme.titleLarge, // Themed
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Your daily travel records",
                                  style: textTheme.bodyMedium, // Themed
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh),
                              onPressed: _loadTimelineData,
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: isLoadingTimeline
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                )
                              : timelineTrips.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.history,
                                            size: 64,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No travel records yet',
                                            style: textTheme.bodyLarge,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView(
                                      children: timelineTrips.map((trip) {
                                        IconData vehicleIcon = Icons.directions_bike;
                                        final vehicle = trip["vehicle"]?.toString().toLowerCase() ?? '';
                                        if (vehicle.contains('car') || vehicle.contains('company')) {
                                          vehicleIcon = Icons.directions_car;
                                        } else if (vehicle.contains('colleague') || vehicle.contains('person')) {
                                          vehicleIcon = Icons.directions_walk;
                                        }

                                        return Card(
                                          // Use nested cards with surfaceVariant
                                          color: colorScheme.surfaceContainerHighest,
                                          elevation: 0,
                                          margin: EdgeInsets.only(bottom: 12),
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  vehicleIcon,
                                                  size: 32,
                                                  color: colorScheme.primary, // Themed
                                                ),
                                                SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      trip["date"]?.toString() ?? '',
                                                      style:
                                                          textTheme.titleSmall, // Themed
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      "${(trip["distance"] as num).toStringAsFixed(2)} km",
                                                      style:
                                                          textTheme.bodyMedium, // Themed
                                                    ),
                                                  ],
                                                ),
                                                Spacer(),
                                                Text(
                                                  "₹${(trip["payout"] as num).toStringAsFixed(2)}",
                                                  style: textTheme.titleMedium?.copyWith(
                                                    color: Colors.green[700], // Semantic
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Payout content (Themed)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Card(
                  // cardTheme will be applied
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Monthly Payout",
                                  style: textTheme.titleLarge, // Themed
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "$currentMonth - ₹${monthlySummary?['ratePerKm'] ?? 3} per km",
                                  style: textTheme.bodyMedium, // Themed
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh),
                              onPressed: _loadPayoutData,
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: isLoadingPayout
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                )
                              : payoutData.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.payments_outlined,
                                            size: 64,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No payout data for this month',
                                            style: textTheme.bodyLarge,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView(
                                      children: [
                                        ...payoutData.map((p) {
                                          final double km = (p['km'] as num).toDouble();
                                          final double payout = (p['payout'] as num).toDouble();
                                          final String vehicleType = p['vehicle_type']?.toString() ?? '';
                                          final ratePerKm = (monthlySummary?['ratePerKm'] ?? 3.0).toDouble();
                                          
                                          // Only show payout calculation for OWN_VEHICLE
                                          final bool isEligible = vehicleType == 'OWN_VEHICLE';
                                          
                                          return Card(
                                            // Use nested cards with surfaceVariant
                                            color: colorScheme.surfaceContainerHighest,
                                            elevation: 0,
                                            margin: EdgeInsets.only(bottom: 12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        p['date']?.toString() ?? '',
                                                        style: textTheme
                                                            .titleSmall, // Themed
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        isEligible
                                                            ? "${km.toStringAsFixed(2)} km × ₹${ratePerKm.toStringAsFixed(0)} = ₹${payout.toStringAsFixed(2)}"
                                                            : "${km.toStringAsFixed(2)} km (${vehicleType == 'COLLEAGUE' ? 'Colleague' : vehicleType == 'COMPANY_VEHICLE' ? 'Company vehicle' : vehicleType}) - Not eligible",
                                                        style: textTheme
                                                            .bodyMedium, // Themed
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    "₹${payout.toStringAsFixed(2)}",
                                                    style: textTheme.titleMedium
                                                        ?.copyWith(
                                                          color: isEligible 
                                                              ? Colors.green[700] 
                                                              : Colors.grey[600], // Semantic
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                        SizedBox(height: 16),
                                        Container(
                                          padding: EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: colorScheme.outline,
                                            ), // Themed
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Total Payout",
                                                style: textTheme.titleMedium, // Themed
                                              ),
                                              Text(
                                                "₹${((monthlySummary?['totalPayout'] ?? 0.0) as num).toStringAsFixed(2)}",
                                                style: textTheme.titleMedium?.copyWith(
                                                  color: Colors.green[700], // Semantic
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- TravelSummaryPopup (Now Themed) ---
class TravelSummaryPopup extends StatelessWidget {
  final double totalDistance;
  const TravelSummaryPopup({super.key, required this.totalDistance});

  @override
  Widget build(BuildContext context) {
    // --- Get theme data ---
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    // ---

    double payout = totalDistance * 3;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ), // Use theme's card shape
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 24), // For centering
                Text(
                  "Travel Summary",
                  style: textTheme.titleLarge, // Themed
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close,
                    color: colorScheme.onSurface,
                  ), // Themed
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Today's travel completed",
              style: textTheme.bodyMedium, // Themed
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest, // Themed
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ), // Semantic
                  SizedBox(height: 16),
                  Text(
                    "${totalDistance.toStringAsFixed(2)} km",
                    style: textTheme.displaySmall, // Themed
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Total distance",
                    style: textTheme.bodyMedium, // Themed
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50], // Semantic
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    "Payout",
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.grey[700],
                    ), // Themed
                  ),
                  SizedBox(height: 8),
                  Text(
                    "₹${payout.toStringAsFixed(2)}",
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.green[700],
                    ), // Themed
                  ),
                  SizedBox(height: 4),
                  Text(
                    "@ ₹3 per km",
                    style: textTheme.bodySmall, // Themed
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                // Style will come from elevatedButtonTheme (Teal)
                // We'll override it to be the primary blue for "Done"
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text("Done", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
