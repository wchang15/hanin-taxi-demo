import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

//google maps/geo service imports
import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:tuple/tuple.dart';
import 'package:latlong2/latlong.dart';

//models and meta imports
import '../models/user_location.dart';
import '../services/mapbox_service.dart';
import '../utils/constants.dart';

enum EnumLocationControllerStatus { Loading, Success, Error }

/// Controls the functionality related to a user's location
class LocationController extends GetxController {
  final Geocoding _geocoding = Geocoding();
  final locationStatus = EnumLocationControllerStatus.Loading.obs;
  final isLoading = false.obs;
  final currentLocation = (null as UserLocation?).obs;
  Future<void>? _currentLocationRequest;
  Timer? timer;

  ////////// Getters //////////

  /// returns a formatted street address of the current user's current location
  String getCurrentAddress() => currentLocation.value?.address ?? "";

  /// returns a latitude and longitude point of the current user's current location
  LatLng getCurrentLocation() {
    if (currentLocation.value == null) {
      return LatLng(DEFAULT_MAP_LATITUDE, DEFAULT_MAP_LONGITUDE);
    }
    return LatLng(
        currentLocation.value!.latitude, currentLocation.value!.longitude);
  }

  /// Calculates a route from the given [src] and [dst] points
  Future<Tuple2<List<LatLng>, int>> getRoute(LatLng src, LatLng dst) async {
    List<LatLng> route = [];
    int duration = 0;
    var res = await MapBoxService.getDirection(src, dst);
    if (res.item1 != null) {
      route = res.item1!;
      duration = res.item2!;
    }

    return Tuple2(route, duration);
  }

  /// auto completes the given [text] to a set of addresses
  Future<List<UserLocation>> autoCompleteSearch(String text) async {
    return await MapBoxService.getAutoComplete(text);
  }

  ////////// Setters //////////s

  ///Get Coordinates
  Future<void> getCoordinates(UserLocation userLocation) async {
    if (userLocation.latitude != 0 || userLocation.longitude != 0) return;

    final coordinates = await _geocoding
        .locationFromAddress("${userLocation.name}, ${userLocation.address}");
    if (coordinates.isEmpty)
      throw Exception('Location coordinates could not be found.');
    userLocation.latitude = coordinates[0].latitude;
    userLocation.longitude = coordinates[0].longitude;
  }

  /// Attempts to retrieve the user's current location and sets location status
  Future<void> setCurrentLocation() {
    final activeRequest = _currentLocationRequest;
    if (activeRequest != null) return activeRequest;

    final request = _setCurrentLocation();
    _currentLocationRequest = request;
    request.whenComplete(() {
      if (identical(_currentLocationRequest, request)) {
        _currentLocationRequest = null;
      }
    });
    return request;
  }

  Future<void> _setCurrentLocation() async {
    locationStatus(EnumLocationControllerStatus.Loading);
    try {
      await fetchCurrentLocation();
      locationStatus(EnumLocationControllerStatus.Success);
    } catch (e) {
      if (DEMO_MODE) {
        currentLocation(
          UserLocation(
            name: 'Hanin Taxi Demo Office',
            address: '100 Main St, Fort Lee, NJ 07024',
            latitude: DEFAULT_MAP_LATITUDE,
            longitude: DEFAULT_MAP_LONGITUDE,
            locationType: EnumLocationType.OTHER,
          ),
        );
        locationStatus(EnumLocationControllerStatus.Success);
      } else {
        locationStatus(EnumLocationControllerStatus.Error);
      }
    }
  }

  ////////// Helper //////////

  /// Fetches a user's current location
  Future<void> fetchCurrentLocation() async {
    try {
      Position? position;

      // validate service is enabled and location services are set
      if (await checkLocationPermission()) {
        position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        )).timeout(
          const Duration(seconds: DEMO_MODE ? 10 : 30),
          onTimeout: () {
            throw TimeoutException(
                "Location information could not be obtained within the requested time.");
          },
        );

        // if lng and lat is same, don't retrieve new one
        if (currentLocation.value != null) {
          if (currentLocation.value!.latitude == position.latitude &&
              currentLocation.value!.longitude == position.longitude) {
            return;
          }
        }

        var name = 'Current location';
        var street = '';
        var address = 'Current location';
        var list = <UserLocation>[];

        try {
          final placemarks = await _geocoding.placemarkFromCoordinates(
              position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final placeMark = placemarks.first;
            name = placeMark.name ?? name;
            street = placeMark.street ?? '';
            final locality = placeMark.locality ?? '';
            final administrativeArea = placeMark.administrativeArea ?? '';
            final postalCode = placeMark.postalCode ?? '';
            address = [street, locality, administrativeArea, postalCode]
                .where((part) => part.isNotEmpty)
                .join(', ');
          }

          list = await MapBoxService.getAutoComplete(address);
          if (list.isEmpty && street.isNotEmpty) {
            list = await MapBoxService.getAutoComplete(street);
          }
        } catch (e) {
          print('Location address lookup failed; using coordinates: $e');
        }

        final loc = list.isNotEmpty
            ? list.first
            : UserLocation(
                name: street.isNotEmpty ? street : name,
                address: address,
                latitude: position.latitude,
                longitude: position.longitude,
                locationType: EnumLocationType.OTHER,
              );

        loc.latitude = position.latitude;
        loc.longitude = position.longitude;

        currentLocation(loc);

        // UserLocation? loc = await MapBoxService.getReverseGeocode(position.latitude, position.longitude);
        // loc!.latitude = position.latitude;
        // loc.longitude = position.longitude;

        // currentLocation(loc);

        // currentLocation(
        //   UserLocation(
        //       address: '$street $state, $country $zip',
        //       name: '$street',
        //       latitude: position.latitude,
        //       longitude: position.longitude,
        //       locationType: EnumLocationType.OTHER),
        // );
      } else {
        throw Exception("Location Service request has been denied!");
      }
    } on TimeoutException catch (e) {
      print('location_controller.fetchCurrentLocation');
      print(e);
      throw e;
    } catch (e) {
      print('location_controller.fetchCurrentLocation');
      print(e);
      throw e;
    }
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
}
