//general imports

import 'dart:async';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:tax_app/controllers/customer_controller.dart';

import 'package:tax_app/controllers/location_controller.dart';

import 'package:tax_app/services/trip_service.dart';
import 'package:tax_app/utils/color_constants.dart';
import 'package:tax_app/widgets/custom_cancel_dialog.dart';
import 'package:latlong2/latlong.dart';

import '../models/driver.dart';
import '../models/user_location.dart';

import '../utils/constants.dart';
import '../utils/image_constants.dart';
import '../utils/text_styles.dart';
import 'package:vibration/vibration.dart';

//This Enum has to match with the one in db
//enum EnumTripStatus { findFare, matching, waiting, moving, completed, driverCanceled, customerCanceled }
enum EnumTripStatus {
  NONE, // Not being used for customer
  CUSTOMERSEARCHING,
  MATCHING,
  PICKINGUPCUSTOMER,
  GOINGTODEST,
  COMPLETED,
  DRIVERCANCELED,
  CUSTOMERCANCELED
}

//This Enum has to match with the one in db
enum EnumPaymentType { card, pointCard, point, cash }

bool isSupportedServiceTrip(UserLocation start, UserLocation _) {
  final pickup = '${start.name}, ${start.address}'.toLowerCase();
  return pickup.contains(', ny') ||
      pickup.contains(', new york') ||
      pickup.contains(', nj') ||
      pickup.contains(', new jersey');
}

