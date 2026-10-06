//general imports

import 'dart:async';

import 'package:driverapp/controllers/location_controller.dart';
import 'package:driverapp/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/trip.dart';
import '../models/user_location.dart';
import '../services/trip_service.dart';

//This Enum has to match with the one in db
enum EnumTripStatus {
  NONE, //No Queue
  CUSTOMERSEARCHING, //Waiting for match
  MATCHING, // Will you accept customer?
  PICKINGUPCUSTOMER,
  GOINGTODEST,
  COMPLETED,
  DRIVERCANCELED,
  CUSTOMERCANCELED,
  COMPANYCANCELED
}

//This Enum has to match with the one in db
enum EnumTripType { CARD, CASH, VOUCHER, ALCOHOL1, ALCOHOL2 }

enum EnumPaymentType { CARD, POINTCARD, POINT, CASH }

class TripController extends GetxController with WidgetsBindingObserver {
  final isLoading = false.obs;
  final tripStatus = EnumTripStatus.NONE.obs;
  final queueOrder = 99.obs;

  final trip = (null as Trip?).obs;

  //Used to check for initial load
  final isTripRetrieved = false.obs;

  final errorResponse = "".obs;

  Timer? timer; // update driver location
  Timer? pollingTimer;
  Timer? matchTimer;
  final matchSeconds = MATCHTIMER.obs;
  bool isGettingStatus = false;
  final locationController = Get.find<LocationController>();

  final isAppActive = true.obs;

