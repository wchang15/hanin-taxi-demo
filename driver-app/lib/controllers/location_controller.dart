import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
// import 'package:background_locator_2/background_locator.dart';
// import 'package:background_locator_2/settings/android_settings.dart';
// import 'package:background_locator_2/settings/ios_settings.dart';
// import 'package:background_locator_2/settings/locator_settings.dart' as backloc;
// import 'package:background_locator_2/settings/android_settings.dart' as android;
import 'package:driverapp/controllers/trip_controller.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

//google maps/geo service imports
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

//models and meta imports
import '../models/user_location.dart';
import '../services/trip_service.dart';
import '../utils/constants.dart';

enum EnumLocationControllerStatus { Loading, Success, Error }

/// Controls the functionality related to a user's location
class LocationController extends GetxController {
  final Geocoding _geocoding = Geocoding();
  final locationStatus = EnumLocationControllerStatus.Loading.obs;
  final isLoading = false.obs;
  final currentLocation = (null as LatLng?).obs;

  ReceivePort port = ReceivePort();

  Timer? locationTimer;

  //final currentLocation = (null as UserLocation?).obs;

  ////////// Getters //////////

  /// returns a formatted street address of the current user's current location
  // String getCurrentAddress() => currentLocation.value?.address ?? "";

  // /// returns a latitude and longitude point of the current user's current location
  // LatLng getCurrentLocation() {
  //   if (currentLocation.value == null) return LatLng(42.8243, -73.9096);
  //   return LatLng(currentLocation.value!.latitude, currentLocation.value!.longitude);
  // }

  ////////// Setters //////////s
  ///
  ///Get Coordinates (Not being used)
  Future<void> getCoordinates(UserLocation userLocation) async {
    var coordinates = await _geocoding
        .locationFromAddress("${userLocation.name}, ${userLocation.address}");
    userLocation.latitude = coordinates[0].latitude;
    userLocation.longitude = coordinates[0].longitude;
  }

  /// Attempts to retrieve the user's current location and sets location status
  Future<void> setCurrentLocation() async {
    // try {
    //   await fetchCurrentLocation();
    //   locationStatus(EnumLocationControllerStatus.Success);
    // } catch (e) {
    //   locationStatus(EnumLocationControllerStatus.Error);
    // }

    await fetchCurrentLocation();

    locationTimer?.cancel();
    if (locationStatus.value == EnumLocationControllerStatus.Success) {
      locationTimer = Timer.periodic(const Duration(seconds: STATUSUPDATE),
          (Timer t) async {
        await fetchCurrentLocation();
      });
    }

    // if (IsolateNameServer.lookupPortByName(LocationServiceRepository.isolateName) != null) {
    //   IsolateNameServer.removePortNameMapping(LocationServiceRepository.isolateName);
    // }

    // IsolateNameServer.registerPortWithName(port.sendPort, LocationServiceRepository.isolateName);

    // port.listen(
    //   (dynamic data) async {
    //     print("background listen $data");
    //     await updateLocation(data);
    //     if (data != null) sendNotification("Location Updated", data.toString());
    //   },
    // );

    // await initPlatformState();

    // if (await checkLocationPermission()) {
    //   await startLocator();
    // }
  }

  ////////// Helper //////////

  /// Fetches a user's current location
  Future<void> fetchCurrentLocation() async {
    if (currentLocation.value == null) {
      locationStatus(EnumLocationControllerStatus.Loading);
    }

    try {
      if (!await checkLocationPermission()) {
        throw Exception("Location Service request has been denied!");
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await _applyPosition(lastKnown, isLastKnown: true);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 8),
          ),
        );
        await _applyPosition(position, isLastKnown: false);
      } catch (error) {
        if (lastKnown == null) rethrow;
        print('Current location refresh failed; using last known: $error');
      }
    } catch (e) {
      if (currentLocation.value == null) {
        locationStatus(EnumLocationControllerStatus.Error);
      } else {
        locationStatus(EnumLocationControllerStatus.Success);
      }
      print('location_controller.fetchCurrentLocation');
      print(e);
    }
  }

  Future<void> _applyPosition(
    Position position, {
    required bool isLastKnown,
  }) async {
    print(
        'isLastKnown: $isLastKnown : location updated ${position.latitude} ${position.longitude} ${DateTime.now()}');

    if (currentLocation.value != null &&
        currentLocation.value!.latitude == position.latitude &&
        currentLocation.value!.longitude == position.longitude) {
      locationStatus(EnumLocationControllerStatus.Success);
      return;
    }

    final location = LatLng(position.latitude, position.longitude);
    currentLocation(location);
    locationStatus(EnumLocationControllerStatus.Success);
    await TripService.updateQueueLocation(location);
  }

  Future<bool> checkLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  void onClose() {
    locationTimer?.cancel();
    port.close();
    super.onClose();
  }

  // Future<bool> checkBatteryPermission() async {
  //   final access = await Permission.ignoreBatteryOptimizations.status;
  //   switch (access) {
  //     case PermissionStatus.denied:
  //     case PermissionStatus.restricted:
  //       final permission = await Permission.ignoreBatteryOptimizations.request();
  //       if (permission == PermissionStatus.granted) {
  //         return true;
  //       } else {
  //         return false;
  //       }
  //     case PermissionStatus.granted:
  //       return true;
  //     default:
  //       final permission = await Permission.ignoreBatteryOptimizations.request();
  //       if (permission == PermissionStatus.granted) {
  //         return true;
  //       } else {
  //         return false;
  //       }
  //   }
  // }

  Future<void> updateLocation(dynamic data) async {
    if (data != null) {
      double latitude = data["latitude"];
      double longitude = data["longitude"];
      LatLng ll = LatLng(latitude, longitude);
      currentLocation(ll);
      await TripService.updateQueueLocation(ll);

      var status = await TripService.getQueueStatus();
      if (status.item2 != null) {
        if (status.item2 == EnumTripStatus.CUSTOMERCANCELED ||
            status.item2 == EnumTripStatus.COMPANYCANCELED) {
          sendNotification("Customer Canceled the Trip",
              "Please take action to get matched with another customer.");
        }
      }
    }
  }

  // Future<void> initPlatformState() async {
  //   await BackgroundLocator.initialize();
  //   print('Initialization background locator done');
  //   await BackgroundLocator.isServiceRunning();
  // }

  // Future<void> startLocator() async {
  //   Map<String, dynamic> data = {'countInit': 1};
  //   if (await BackgroundLocator.isServiceRunning()) await BackgroundLocator.unRegisterLocationUpdate();
  //   return await BackgroundLocator.registerLocationUpdate(
  //     LocationCallbackHandler.callback,
  //     initCallback: LocationCallbackHandler.initCallback,
  //     initDataCallback: data,
  //     disposeCallback: LocationCallbackHandler.disposeCallback,
  //     iosSettings: const IOSSettings(
  //         accuracy: backloc.LocationAccuracy.NAVIGATION, distanceFilter: 800, stopWithTerminate: true), // half mile
  //     autoStop: false,
  //     androidSettings: const android.AndroidSettings(
  //       accuracy: backloc.LocationAccuracy.NAVIGATION,
  //       interval: 60, // hour trying to ignore this and use distance filter for both
  //       distanceFilter: 800,
  //       client: android.LocationClient.google,
  //     ),
  //   );
  // }

  void sendNotification(String title, String body) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: Random().nextInt(100),
          channelKey: "HaninTaxi_Key",
          title: title,
          body: body,
          wakeUpScreen: true),
    );
  }
}
