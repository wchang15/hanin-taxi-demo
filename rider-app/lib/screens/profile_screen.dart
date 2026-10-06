import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/controllers/trip_controller.dart';
import 'package:tax_app/models/register_request.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';
import '../utils/color_constants.dart';
import '../utils/constants.dart';
import '../utils/icon_constants.dart';
import '../utils/secure_storage.dart';
import '../utils/validate_text.dart';
import '../utils/size.dart';
import '../utils/text_styles.dart';
import '../widgets/custom_alert.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_tap.dart';
import '../widgets/custom_text_form_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ProfileScreenState();
}

// ignore_for_file: must_be_immutable
class ProfileScreenState extends State<ProfileScreen> {
  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final formGlobalKey = GlobalKey<FormState>();
  final customerController = Get.find<CustomerController>();
  final tripController = Get.find<TripController>();
  bool isFormReady = true;
  final errorText = "register_error".tr;
  late StreamSubscription<Customer?> listener;

  void formReady() {
    if (firstnameController.value.text.isNotEmpty && lastnameController.value.text.isNotEmpty) {
      setState(() {
        isFormReady = true;
      });
    } else {
      setState(() {
        isFormReady = false;
      });
    }
  }

  @override
  void initState() {
    passwordController.text = "password";
    phoneNumberController.text = customerController.customer.value!.phoneNumber ?? "";
    firstnameController.text = customerController.customer.value!.firstName;
    lastnameController.text = customerController.customer.value!.lastName;
    emailController.text = customerController.customer.value!.email ?? "";
    customerController.customer.listen((event) {
      if (customerController.customer.value != null) {
        phoneNumberController.text = customerController.customer.value!.phoneNumber ?? "";
      }
    });
    FocusManager.instance.primaryFocus?.unfocus();

    super.initState();
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("profile_header".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () => Get.back(),
            ),
          ),
          body: Form(
            key: formGlobalKey,
            child: Container(
              width: SIZE.width,
              padding: getPadding(left: 16, top: 0, right: 16, bottom: 24),
              child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: getPadding(left: 8, top: 34, bottom: 10),
                    child: Text("register_name".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: CustomTextFormField(
                          controller: firstnameController,
                          text: 'register_firstname'.tr,
                          validate: validateText,
                          onChanged: (text) => setState(() {
                            customerController.setError("");
                            formReady();
                          }),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        flex: 1,
                        child: CustomTextFormField(
                          controller: lastnameController,
                          text: 'register_lastname'.tr,
                          validate: validateText,
                          onChanged: (text) => setState(() {
                            customerController.setError("");
                            formReady();
                          }),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 23, bottom: 10),
                    child: Text("phone_phone".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextFormField(
                          controller: phoneNumberController,
                          onChanged: (String value) {},
                          text: '',
                          readOnly: true,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: CustomTap(
                          color: ColorConstant.PRIMARY,
                          onTap: () => Get.toNamed(PHONEEDIT),
                          circular: BorderRadius.circular(12),
                          child: Text("phone_edit".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 23, bottom: 10),
                    child: Text("register_password".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: CustomTextFormField(
                          controller: passwordController,
                          onChanged: (String value) {},
                          text: '',
                          readOnly: true,
                          obscure: true,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: CustomTap(
                          color: ColorConstant.PRIMARY,
                          onTap: () => Get.toNamed(PASSWORDEDIT),
                          circular: BorderRadius.circular(12),
                          child: Text("phone_edit".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 23, bottom: 10),
                    child: Text("register_email".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    controller: emailController,
                    text: 'register_email_hint'.tr,
                    validate: validateText,
                    onChanged: (text) => customerController.setError(""),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        var res = await CustomerServices.deleteUser();
                        if (res) {
                          //success
                          customerController.customer.value = null;
                          tripController.resetTrip();
                          StorageService.deleteAllSecureData();
                          Get.offNamed(LOGIN);
                        }
                      },
                      child: Text(
                        'profile_delete'.tr,
                        style: CustomTextStyle.txtCaption2(color: ColorConstant.GREY3)
                            .copyWith(decoration: TextDecoration.underline, decorationThickness: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
              CustomTap(
                color: isFormReady ? ColorConstant.PRIMARY : ColorConstant.GREY2,
                onTap: isFormReady
                    ? () async {
                        //Get.back();
                        var firstName = firstnameController.value.text;
                        var lastName = lastnameController.value.text;
                        var email = emailController.value.text;
                        var res = await customerController.updateCustomer(firstName, lastName, email);
                        if (res) {
                          Get.back();
                        } else {
                          customerController.setError("There was an error");
                        }
                      }
                    : null,
                child: Text("phone_edit".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
              ),
            ],
          ),
        ),
        Obx(
          () {
            if (customerController.isLoading.value) {
              return CustomLoadingDialog();
            } else {
              return Center();
            }
          },
        )
      ],
    );
  }
}
