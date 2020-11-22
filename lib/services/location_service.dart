import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../logger.dart';
import '../models/location_model.dart';

final log = getLogger('LocationService');

class LocationService {
  StreamController<DeviceLocation> _locationController =
      StreamController<DeviceLocation>.broadcast();

  Stream<DeviceLocation> get locationStream => _locationController.stream;

  /// Stream user current location
  LocationService() {
    log.i('locationServiceConstructor ');

    // is permission given?

    Geolocator.checkPermission().then((permission) {
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        // Check if location Service is enable.

        Geolocator.isLocationServiceEnabled().then((locationServiceEnabled) {
          // if (locationServiceEnabled) {
          log.i('starting location stream');
          Geolocator.getPositionStream(
                  desiredAccuracy: LocationAccuracy.medium, distanceFilter: 0)
              .listen((Position position) {
            log.d('$position');
            if (position != null) {
              _locationController.add(
                DeviceLocation(
                  accuracy: position.accuracy,
                  latitude: position.latitude,
                  longitude: position.longitude,
                  speed: position.speed,
                  altitude: position.altitude,
                ),
              );
            }
          }).onError((error) {
            log.wtf('error is here?: $error');
            bool closed = _locationController.isClosed;
            bool paused = _locationController.isPaused;

            log.e('handled position error: $error');
            log.e(
                'location controller status: closed: $closed, paused: $paused');
          });
          // } else {
          //   log.d('location service is disabled');

          //   throw 'location service is disabled. please enable it1.';
          // }
        }).catchError((e) => log.e(e));
      } else if (permission == LocationPermission.denied) {
        // if permission is not granted
        log.d('Permission was found to be denied, requesting permissions.');
        Geolocator.requestPermission().then(
          (permission) {
            // request permision
            log.d('returned permission: $permission');
            if (permission == LocationPermission.always ||
                permission == LocationPermission.whileInUse) {
              // if permission is granted
              log.d('permission granted');
              Geolocator.isLocationServiceEnabled().then(
                (locationServiceEnabled) {
                  // if (locationServiceEnabled) {
                  log.d(
                      'Starting location stream after being granted permission.');

                  Geolocator.getPositionStream(
                          desiredAccuracy: LocationAccuracy.medium,
                          distanceFilter: 0)
                      .listen((Position position) {
                    log.d('$position');
                    if (position != null) {
                      _locationController.add(
                        DeviceLocation(
                          accuracy: position.accuracy,
                          latitude: position.latitude,
                          longitude: position.longitude,
                          speed: position.speed,
                          altitude: position.altitude,
                        ),
                      );
                    }
                    log.d('added location to stream');
                  }).onError((error) {
                    log.wtf('error is here?: $error');
                    bool closed = _locationController.isClosed;
                    bool paused = _locationController.isPaused;

                    log.e('handled position error: $error');
                    log.e(
                        'location controller status: closed: $closed, paused: $paused');
                  });
                  // } else {
                  //   log.d('location service is disabled');
                  //   throw 'location service is disabled. please enable it2.';
                  // }
                },
              ).catchError(
                (e) => log.e(e),
              );
            } else {
              log.d('permission denied.... for now');
              throw 'permission denied.... for now';
            }
          },
        ).catchError(
          (e) => log.e(e),
        );
      } else {
        log.d('location was permanantly denied');
        throw 'location permission was permanantly denied';
      }
    }).catchError(
      (e) => log.e(e),
    );
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
}
