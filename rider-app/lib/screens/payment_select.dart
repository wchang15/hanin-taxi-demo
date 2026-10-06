import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
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
import '../widgets/custom_card.dart';
import '../widgets/custom_switch.dart';
import '../widgets/custom_text_arrow.dart';

class PaymentSelectScreen extends StatefulWidget {
  const PaymentSelectScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PaymentSelectScreenState();
}

// ignore_for_file: must_be_immutable
class PaymentSelectScreenState extends State<PaymentSelectScreen> {
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
            title:
                Text("payment_header".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () {
                customerController.setError("");
                Get.back();
              },
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Obx(
                () => CustomAlert(
                  bgColor: ColorConstant.RED1,
                  color: ColorConstant.RED,
                  icon: IconConstant.Notification,
                  text: customerController.errorResponse.value,
                  visible: customerController.errorResponse.value.isNotEmpty,
                ),
              ),
            ],
          ),

          // main container; map and input menu
          body: Container(
            padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
            width: SIZE.width,
            child: ListView(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text("payment_point".tr,
                          style: CustomTextStyle.txtTitle1(
                              color: ColorConstant.BLACK1)),
                    ),
                    CustomTextArrow(
                      onPressed: () => Get.toNamed(POINTADD),
                      firstWidget: Text('payment_add_point'.tr,
                          style: CustomTextStyle.txtCaption2(
                              color: ColorConstant.GREY3)),
                      secondWidget: Icon(IconConstant.ArrowForward,
                          size: 16, color: ColorConstant.GREY3),
                    ),
                  ],
                ),
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text("payment_useable_point".tr,
                            style: CustomTextStyle.txtBody2(
                                color: ColorConstant.BLACK1)),
                      ),
                      Expanded(
                        child: Text(
                            customerController.customer.value!.point
                                .toCurrencyString(leadingSymbol: '\$'),
                            style: CustomTextStyle.txtBody2(
                                color: ColorConstant.PRIMARY)),
                      ),
                      CustomSwtich(
                        text: '',
                        val: tripController.usePoints.value,
                        onChanged: (value) {
                          setState(() {
                            tripController.setUsePoint(value);
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text("payment_card".tr,
                          style: CustomTextStyle.txtTitle1(
                              color: ColorConstant.BLACK1)),
                    ),
                    CustomTextArrow(
                      onPressed: () => Get.toNamed(CARDADD),
                      firstWidget: Text('payment_add_card'.tr,
                          style: CustomTextStyle.txtCaption2(
                              color: ColorConstant.GREY3)),
                      secondWidget: Icon(IconConstant.ArrowForward,
                          size: 16, color: ColorConstant.GREY3),
                    ),
                  ],
                ),
                Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var card
                          in customerController.customer.value!.savedCards)
                        CustomCard(
                          image: card.brand!,
                          number: Text("**** ${card.last4}",
                              style: CustomTextStyle.txtBody1(
                                  color: ColorConstant.BLACK1)),
                          fillColor: tripController.customerCardID.value ==
                                  card.customerCardID
                              ? ColorConstant.YELLOW
                              : null,
                          borderColor: tripController.customerCardID.value ==
                                  card.customerCardID
                              ? ColorConstant.PRIMARY
                              : null,
                          onTap: () {
                            tripController
                                .selectCustomerCard(card.customerCardID!);
                            Get.back();
                          },
                          disabled: card.isExpired(),
                          cardID: card.customerCardID!,
                          isDefault: card.isDefault ?? false,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
