import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_app/controllers/customer_controller.dart';

import '../controllers/trip_controller.dart';
import '../models/trip_history.dart';
import '../services/customer_service.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/image_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_loading_dialog.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TripHistoryScreenState();
}

// ignore_for_file: must_be_immutable
class TripHistoryScreenState extends State<TripHistoryScreen> {
  final customerController = Get.find<CustomerController>();
  final tripController = Get.find<TripController>();
  //Filter order has to match backend
  final historyFilter = [
    'trip_history_today'.tr,
    'trip_history_week'.tr,
    'trip_history_month'.tr,
    'trip_history_last_month'.tr,
    'trip_history_total'.tr
  ];
  int numFilter = 0;
  List<TripHistory?> tripHistories = List.empty();
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    numFilter = -1;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await setData(0);
    });
  }

  setData(int i) async {
    if (numFilter == i) return;
    setState(() {
      isLoading = true;
    });
    var res = await CustomerServices.getMyCompletedTrips(i);

    setState(() {
      numFilter = i;
      tripHistories = res;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("trip_history_header".tr,
                style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () => Get.back(),
            ),
          ),
          body: Container(
            padding: getPadding(left: 16, right: 16, top: 10),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < historyFilter.length; i++)
                        Flexible(
                          child: TextButton(
                            onPressed: () async {
                              await setData(i);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: i == numFilter
                                  ? ColorConstant.PRIMARY
                                  : ColorConstant.WHITE1,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              historyFilter[i].toString(),
                              style: CustomTextStyle.txtCaption2(
                                color: i == numFilter
                                    ? ColorConstant.WHITE
                                    : ColorConstant.BLACK3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  for (var history in tripHistories)
                    Column(
                      children: [
                        const Divider(thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(history!.date,
                                        style: CustomTextStyle.txtCaption2(
                                            color: ColorConstant.GREY3)),
                                    const SizedBox(
                                        height: 15,
                                        child: VerticalDivider(thickness: 1)),
                                    Text(history.time,
                                        style: CustomTextStyle.txtCaption2(
                                            color: ColorConstant.GREY3)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(history.pickUpLocation,
                                    style: CustomTextStyle.txtCaption2(
                                        color: ColorConstant.BLACK1)),
                                const SizedBox(height: 5),
                                Text(history.dropUpLocation,
                                    style: CustomTextStyle.txtCaption2(
                                        color: ColorConstant.BLACK1)),
                              ],
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    Text("${history.mileage}Mi",
                                        style: CustomTextStyle.txtCaption2(
                                            color: ColorConstant.BLACK1)),
                                    const SizedBox(
                                      height: 15,
                                      child: VerticalDivider(thickness: 1),
                                    ),
                                    Text(history.amount,
                                        style: CustomTextStyle.txtCaption2(
                                            color: ColorConstant.BLACK1)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text("Tip ${history.tip}",
                                    style: CustomTextStyle.txtCaption2(
                                        color: ColorConstant.GREY3)),
                                const SizedBox(height: 5),
                                Text("Tax ${history.tax}",
                                    style: CustomTextStyle.txtCaption2(
                                        color: ColorConstant.GREY3)),
                                const SizedBox(height: 5),
                                Text(history.totalAmount,
                                    style: CustomTextStyle.txtCaption2(
                                        color: ColorConstant.BLACK1)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
        isLoading ? CustomLoadingDialog() : const Center(),
      ],
    );
  }
}
