import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/services/general_service.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';
import 'package:tax_app/widgets/custom_text_arrow.dart';

import '../models/event.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/image_constants.dart';
import '../utils/secure_storage.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_event.dart';
import '../widgets/custom_tap.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SettingScreenState();
}

// ignore_for_file: must_be_immutable
class SettingScreenState extends State<SettingScreen> {
  TripController tripController = Get.find<TripController>();
  CustomerController customerController = Get.find<CustomerController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Scaffold(
        backgroundColor: ColorConstant.WHITE,
        appBar: CustomAppBar(
          title: Text("setting_header".tr, style: CustomTextStyle.txtTitle2()),
          leading: IconButton(
            icon: Icon(IconConstant.ArrowBack),
            iconSize: 24,
            onPressed: () => Get.back(),
          ),
        ),
        body: Padding(
          padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                  onPressed: () => Get.toNamed(LANGUAGE),
                  child: Text("language".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1))),
              TextButton(
                  onPressed: () {
                    AwesomeNotifications().showNotificationConfigPage();
                  },
                  child: Text("notification".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1))),
              TextButton(
                  onPressed: () => Get.toNamed(TERM, arguments: 0),
                  child: Text("terms".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1))),
              TextButton(
                  onPressed: () {
                    tripController.resetTrip();
                    customerController.customer.value = null;
                    StorageService.deleteAllSecureData();
                    Get.offNamed(LOGIN);
                  },
                  child: Text("logout".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)))
            ],
          ),
        ));
  }
}
