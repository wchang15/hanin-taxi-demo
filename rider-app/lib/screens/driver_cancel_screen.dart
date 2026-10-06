import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';

import '../services/email_service.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_cancel_dialog.dart';
import '../widgets/custom_loading_dialog.dart';
import '../widgets/custom_switch.dart';
import '../widgets/custom_tap.dart';

class DriverCancelScreen extends StatefulWidget {
  const DriverCancelScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DriverCancelScreenState();
}

class DriverCancelScreenState extends State<DriverCancelScreen> {
  final customerController = Get.find<CustomerController>();
  final tripController = Get.find<TripController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: getPadding(top: 10, right: 12),
              child: Container(
                decoration: BoxDecoration(color: ColorConstant.WHITE1, borderRadius: BorderRadius.circular(25)),
                child: TextButton.icon(
                  onPressed: () {
                    customCancelDialog(
                      okayClick: () async {
                        EmailService.sendEmailToHanin(
                            message: tripController.complaintController.text,
                            screen: "DriverCancel",
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
        ],
      ),
      backgroundColor: ColorConstant.WHITE,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: SIZE.width,
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomTap(
              color: ColorConstant.BLACK1,
              width: SIZE.width / 2.3,
              borderRadius: 12,
              onTap: () async {
                //remove customer queue
                var res = await tripController.removeCQ();
                if (res) {
                  await tripController.resetTrip();
                  Get.until((route) => Get.currentRoute == HOME);
                }
              },
              child: Text("trip_driver_cancel_home".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
            ),
            CustomTap(
              color: ColorConstant.PRIMARY,
              width: SIZE.width / 2.3,
              borderRadius: 12,
              onTap: () async {
                //remove customer queue
                var res = await tripController.rematchCQ();
                if (res) {
                  //await tripController.resetTrip();
                  Get.until((route) => Get.currentRoute == HOME);
                }
              },
              child:
                  Text("trip_driver_cancel_newdriver".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: getPadding(top: 0, left: 16, right: 16),
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 200),
            Icon(IconConstant.Error, color: ColorConstant.PRIMARY, size: 50),
            const SizedBox(height: 15),
            Text(
              "trip_driver_cancel_header".tr,
              style: CustomTextStyle.txtTitle2(color: ColorConstant.BLACK1),
            ),
            const SizedBox(height: 15),
            Text(
              "trip_driver_cancel_body".tr,
              textAlign: TextAlign.center,
              style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK3, height: 1.5),
            ),
          ],
        )),
      ),
    );
  }
}
