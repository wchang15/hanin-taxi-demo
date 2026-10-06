import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';

import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_loading_dialog.dart';
import '../widgets/custom_switch.dart';
import '../widgets/custom_tap.dart';

class RateDriverScreen extends StatefulWidget {
  const RateDriverScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RateDriverScreenState();
}

class RateDriverScreenState extends State<RateDriverScreen> {
  final customerController = Get.find<CustomerController>();
  final tripController = Get.find<TripController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            actions: [
              Padding(
                padding: getPadding(top: 12, right: 16),
                child: IconButton(
                  icon: Icon(IconConstant.Cancel),
                  iconSize: 30,
                  color: ColorConstant.BLACK1,
                  onPressed: () {
                    tripController.resetTrip();
                    Get.toNamed(HOME);
                  },
                ),
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomAlert(
                bgColor: ColorConstant.WHITE1,
                color: ColorConstant.BLACK3,
                icon: IconConstant.Notification,
                text: 'trip_rate_alert'.tr,
                visible: true,
              ),
              CustomTap(
                color: ColorConstant.PRIMARY,
                onTap: () async {
                  var res = await tripController.giveRating();
                  if (res) {
                  } else {
                    tripController.resetTrip();
                  }
                  Get.toNamed(HOME);
                },
                child: Text("trip_rate_button".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
              ),
            ],
          ),
          body: Container(
            //alignment: Alignment.topCenter,
            width: double.infinity,
            padding: getPadding(left: 16, top: 150, right: 16, bottom: 24),
            child: Column(
              children: [
                Text('trip_rate_experience'.tr, style: CustomTextStyle.txtTitle2(color: ColorConstant.BLACK1)),
                const SizedBox(height: 15),
                RatingBar.builder(
                  initialRating: tripController.rating.value.toDouble(),
                  minRating: 1,
                  direction: Axis.horizontal,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => Icon(IconConstant.Star, color: ColorConstant.PRIMARY),
                  onRatingUpdate: (rating) => tripController.rating.value = rating.toInt(),
                ),
              ],
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
