import 'package:driverapp/controllers/driver_controller.dart';
import 'package:driverapp/controllers/location_controller.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/icon_constants.dart';
import 'package:driverapp/utils/text_styles.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../controllers/trip_controller.dart';
import '../models/trip.dart';
import '../services/redirect_service.dart';
import '../utils/constants.dart';
import '../utils/image_constants.dart';
import '../utils/size.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_cancel_dialog.dart';
import '../widgets/custom_loading_dialog.dart';
import '../widgets/custom_open_with_map.dart';
import '../widgets/custom_tap.dart';

class TripScreen extends StatefulWidget {
  const TripScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TripScreenState();
}

// ignore_for_file: must_be_immutable
class TripScreenState extends State<TripScreen> {
  final driverController = Get.find<DriverController>();
  final tripController = Get.find<TripController>();
  final locationController = Get.find<LocationController>();

  String _paymentMessageKey(Trip trip) {
    final tripType = trip.getEnumTripType();
    if (tripType == EnumTripType.VOUCHER) return 'trip_voucher';
    if (tripType == EnumTripType.ALCOHOL1) return 'trip_alcohol1';
    if (tripType == EnumTripType.ALCOHOL2) return 'trip_alcohol2';

    return trip.getEnumPaymentType() == EnumPaymentType.CASH
        ? 'trip_cash'
        : 'trip_card';
  }

