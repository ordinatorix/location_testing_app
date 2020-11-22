import 'package:flutter/foundation.dart';

class DeviceLocation {
  final double latitude;
  final double longitude;
  final String address;
  final double accuracy;
  final double speed;
  final double altitude;

  const DeviceLocation({
    @required this.latitude,
    @required this.longitude,
    this.address,
    @required this.accuracy,
    this.speed,
    this.altitude,
  });

  @override
  String toString() {
    return 'Lat: ${latitude.toStringAsFixed(4)}, Long: ${longitude.toStringAsFixed(4)}, acc: ${accuracy.toStringAsFixed(4)}, spd: ${speed.toStringAsFixed(4)}, alt: ${altitude.toStringAsFixed(4)}';
  }
}
