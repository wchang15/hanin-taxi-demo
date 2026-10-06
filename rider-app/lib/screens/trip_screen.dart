import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';
import 'package:tax_app/widgets/custom_cancel_dialog.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';
import '../services/email_service.dart';
import '../services/redirect_service.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/image_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_driver_card.dart';
import '../widgets/custom_tap.dart';

//Trip Screen is without Map (Moving, completed stage)
class TripScreen extends StatefulWidget {
  const TripScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TripScreenState();
}

// ignore_for_file: must_be_immutable
class TripScreenState extends State<TripScreen> {
  final customerController = Get.find<CustomerController>();
  final locationController = Get.find<LocationController>();
  final tripController = Get.find<TripController>();
  final presetTips = [1, 2, 3];
  var tipController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var movingColumn = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(ImageConstant.animationCar),
        const SizedBox(height: 15),
        Text('trip_going_to_dest'.tr, style: CustomTextStyle.txtTitle2(color: ColorConstant.BLACK1)),
        const SizedBox(height: 15),
        Text('trip_riding'.tr, style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK3)),
        const SizedBox(height: 10),
        Obx(
          () => tripController.driver.value != null
              ? CustomDriverCard(
                  licensePlate: tripController.driver.value!.licensePlate,
                  carAndColor: '${tripController.driver.value!.carModel} ${tripController.driver.value!.carColor}',
                  companyName: tripController.driver.value!.companyName,
                  driverName: tripController.driver.value!.driverName,
                  phoneNumber: tripController.driver.value!.phoneNumber,
                  photo: 'photo',
                  isFull: true,
                )
              : const Center(),
        ),
        Container(
          padding: getPadding(left: 5, right: 5),
          decoration: BoxDecoration(color: ColorConstant.WHITE1, borderRadius: BorderRadius.circular(25)),
          child: TextButton.icon(
            onPressed: () {
              if (tripController.tripStatus.value == EnumTripStatus.GOINGTODEST) {
                RedirectService.launchMapNavigation(
                    tripController.endLocation.value!.latitude!, tripController.endLocation.value!.longitude!);
              }
            },
            icon: Icon(IconConstant.Location, color: ColorConstant.BLACK3),
            label: Text("trip_map".tr, style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3)),
          ),
        ),
      ],
    );
    var completedScreen = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(IconConstant.CheckCircle, color: ColorConstant.PRIMARY, size: 50),
              const SizedBox(height: 15),
              Text('trip_complete'.tr, style: CustomTextStyle.txtTitle2(color: ColorConstant.BLACK1)),
            ],
          ),
        ),
        const Divider(thickness: 1),
        Text('trip_tip_add'.tr, style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK1)),
        const SizedBox(height: 10),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var tip in presetTips)
                GestureDetector(
                  onTap: () => tripController.tipAmount.value = double.tryParse(tip.toStringAsFixed(2)) ?? 0.00,
                  child: Container(
                    margin: getMargin(all: 10),
                    padding: getPadding(all: 20),
                    decoration: BoxDecoration(
                      color: ColorConstant.YELLOW,
                      shape: BoxShape.circle,
                      border: tripController.tipAmount.value == tip
                          ? Border.all(color: ColorConstant.PRIMARY, width: 1.5)
                          : null,
                    ),
                    child: Text("\$$tip", style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Get.bottomSheet(
            Container(
              width: SIZE.width,
              padding: getPadding(left: 16, top: 24, right: 16, bottom: 32),
              decoration: BoxDecoration(
                color: ColorConstant.WHITE,
                borderRadius: const BorderRadiusDirectional.vertical(top: Radius.circular(25.0)),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstant.BLACK1.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Text('trip_tip_other_amount'.tr, style: CustomTextStyle.txtBody1(color: ColorConstant.PRIMARY)),
                        const SizedBox(height: 15),
                        Obx(
                          () {
                            tipController =
                                TextEditingController(text: tripController.tipAmount.value.toStringAsFixed(2));
                            return TextField(
                              controller: tipController,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                prefixText: '\$',
                                hintStyle: CustomTextStyle.txtBody1(color: ColorConstant.GREY3),
                                enabledBorder: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(getHorizontalSize(12.00)),
                                  borderSide: BorderSide(color: ColorConstant.PRIMARY, width: 2),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(getHorizontalSize(12.00)),
                                  borderSide: BorderSide(color: ColorConstant.PRIMARY, width: 2),
                                ),
                                contentPadding: getPadding(all: 10),
                              ),
                              keyboardType: TextInputType.number,
                              onTap: () => tipController.selection =
                                  TextSelection(baseOffset: 0, extentOffset: tipController.text.length),
                            );
                          },
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: CustomTap(
                        color: ColorConstant.PRIMARY,
                        onTap: () {
                          tripController.tipAmount.value = double.tryParse(tipController.text) ?? 0.00;
                          Get.back();
                        },
                        child: Text("trip_tip_okay".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ), //bottomSheet,
          child: Text('trip_tip_other_amount'.tr, style: CustomTextStyle.txtBody1(color: ColorConstant.PRIMARY)),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Text(
            "${'trip_payment_amount'.tr} ${tripController.getTripAmount()} ${'trip_tip'.tr} ${tripController.getTipAmount()}",
            style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3),
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () =>
              Text(tripController.getTripAndTipAmount(), style: CustomTextStyle.txtTitle1(color: ColorConstant.BLACK1)),
        ),
        const SizedBox(height: 100),
      ],
    );

    return Stack(
      children: [
        Scaffold(
          //key: scaffoldKey,
          backgroundColor: ColorConstant.WHITE,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(
                () => CustomAlert(
                  bgColor: ColorConstant.RED1,
                  color: ColorConstant.RED,
                  icon: IconConstant.Notification,
                  text: tripController.errorResponse.value,
                  visible: tripController.errorResponse.value.isNotEmpty,
                ),
              ),
              Obx(
                () => tripController.tripStatus.value == EnumTripStatus.COMPLETED
                    ? CustomTap(
                        color: ColorConstant.PRIMARY,
                        onTap: () async {
                          var res = await tripController.completeTrip();
                          if (res) {
                            Get.toNamed(RATEDRIVER);
                          }
                        },
                        child: Text("trip_payment_complete".tr,
                            style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
                      )
                    : const Center(),
              ),
            ],
          ),
          body: Obx(
            () => Container(
              color: ColorConstant.WHITE,
              width: SIZE.width,
              height: SIZE.height,
              padding: getPadding(left: 16, top: 24, right: 16, bottom: 32),
              child: tripController.tripStatus.value == EnumTripStatus.GOINGTODEST
                  ? movingColumn
                  : tripController.tripStatus.value == EnumTripStatus.COMPLETED
                      ? completedScreen
                      : const Center(),
            ),
          ),
        ),

        // top left button
        Obx(
          () => tripController.tripStatus.value != EnumTripStatus.GOINGTODEST &&
                  tripController.tripStatus.value != EnumTripStatus.COMPLETED
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: getPadding(top: 24, left: 8),
                    child: FloatingActionButton(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      onPressed: () {},
                      child: Container(
                        decoration: BoxDecoration(color: ColorConstant.WHITE, borderRadius: BorderRadius.circular(25)),
                        child: IconButton(
                          icon: Icon(
                            IconConstant.ArrowBack,
                            color: ColorConstant.BLACK,
                          ),
                          onPressed: () => tripController.removeTrip(),
                        ),
                      ),
                    ),
                  ),
                )
              : const Center(),
        ),

        //top right button
        Obx(
          () => tripController.tripStatus.value == EnumTripStatus.GOINGTODEST
              ? Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: getPadding(top: 24, right: 12),
                    child: Container(
                      decoration: BoxDecoration(color: ColorConstant.WHITE1, borderRadius: BorderRadius.circular(25)),
                      child: TextButton.icon(
                        onPressed: () {
                          customCancelDialog(
                            okayClick: () async {
                              EmailService.sendEmailToHanin(
                                  message: tripController.complaintController.text,
                                  screen: "Report",
                                  tripID: tripController.tripID.value);
                              Get.back();
                            }, //Send to API
                            title: 'trip_report'.tr,
                            contentText: 'trip_report_body'.tr,
                            cancelText: 'trip_report_close'.tr,
                            okayText: 'trip_report'.tr,
                            isContent: true,
                            hintText: 'trip_report_hint'.tr,
                            controller: tripController.complaintController,
                          );
                        },
                        icon: Icon(IconConstant.CarReport, color: ColorConstant.BLACK3),
                        label: Text("trip_report".tr, style: CustomTextStyle.txtCaption2(color: ColorConstant.BLACK3)),
                      ),
                    ),
                  ),
                )
              : const Center(),
        ),
        Obx(
          () {
            if (tripController.isLoading.value) {
              return CustomLoadingDialog();
            } else {
              return const Center();
            }
          },
        ),
      ],
    );
  }
}