  Widget _navigationMapIcon() {
    final selectedMap = driverController.map.value;
    if (selectedMap == null) {
      return Icon(Icons.map_outlined, color: ColorConstant.BLACK3, size: 30);
    }
    return Image.memory(selectedMap.iconBytes, height: 30, width: 30);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var stopCallButton = CustomTap(
      color: ColorConstant.PRIMARY,
      onTap: () async {
        customCancelDialog(
          title: 'Trip_Stop'.tr,
          body: "Trip_Stop_Message".tr,
          okayText: 'Trip_Stop'.tr,
          cancelText: 'Dialog_Close'.tr,
          okayClick: () async {
            EasyDebounce.debounce('buttondebounce',
                const Duration(milliseconds: DOUBLECLICKDEBOUNCE), () async {
              tripController.stopTimer();
              var res = await tripController.removeQueueFromDB();
              if (!res) {
                tripController.startTimer();
              } else {
                tripController.tripStatus(EnumTripStatus.NONE);
                //Get.back();
                Get.until((route) => Get.currentRoute == HOME);
              }
            });
          },
        );
      },
      child: Text("Trip_Stop".tr,
          style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
    );
    var acceptDeclineButtons = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Obx(
          () => Text(
            'Trip_Auto_Decline'.trParams({
              'seconds': tripController.matchSeconds.value.toString(),
            }),
            style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK3),
          ),
        ),
        const SizedBox(height: 15),
        CustomAlert(
          bgColor: ColorConstant.WHITE1,
          color: ColorConstant.BLACK3,
          icon: IconConstant.Notification,
          text: 'Trip_Alert_Message'.tr,
          visible: true,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomTap(
              color: ColorConstant.GREY,
              onTap: () async {
                customCancelDialog(
                  title: 'Trip_Reject'.tr,
                  body: 'Trip_Reject_Message'.tr,
                  okayText: 'Trip_Reject'.tr,
                  cancelText: 'Dialog_Close'.tr,
                  okayClick: () async {
                    EasyDebounce.debounce('buttondebounce',
                        const Duration(milliseconds: DOUBLECLICKDEBOUNCE),
                        () async {
                      //This should change the queue status to waiting again
                      var res = await tripController.increaseDeclined();
                      if (res == null) {
                        //error
                      } else {
                        tripController.trip.value = null;
                        if (res!) {
                          tripController
                              .tripStatus(EnumTripStatus.CUSTOMERSEARCHING);
                          Get.back();
                        } else {
                          tripController.tripStatus(EnumTripStatus.NONE);
                          Get.until((route) => Get.currentRoute == HOME);
                        }
                      }
                    });
                  },
                );
              },
              width: SIZE.width / 2.3,
              borderRadius: 12,
              child: Text('Trip_Reject'.tr,
                  style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK3)),
            ),
            Obx(
              () => CustomTap(
                color: ColorConstant.PRIMARY,
                onTap: tripController.isLoading.value
                    ? null
                    : () async {
                        tripController.isLoading.value = true;
                        //Call db and match the trip
                        tripController.stopMatchTimer();
                        var res = await tripController.matchTrip();
                        if (res) {
                          tripController
                              .tripStatus(EnumTripStatus.PICKINGUPCUSTOMER);
                        } else {
                          //Match with other customer?
                          tripController
                              .tripStatus(EnumTripStatus.CUSTOMERSEARCHING);
                        }
                        if (tripController.trip.value?.getEnumTripType() ==
                            EnumTripType.ALCOHOL2) {
                          await tripController.getStatus();
                        }
                        tripController.isLoading.value = false;
                      },
                width: SIZE.width / 2.3,
                borderRadius: 12,
                child: Text('Trip_Accept'.tr,
                    style:
                        CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
              ),
            ),
          ],
        ),
      ],
    );
    var rideStartButton = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Obx(
          () => tripController.trip.value != null
              ? CustomAlert(
                  bgColor: ColorConstant.WHITE1,
                  color: ColorConstant.BLACK3,
                  icon: IconConstant.Error,
                  text: _paymentMessageKey(tripController.trip.value!).tr,
                  visible: true,
                )
              : const Center(),
        ),
        Obx(
          () => CustomTap(
            color: tripController.trip.value?.getEnumTripType() ==
                        EnumTripType.ALCOHOL2 &&
                    (tripController.trip.value?.endName == null ||
                        tripController.trip.value?.endName == "")
                ? ColorConstant.GREY3
                : ColorConstant.PRIMARY,
            onTap: tripController.trip.value?.getEnumTripType() ==
                        EnumTripType.ALCOHOL2 &&
                    (tripController.trip.value?.endName == null ||
                        tripController.trip.value?.endName == "")
                ? null
                : () async {
                    tripController.setError("");
                    if (tripController.trip.value!.endName == null) {
                      Get.toNamed(SELECTLOCATION);
                    } else if (tripController.trip.value?.getEnumTripType() ==
                        EnumTripType.CARD) {
                      customCancelDialog(
                        title: 'trip_customer_inside'.tr,
                        body: "trip_customer_confirm_message".tr,
                        okayText: 'okay'.tr,
                        cancelText: 'Dialog_Close'.tr,
                        okayClick: () async {
                          EasyDebounce.debounce('buttondebounce',
                              const Duration(milliseconds: DOUBLECLICKDEBOUNCE),
                              () async {
                            var res = await tripController.startTrip();
                            if (!res) {
                              //Fail
                              Get.until((route) => Get.currentRoute == HOME);
                            } else {
                              Get.back();
                            }
                          });
                        },
                      );
                    } else {
                      EasyDebounce.debounce('buttondebounce',
                          const Duration(milliseconds: DOUBLECLICKDEBOUNCE),
                          () async {
                        var res = await tripController.startTrip();
                        if (!res) {
                          //Fail
                          Get.until((route) => Get.currentRoute == HOME);
                        }
                      });
                    }
                  },
            child: Text("trip_start".tr,
                style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
          ),
        ),
      ],
    );
    var paymentAlert = Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Obx(
          () => tripController.trip.value != null
              ? CustomAlert(
                  bgColor: ColorConstant.WHITE1,
                  color: ColorConstant.BLACK3,
                  icon: IconConstant.Error,
                  text: _paymentMessageKey(tripController.trip.value!).tr,
                  visible: true,
                )
              : const Center(),
        ),
        CustomTap(
          color: ColorConstant.PRIMARY,
          onTap: () async {
            customCancelDialog(
              title: 'trip_complete_modal_title'.tr,
              body: "trip_complete_modal_body".tr,
              okayText: 'okay'.tr,
              cancelText: 'cancel'.tr,
              okayClick: () async {
                EasyDebounce.debounce('buttondebounce',
                    const Duration(milliseconds: DOUBLECLICKDEBOUNCE),
                    () async {
                  tripController.stopTimer();
                  var res = await tripController.completeTrip();
                  if (!res) {
                    //Fail
                    //Get.back();
                    Get.until((route) => Get.currentRoute == HOME);
                  } else {
                    //Success
                    driverController.driver.value!.earnedToday +=
                        tripController.trip.value!.tripAmount;
                    Get.back();
                  }
                });
              },
            );
          },
          child: Text("trip_complete".tr,
              style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
        ),
      ],
    );
    var completedButton = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CustomTap(
          color: ColorConstant.GREY,
          onTap: () => Get.until((route) => Get.currentRoute == HOME),
          width: SIZE.width / 2.3,
          borderRadius: 12,
          child: Text('trip_rest'.tr,
              style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK3)),
        ),
        CustomTap(
          color: ColorConstant.PRIMARY,
          onTap: () async {
            customCancelDialog(
              title: 'trip_wait'.tr,
              body: 'trip_wait_body'.tr,
              okayText: 'okay'.tr,
              cancelText: 'cancel'.tr,
              okayClick: () async {
                EasyDebounce.debounce('buttondebounce',
                    const Duration(milliseconds: DOUBLECLICKDEBOUNCE),
                    () async {
                  var res = await driverController.enqueue();
                  if (res) {
                    Get.back();
                    tripController.tripStatus.value =
                        EnumTripStatus.CUSTOMERSEARCHING;
                  }
                });
              },
            );
          },
          width: SIZE.width / 2.3,
          borderRadius: 12,
          child: Text('trip_wait'.tr,
              style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
        )
      ],
    );
    var customerCancelButton = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CustomTap(
          color: ColorConstant.GREY,
          onTap: () => Get.until((route) => Get.currentRoute == HOME),
          width: SIZE.width / 2.3,
          borderRadius: 12,
          child: Text('trip_rest'.tr,
              style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK3)),
        ),
        CustomTap(
          color: ColorConstant.PRIMARY,
          onTap: () async {
            customCancelDialog(
              title: 'trip_wait'.tr,
              body: 'trip_wait_body'.tr,
              okayText: 'okay'.tr,
              cancelText: 'cancel'.tr,
              okayClick: () async {
                EasyDebounce.debounce('buttondebounce',
                    const Duration(milliseconds: DOUBLECLICKDEBOUNCE),
                    () async {
                  var res = await driverController.enqueue();
                  if (res) {
                    Get.back();
                    tripController.tripStatus.value =
                        EnumTripStatus.CUSTOMERSEARCHING;
                  } else {
                    Get.until((route) => Get.currentRoute == HOME);
                  }
                });
              },
            );
          },
          width: SIZE.width / 2.3,
          borderRadius: 12,
          child: Text('trip_wait'.tr,
              style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
        )
      ],
    );

    var customerSearching = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 100),
        Lottie.asset(ImageConstant.animationCallWaiting),
        Text('Trip_Waiting'.tr,
            style: CustomTextStyle.txtTitle3(color: ColorConstant.BLACK1)),
      ],
    );
    var matching = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 100),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                  text: 'Trip_Call'.tr,
                  style: CustomTextStyle.txtTitle3(
                      color: ColorConstant.SECONDARY)),
              TextSpan(
                  text: 'Trip_Call_Received'.tr,
                  style:
                      CustomTextStyle.txtTitle3(color: ColorConstant.BLACK1)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: getPadding(left: 15, right: 15, top: 7, bottom: 7),
          decoration: BoxDecoration(
              color: ColorConstant.WHITE1,
              borderRadius: BorderRadius.circular(12)),
          child: Text('Trip_Start_Location'.tr,
              style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3)),
        ),
        const SizedBox(height: 30),
        Obx(
          () => Text(
            tripController.trip.value?.fullStartName() ?? "",
            style: CustomTextStyle.txtTitle3(
                color: ColorConstant.BLACK1, height: 1.2),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    var pickingup = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                  text: 'trip_customer'.tr,
                  style: CustomTextStyle.txtTitle3(
                      color: ColorConstant.SECONDARY)),
              TextSpan(
                  text: 'trip_going'.tr,
                  style:
                      CustomTextStyle.txtTitle3(color: ColorConstant.BLACK1)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Container(
          width: SIZE.width,
          alignment: Alignment.center,
          padding: getPadding(all: 30),
          margin: getMargin(left: 20, right: 20),
          decoration: BoxDecoration(color: ColorConstant.WHITE1),
          child: Column(
            children: [
              Obx(
                () => Text(tripController.trip.value?.fullStartName() ?? "",
                    textAlign: TextAlign.center,
                    style: CustomTextStyle.txtTitle3(
                        color: ColorConstant.BLACK1, height: 1.2)),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("trip_customer_name".tr,
                      style: CustomTextStyle.txtCaption2(
                          color: ColorConstant.BLACK3)),
                  const SizedBox(width: 10),
                  Obx(
                    () => Text(
                        tripController.trip.value?.customerFirstName ?? "",
                        style: CustomTextStyle.txtBody2(
                            color: ColorConstant.BLACK1)),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: getPadding(all: 2),
                    decoration: BoxDecoration(
                      color: ColorConstant.YELLOW,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(IconConstant.Phone,
                        color: ColorConstant.SECONDARY, size: 18),
                  ),
                  const SizedBox(width: 5),
                  Obx(
                    () => TextButton(
                      child: Text(
                        '+1 ${tripController.trip.value?.customerPhoneNumber ?? ""}',
                        style: CustomTextStyle.txtBody1(
                            color: ColorConstant.BLACK1),
                      ),
                      onPressed: () async {
                        await RedirectService.makeCall(
                            tripController.trip.value?.customerPhoneNumber ??
                                "");
                      },
                    ),
                  ),
                ],
              ),
              Obx(
                () => tripController.trip.value?.getEnumTripType() ==
                            EnumTripType.ALCOHOL1 ||
                        tripController.trip.value?.getEnumTripType() ==
                            EnumTripType.ALCOHOL2
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: getPadding(all: 2),
                            decoration: BoxDecoration(
                              color: ColorConstant.YELLOW,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              children: [
                                Icon(IconConstant.Car,
                                    color: ColorConstant.SECONDARY, size: 18),
                                Icon(IconConstant.Phone,
                                    color: ColorConstant.SECONDARY, size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            child: Text(
                              '+1 ${tripController.trip.value?.alcoholPhoneNumber ?? ""}',
                              style: CustomTextStyle.txtBody1(
                                  color: ColorConstant.BLACK1),
                            ),
                            onPressed: () async {
                              await RedirectService.makeCall(tripController
                                      .trip.value?.alcoholPhoneNumber ??
                                  "");
                            },
                          ),
                        ],
                      )
                    : const Center(),
              ),
              Obx(
                () => tripController.trip.value!.getEnumTripType() !=
                        EnumTripType.CARD
                    ? Padding(
                        padding: getPadding(top: 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("note".tr,
                                style: CustomTextStyle.txtCaption2(
                                    color: ColorConstant.BLACK3)),
                            const SizedBox(height: 5),
                            Text(tripController.trip.value!.note,
                                style: CustomTextStyle.txtBody2(
                                    color: ColorConstant.BLACK1,
                                    weight: FontWeight.w400,
                                    height: 1.2)),
                          ],
                        ),
                      )
                    : const Center(),
              )
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: getPadding(left: 5, right: 5),
              decoration: BoxDecoration(
                  color: ColorConstant.WHITE1,
                  borderRadius: BorderRadius.circular(25)),
              child: TextButton.icon(
                onPressed: () {
                  if (tripController.tripStatus.value ==
                      EnumTripStatus.PICKINGUPCUSTOMER) {
                    RedirectService.launchMapNavigation(
                        tripController.trip.value!.startLatitude,
                        tripController.trip.value!.startLongitude);
                  }
                },
                icon: Icon(IconConstant.Location, color: ColorConstant.BLACK3),
                label: Text("trip_view_customer_map".tr,
                    style: CustomTextStyle.txtCaption2(
                        color: ColorConstant.BLACK3)),
              ),
            ),
            Obx(
              () => TextButton(
                onPressed: () async {
                  final availableMaps =
                      await driverController.getAvailableNavigationMaps();
                  Get.bottomSheet(CustomOpenWithMap(data: availableMaps));
                },
                child: _navigationMapIcon(),
              ),
            )
          ],
        )
      ],
    );
    var goingDest = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                  text: 'trip_dest'.tr,
                  style: CustomTextStyle.txtTitle3(
                      color: ColorConstant.SECONDARY)),
              TextSpan(
                  text: 'trip_dest_going'.tr,
                  style:
                      CustomTextStyle.txtTitle3(color: ColorConstant.BLACK1)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Text('trip_customer_onboard'.tr,
            style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK3)),
        const SizedBox(height: 15),
        Container(
          width: SIZE.width,
          alignment: Alignment.center,
          padding: getPadding(all: 30),
          margin: getMargin(left: 20, right: 20),
          decoration: BoxDecoration(color: ColorConstant.WHITE1),
          child: Column(
            children: [
              Obx(
                () => Text(tripController.trip.value?.fullEndName() ?? "",
                    textAlign: TextAlign.center,
                    style: CustomTextStyle.txtTitle3(
                        color: ColorConstant.BLACK1, height: 1.2)),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("trip_customer_name".tr,
                      style: CustomTextStyle.txtCaption2(
                          color: ColorConstant.BLACK3)),
                  const SizedBox(width: 10),
                  Obx(
                    () => Text(
                        tripController.trip.value?.customerFirstName ?? "",
                        style: CustomTextStyle.txtBody2(
                            color: ColorConstant.BLACK1)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("trip_amount".tr,
                      style: CustomTextStyle.txtCaption2(
                          color: ColorConstant.BLACK3)),
                  const SizedBox(width: 10),
                  Obx(
                    () => Text(
                        tripController.trip.value?.tripAmountString() ?? "?",
                        style: CustomTextStyle.txtBody2(
                            color: ColorConstant.BLACK1)),
                  ),
                ],
              ),
              Obx(
                () => tripController.trip.value?.getEnumTripType() ==
                            EnumTripType.ALCOHOL1 ||
                        tripController.trip.value?.getEnumTripType() ==
                            EnumTripType.ALCOHOL2
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: getPadding(all: 2),
                            decoration: BoxDecoration(
                              color: ColorConstant.YELLOW,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              children: [
                                Icon(IconConstant.Car,
                                    color: ColorConstant.SECONDARY, size: 18),
                                Icon(IconConstant.Phone,
                                    color: ColorConstant.SECONDARY, size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          TextButton(
                            child: Text(
                              '+1 ${tripController.trip.value?.alcoholPhoneNumber ?? ""}',
                              style: CustomTextStyle.txtBody1(
                                  color: ColorConstant.BLACK1),
                            ),
                            onPressed: () async {
                              await RedirectService.makeCall(tripController
                                      .trip.value?.alcoholPhoneNumber ??
                                  "");
                            },
                          ),
                        ],
                      )
                    : const Center(),
              ),
              Obx(
                () => tripController.trip.value!.getEnumTripType() !=
                        EnumTripType.CARD
                    ? Padding(
                        padding: getPadding(top: 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("note".tr,
                                style: CustomTextStyle.txtCaption2(
                                    color: ColorConstant.BLACK3)),
                            const SizedBox(height: 5),
                            Text(tripController.trip.value!.note,
                                style: CustomTextStyle.txtBody2(
                                    color: ColorConstant.BLACK1,
                                    weight: FontWeight.w400,
                                    height: 1.2)),
                          ],
                        ),
                      )
                    : const Center(),
              )
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: getPadding(left: 5, right: 5),
              decoration: BoxDecoration(
                  color: ColorConstant.WHITE1,
                  borderRadius: BorderRadius.circular(25)),
              child: TextButton.icon(
                onPressed: () {
                  if (tripController.tripStatus.value ==
                      EnumTripStatus.GOINGTODEST) {
                    RedirectService.launchMapNavigation(
                        tripController.trip.value!.endLatitude!,
                        tripController.trip.value!.endLongitude!);
                  }
                },
                icon: Icon(IconConstant.Location, color: ColorConstant.BLACK3),
                label: Text("trip_dest_map".tr,
                    style: CustomTextStyle.txtCaption2(
                        color: ColorConstant.BLACK3)),
              ),
            ),
            Obx(
              () => TextButton(
                onPressed: () async {
                  final availableMaps =
                      await driverController.getAvailableNavigationMaps();
                  Get.bottomSheet(CustomOpenWithMap(data: availableMaps));
                },
                child: _navigationMapIcon(),
              ),
            )
          ],
        ),
      ],
    );
    var completed = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 100),
        Icon(IconConstant.Check, color: ColorConstant.PRIMARY, size: 50),
        const SizedBox(height: 15),
        Text(
          "trip_complete!".tr,
          style: CustomTextStyle.txtTitle2(color: ColorConstant.BLACK1),
        ),
        const SizedBox(height: 15),
        Text(
          "trip_safe_thanks".tr,
          textAlign: TextAlign.center,
          style: CustomTextStyle.txtBody2(
              color: ColorConstant.BLACK3, height: 1.5),
        )
      ],
    );
    var customerCancel = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 100),
        Icon(IconConstant.Error, color: ColorConstant.PRIMARY, size: 50),
        const SizedBox(height: 15),
        Text(
          "trip_customer_cancel".tr,
          style: CustomTextStyle.txtTitle2(color: ColorConstant.BLACK1),
        ),
        const SizedBox(height: 15),
        Text(
          "trip_customer_cancel_body".tr,
          textAlign: TextAlign.center,
          style: CustomTextStyle.txtBody2(
              color: ColorConstant.BLACK3, height: 1.5),
        ),
      ],
    );

    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            actions: [
              Obx(
                () => tripController.tripStatus.value ==
                        EnumTripStatus.PICKINGUPCUSTOMER
                    ? Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: getPadding(top: 10, right: 12),
                          child: Container(
                            decoration: BoxDecoration(
                                color: ColorConstant.WHITE1,
                                borderRadius: BorderRadius.circular(25)),
                            child: TextButton.icon(
                              onPressed: () {
                                customCancelDialog(
                                  title: 'trip_customer_noshow'.tr,
                                  body: "trip_customer_noshow_body".tr,
                                  okayText: 'okay'.tr,
                                  cancelText: 'Dialog_Close'.tr,
                                  okayClick: () async {
                                    var res =
                                        await tripController.driverCancel();
                                    if (res == null) {
                                      //error //snack bar
                                    } else {
                                      Get.back();
                                      //Get.toNamed(TRIP);
                                    }
                                  },
                                );
                              },
                              icon: Icon(IconConstant.CarReport,
                                  color: ColorConstant.BLACK3),
                              label: Text('trip_customer_noshow_short'.tr,
                                  style: CustomTextStyle.txtCaption2(
                                      color: ColorConstant.BLACK3)),
                            ),
                          ),
                        ),
                      )
                    : const Center(),
              ),
            ],
          ),
          backgroundColor: ColorConstant.WHITE,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Obx(
            () => Container(
              width: SIZE.width,
              alignment: Alignment.bottomCenter,
              child: tripController.tripStatus.value ==
                      EnumTripStatus.CUSTOMERSEARCHING
                  ? stopCallButton
                  : tripController.tripStatus.value == EnumTripStatus.MATCHING
                      ? acceptDeclineButtons
                      : tripController.tripStatus.value ==
                              EnumTripStatus.PICKINGUPCUSTOMER
                          ? rideStartButton
                          : tripController.tripStatus.value ==
                                  EnumTripStatus.GOINGTODEST
                              ? paymentAlert
                              : tripController.tripStatus.value ==
                                      EnumTripStatus.COMPLETED
                                  ? completedButton
                                  : tripController.tripStatus.value ==
                                              EnumTripStatus.CUSTOMERCANCELED ||
                                          tripController.tripStatus.value ==
                                              EnumTripStatus.COMPANYCANCELED
                                      ? customerCancelButton
                                      : const Center(),
            ),
          ),
          body: Padding(
            padding: getPadding(top: 0, left: 16, right: 16),
            child: Obx(
              () => Center(
                child: tripController.tripStatus.value ==
                        EnumTripStatus.CUSTOMERSEARCHING
                    ? customerSearching
                    : tripController.tripStatus.value == EnumTripStatus.MATCHING
                        ? matching
                        : tripController.tripStatus.value ==
                                EnumTripStatus.PICKINGUPCUSTOMER
                            ? pickingup
                            : tripController.tripStatus.value ==
                                    EnumTripStatus.GOINGTODEST
                                ? goingDest
                                : tripController.tripStatus.value ==
                                        EnumTripStatus.COMPLETED
                                    ? completed
                                    : tripController.tripStatus.value ==
                                                EnumTripStatus
                                                    .CUSTOMERCANCELED ||
                                            tripController.tripStatus.value ==
                                                EnumTripStatus.COMPANYCANCELED
                                        ? customerCancel
                                        : const Center(),
              ),
            ),
          ),
        ),
        Obx(
          () {
            if (tripController.isLoading.value) {
              return CustomLoadingDialog();
            } else {
              return const Center();
            }
          },
        )
      ],
    );
  }
}