  @override
  void onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        isLoading(true);
        isAppActive(true);
        print("app resumed");
        await getStatus();
        isLoading(false);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        isAppActive(false);
        print("background");
        break;
    }
  }

  ///Getters

  ///Setters
  void setError(String err) => errorResponse(err);

  ///API Calls

  ///Helpers

  Future getStatus() async {
    isGettingStatus = true;

    var status = await TripService.getQueueStatus();
    if (status.item1 == null) {
      // Error || waiting || nothing
      if (status.item3 != null) setError(status.item3!);
      tripStatus(status.item2);
      print("status is ${status.item2}");
    } else {
      // set trip
      if (Get.currentRoute != TRIP) Get.toNamed(TRIP);
      trip(status.item1);
      var tstatus = EnumTripStatus.values[status.item1!.tripStatus - 1];
      tripStatus(tstatus);
      print("status is $tstatus");
    }

    isGettingStatus = false;
  }

  Future updateStatus(Trip? curTrip, int status) async {
    trip(curTrip);
    var newtripStatus = EnumTripStatus.values[status - 1];
    tripStatus(newtripStatus);
  }

  Future updateLocation() async {
    final currentLocation = locationController.currentLocation.value;
    if (currentLocation == null) return;
    await TripService.updateQueueLocation(currentLocation);
  }

  Future<bool> removeQueueFromDB() async {
    var err = await TripService.removeQueueFromDB();
    if (err != null) {
      setError(err);
      return false;
    }
    return true;
  }

  Future<bool?> increaseDeclined() async {
    var res = await TripService.increaseDeclined();

    if (res.item2 != null) {
      setError(res.item2!);
    }
    return res.item1;
  }

  Future<bool> matchTrip() async {
    var res = await TripService.matchTrip();

    if (res != null) {
      setError(res);
      tripStatus(EnumTripStatus.NONE);
      return false;
    } else {
      tripStatus(EnumTripStatus.PICKINGUPCUSTOMER);
    }
    return true;
  }

  Future<bool> startTrip({UserLocation? dest}) async {
    var res = await TripService.startTrip(dest);

    if (res.item2 != null) {
      setError(res.item2!);
      tripStatus(EnumTripStatus.NONE);
      return false;
    } else {
      if (trip.value!.endName != null || dest != null)
        tripStatus(EnumTripStatus.GOINGTODEST);
      if (dest != null) {
        trip.update((val) {
          val!.endAddress = dest.address;
          val.endPreferredName = dest.preferredName;
          val.endName = dest.name;
          val.endLatitude = dest.latitude;
          val.endLongitude = dest.longitude;
          val.tripAmount = res.item1 ?? 0;
        });
      }
    }
    return true;
  }

  Future<bool> completeTrip() async {
    var res = await TripService.completeTrip();

    if (res != null) {
      setError(res);
      tripStatus(EnumTripStatus.NONE);
      return false;
    } else {
      tripStatus(EnumTripStatus.COMPLETED);
    }
    return true;
  }

  Future<bool> driverCancel() async {
    var res = await TripService.driverCancel();

    if (res != null) {
      setError(res);
      return false;
    } else {
      trip.value = null;
      tripStatus(EnumTripStatus.CUSTOMERSEARCHING);
    }
    return true;
  }

  void startMatchTimer() {
    stopMatchTimer();
    matchSeconds(MATCHTIMER);
    matchTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      if (matchSeconds.value == 0) {
        //reject trip
        stopMatchTimer();
        if (tripStatus.value == EnumTripStatus.MATCHING) {
          await increaseDeclined();
          trip.value = null;
          tripStatus(EnumTripStatus.CUSTOMERSEARCHING);
        }
      } else {
        matchSeconds(matchSeconds.value - 1);
      }
    });
  }

  void stopMatchTimer() {
    if (matchTimer != null) matchTimer!.cancel();
  }

  void startTimer() {
    stopTimer();
    updateLocation();
    timer = Timer.periodic(const Duration(seconds: STATUSUPDATE), (Timer t) {
      if (!isGettingStatus) {
        updateLocation();
      }
    });
  }

  void startPolling({int? duration}) {
    if (pollingTimer != null) pollingTimer!.cancel();
    pollingTimer = Timer.periodic(Duration(seconds: duration ?? POLLINGTIMER),
        (Timer t) async {
      print("polling");
      if (tripStatus.value == EnumTripStatus.COMPLETED) return;

      var status = await TripService.getQueueStatus();

      // matching, waiting, cancel
      if (status.item2 != null) {
        if (tripStatus.value != status.item2) {
          tripStatus(status.item2);
        }
        return;
      }

      // if db trip is not matched at all. do nothing
      if (status.item1 == null) return;
      // if db trip is matched
      // if app trip exists
      var tstatus = EnumTripStatus.values[status.item1!.tripStatus - 1];
      if (trip.value != null) {
        // if db trip == app trip do nothing
        if (tstatus == tripStatus.value) return;
      }
      // if trip status is not same or trip does not exist
      trip(status.item1);
      tripStatus(tstatus);
    });
  }

  void stopTimer() {
    if (timer != null) timer!.cancel();
  }

  void tripStatusListen() {
    tripStatus.listen((status) {
      print(status);
      stopMatchTimer();
      switch (status) {
        case EnumTripStatus.NONE:
          stopTimer();
          if (Get.currentRoute == TRIP) {
            Get.offAllNamed(HOME);
          }
          break;
        case EnumTripStatus.CUSTOMERSEARCHING:
          //Driver in queue
          startTimer();
          startPolling();
          if (Get.currentRoute != TRIP) Get.toNamed(TRIP);
          break;
        case EnumTripStatus.MATCHING:
          //Driver accepting / rejecting call
          if (Get.currentRoute != TRIP) Get.toNamed(TRIP);
          startTimer();
          startPolling();
          startMatchTimer();
          break;
        case EnumTripStatus.PICKINGUPCUSTOMER:
          //Driver driving to the customer
          if (Get.currentRoute != TRIP) Get.toNamed(TRIP);
          startTimer();
          //update driverQueue latlng
          break;
        case EnumTripStatus.GOINGTODEST:
          //Driver driving the customer to dest
          //if Trip destination is null go to DEST screen
          if (Get.currentRoute != TRIP) Get.toNamed(TRIP);
          startTimer();
          //if (trip.value == null) getStatus();
          break;
        case EnumTripStatus.CUSTOMERCANCELED:
        case EnumTripStatus.COMPANYCANCELED:
          //Driver driving the customer to dest
          if (!isAppActive.value) {
            locationController.sendNotification("Customer Canceled the Trip",
                "Please take action to get matched with another customer.");
          }
          if (Get.currentRoute != TRIP) Get.toNamed(TRIP);
          stopTimer();
          //if (trip.value == null) getStatus();
          break;
        case EnumTripStatus.COMPLETED:
          //Drive ended
          stopTimer();
          break;
        default:
      }
    });
  }
}
