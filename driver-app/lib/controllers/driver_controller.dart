//general imports

import 'dart:async';

import 'package:driverapp/controllers/location_controller.dart';
import 'package:driverapp/controllers/trip_controller.dart';
import 'package:driverapp/services/driver_service.dart';
import 'package:get/get.dart';
import 'package:map_launcher/map_launcher.dart';

import '../models/driver.dart';
import '../models/user_login.dart';
import '../services/login_service.dart';
import '../utils/constants.dart';

class DriverController extends GetxController {
  static const navigationMaps = <MapApp>[
    MapApp.apple,
    MapApp.google,
    MapApp.waze,
  ];

  final isLoading = false.obs;
  final errorResponse = "".obs;
  final driver = (null as Driver?).obs;
  final isRefreshSuccess = (null as bool?).obs;
  final map = (null as MapApp?).obs;

  final locationController = Get.find<LocationController>();
  final tripController = Get.find<TripController>();

  ///getter

  ///setter
  void setError(String text) => errorResponse(text);

  Future<List<SupportedMap>> getAvailableNavigationMaps() async {
    final maps = await MapLauncher.getAvailableMaps(navigationMaps);
    final installedMaps = maps.where((map) => map.isInstalled).toList();
    return installedMaps.isNotEmpty ? installedMaps : maps;
  }

  Future setMap(String text) async {
    final mapName = text.toLowerCase().replaceAll(' maps', '').trim();
    final maps = await getAvailableNavigationMaps();
    SupportedMap chosen;
    try {
      chosen = maps
          .where((element) =>
              element.map.id.toLowerCase() == mapName ||
              element.name.toLowerCase().replaceAll(' maps', '') == mapName)
          .first;
    } catch (err) {
      chosen = maps.first;
    }
    map(chosen.map);
  }

  Future setMapWithMap(SupportedMap availableMap) async {
    map(availableMap.map);
    //Save db
    final lowerMap = availableMap.map.id.toLowerCase();
    final res = await DriverService.updateMap(lowerMap);
    if (res == null) {
      driver.value!.map = lowerMap;
    }
  }

  ///api calls
  Future<void> login(UserLogin userLogin) async {
    isLoading(true);

    try {
      final response = await LoginService.postLoginDriver(userLogin);
      driver(response.item1);
      errorResponse(response.item2);
      await updateLanguage();
    } catch (e) {
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshToken() async {
    isLoading(true);

    try {
      final response = await LoginService.postRefreshToken();
      driver(response.item1);
      errorResponse(response.item2);
      isRefreshSuccess(response.item1 != null);
      await updateLanguage();
    } catch (e) {
    } finally {
      isLoading(false);
    }
  }

  Future<void> logout() async {
    isLoading(true);

    try {
      await LoginService.postLogout();
      driver.value = null;
      refresh();
    } catch (e) {
    } finally {
      isLoading(false);
    }
  }

  Future<bool> enqueue() async {
    bool ret = false;
    final currentLocation = locationController.currentLocation.value;
    if (currentLocation == null) return ret;

    try {
      final response = await DriverService.postDriverQueue(currentLocation);
      if (response != null) return ret;
      ret = true;
      if (tripController.tripStatus.value == EnumTripStatus.NONE) {
        tripController.tripStatus(EnumTripStatus.CUSTOMERSEARCHING);
      }
    } catch (e) {
    } finally {}
    return ret;
  }

  Future updateLanguage() async {
    if (driver.value != null) {
      await Get.updateLocale(LANGUAGEMAP[driver.value!.language]);
    }
  }
}
