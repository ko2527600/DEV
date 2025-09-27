import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:developer' as developer;

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      developer.log('Error checking location service: $e', name: 'LocationService');
      return false;
    }
  }

  // Check location permissions
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      developer.log('Error checking permission: $e', name: 'LocationService');
      return LocationPermission.denied;
    }
  }

  // Request location permissions
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission();
    } catch (e) {
      developer.log('Error requesting permission: $e', name: 'LocationService');
      return LocationPermission.denied;
    }
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location service is enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        developer.log('Location service is disabled', name: 'LocationService');
        return null;
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          developer.log('Location permission denied', name: 'LocationService');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('Location permission denied forever', name: 'LocationService');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      developer.log('Error getting current position: $e', name: 'LocationService');
      return null;
    }
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      developer.log('Error getting last known position: $e', name: 'LocationService');
      return null;
    }
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.locality}, ${placemark.administrativeArea}';
      }
      return null;
    } catch (e) {
      developer.log('Error getting address: $e', name: 'LocationService');
      return null;
    }
  }

  // Get coordinates from address
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      developer.log('Error getting coordinates: $e', name: 'LocationService');
      return null;
    }
  }

  // Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
    } catch (e) {
      developer.log('Error calculating distance: $e', name: 'LocationService');
      return 0.0;
    }
  }

  // Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  // Get location stream for real-time updates
  Stream<Position> getPositionStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      );
    } catch (e) {
      developer.log('Error getting position stream: $e', name: 'LocationService');
      return Stream.empty();
    }
  }

  // Check if location is within radius
  bool isWithinRadius({
    required double centerLatitude,
    required double centerLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusInMeters,
  }) {
    try {
      final distance = calculateDistance(
        centerLatitude,
        centerLongitude,
        targetLatitude,
        targetLongitude,
      );
      return distance <= radiusInMeters;
    } catch (e) {
      developer.log('Error checking radius: $e', name: 'LocationService');
      return false;
    }
  }

  // Get nearby locations within radius
  List<Map<String, dynamic>> getNearbyLocations({
    required double centerLatitude,
    required double centerLongitude,
    required double radiusInMeters,
    required List<Map<String, dynamic>> locations,
  }) {
    try {
      return locations.where((location) {
        final lat = location['latitude'] as double?;
        final lng = location['longitude'] as double?;
        
        if (lat == null || lng == null) return false;
        
        return isWithinRadius(
          centerLatitude: centerLatitude,
          centerLongitude: centerLongitude,
          targetLatitude: lat,
          targetLongitude: lng,
          radiusInMeters: radiusInMeters,
        );
      }).toList();
    } catch (e) {
      developer.log('Error getting nearby locations: $e', name: 'LocationService');
      return [];
    }
  }
}
