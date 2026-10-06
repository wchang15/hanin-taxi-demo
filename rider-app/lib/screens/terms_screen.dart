import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/location_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';
import 'package:tax_app/widgets/custom_text_arrow.dart';

import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/image_constants.dart';
import '../utils/secure_storage.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_tap.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TermsScreenState();
}

// ignore_for_file: must_be_immutable
class TermsScreenState extends State<TermsScreen> {
  final customerController = Get.find<CustomerController>();

  @override
  void initState() {
    super.initState();
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
      MaterialState.selected,
    };
    if (states.any(interactiveStates.contains)) {
      return ColorConstant.PRIMARY;
    }
    return ColorConstant.GREY2;
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Scaffold(
      backgroundColor: ColorConstant.WHITE,
      appBar: CustomAppBar(
        title: Text("terms_agree".tr, style: CustomTextStyle.txtTitle2()),
        leading: IconButton(
            icon: Icon(IconConstant.ArrowBack),
            iconSize: 24,
            onPressed: () {
              StorageService.deleteAllSecureData();
              customerController.customer.value = null;
              Get.offNamed(LOGIN);
            }),
      ),
      body: Container(
        width: SIZE.width,
        padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("terms_agree_body".tr, maxLines: null, style: CustomTextStyle.txtTitle2(height: 1.5)),
            const SizedBox(height: 10),
            for (var index = 0; index < customerController.termsCheck.length; index++)
              Row(
                children: [
                  Obx(
                    () => Checkbox(
                      checkColor: ColorConstant.WHITE,
                      activeColor: ColorConstant.PRIMARY,
                      fillColor: MaterialStateProperty.resolveWith<Color>(getColor),
                      value: customerController.termsCheck[index],
                      onChanged: (bool? value) {
                        setState(() {
                          customerController.termsCheck[index] = value!;
                        });
                      },
                    ),
                  ),
                  CustomTextArrow(
                    firstWidget: Text(customerController.terms[index][0].tr,
                        style: CustomTextStyle.txtBody2(color: ColorConstant.BLACK1)),
                    secondWidget: customerController.terms[index][1] != ""
                        ? Icon(IconConstant.ArrowForward, size: 15, color: ColorConstant.BLACK1)
                        : const Center(),
                    onPressed: () =>
                        customerController.terms[index][1] != "" ? Get.toNamed(TERM, arguments: index) : null,
                    padding: getPadding(all: 0),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Obx(
            () => CustomTap(
              color: customerController.checkedRequiredTerms() ? ColorConstant.PRIMARY : ColorConstant.GREY2,
              onTap: () {
                customerController.checkedRequiredTerms() ? Get.toNamed(REGISTER) : null;
              },
              child: Text("register_button".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
            ),
          ),
        ],
      ),
    );
  }
}