class TripController extends GetxController with WidgetsBindingObserver {
  @override
  void onInit() async {
    super.onInit();

    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void onClose() {
    _routeRequestVersion++;
    WidgetsBinding.instance?.removeObserver(this);
  }

  final isAppActive = true.obs;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        isLoading(true);
        isAppActive(true);
        print("app resume");
        await setCurrentTrip();
        openCurrentTripScreenIfNeeded();
        isLoading(false);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        isAppActive(false);
        print("app detatch");
        break;
    }
  }

  final isLoading = false.obs;
  final tripStatus = EnumTripStatus.CUSTOMERSEARCHING.obs;

  final startLocationController = TextEditingController().obs;
  final startLocation = (null as UserLocation?).obs;

  final endLocationController = TextEditingController().obs;
  final endLocation = (null as UserLocation?).obs;

  final estimatedTime = 0.obs; //in seconds
  final estimatedRoute = (null as List<LatLng>?).obs;
  int _routeRequestVersion = 0;

  final smallTaxiFee = '\$0.00'.obs;
  final largeTaxiFee = '\$0.00'.obs;

  final tripID = 0.obs;
  final enumTaxiSize = 1.obs;
  final customerCardID = 0.obs;
  final usePoints = (!DEMO_MODE).obs;
  final paymentType =
      (DEMO_MODE ? EnumPaymentType.cash : EnumPaymentType.pointCard).obs;

  final driverLocation = (null as LatLng?).obs;
  final driver = (null as Driver?).obs;

  //Focus on the start location or end location
  final isFocusStart = true.obs;
  //Used to check for initial load
  final isTripRetrieved = false.obs;

  final errorResponse = "".obs;

  final locationController = Get.find<LocationController>();
  final customerController = Get.find<CustomerController>();

  final complaintController = TextEditingController();

  final tipAmount = 0.00.obs;

  final rating = 5.obs;

  final isTripSupported = false.obs;

  // notifying that the driver is near.
  Worker? worker60;
  Worker? worker180;

  //Status of data polling
  bool isGettingStatus = false;
  final cars = [ImageConstant.imgCar, ImageConstant.imgVan];

  ////////// Getters //////////

  bool isTripSet() {
    return startLocation.value != null &&
        endLocation.value != null &&
        "${startLocation.value!.name} ${startLocation.value!.address}" !=
            "${endLocation.value!.name} ${endLocation.value!.address}";
  }

  bool checkIfTripSupported() {
    final ret = isSupportedServiceTrip(
      startLocation.value!,
      endLocation.value!,
    );
    isTripSupported(ret);
    return ret;
  }

  bool isShowMap() =>
      tripStatus.value == EnumTripStatus.CUSTOMERSEARCHING ||
      tripStatus.value == EnumTripStatus.MATCHING;

  LatLng getStartLatLng() =>
      LatLng(startLocation.value!.latitude, startLocation.value!.longitude);

  LatLng getEndLatLng() =>
      LatLng(endLocation.value!.latitude, endLocation.value!.longitude);

  String getPaymentMethodText() {
    String ret = "";
    if (paymentType.value == EnumPaymentType.card) {
      ret =
          customerController.customer.value!.getCardName(customerCardID.value);
    } else if (paymentType.value == EnumPaymentType.pointCard) {
      ret =
          "${"point".tr} & ${customerController.customer.value!.getCardName(customerCardID.value)}";
    } else if (paymentType.value == EnumPaymentType.point) {
      ret = "point".tr;
    } else if (paymentType.value == EnumPaymentType.cash) {
      ret = "cash".tr;
    }
    return ret;
  }

  String getTripAmount() =>
      enumTaxiSize.value == 1 ? smallTaxiFee.value : largeTaxiFee.value;

  String getTipAmount() => '\$${tipAmount.value.toStringAsFixed(2)}';

  String getTripAndTipAmount() {
    double? trip = double.tryParse(getTripAmount().substring(1));
    if (trip == null) return 'Error';
    var total = trip + tipAmount.value;
    return '\$${total.toStringAsFixed(2)}';
  }

  List<LatLng> getRoute() {
    var route = <LatLng>[];
    return estimatedRoute.value ?? route;
  }

  String getDurationString() {
    int m;
    int value = estimatedTime.value;
    // h = value ~/ 3600;
    m = value ~/ 60;
    return "$m ${'min'.tr}";
  }

  ////////// Setters //////////

  void setDriverNearOnce() {
    worker180?.dispose();
    worker60?.dispose();
    worker180 = once(
      estimatedTime,
      (time) {
        sendNotification(
            "Driver is 3 minutes away!", "Please be ready for the driver.");
      },
      condition: () =>
          estimatedTime.value < 240 &&
          estimatedTime.value > 30 &&
          tripStatus.value == EnumTripStatus.PICKINGUPCUSTOMER,
    );

    worker60 = once(
      estimatedTime,
      (time) {
        Vibration.vibrate(duration: 10000);
        Get.defaultDialog(
          title: "Rider is Here",
          barrierDismissible: false,
          content: Container(
            alignment: Alignment.center,
            child: LinearPercentIndicator(
              //width: SIZE.width / 2,
              animation: true,
              lineHeight: 20.0,
              animationDuration: 10000,
              percent: 1,
              progressColor: Colors.greenAccent,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Vibration.cancel();
                Get.back();
              },
              child: Text("trip_tip_okay".tr,
                  style: CustomTextStyle.txtBody2(color: ColorConstant.RED)),
            ),
          ],
        );
      },
      condition: () =>
          estimatedTime.value < 60 &&
          estimatedTime.value > 30 &&
          tripStatus.value == EnumTripStatus.PICKINGUPCUSTOMER,
    );
  }

  ///Set End location with [UserLocation]
  Future setEndWithLocation(UserLocation? loc) async {
    _routeRequestVersion++;
    endLocation(loc);
    if (loc == null) endLocation.value = null;
    endLocationController.value.text = loc == null ? "" : loc.name;
    if (loc != null) {
      var isDup = false;
      for (var history in customerController.customer.value!.searchHistories) {
        if (isDup) break;
        isDup = history.address == loc.address && history.name == loc.name;
      }
      if (!isDup) customerController.customer.value!.searchHistories.add(loc);
    }
    update();
  }

  ///Set start location with [UserLocation]
  Future setStartWithLocation(UserLocation? loc) async {
    _routeRequestVersion++;
    startLocation(loc);
    startLocationController.value.text = loc?.name ?? "";
    update();
  }

  void setCustomerCardID(int cardID) => customerCardID(cardID);

  void selectCustomerCard(int cardID) {
    customerCardID(cardID);
    paymentType(
      usePoints.value ? EnumPaymentType.pointCard : EnumPaymentType.card,
    );
  }

  //Set use points && payment type
  void setUsePoint(bool isUse) {
    usePoints(isUse);
    if (isUse) {
      if (paymentType.value == EnumPaymentType.card) {
        paymentType(EnumPaymentType.pointCard);
      }
    } else {
      if (paymentType.value == EnumPaymentType.pointCard) {
        paymentType(EnumPaymentType.card);
      }
    }
  }

  ///Set use points based on the [EnumPaymentType]
  void setUsePointWithType(EnumPaymentType type) {
    if (type == EnumPaymentType.card) {
      usePoints(false);
    } else if (type == EnumPaymentType.pointCard) {
      usePoints(true);
    }
  }

  //Setting extimated route and time
  Future setEstimatedRoute(LatLng src, LatLng dest) async {
    final requestVersion = ++_routeRequestVersion;
    if (isTripSet()) {
      var route = await locationController.getRoute(src, dest);
      // A cancelled trip or newer destination must not be restored by a late response.
      if (requestVersion != _routeRequestVersion || !isTripSet()) return;
      estimatedRoute(route.item1.length >= 2 ? route.item1 : null);
      estimatedTime(route.item2);
    }
  }

  void setFocusEnd() => isFocusStart(false);

  void setFocusStart() => isFocusStart(true);

  //Start search text highlight
  void highlightStart() =>
      startLocationController.value.selection = TextSelection(
          baseOffset: 0,
          extentOffset: startLocationController.value.text.length);

  //End search text highlight
  void highlightEnd() => endLocationController.value.selection = TextSelection(
      baseOffset: 0, extentOffset: endLocationController.value.text.length);

  //dispose highlight
  void disposeSelection() {
    endLocationController.value.selection =
        const TextSelection.collapsed(offset: 0);
    startLocationController.value.selection =
        const TextSelection.collapsed(offset: 0);
  }

  //removing the trip
  void removeTrip() async {
    isLoading(true);

    if (tripStatus.value == EnumTripStatus.CUSTOMERSEARCHING) {
      resetTrip();
      refresh();
    } else if (tripStatus.value == EnumTripStatus.MATCHING) {
      customCancelDialog(
        title: 'trip_cancel_title'.tr,
        body: "trip_cancel_matching".tr,
        okayText: 'trip_cancel_button'.tr,
        cancelText: 'close'.tr,
        okayClick: () async {
          var res = await removeQueueFromDB();
          if (!res) {
            return;
          }
          Get.back();
          resetTrip();
          refresh();
          // tripStatus(EnumTripStatus.CUSTOMERSEARCHING);
          // Get.back();
          //Get.until((route) => Get.currentRoute == HOME);
        },
      );
    } else if (tripStatus.value == EnumTripStatus.PICKINGUPCUSTOMER) {
      customCancelDialog(
        title: 'trip_cancel_title'.tr,
        body: "trip_cancel_pickup".tr,
        okayText: 'trip_cancel_button'.tr,
        cancelText: 'close'.tr,
        okayClick: () async {
          var res = await removeQueueFromDB();
          if (!res) {
            return;
          }
          await resetTrip();
          Get.back();
          //Get.until((route) => Get.currentRoute == HOME);
        },
      );
    }

    isLoading(false);
  }

  void setError(String err) {
    //print(err);
    errorResponse(err);
  }

  //reset Trip to find fare
  Future resetTrip() async {
    _routeRequestVersion++;
    usePoints(!DEMO_MODE);
    tripID(0);
    isFocusStart(true);
    final defaultCardID = customerController.customer.value!.defaultCardID ?? 0;
    customerCardID(defaultCardID);
    paymentType(
      defaultCardID == 0
          ? EnumPaymentType.cash
          : (usePoints.value
              ? EnumPaymentType.pointCard
              : EnumPaymentType.card),
    );
    estimatedRoute.value = null;
    estimatedTime(0);
    tripStatus(EnumTripStatus.CUSTOMERSEARCHING);
    isTripSupported(false);
    await setEndWithLocation(null);
    await setStartWithLocation(locationController.currentLocation.value);
  }

  ////////// API calls //////////

  //make a new find fare trip
  Future<bool> makeNewTrip() async {
    var ret = false;
    //isLoading(true);
    if (isTripSet()) {
      if (!checkIfTripSupported()) return true;
      var tripFare =
          await TripService.newTrip(startLocation.value!, endLocation.value!);
      if (tripFare.smallTaxiFee == null) {
        errorResponse(tripFare.response);
        ret = false;
      } else {
        smallTaxiFee(tripFare.smallTaxiFee);
        largeTaxiFee(tripFare.largeTaxiFee);
        tripID(tripFare.tripID);
        customerCardID(tripFare.customerCardID);
        ret = true;
      }
    }
    //isLoading(false);
    return ret;
  }

  //update the trip to matching stage
  Future confirmTrip() async {
    isLoading(true);

    var error = await TripService.confirmTrip(tripID.value,
        customerCardID.value, enumTaxiSize.value, paymentType.value.index + 1);
    if (error != null) {
      errorResponse(error);
    } else {
      tripStatus(EnumTripStatus.MATCHING);
    }

    isLoading(false);
  }

  //Data polling to get updated status
  // Future getStatus() async {
  //   isGettingStatus = true;

  //   var status = await TripService.getTripStatus();
  //   if (status != null) {
  //     var intStatus = int.parse(status) - 1;
  //     if (tripStatus.value.index != intStatus) {
  //       tripStatus(EnumTripStatus.values[intStatus]);
  //     }
  //   }
  //   isGettingStatus = false;
  // }

  Future updateStatus(int status) async {
    var newtripStatus = EnumTripStatus.values[status - 1];
    tripStatus(newtripStatus);
    refresh();
  }

  //getting the mathed driver information
  Future getDriverInformation() async {
    var driverInfo = await TripService.getTripDriver();
    if (driverInfo.item1 != null) {
      driver(driverInfo.item1);
    } else {
      setError(driverInfo.item2!);
    }
  }

  //getting the matched drivers location
  Future getDriverLocation() async {
    var locationInfo = await TripService.getTripDriverLocation();
    if (locationInfo.item1 != null) {
      driverLocation(locationInfo.item1);
      if (tripStatus.value == EnumTripStatus.PICKINGUPCUSTOMER) {
        await setEstimatedRoute(locationInfo.item1!, getStartLatLng());
      }
    } else {
      setError(locationInfo.item2!);
    }
  }

  Future setDriverLocation(LatLng loc) async {
    driverLocation(loc);
    if (tripStatus.value == EnumTripStatus.PICKINGUPCUSTOMER) {
      await setEstimatedRoute(loc, getStartLatLng());
    }
  }

  //Setting the current trip from scratch
  Future setCurrentTrip() async {
    //isLoading(true);
    var tripResponse = await TripService.getCurrentTrip();
    if (tripResponse.trip != null) {
      var trip = tripResponse.trip!;
      tripID(trip.tripID);
      smallTaxiFee(trip.smallTaxiFee);
      largeTaxiFee(trip.largeTaxiFee);

      var start = UserLocation(
          address: trip.startAddress,
          name: trip.startName,
          latitude: trip.startLatitude,
          longitude: trip.startLongitude,
          locationType: trip.startLocationType);
      startLocation(start);
      startLocationController.value.text = trip.startName;
      var end = UserLocation(
          address: trip.endAddress,
          name: trip.endName,
          latitude: trip.endLatitude,
          longitude: trip.endLongitude,
          locationType: trip.endLocationType);
      endLocation(end);
      endLocationController.value.text = trip.endName;
      customerCardID(trip.customerCardID ?? 0);
      paymentType(EnumPaymentType.values[trip.enumPaymentType - 1]);
      var curTripStatus = EnumTripStatus.values[trip.tripStatus - 1];
      if (curTripStatus == EnumTripStatus.MATCHING) {
        await setEstimatedRoute(getStartLatLng(), getEndLatLng());
      }
      //usePointWithType(EnumPaymentType.values[trip.enumPaymentType - 1]);
      refresh();
      tripStatus(curTripStatus);
    }
    isTripRetrieved(true);
    //isLoading(false);
  }

  void openCurrentTripScreenIfNeeded() {
    final status = tripStatus.value;
    if ((status == EnumTripStatus.GOINGTODEST ||
            status == EnumTripStatus.COMPLETED) &&
        Get.currentRoute != TRIP) {
      Get.toNamed(TRIP);
    }
  }

  Future<bool> removeQueueFromDB() async {
    var ret = true;
    isLoading(true);
    var error = await TripService.removeTrip();
    if (error != null) {
      errorResponse(error);
      ret = false;
    }
    isLoading(false);
    return ret;
  }

  Future<bool> completeTrip() async {
    var ret = true;
    isLoading(true);
    var error = await TripService.completeTrip(tipAmount.value);
    if (error != null) {
      errorResponse(error);
      ret = false;
    }
    isLoading(false);
    return ret;
  }

  Future<bool> removeCQ() async {
    var ret = true;
    isLoading(true);
    var error = await TripService.removeCQ();
    if (error != null) {
      errorResponse(error);
      ret = false;
    }
    isLoading(false);
    return ret;
  }

  Future<bool> rematchCQ() async {
    var ret = true;
    isLoading(true);
    var error = await TripService.rematchCQ();
    if (error != null) {
      errorResponse(error);
      ret = false;
    } else {
      setCurrentTrip();
    }
    isLoading(false);
    return ret;
  }

  Future<bool> giveRating() async {
    var ret = true;
    isLoading(true);
    var error = await TripService.giveRating(tripID.value, rating.value);
    if (error != null) {
      errorResponse(error);
      ret = false;
    }
    resetTrip();
    isLoading(false);
    return ret;
  }

  ////////// Helper //////////

  //listening to the trip status for data polling
  void tripStatusListen() {
    tripStatus.listen((status) {
      switch (status) {
        case EnumTripStatus.MATCHING:
          break;
        case EnumTripStatus.PICKINGUPCUSTOMER:
          if (!isAppActive.value) {
            sendNotification("Driver is on the way!",
                "Driver is coming to pick you up. Please be ready for the driver.");
          }
          getDriverInformation();
          getDriverLocation();
          setDriverNearOnce();
          break;
        case EnumTripStatus.GOINGTODEST:
          openCurrentTripScreenIfNeeded();
          if (driver.value == null) getDriverInformation();
          break;
        case EnumTripStatus.COMPLETED:
          openCurrentTripScreenIfNeeded();
          break;
        case EnumTripStatus.DRIVERCANCELED:
          if (!isAppActive.value) {
            sendNotification("Driver Canceled the Trip",
                "Please take action to get matched with another driver.");
          }
          Get.toNamed(DRIVERCANCEL);

          break;
        default:
      }
    });
  }

  void sendNotification(String title, String body) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: Random().nextInt(100),
          channelKey: "HaninTaxi_Key",
          title: title,
          body: body),
    );
  }
}
