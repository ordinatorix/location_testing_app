import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../logger.dart';
import '../models/location_model.dart';

final log = getLogger('LocationService');

class LocationService {
  StreamController<DeviceLocation> _locationController =
      StreamController<DeviceLocation>.broadcast();

  Stream<DeviceLocation> get locationStream => _locationController.stream;

  StreamSubscription locationStreamer;

  Completer locationStatus = Completer<bool>();

  /// Stream user current location
  LocationService() {
    log.i('locationServiceConstructor ');

    // is permission given?

    checkLocationServiceStatus().then((value) {
      log.d('waiting for future to complete');
      locationStatus.future.then((greenLight) {
        if (greenLight) {
          locationStreamer = _streamLocation();
        } else {
          log.w('You are shit out of luck');
        }
      });
    });
  }

  /// Dispose of location service.
  ///
  /// Closes any active controllers.
  void dispose() {
    _locationController?.close();
    log.d('Location controller closed');
  }

  /// Get current user location.
  Future<DeviceLocation> getCurrentUserLocation() async {
    log.i('getCurrentUserLocation');
    try {
      Position position;
      // check the status of location service

      bool locationEnabled = await Geolocator.isLocationServiceEnabled();

      if (locationEnabled) {
        // check for current location
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        log.d(
            'current user position: (${position.latitude}, ${position.longitude} @ ${position.timestamp})');
      }

      final location = DeviceLocation(
        accuracy: position.accuracy,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        altitude: position.altitude,
      );

      return location;
    } catch (error) {
      log.e('error getting user location: $error');
      return DeviceLocation(
        latitude: 0.0,
        longitude: 0.0,
        accuracy: 0.0,
      );
    }
  }

  void _isLocationActive() async {
    log.i('_isLocationActive');

    log.d('checking location service status');
    bool result = await Geolocator.isLocationServiceEnabled();

    if (result) {
      log.d('location is enabled?: $result');
      // complete with true
      locationStatus.complete(result);
    } else {
      log.d('location is enabled?: $result');
      Future.delayed(Duration(seconds: 1), () {
        log.d('waited half a second');
        _isLocationActive();
      });
    }
  }

  bool justDenied = false;
  Future<void> checkLocationServiceStatus() async {
    log.i('checkLocationServiceStatus');

    log.d('checking location permission');
    LocationPermission permissionStatus = await Geolocator.checkPermission();
    switch (permissionStatus) {
      case LocationPermission.always:
        {
          log.d('Location is always permitted.');
          // check to see if service is active
          _isLocationActive();
        }

        break;
      case LocationPermission.whileInUse:
        {
          log.d('Location is permitted while in use.');
          // check to see if service is active
          _isLocationActive();
        }

        break;
      case LocationPermission.denied:
        {
          log.d('Location is denied.');
          // request permissions
          if (!justDenied) {
            Geolocator.requestPermission()
                .then((value) => checkLocationServiceStatus());
          } else {
            locationStatus.complete(false);
            // TODO: show banner indicating that location is not permitted.
          }
          justDenied = true;
        }

        break;
      case LocationPermission.deniedForever:
        {
          log.w('Location is denied FOR EVER.');
          locationStatus.complete(false);
          // TODO: show banner indicating that location is not permitted.
          // let user know that permission is permanatly denied
        }

        break;

      default:
        {
          // request permission if the permision status is unknown
          Geolocator.requestPermission()
              .then((value) => checkLocationServiceStatus());
        }
    }
  }

  /// Stream user current location.
  StreamSubscription<Position> _streamLocation() {
    log.i('_streamLocation');

    StreamSubscription<Position> positionStream = Geolocator.getPositionStream(
            desiredAccuracy: LocationAccuracy.medium, distanceFilter: 0)
        .listen((Position position) {
      log.d('position: $position');
      if (position != null) {
        _locationController.add(DeviceLocation(
          accuracy: position.accuracy,
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          altitude: position.altitude,
        ));
      }
    }, onError: (error) {
      log.wtf('error is here?: $error');
      bool closed = _locationController.isClosed;
      bool paused = _locationController.isPaused;

      log.e('handled position error: $error');
      log.e('location controller status: closed: $closed, paused: $paused');
    });

    return positionStream;
  }
}
