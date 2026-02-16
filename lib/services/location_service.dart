import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../l10n/app_strings.dart';

class LocationService {
  Future<String> getCurrentAddress() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return AppStrings.locationOff;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          return AppStrings.locationNoPermission;
      }
      if (permission == LocationPermission.deniedForever)
        return AppStrings.locationNoPermission;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5), onTimeout: () => <Placemark>[]);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[
          if (place.locality?.isNotEmpty == true) place.locality!,
          if (place.subLocality?.isNotEmpty == true) place.subLocality!,
          if (place.thoroughfare?.isNotEmpty == true) place.thoroughfare!,
        ];
        if (parts.isNotEmpty) return parts.join(' ');
        return place.street ?? AppStrings.locationUnknown;
      }
      return AppStrings.locationUnknown;
    } catch (e) {
      debugPrint('⚠️ 위치 에러: $e');
      return AppStrings.locationError;
    }
  }
}
