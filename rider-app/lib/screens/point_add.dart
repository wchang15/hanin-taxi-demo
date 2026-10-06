import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/utils/icon_constants.dart';

import '../services/customer_service.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../utils/validate_text.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_loading_dialog.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_text_arrow.dart';
import '../widgets/custom_text_form_field.dart';

class PointAddScreen extends StatefulWidget {
  const PointAddScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PointAddScreenState();
}

class PointAddScreenState extends State<PointAddScreen> {
  final customerController = Get.find<CustomerController>();
  final pointEditingController = TextEditingController();

  bool isSuccess = false;
  bool isSubmited = false;

  @override
  void initState() {
    super.initState();
  }

  bool isCoupon() => pointEditingController.value.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("pointcoupon_add_header".tr, style: CustomTextStyle.txtTitle2()),
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
                text: isSuccess ? 'pointcoupon_add_success'.tr : 'pointcoupon_add_fail'.tr,
                visible: isSubmited,
              ),
              CustomTap(
                color: isCoupon() ? ColorConstant.PRIMARY : ColorConstant.GREY2,
                onTap: isCoupon()
                    ? () async {
                        isSubmited = true;
                        final result = await CustomerServices.applyCoupon(pointEditingController.value.text);
                        if (result != null) {
                          pointEditingController.clear();
                          customerController.customer.value!.point = result;
                          isSuccess = true;
                        } else {
                          isSuccess = false;
                        }
                        setState(() {});
                      }
                    : null,
                child: Text("pointcoupon_add_button".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
              ),
            ],
          ),
          body: Container(
            padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("payment_point".tr, style: CustomTextStyle.txtTitle1(color: ColorConstant.BLACK1)),
                    CustomTextArrow(
                      onPressed: () => Get.toNamed(ADDPOINTSFROMCARD),
                      firstWidget: Text('pointcoupon_add_point'.tr,
                          style: CustomTextStyle.txtCaption2(color: ColorConstant.GREY3)),
                      secondWidget: Icon(IconConstant.ArrowForward, size: 16, color: ColorConstant.GREY3),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Text(customerController.customer.value!.point.toCurrencyString(leadingSymbol: '\$'),
                      style: CustomTextStyle.txtTitle4(color: ColorConstant.PRIMARY)),
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),
                Text("pointcoupon_add_coupon".tr, style: CustomTextStyle.txtTitle1(color: ColorConstant.BLACK1)),
                const SizedBox(height: 10),
                CustomTextFormField(
                  controller: pointEditingController,
                  text: 'pointcoupon_add_coupon_hint'.tr,
                  validate: validateText,
                  onChanged: (text) {
                    isSubmited = false;
                    setState(() {
                      customerController.setError("");
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        Obx(
          () {
            if (customerController.isLoading.value) {
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
