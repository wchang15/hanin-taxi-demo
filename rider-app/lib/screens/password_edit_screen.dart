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
import '../services/customer_service.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/image_constants.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../utils/validate_text.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_event.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_text_form_field.dart';

enum PasswordMatch { none, match, fail }

class PasswordEditScreen extends StatefulWidget {
  const PasswordEditScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => PasswordEditScreenState();
}

// ignore_for_file: must_be_immutable
class PasswordEditScreenState extends State<PasswordEditScreen> {
  bool isPWDSuccess = false;
  PasswordMatch isPasswordMatch = PasswordMatch.none;
  int customerID = 0;
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmController = TextEditingController();
  final customerController = Get.find<CustomerController>();

  bool isAlert = false;
  bool isSuccess = false;
  String alertMsg = "";

  @override
  void initState() {
    super.initState();
  }

  void checkPasswordMatch() {
    if (passwordController.value.text.isNotEmpty && passwordConfirmController.value.text.isNotEmpty) {
      if (passwordController.value.text != passwordConfirmController.value.text) {
        setState(() {
          isPasswordMatch = PasswordMatch.fail;
        });
      } else {
        setState(() {
          isPasswordMatch = PasswordMatch.match;
        });
      }
    } else {
      setState(() {
        isPasswordMatch = PasswordMatch.none;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //This needs to be changed to a new animation
    return Scaffold(
      backgroundColor: ColorConstant.WHITE,
      appBar: CustomAppBar(
        title: Text("register_password".tr, style: CustomTextStyle.txtTitle2()),
        leading: IconButton(
          icon: Icon(IconConstant.ArrowBack),
          iconSize: 24,
          onPressed: () {
            Get.back();
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CustomAlert(
            bgColor: ColorConstant.RED1,
            color: ColorConstant.RED,
            icon: IconConstant.Error,
            text: alertMsg,
            visible: isAlert,
          ),
          CustomTap(
            color: isPasswordMatch == PasswordMatch.match ? ColorConstant.PRIMARY : ColorConstant.GREY2,
            onTap: isPasswordMatch == PasswordMatch.match
                ? () async {
                    var res = await CustomerServices.resetPassword(
                        passwordController.value.text, customerController.customer.value!.customerId!);
                    if (res == "") {
                      //success
                      Get.back();
                    } else {
                      //error
                      setState(() {
                        isAlert = true;
                        isSuccess = false;
                        alertMsg = "reset_pwd_fail".tr;
                      });
                    }
                  }
                : null,
            child: Text("reset_pwd".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
          ),
        ],
      ),
      body: Padding(
        padding: getPadding(left: 16, top: 24, right: 16, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: getPadding(left: 8, top: 23, bottom: 10),
              child: Text("register_password".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
            ),
            CustomTextFormField(
              controller: passwordController,
              text: 'register_password_hint1'.tr,
              validate: validatePassword,
              obscure: true,
              onChanged: (text) => setState(() {
                isAlert = false;
                checkPasswordMatch();
              }),
            ),
            const SizedBox(height: 5),
            CustomTextFormField(
              controller: passwordConfirmController,
              text: 'register_password_hint2'.tr,
              validate: validatePassword,
              obscure: true,
              onChanged: (text) => setState(() {
                isAlert = false;
                checkPasswordMatch();
              }),
            ),
            Padding(
              padding: getPadding(left: 8, top: 10),
              child: isPasswordMatch == PasswordMatch.none
                  ? Text('register_password_validate'.tr,
                      style: CustomTextStyle.txtCaption1(color: ColorConstant.GREY3))
                  : isPasswordMatch == PasswordMatch.fail
                      ? Text('register_password_not_match'.tr,
                          style: CustomTextStyle.txtCaption1(color: ColorConstant.RED))
                      : Text('register_password_match'.tr,
                          style: CustomTextStyle.txtCaption1(color: ColorConstant.BLUE)),
            ),
          ],
        ),
      ),
    );
  }
}
