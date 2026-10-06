import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:get/get.dart';
import 'package:tax_app/controllers/customer_controller.dart';
import 'package:tax_app/models/register_request.dart';
import 'package:tax_app/services/customer_service.dart';
import 'package:tax_app/services/login_service.dart';
import 'package:tax_app/widgets/custom_loading_dialog.dart';

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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RegisterScreenState();
}

enum PasswordMatch { none, match, fail }

// ignore_for_file: must_be_immutable
class RegisterScreenState extends State<RegisterScreen> {
  TextEditingController firstnameController = TextEditingController();
  TextEditingController lastnameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController passwordConfirmController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final formGlobalKey = GlobalKey<FormState>();
  final customerController = Get.find<CustomerController>();
  bool isFormReady = false;
  PasswordMatch isPasswordMatch = PasswordMatch.none;
  AutovalidateMode autoValidate = AutovalidateMode.disabled;
  final errorText = "register_error".tr;

  void formReady() {
    if (firstnameController.value.text.isNotEmpty &&
        lastnameController.value.text.isNotEmpty &&
        usernameController.value.text.isNotEmpty &&
        passwordController.value.text.isNotEmpty &&
        passwordConfirmController.value.text.isNotEmpty &&
        phoneNumberController.value.text.length == 12 &&
        isPasswordMatch == PasswordMatch.match) {
      setState(() {
        isFormReady = true;
      });
    } else {
      setState(() {
        isFormReady = false;
      });
    }
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
  void initState() {
    if (customerController.customer.value != null) {
      firstnameController.text = customerController.customer.value!.firstName;
      lastnameController.text = customerController.customer.value!.lastName;
      usernameController.text = customerController.customer.value!.userName;
      passwordController.text = "password";
      passwordConfirmController.text = "password";
      emailController.text = customerController.customer.value!.email ?? "";
      phoneNumberController.text = customerController.customer.value!.phoneNumber ?? "";
      isPasswordMatch = PasswordMatch.match;
    }
    super.initState();
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: ColorConstant.WHITE,
          appBar: CustomAppBar(
            title: Text("register_header".tr, style: CustomTextStyle.txtTitle2()),
            leading: IconButton(
              icon: Icon(IconConstant.ArrowBack),
              iconSize: 24,
              onPressed: () {
                Get.back();
              },
            ),
          ),
          body: Form(
            autovalidateMode: autoValidate,
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
                          enable: customerController.customer.value == null,
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
                          enable: customerController.customer.value == null,
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
                    child: Text("register_id".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    enable: customerController.customer.value == null,
                    controller: usernameController,
                    text: 'register_id_hint'.tr,
                    validate: validateText,
                    onChanged: (text) => setState(() {
                      customerController.setError("");
                      formReady();
                    }),
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 23, bottom: 10),
                    child: Text("register_password".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    enable: customerController.customer.value == null,
                    controller: passwordController,
                    text: 'register_password_hint1'.tr,
                    validate: validatePassword,
                    obscure: true,
                    onChanged: (text) => setState(() {
                      customerController.setError("");
                      checkPasswordMatch();
                      formReady();
                    }),
                  ),
                  const SizedBox(height: 5),
                  CustomTextFormField(
                    enable: customerController.customer.value == null,
                    controller: passwordConfirmController,
                    text: 'register_password_hint2'.tr,
                    validate: validatePassword,
                    obscure: true,
                    onChanged: (text) => setState(() {
                      customerController.setError("");
                      checkPasswordMatch();
                      formReady();
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
                  Padding(
                    padding: getPadding(left: 8, top: 23, bottom: 10),
                    child: Text("phone_phone".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    controller: phoneNumberController,
                    validate: validateText,
                    onChanged: (text) {
                      customerController.setError("");
                      formReady();
                    },
                    inputFormat: [MaskedInputFormatter('###-###-####', allowedCharMatcher: RegExp(r'^[0-9]+$'))],
                    text: "phone_phone".tr,
                  ),
                  Padding(
                    padding: getPadding(left: 8, top: 23, bottom: 10),
                    child: Text("register_email".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.BLACK1)),
                  ),
                  CustomTextFormField(
                    enable: customerController.customer.value == null,
                    controller: emailController,
                    text: 'register_email_hint'.tr,
                    validate: validateText,
                    onChanged: (text) => customerController.setError(""),
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
                        autoValidate = AutovalidateMode.onUserInteraction;
                        if (customerController.customer.value != null) {
                          await customerController.editPhone(phoneNumberController.value.text);
                          Get.toNamed(PHONE);
                        } else if (isPasswordMatch == PasswordMatch.match && formGlobalKey.currentState!.validate()) {
                          final register = RegisterRequest(
                              username: usernameController.value.text,
                              password: passwordController.value.text,
                              role: 2,
                              firstName: firstnameController.value.text,
                              lastName: lastnameController.value.text,
                              email: emailController.value.text,
                              language: customerController.language.value,
                              phoneNumber: phoneNumberController.value.text,
                              terms: customerController.termsCheck);
                          await customerController.register(register);
                          if (customerController.customer.value != null) {
                            customerController.setError("");
                            Get.toNamed(PHONE);
                          } else {}
                        } else {
                          customerController.setError(errorText);
                        }
                        //Get.back();
                      }
                    : null,
                child: Text("register_button".tr, style: CustomTextStyle.txtBody3(color: ColorConstant.WHITE)),
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
