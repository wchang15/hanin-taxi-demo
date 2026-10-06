import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';

import '../services/customer_service.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_switch.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_text_arrow.dart';
import '../widgets/custom_text_form_field.dart';

class AddPointsFromCard extends StatefulWidget {
  const AddPointsFromCard({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => AddPointsFromCardState();
}

// ignore_for_file: must_be_immutable
class AddPointsFromCardState extends State<AddPointsFromCard> {
  final customerController = Get.find<CustomerController>();
  final tripController = Get.find<TripController>();
  final amountEditingController = TextEditingController();
  late int customerCardID;
  @override
  void initState() {
    super.initState();
    customerCardID = customerController.customer.value!.defaultCardID == null
        ? 0
        : customerController.customer.value!.defaultCardID!;
  }

  bool isAmount() => amountEditingController.value.text.isNotEmpty && customerCardID != 0;
  bool isSuccess = false;
  bool isSubmited = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("pointcard_add_point".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () => Get.back(),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomAlert(
                bgColor: isSuccess ? ColorConstant.BLUE1 : ColorConstant.RED1,
                color: isSuccess ? ColorConstant.BLUE : ColorConstant.RED,
                icon: isSuccess ? IconConstant.CheckCircle : IconConstant.Error,
                text: isSuccess ? 'pointcard_success'.tr : 'pointcard_fail'.tr,
                visible: isSubmited,
              ),
              CustomTap(
                color: isAmount() ? ColorConstant.PRIMARY : ColorConstant.GREY2,
                onTap: isAmount()
                    ? () async {
                        isSubmited = true;
                        final result =
                            await CustomerServices.addPoints(amountEditingController.value.text, customerCardID);
                        if (result != null) {
                          amountEditingController.clear();
                          customerController.customer.value!.point = result;
                          isSuccess = true;
                        } else {
                          isSuccess = false;
                        }
                        setState(() {});
                      }
                    : null,
                child: Text("pointcard_button".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
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
                Text("pointcard_amount".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                const SizedBox(height: 15),
                CustomTextFormField(
                  controller: amountEditingController,
                  text: 'pointcard_amount_hint'.tr,
                  inputFormat: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (text) {
                    isSubmited = false;
                    setState(() {
                      customerController.setError("");
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("pointcard_card".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                    CustomTextArrow(
                      onPressed: () => Get.toNamed(CARDADD),
                      firstWidget:
                          Text('pointcard_add_card'.tr, style: CustomTextStyle.txtCaption2(color: ColorConstant.GREY3)),
                      secondWidget: Icon(IconConstant.ArrowForward, size: 16, color: ColorConstant.GREY3),
                    ),
                  ],
                ),
                Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var card in customerController.customer.value!.savedCards)
                        CustomCard(
                          image: card.brand!,
                          number:
                              Text("**** ${card.last4}", style: CustomTextStyle.txtBody1(color: ColorConstant.BLACK1)),
                          fillColor: customerCardID == card.customerCardID ? ColorConstant.YELLOW : null,
                          borderColor: customerCardID == card.customerCardID ? ColorConstant.PRIMARY : null,
                          onTap: () {
                            customerCardID = card.customerCardID!;
                            setState(() {});
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
