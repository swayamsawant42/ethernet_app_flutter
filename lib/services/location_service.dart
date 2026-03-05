import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const String _latitudeKey = 'last_latitude';
  static const String _longitudeKey = 'last_longitude';
  static const String _locationTimestampKey = 'location_timestamp';

  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Cache the location
      await _cacheLocation(position.latitude, position.longitude);

      return position;
    } catch (e) {
      print('LocationService.getCurrentLocation error: $e');
      return null;
    }
  }

  static Future<void> _cacheLocation(double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, latitude);
    await prefs.setDouble(_longitudeKey, longitude);
    await prefs.setInt(_locationTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, double>?> getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);
    final timestamp = prefs.getInt(_locationTimestampKey);

    if (latitude == null || longitude == null || timestamp == null) {
      return null;
    }

    // Return cached location if it's less than 5 minutes old
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age < 5 * 60 * 1000) {
      return {
        'latitude': latitude,
        'longitude': longitude,
      };
    }

    return null;
  }

  static Future<Map<String, double>?> getLocation() async {
    // Try to get fresh location first
    final position = await getCurrentLocation();
    if (position != null) {
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    }

    // Fall back to cached location
    return await getCachedLocation();
  }

  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<void> startBackgroundLocationUpdates() async {
    // This can be extended to use background location updates
    // For now, we'll just ensure we have permission and cache location periodically
    if (await hasLocationPermission()) {
      await getCurrentLocation();
    }
  }
}







