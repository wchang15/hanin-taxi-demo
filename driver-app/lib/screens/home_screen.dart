import 'package:driverapp/controllers/driver_controller.dart';
import 'package:driverapp/controllers/location_controller.dart';
import 'package:driverapp/utils/color_constants.dart';
import 'package:driverapp/utils/icon_constants.dart';
import 'package:driverapp/utils/text_styles.dart';
import 'package:driverapp/widgets/custom_text_arrow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/trip_controller.dart';
import '../services/hub_service.dart';
import '../utils/constants.dart';
import '../utils/secure_storage.dart';
import '../utils/size.dart';
import '../widgets/custom_driver_card.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_taxi_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeScreenState();
}

// ignore_for_file: must_be_immutable
class HomeScreenState extends State<HomeScreen> {
  final driverController = Get.find<DriverController>();
  final locationController = Get.find<LocationController>();
  final tripController = Get.find<TripController>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await locationController.setCurrentLocation();
      if (tripController.trip.value == null) {
        tripController.getStatus();
      }
      await HubService.initSignalR();
    });
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Scaffold(
      backgroundColor: ColorConstant.WHITE,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(
            () {
              final hasLocation =
                  locationController.currentLocation.value != null;
              final isLoading = driverController.isLoading.value ||
                  locationController.locationStatus.value ==
                      EnumLocationControllerStatus.Loading;
              return CustomTap(
                color: isLoading ? ColorConstant.GREY2 : ColorConstant.PRIMARY,
                onTap: isLoading
                    ? null
                    : () async {
                        if (!hasLocation) {
                          await locationController.setCurrentLocation();
                          return;
                        }
                        driverController.isLoading.value = true;
                        var res = await driverController.enqueue();
                        if (res) {
                          tripController.tripStatus.value =
                              EnumTripStatus.CUSTOMERSEARCHING;
                          Get.toNamed(TRIP);
                        }
                        driverController.isLoading.value = false;
                      },
                child: Text(
                  hasLocation
                      ? "Home_Start".tr
                      : "location_permission_retry".tr,
                  style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: getPadding(top: 60, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: getPadding(top: 20, bottom: 12),
              child:
                  Text('Home_Profile'.tr, style: CustomTextStyle.txtTitle1()),
            ),
            CustomDriverCard(
              companyName: driverController.driver.value!.companyName,
              driverName: driverController.driver.value!.fullName(),
              driverNumber: 'driver_number_label'.trParams({
                'number':
                    driverController.driver.value!.driverNumber.toString(),
              }),
              phoneNumber: driverController.driver.value!.phoneNumber,
              photo: 'photo',
            ),
            Padding(
              padding: getPadding(top: 20, bottom: 12),
              child:
                  Text('Home_Car_Info'.tr, style: CustomTextStyle.txtTitle1()),
            ),
            CustomTaxiCard(
              licensePlate: driverController.driver.value!.licensePlate,
              make: driverController.driver.value!.make,
              model: driverController.driver.value!.model,
              color: driverController.driver.value!.color,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Home_Recent_History'.tr,
                    style: CustomTextStyle.txtTitle1()),
                CustomTextArrow(
                  firstWidget: Text('Home_Show_More'.tr,
                      style: CustomTextStyle.txtCaption2(
                          color: ColorConstant.GREY3)),
                  secondWidget: Icon(IconConstant.ArrowForward,
                      size: 12, color: ColorConstant.GREY3),
                  onPressed: () => Get.toNamed(TRIPHISTORY),
                )
              ],
            ),
            Container(
              width: SIZE.width,
              //alignment: Alignment.center,
              color: ColorConstant.WHITE1,
              padding: getPadding(all: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      padding:
                          getPadding(left: 10, right: 10, top: 5, bottom: 5),
                      decoration: BoxDecoration(
                        color: ColorConstant.YELLOW,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Text('Home_Today'.tr,
                          style: CustomTextStyle.txtCaption2(
                              color: ColorConstant.SECONDARY))),
                  const SizedBox(height: 15),
                  Obx(
                    () => Text(
                        driverController.driver.value?.earnedString() ??
                            "\$0.00",
                        style: CustomTextStyle.txtTitle3(
                            color: ColorConstant.BLACK1)),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              child: TextButton(
                child: Text('Home_Logout'.tr,
                    style: CustomTextStyle.txtCaption2(
                        color: ColorConstant.GREY3, weight: FontWeight.w400)),
                onPressed: () {
                  StorageService.deleteAllSecureData();
                  tripController.tripStatus.value = EnumTripStatus.NONE;
                  tripController.trip.value = null;
                  driverController.driver.value = null;
                  Get.offNamed(LOGIN);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
